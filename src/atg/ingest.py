"""Ingest Star Wars API (SWAPI) resources into a DuckDB database."""

from __future__ import annotations

import argparse
import json
import re
import tempfile
from collections.abc import Iterable
from pathlib import Path
from typing import Any

import duckdb
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

DEFAULT_BASE_URL = "https://swapi.dev/api/"
DEFAULT_DB_PATH = Path("swapi/dev.duckdb")
DEFAULT_SCHEMA = "raw"

_IDENTIFIER_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def _validate_identifier(name: str) -> str:
    """Validate a SQL identifier to prevent injection when formatting DDL."""
    if not _IDENTIFIER_RE.match(name):
        raise ValueError(f"Invalid SQL identifier: {name!r}")
    return name


def build_session(timeout_retries: int = 3) -> requests.Session:
    """Create a requests Session configured with retry handling."""
    session = requests.Session()
    retry = Retry(
        total=timeout_retries,
        backoff_factor=0.5,
        status_forcelist=(429, 500, 502, 503, 504),
        allowed_methods=("GET",),
    )
    adapter = HTTPAdapter(max_retries=retry)
    session.mount("https://", adapter)
    session.mount("http://", adapter)
    return session


def fetch_endpoints(
    session: requests.Session,
    base_url: str = DEFAULT_BASE_URL,
    timeout: float = 30.0,
) -> dict[str, str]:
    """Fetch the root SWAPI index mapping resource names to endpoint URLs."""
    response = session.get(base_url, timeout=timeout)
    response.raise_for_status()
    data = response.json()
    if not isinstance(data, dict):
        raise ValueError(f"Expected JSON object from {base_url}, got {type(data).__name__}")
    return {str(k): str(v) for k, v in data.items()}


def fetch_resource(
    session: requests.Session,
    url: str,
    timeout: float = 30.0,
) -> list[dict[str, Any]]:
    """Fetch all records for a SWAPI resource, following pagination links."""
    records: list[dict[str, Any]] = []
    next_url: str | None = url

    while next_url:
        response = session.get(next_url, timeout=timeout)
        response.raise_for_status()
        payload = response.json()

        if isinstance(payload, list):
            records.extend(payload)
            break
        if isinstance(payload, dict) and "results" in payload:
            records.extend(payload["results"])
            next_url = payload.get("next")
        else:
            raise ValueError(f"Unexpected payload structure from {next_url}")

    return records


def load_records_to_duckdb(
    con: duckdb.DuckDBPyConnection,
    schema: str,
    table: str,
    records: list[dict[str, Any]],
) -> int:
    """Write JSON records into a DuckDB table, replacing any existing data."""
    safe_schema = _validate_identifier(schema)
    safe_table = _validate_identifier(table)
    con.execute(f"CREATE SCHEMA IF NOT EXISTS {safe_schema}")

    if not records:
        return 0

    with tempfile.NamedTemporaryFile(
        mode="w",
        suffix=".ndjson",
        encoding="utf-8",
        delete=True,
    ) as tmp:
        for record in records:
            tmp.write(json.dumps(record))
            tmp.write("\n")
        tmp.flush()

        con.execute(
            f"""
            CREATE OR REPLACE TABLE {safe_schema}.{safe_table} AS
            SELECT *, CURRENT_TIMESTAMP AS _ingested_at
            FROM read_json_auto(?)
            """,
            [tmp.name],
        )

    return len(records)


def ingest_swapi(
    db_path: Path = DEFAULT_DB_PATH,
    base_url: str = DEFAULT_BASE_URL,
    schema: str = DEFAULT_SCHEMA,
    resources: Iterable[str] | None = None,
    session: requests.Session | None = None,
) -> dict[str, int]:
    """Ingest SWAPI resources into DuckDB and return row counts per table."""
    own_session = session is None
    active_session = session or build_session()
    counts: dict[str, int] = {}

    try:
        endpoints = fetch_endpoints(active_session, base_url=base_url)
        selected = list(resources) if resources is not None else list(endpoints.keys())

        unknown = [name for name in selected if name not in endpoints]
        if unknown:
            available = ", ".join(sorted(endpoints))
            raise ValueError(f"Unknown SWAPI resources: {', '.join(unknown)}. Available: {available}")

        db_path.parent.mkdir(parents=True, exist_ok=True)
        with duckdb.connect(str(db_path)) as con:
            for name in selected:
                records = fetch_resource(active_session, endpoints[name])
                counts[name] = load_records_to_duckdb(con, schema=schema, table=name, records=records)
    finally:
        if own_session:
            active_session.close()

    return counts


def main(argv: list[str] | None = None) -> None:
    """CLI entrypoint for ingesting SWAPI data into DuckDB."""
    parser = argparse.ArgumentParser(description="Ingest SWAPI data into DuckDB.")
    parser.add_argument(
        "--db-path",
        type=Path,
        default=DEFAULT_DB_PATH,
        help=f"Path to DuckDB database file (default: {DEFAULT_DB_PATH})",
    )
    parser.add_argument(
        "--base-url",
        default=DEFAULT_BASE_URL,
        help=f"SWAPI root API URL (default: {DEFAULT_BASE_URL})",
    )
    parser.add_argument(
        "--schema",
        default=DEFAULT_SCHEMA,
        help=f"Target DuckDB schema (default: {DEFAULT_SCHEMA})",
    )
    parser.add_argument(
        "--resources",
        nargs="+",
        default=None,
        help="Optional subset of resources to ingest (e.g. people planets films)",
    )
    args = parser.parse_args(argv)

    counts = ingest_swapi(
        db_path=args.db_path,
        base_url=args.base_url,
        schema=args.schema,
        resources=args.resources,
    )
    for resource, count in counts.items():
        print(f"Loaded {count} rows into {args.schema}.{resource}")


if __name__ == "__main__":
    main()
