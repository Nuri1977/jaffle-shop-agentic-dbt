-- Revenue parity: total revenue in the store daily KPIs mart must equal
-- total order revenue (order_total) in the orders mart for the same date range.
-- A singular test passes when it returns zero rows.
with mart as (

    select sum(coalesce(revenue, 0)) as revenue
    from {{ ref('fct_store_daily_kpis') }}

),

orders_mart as (

    select sum(coalesce(order_total, 0)) as revenue
    from {{ ref('orders') }}
    where cast(ordered_at as date) >= (select min(order_date) from {{ ref('fct_store_daily_kpis') }})
      and cast(ordered_at as date) <= (select max(order_date) from {{ ref('fct_store_daily_kpis') }})

)

select *
from mart
cross join orders_mart
where mart.revenue <> orders_mart.revenue
