# Jaffle Shop

An e-commerce dbt project modeling the fictional **Jaffle Shop**. Sources are raw customers, orders, items, stores, products, and supplies (`ecom.raw_*`), transformed through staging → intermediate → mart layers into clean dimensions and facts for BI.

## Targets

| Target | Warehouse | Use |
|--------|-----------|-----|
| `dev` | DuckDB | Local development (`jaffle_shop.duckdb`, schema `main`) |
| `prod` | Databricks | Production deployment |

Switch targets with `--target dev` (default) or `--target prod`.

## Built with Rosetta DBT Studio

This project was built with an AI agent in **Rosetta DBT Studio**. See [`AGENTS.md`](AGENTS.md) for the project's AI instructions, naming conventions, model layers, and strict rules (including never touching `seeds/jaffle-data` and always running dbt with `--select`).

## Quick start

From the project root:

```bash
# Inspect the connection
dbt debug

# Run a single model
dbt run --select stg_customers

# Run a model and its downstream dependencies
dbt run --select stg_customers+

# Test a specific model
dbt test --select stg_orders

# Build + test a selection
dbt build --select tag:nightly
```

Never run bare `dbt run`, `dbt test`, or `dbt build` without a `--select` selector.

## Unused upstream files

The following files exist in the repo but are not used by the DuckDB dev / Databricks prod workflow in Rosetta DBT Studio. They are leftovers from the original dbt-Labs template and can be removed if desired:

- `.github/workflows/` — GitHub Actions CI/CD (`ci.yml`, `cd_prod.yml`, `cd_staging.yml`) that trigger dbt Cloud jobs for Snowflake, BigQuery, and Postgres. Not wired to this project's DuckDB/Databricks targets.
- `Taskfile.yml` — a `task` runner for generating synthetic data (`jafgen`), seeding, and cleaning up local dev environments.
- `requirements.in` / `requirements.txt` — Python dependencies (`pre-commit`, `requests`, `jafgen`, etc.) for local data generation and linting. Not required to run dbt in Rosetta DBT Studio.

## Model layers

- **Staging** (`models/staging/stg_*.sql`) — 1:1 with sources; renaming/casting only.
- **Intermediate** (`models/intermediate/int_*.sql`) — joins across staging models.
- **Marts** (`models/marts/dim_*.sql`, `models/marts/fct_*.sql`) — business-level aggregates for BI.

See `AGENTS.md` for full conventions and strict rules.
