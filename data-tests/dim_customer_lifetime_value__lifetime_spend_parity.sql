-- Revenue parity: lifetime_spend in the CLV mart must equal revenue (order_total) in orders.
-- A singular test passes when it returns zero rows.
with mart as (

    select sum(coalesce(lifetime_spend, 0)) as lifetime_spend
    from {{ ref('dim_customer_lifetime_value') }}

),

orders_mart as (

    select sum(coalesce(order_total, 0)) as lifetime_spend
    from {{ ref('orders') }}

)

select *
from mart
cross join orders_mart
where mart.lifetime_spend <> orders_mart.lifetime_spend
