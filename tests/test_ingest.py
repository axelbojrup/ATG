"""Unit tests for SWAPI to DuckDB ingestion."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from typing import Any
from unittest.mock import MagicMock

import duckdb

from atg.ingest import ingest_swapi


class _FakeResponse:
    def __init__(self, payload: Any, status_code: int = 200) -> None:
        self._payload = payload
        self.status_code = status_code

    def raise_for_status(self) -> None:
        if self.status_code >= 400:
            raise RuntimeError(f"HTTP {self.status_code}")

    def json(self) -> Any:
        return self._payload


class IngestSwapiTests(unittest.TestCase):
    def test_ingest_paginated_and_list_resources(self) -> None:
        responses = {
            "https://swapi.example/api/": _FakeResponse(
                {
                    "people": "https://swapi.example/api/people/",
                    "planets": "https://swapi.example/api/planets/",
                }
            ),
            "https://swapi.example/api/people/": _FakeResponse(
                {
                    "count": 2,
                    "next": "https://swapi.example/api/people/?page=2",
                    "results": [
                        {"name": "Luke Skywalker", "films": ["https://swapi.example/api/films/1/"]},
                    ],
                }
            ),
            "https://swapi.example/api/people/?page=2": _FakeResponse(
                {
                    "count": 2,
                    "next": None,
                    "results": [
                        {"name": "Darth Vader", "films": ["https://swapi.example/api/films/1/"]},
                    ],
                }
            ),
            "https://swapi.example/api/planets/": _FakeResponse(
                [
                    {"name": "Tatooine", "climate": "arid"},
                ]
            ),
        }

        session = MagicMock()
        session.get.side_effect = lambda url, timeout=30.0: responses[url]

        with tempfile.TemporaryDirectory() as tmpdir:
            db_path = Path(tmpdir) / "test.duckdb"
            counts = ingest_swapi(
                db_path=db_path,
                base_url="https://swapi.example/api/",
                schema="raw",
                session=session,
            )

            self.assertEqual(counts, {"people": 2, "planets": 1})

            with duckdb.connect(str(db_path), read_only=True) as con:
                people = con.execute("SELECT name, films FROM raw.people ORDER BY name").fetchall()
                self.assertEqual(
                    people,
                    [
                        ("Darth Vader", ["https://swapi.example/api/films/1/"]),
                        ("Luke Skywalker", ["https://swapi.example/api/films/1/"]),
                    ],
                )
                planets = con.execute("SELECT name, climate FROM raw.planets").fetchall()
                self.assertEqual(planets, [("Tatooine", "arid")])

    def test_unknown_resource_raises(self) -> None:
        session = MagicMock()
        session.get.return_value = _FakeResponse({"people": "https://swapi.example/api/people/"})

        with tempfile.TemporaryDirectory() as tmpdir:
            with self.assertRaises(ValueError):
                ingest_swapi(
                    db_path=Path(tmpdir) / "test.duckdb",
                    base_url="https://swapi.example/api/",
                    resources=["starships"],
                    session=session,
                )


if __name__ == "__main__":
    unittest.main()
