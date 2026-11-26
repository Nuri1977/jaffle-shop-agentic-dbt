# Plan 01 — New Mart Models for Business Requirements

## Objective
Implement four new mart models satisfying requirements 1–4 of `requirements.md`, with quality tests per requirement 5 and documentation per requirement 6. No existing models are modified.

## Existing models (reference only — not modified)
Staging (views): `stg_customers`, `stg_orders`, `stg_order_items`, `stg_products`, `stg_supplies`, `stg_locations`
Marts (tables): `customers`, `orders`, `order_items`, `products`, `supplies`, `locations`, `metricflow_time_spine`

Upstream dependencies relevant to the new marts:
- `orders` mart depends on `stg_orders` + `order_items` mart
- `order_items` mart depends on `stg_order_items`, `stg_orders`, `stg_products`, `stg_supplies`
- `customers` mart depends on `stg_customers` + `orders` mart

## New models

### 1. `dim_customer_lifetime_value`
**Requirement:** 1 — Customer lifetime value  
**Materialization:** table (mart default)  
**Grain:** one row per customer (`customer_id`)  
**Dependencies:** `stg_customers`, `orders` mart

Proposed columns:
- `customer_id` — primary key, not_null, unique
- `first_order_date` — date of customer's first order
- `last_order_date` — date of customer's most recent order
- `order_count` — total number of orders
- `lifetime_spend` — sum of order totals (lifetime spend)
- `avg_days_between_orders` — average days between consecutive orders
- `days_since_last_order` — days between last order and max order date (for segmentation)
- `segment` — `new`, `active`, `at risk`, `lapsed` based on `days_since_last_order`

Tests (requirement 5):
- `unique` + `not_null` on `customer_id` (primary key)
- `accepted_values` on `segment`: [`new`, `active`, `at risk`, `lapsed`]
- `not_null` on all key columns
- singular test: `lifetime_spend` in this mart equals `lifetime_spend` in `customers` mart (revenue parity with orders)

Docs (requirement 6): model description + description on every column.

### 2. `fct_monthly_cohort_retention`
**Requirement:** 2 — Monthly cohort retention  
**Materialization:** table (mart default)  
**Grain:** one row per `cohort_month` × `month_offset` (offsets 0–6)  
**Dependencies:** `orders` mart (or `stg_orders`)

Proposed columns:
- `cohort_month` — first-order month of the cohort (date, month grain)
- `month_offset` — integer 0–6 (0 = cohort month)
- `cohort_size` — number of customers whose first order was in `cohort_month`
- `retained_customers` — number of those customers who placed at least one order in the month at `month_offset`
- `retention_rate` — `retained_customers / cohort_size`

Tests (requirement 5):
- `unique` + `not_null` on composite key (`cohort_month`, `month_offset`)
- `not_null` on key columns
- singular test: total revenue attributed to cohorts in this mart equals revenue in `orders` mart (revenue parity)

Docs (requirement 6): model description + description on every column.

### 3. `fct_product_performance_weekly`
**Requirement:** 3 — Product performance  
**Materialization:** table (mart default)  
**Grain:** one row per product per week (`product_id`, `week_start`)  
**Dependencies:** `order_items` mart (which joins `stg_order_items`, `stg_orders`, `stg_products`, `stg_supplies`)

Proposed columns:
- `product_id`
- `product_type`
- `week_start` — week start date
- `revenue` — sum of product price (units × price)
- `units` — count of order items / quantity
- `gross_margin` — revenue minus supply cost (price minus supply cost)
- `rank_within_product_type` — rank of the product within its `product_type` for that week (by revenue)

Tests (requirement 5):
- `unique` + `not_null` on composite key (`product_id`, `week_start`)
- `not_null` on key columns
- singular test: total `revenue` in this mart equals revenue in `orders` mart (revenue parity)

Docs (requirement 6): model description + description on every column.

### 4. `fct_store_daily_kpis`
**Requirement:** 4 — Store daily KPIs  
**Materialization:** incremental  
**Grain:** one row per store per day (`location_id`, `order_date`)  
**Dependencies:** `orders` mart

Proposed columns:
- `location_id`
- `order_date`
- `order_count` — number of orders
- `revenue` — sum of order totals
- `average_order_value` — revenue / order_count

Incremental strategy: filter on `order_date` greater than the max `order_date` already in the table; unique key on (`location_id`, `order_date`) for merge/dedup.

Tests (requirement 5):
- `unique` + `not_null` on composite key (`location_id`, `order_date`)
- `not_null` on key columns
- singular test: total `revenue` in this mart equals revenue in `orders` mart (revenue parity)

Docs (requirement 6): model description + description on every column.

## Build order
1. Staging models `stg_*` — already exist (views), no change
2. Mart models `orders`, `order_items`, `customers` — already exist (tables), no change
3. `dim_customer_lifetime_value` — depends on `stg_customers`, `orders`
4. `fct_monthly_cohort_retention` — depends on `orders`
5. `fct_product_performance_weekly` — depends on `order_items`
6. `fct_store_daily_kpis` — depends on `orders` (incremental)

Build via `dbt build --select <model>` for each model in order, or `dbt build --select <downstream model>+` to include dependencies.

## Test conventions (from existing schema files)
- Primary key: `not_null` + `unique` on the id column, with `entity.type: primary`
- Foreign keys: `relationships` test to `ref(...)` with `entity.type: foreign`
- Accepted values: `accepted_values` with `arguments.values`
- Revenue parity: `dbt_utils.expression_is_true` or a singular/data test comparing mart revenue to `orders` revenue
- Every column: `description`

## File layout to create
```
models/marts/dim_customer_lifetime_value.sql
models/marts/dim_customer_lifetime_value.yml
models/marts/fct_monthly_cohort_retention.sql
models/marts/fct_monthly_cohort_retention.yml
models/marts/fct_product_performance_weekly.sql
models/marts/fct_product_performance_weekly.yml
models/marts/fct_store_daily_kpis.sql
models/marts/fct_store_daily_kpis.yml
```

No SQL is written in this plan. The next step is to author the model SQL and schema YAML files per this plan, then build and test incrementally.