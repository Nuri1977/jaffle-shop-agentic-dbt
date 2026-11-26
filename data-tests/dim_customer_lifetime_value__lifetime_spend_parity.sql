-- Revenue parity: lifetime_spend in the CLV mart must equal lifetime_spend in the customers mart.
-- A singular test passes when it returns zero rows.
with mart as (

    select sum(coalesce(lifetime_spend, 0)) as lifetime_spend
    from {{ ref('dim_customer_lifetime_value') }}

),

customers_mart as (

    select sum(coalesce(lifetime_spend, 0)) as lifetime_spend
    from {{ ref('customers') }}

)

select *
from mart
cross join customers_mart
where mart.lifetime_spend <> customers_mart.lifetime_spend
