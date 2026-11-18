FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

WORKDIR /app
ENV DUCKDB_PATH=/app/swapi/dev.duckdb \
    DAGSTER_HOME=/app/.dagster_home

# Install dependencies first for layer caching
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

# Copy project source and dbt project
COPY src/ src/
COPY swapi/ swapi/
COPY README.md ./

RUN uv sync --frozen --no-dev && \
    uv run dbt parse --project-dir swapi --profiles-dir swapi && \
    mkdir -p /app/.dagster_home

EXPOSE 3000

CMD ["uv", "run", "dagster", "asset", "materialize", "-m", "atg.orchestration", "--select", "*"]
