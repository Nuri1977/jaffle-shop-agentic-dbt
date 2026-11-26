{{
    config(
        materialized='incremental',
        unique_key=['location_id', 'order_date'],
        incremental_strategy='merge'
    )
}}

with orders as (

    select * from {{ ref('orders') }}

),

daily_kpis as (

    select
        location_id,
        cast(ordered_at as date) as order_date,
        count(order_id) as order_count,
        sum(order_total) as revenue

    from orders

    group by 1, 2

)

select
    location_id,
    order_date,
    order_count,
    revenue,
    revenue / nullif(order_count, 0) as average_order_value

from daily_kpis

{% if is_incremental() %}
where order_date > (select max(order_date) from {{ this }})
{% endif %}
