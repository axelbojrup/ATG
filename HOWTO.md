# How to Run the SWAPI ELT Pipeline

## Option 1: Run with Docker (Recommended)

Build the image:

```bash
docker build -t swapi-elt .
```

Run the full ELT pipeline (`atg` ingestion + `dbt build`) and write `swapi/dev.duckdb` to your local `swapi/` directory:

```bash
docker run --rm -v "$(pwd)/swapi:/app/swapi" swapi-elt
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

## Option 2: Run Locally with `uv`

```bash
uv run atg && DUCKDB_PATH=swapi/dev.duckdb uv run dbt build --project-dir swapi --profiles-dir swapi
```

Preview any model or inline query:

```bash
DUCKDB_PATH=swapi/dev.duckdb uv run dbt show --project-dir swapi --profiles-dir swapi --select person_vehicles --limit -1
```
