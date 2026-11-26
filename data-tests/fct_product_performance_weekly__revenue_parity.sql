-- Revenue parity: total revenue in the weekly product performance mart must equal
-- total product revenue (order_items_subtotal) in the orders mart.
-- A singular test passes when it returns zero rows.
with mart as (

    select sum(coalesce(revenue, 0)) as revenue
    from {{ ref('fct_product_performance_weekly') }}

),

orders_mart as (

    select sum(coalesce(order_items_subtotal, 0)) as revenue
    from {{ ref('orders') }}

)

select *
from mart
cross join orders_mart
where mart.revenue <> orders_mart.revenue
