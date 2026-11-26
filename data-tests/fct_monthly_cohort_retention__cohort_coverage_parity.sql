-- Cohort coverage parity: the total cohort size at month 0 (each customer's first-order
-- month) must equal the number of distinct customers in the orders mart.
-- A singular test passes when it returns zero rows.

with mart as (

    select sum(cohort_size) as cohort_customers
    from {{ ref('fct_monthly_cohort_retention') }}
    where month_offset = 0

),

orders_mart as (

    select count(distinct customer_id) as ordered_customers
    from {{ ref('orders') }}

)

select *
from mart
cross join orders_mart
where mart.cohort_customers <> orders_mart.ordered_customers
