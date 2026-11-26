# Business Requirements

1. **Customer lifetime value:** one row per customer with first and last order, order count, lifetime spend, average days between orders, and a segment (new, active, at risk, lapsed) from days since the last order.
2. **Monthly cohort retention:** for each first-order month, the share of customers who ordered again in months 1 to 6.
3. **Product performance:** revenue, units and gross margin (price minus supply cost) per product per week, with the rank inside its product type.
4. **Store daily KPIs:** an incremental model with orders, revenue and average order value per store per day.
5. **Quality rules:** every new mart has a primary-key test, `not_null` on keys, an `accepted_values` test on the segment, and a singular test that revenue in the marts equals revenue in `orders`.
6. **Docs:** every new model and column has a description.
