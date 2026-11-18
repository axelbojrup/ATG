"""Unit tests for Dagster orchestration definitions."""

from __future__ import annotations

import unittest

from dagster import AssetKey

from atg.orchestration import SWAPI_RESOURCES, defs


class OrchestrationTests(unittest.TestCase):
    def test_definitions_include_raw_and_dbt_assets_with_lineage(self) -> None:
        specs = {spec.key: spec for spec in defs.resolve_all_asset_specs()}

        for resource in SWAPI_RESOURCES:
            self.assertIn(AssetKey(["raw", resource]), specs)

        for model_name in ("stg_films", "int_film_planets", "dim_films", "person_vehicles"):
            self.assertIn(AssetKey([model_name]), specs)

        stg_films_deps = {dep.asset_key for dep in specs[AssetKey(["stg_films"])].deps}
        self.assertIn(AssetKey(["raw", "films"]), stg_films_deps)

    def test_job_and_schedule_registered(self) -> None:
        job = defs.resolve_job_def("swapi_elt_job")
        self.assertEqual(job.name, "swapi_elt_job")

        schedule = defs.get_schedule_def("swapi_daily_schedule")
        self.assertEqual(schedule.cron_schedule, "0 6 * * *")
        self.assertEqual(schedule.job_name, "swapi_elt_job")
