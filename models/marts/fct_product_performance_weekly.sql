with

order_items as (

    select * from {{ ref('order_items') }}

),

products as (

    select * from {{ ref('stg_products') }}

),

joined as (

    select

        order_items.product_id,

        products.product_type,

        {{ dbt.date_trunc('week', 'order_items.ordered_at') }} as week_start,

        order_items.product_price,

        order_items.supply_cost

    from order_items

    left join products
        on order_items.product_id = products.product_id

),

aggregated as (

    select

        product_id,
        product_type,
        week_start,

        sum(product_price) as revenue,
        count(*) as units,
        sum(product_price) - sum(coalesce(supply_cost, 0)) as gross_margin

    from joined

    group by 1, 2, 3

),

ranked as (

    select

        product_id,
        product_type,
        week_start,
        revenue,
        units,
        gross_margin,
        rank() over (
            partition by product_type, week_start
            order by revenue desc
        ) as rank_within_product_type

    from aggregated

)

select * from ranked
