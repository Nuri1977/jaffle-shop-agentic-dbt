# Jaffle Shop — dbt Project AI Instructions

## Project Overview

This is the **jaffle_shop** dbt project (version 3.0.0). It models an e-commerce domain with sources, staging, intermediate, and mart layers. The active connection is `jaffle_shop_dev`, a local DuckDB database at `jaffle_shop.duckdb` (schema `main`).

- **Project name:** `jaffle_shop`
- **Profile:** `jaffle_shop`
- **Profile target (dev):** `dev` — DuckDB
- **Profile target (prod):** Databricks
- **Default target:** `dev`

Run dbt from the project root: `/Users/Shared/academy/agentic/projects/jaffle_shop`.

## Naming Conventions

- **Sources:** `ecom.raw_*` (e.g. `ecom.raw_customers`, `ecom.raw_orders`, `ecom.raw_items`, `ecom.raw_stores`, `ecom.raw_products`, `ecom.raw_supplies`).
- **Staging models:** `stg_{entity}.sql` — one-to-one with sources, basic renaming/casting only, no complex logic.
- **Intermediate models:** `int_{name}.sql` — joins and complex transformations between staging models.
- **Mart models:** `dim_{name}.sql` (dimensions) or `fct_{name}.sql` (facts) — clean business-level aggregates for BI.
- **Schema files:** `schema.yml` alongside models, declaring tests and docs.
- **Seeds:** live in `seeds/`; the `jaffle-data` seed is governed by `dbt_project.yml` (`+enabled: '{{ var(''load_source_data'', false) }}'`).

## Model Layers

Follow standard dbt layering:

1. **Staging (`models/staging/`):** `stg_{source_name}.sql` — 1:1 mapping to sources. Column renaming and type casting only. No business logic or joins across sources.
2. **Intermediate (`models/intermediate/`):** `int_{name}.sql` — joins and reusable transformations across staging models.
3. **Marts (`models/marts/`):** `dim_*.sql` and `fct_*.sql` — final aggregates exposed to BI.

Materialization defaults (from `dbt_project.yml`):
- staging → view
- marts → table

## Targets

| Target | Warehouse | Use |
|--------|-----------|-----|
| `dev` | DuckDB | Local development (`jaffle_shop.duckdb`, schema `main`) |
| `prod` | Databricks | Production deployment |

Switch targets with `--target prod` (or `--target dev`). The active target is set in `profiles.yml`.

## Strict Rules

1. **Never touch `seeds/jaffle-data`.** This seed is intentionally disabled by default (`load_source_data` defaults to `false`). Do not modify, enable, or load it without explicit user approval.
2. **Always run dbt with `--select`.** Never run a bare `dbt run`, `dbt test`, or `dbt build` without a `--select` selector (e.g. `--select stg_customers`, `--select tag:nightly`, `--select my_model+`). This prevents accidental full-project executions.
3. Read before writing: inspect existing models/schema/macros with `readDbtModel` or `readFile` before making changes.
4. Verify after running: check dbt logs (`getDbtLogs`) and confirm exit code 0 with zero errors before declaring success.
5. Minimal intervention: make the smallest targeted change needed; do not refactor unrelated code.
6. Do not edit `profiles.yml` or any connection credentials — connection configuration is user-owned.
