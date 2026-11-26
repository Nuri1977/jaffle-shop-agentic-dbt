with

orders_with_month as (

    select
        *,
        cast({{ dbt.date_trunc('month', 'ordered_at') }} as date) as order_month

    from {{ ref('orders') }}

),

customer_first_orders as (

    select
        customer_id,
        min(order_month) as cohort_month

    from orders_with_month

    group by 1

),

customer_orders as (

    select
        o.order_id,
        o.customer_id,
        c.cohort_month,
        {% if target.type == 'databricks' %}
        (month(o.order_month) - month(c.cohort_month)) + 12 * (year(o.order_month) - year(c.cohort_month)) as month_offset
        {% else %}
        date_diff('month', c.cohort_month, o.order_month) as month_offset
        {% endif %}

    from orders_with_month as o

    join customer_first_orders as c
        on o.customer_id = c.customer_id

),

cohort_sizes as (

    select
        cohort_month,

        count(distinct customer_id) as cohort_size

    from customer_first_orders

    group by 1

),

retention as (

    select
        cohort_month,
        month_offset,

        count(distinct customer_id) as retained_customers

    from customer_orders

    where month_offset between 0 and 6

    group by 1, 2

),

joined as (

    select
        r.cohort_month,
        r.month_offset,
        c.cohort_size,
        r.retained_customers,

        cast(r.retained_customers as double) / c.cohort_size as retention_rate

    from retention as r

    join cohort_sizes as c
        on r.cohort_month = c.cohort_month

)

select
    cohort_month,
    month_offset,
    cohort_size,
    retained_customers,
    retention_rate

from joined

order by cohort_month, month_offset
