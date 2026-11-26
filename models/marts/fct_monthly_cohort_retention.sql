with

customer_first_orders as (

    select
        customer_id,
        date_trunc('month', min(ordered_at))::date as cohort_month

    from {{ ref('orders') }}

    group by 1

),

customer_orders as (

    select
        o.order_id,
        o.customer_id,
        c.cohort_month,

        date_diff(
            'month',
            c.cohort_month,
            date_trunc('month', o.ordered_at)::date
        ) as month_offset

    from {{ ref('orders') }} as o

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

        r.retained_customers::double / c.cohort_size as retention_rate

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
