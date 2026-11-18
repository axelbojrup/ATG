FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

WORKDIR /app
ENV DUCKDB_PATH=/app/swapi/dev.duckdb

# Install dependencies first for layer caching
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

# Copy project source and dbt project
COPY src/ src/
COPY swapi/ swapi/
COPY README.md ./

RUN uv sync --frozen --no-dev

CMD ["sh", "-c", "uv run atg && uv run dbt build --project-dir swapi --profiles-dir swapi"]
