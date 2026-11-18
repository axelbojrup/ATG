# How to Run the SWAPI ELT Pipeline

## Option 1: Run with Docker (Recommended)

Build the image:

```bash
docker build -t swapi-elt .
```

Run the full orchestrated ELT pipeline via Dagster (`raw/*` ingestion + `dbt build` + tests) and write `swapi/dev.duckdb` to your local `swapi/` directory:

```bash
docker run --rm -v "$(pwd)/swapi:/app/swapi" swapi-elt
```

Or start the Dagster UI (at http://localhost:3000) inside the container:

```bash
docker run --rm -p 3000:3000 -v "$(pwd)/swapi:/app/swapi" swapi-elt \
  uv run dagster dev -h 0.0.0.0 -p 3000
```

### Querying the data

Because DuckDB is file-based and `swapi/` is mounted into the container, `swapi/dev.duckdb` is available directly on your host machine:

- **From your IDE**: Open any file in `swapi/analyses/` and use the dbt extension's preview/execute action.
- **From the terminal via Docker**:
  ```bash
  docker run --rm -v "$(pwd)/swapi:/app/swapi" swapi-elt \
    uv run dbt show --project-dir swapi --profiles-dir swapi --select person_vehicles
  ```

---

## Option 2: Run with Dagster (Orchestrated ELT)

Start the Dagster UI (webserver + daemon) locally to inspect the full asset lineage (`raw/*` -> `staging` -> `intermediate` -> `marts`), trigger runs, or enable `swapi_daily_schedule`:

```bash
uv run dagster dev
```

Or materialize the entire asset graph from the CLI:

```bash
uv run dagster asset materialize -m atg.orchestration --select "*"
```

---

## Option 3: Run Locally with `uv`

```bash
uv run atg && DUCKDB_PATH=swapi/dev.duckdb uv run dbt build --project-dir swapi --profiles-dir swapi
```

Preview any model or inline query:

```bash
DUCKDB_PATH=swapi/dev.duckdb uv run dbt show --project-dir swapi --profiles-dir swapi --select person_vehicles --limit -1
```
