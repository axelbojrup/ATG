"""Dagster orchestration for the SWAPI ELT pipeline (ingestion + dbt)."""

import os
from collections.abc import Iterator
from pathlib import Path

from dagster import (
    AssetExecutionContext,
    AssetKey,
    AssetOut,
    AssetSelection,
    Definitions,
    MaterializeResult,
    ScheduleDefinition,
    define_asset_job,
    multi_asset,
)
from dagster_dbt import DbtCliResource, DbtProject, dbt_assets

from atg.ingest import DEFAULT_DB_PATH, ingest_swapi

PROJECT_ROOT = Path(__file__).resolve().parents[2]
SWAPI_DIR = PROJECT_ROOT / "swapi"

SWAPI_RESOURCES = (
    "films",
    "people",
    "planets",
    "species",
    "starships",
    "vehicles",
)

swapi_project = DbtProject(
    project_dir=SWAPI_DIR,
    profiles_dir=SWAPI_DIR,
)
swapi_project.prepare_if_dev()


def _resolve_db_path() -> Path:
    """Resolve the DuckDB path from DUCKDB_PATH or fall back to the default."""
    env_path = os.environ.get("DUCKDB_PATH")
    if env_path:
        return Path(env_path)
    if DEFAULT_DB_PATH.is_absolute():
        return DEFAULT_DB_PATH
    return PROJECT_ROOT / DEFAULT_DB_PATH


@multi_asset(
    outs={
        resource: AssetOut(
            key=AssetKey(["raw", resource]),
            group_name="raw",
            description=f"Raw SWAPI {resource} ingested into DuckDB.",
        )
        for resource in SWAPI_RESOURCES
    },
    can_subset=True,
    compute_kind="python",
)
def raw_swapi_assets(context: AssetExecutionContext) -> Iterator[MaterializeResult]:
    """Ingest selected SWAPI resources into the DuckDB raw schema."""
    db_path = _resolve_db_path()
    selected = [key.path[-1] for key in context.selected_asset_keys]
    counts = ingest_swapi(db_path=db_path, resources=selected)

    for resource in selected:
        yield MaterializeResult(
            asset_key=AssetKey(["raw", resource]),
            metadata={
                "row_count": counts[resource],
                "db_path": str(db_path),
            },
        )


@dbt_assets(manifest=swapi_project.manifest_path)
def swapi_dbt_assets(
    context: AssetExecutionContext,
    dbt: DbtCliResource,
) -> Iterator[object]:
    """Build and test all dbt models (staging -> intermediate -> marts)."""
    yield from dbt.cli(["build"], context=context).stream()


swapi_elt_job = define_asset_job(
    name="swapi_elt_job",
    selection=AssetSelection.all(),
    description="Run the full SWAPI ELT pipeline: ingest raw tables and build/test dbt models.",
)

swapi_daily_schedule = ScheduleDefinition(
    name="swapi_daily_schedule",
    job=swapi_elt_job,
    cron_schedule="0 6 * * *",
    description="Daily 06:00 UTC full refresh of SWAPI raw ingestion and dbt models.",
)

defs = Definitions(
    assets=[raw_swapi_assets, swapi_dbt_assets],
    jobs=[swapi_elt_job],
    schedules=[swapi_daily_schedule],
    resources={
        "dbt": DbtCliResource(project_dir=swapi_project),
    },
)
