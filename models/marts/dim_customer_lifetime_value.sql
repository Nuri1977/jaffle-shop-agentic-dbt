with

customers as (

    select * from {{ ref('stg_customers') }}

),

orders as (

    select * from {{ ref('orders') }}

),

customer_orders as (

    select
        customer_id,

        count(distinct order_id) as order_count,
        min(ordered_at) as first_order_date,
        max(ordered_at) as last_order_date,
        sum(order_total) as lifetime_spend

    from orders

    group by customer_id

),

order_gaps as (

    select
        customer_id,
        ordered_at,
        lag(ordered_at) over (
            partition by customer_id
            order by ordered_at asc
        ) as prev_ordered_at

    from orders

),

avg_gaps as (

    select
        customer_id,
        avg({{ dbt.datediff('day', 'prev_ordered_at', 'ordered_at') }}) as avg_days_between_orders

    from order_gaps

    where prev_ordered_at is not null

    group by customer_id

),

max_order_date as (

    select max(ordered_at) as max_ordered_at from orders

),

joined as (

    select
        customers.customer_id,
        customer_orders.first_order_date,
        customer_orders.last_order_date,
        customer_orders.order_count,
        customer_orders.lifetime_spend,
        avg_gaps.avg_days_between_orders,
        {{ dbt.datediff('day', 'customer_orders.last_order_date', 'max_order_date.max_ordered_at') }} as days_since_last_order

    from customers

    left join customer_orders using (customer_id)
    left join avg_gaps using (customer_id)
    cross join max_order_date

)

select
    customer_id,
    first_order_date,
    last_order_date,
    order_count,
    lifetime_spend,
    avg_days_between_orders,
    days_since_last_order,
    case
        when coalesce(order_count, 0) <= 1 then 'new'
        when days_since_last_order <= 30 then 'active'
        when days_since_last_order <= 60 then 'at risk'
        else 'lapsed'
    end as segment

from joined
