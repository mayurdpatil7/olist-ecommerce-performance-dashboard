-- =====================================================
-- SECTION 1: EXECUTIVE KPI ANALYSIS
-- =====================================================
-- Business Question:
-- What is the overall business performance snapshot of Olist?
-- Why This Matters:
-- Executive teams require high-level KPIs to monitor
-- revenue, customer scale, seller activity, and operational efficiency.

SELECT
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue,

    COUNT(DISTINCT o.order_id) AS total_orders,

    COUNT(DISTINCT o.customer_id) AS total_customers,

    COUNT(DISTINCT oi.seller_id) AS total_sellers,

    ROUND(
        SUM(oi.price + oi.freight_value)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS avg_order_value,

    ROUND(
        AVG(
            DATEDIFF(
                o.order_delivered_customer_date,
                o.order_purchase_timestamp
            )
        ),
        2
    ) AS avg_delivery_days

FROM orders AS o

JOIN order_items AS oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'delivered';

-- =====================================================
-- SECTION 2: GROWTH KPI ANALYSIS
-- =====================================================
-- Business Question:
-- How is monthly revenue and order volume changing over time?
-- Why This Matters:
-- Growth trends help businesses identify seasonality,
-- demand patterns, and periods of operational expansion or decline.

SELECT
    DATE_FORMAT(
        o.order_purchase_timestamp,
        '%Y-%m'
    ) AS order_month,

    ROUND(
        SUM(oi.price + oi.freight_value),
        2
    ) AS monthly_revenue,

    COUNT(DISTINCT o.order_id) AS total_orders,

    ROUND(
        SUM(oi.price + oi.freight_value)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS avg_order_value

FROM orders AS o

JOIN order_items AS oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'delivered'

GROUP BY order_month

ORDER BY order_month;

-- -----------------------------------------------------
-- MONTH-OVER-MONTH REVENUE GROWTH ANALYSIS
-- -----------------------------------------------------
-- Business Question:
-- How is revenue growing month-over-month?
-- Why This Matters:
-- Month-over-month growth helps businesses measure
-- growth momentum, detect slowdowns, and evaluate business performance trends.

WITH monthly_revenue AS (

    SELECT
        DATE_FORMAT(
            o.order_purchase_timestamp,
            '%Y-%m'
        ) AS order_month,

        ROUND(
            SUM(oi.price + oi.freight_value),
            2
        ) AS monthly_revenue

    FROM orders AS o

    JOIN order_items AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'
    AND o.order_purchase_timestamp >= '2017-01-01'
    GROUP BY order_month
)

SELECT
    order_month,
    monthly_revenue,
    previous_month_revenue,
ROUND(
        (
            (
                monthly_revenue
                - previous_month_revenue
            )
            / previous_month_revenue
        ) * 100,
        2
    ) AS mom_growth_percentage

FROM (

    SELECT
        order_month,

        monthly_revenue,

        LAG(monthly_revenue)
            OVER (
                ORDER BY order_month
            ) AS previous_month_revenue

    FROM monthly_revenue

) AS growth_data

WHERE previous_month_revenue IS NOT NULL
AND previous_month_revenue > 1000;

-- =====================================================
-- SECTION 3: CUSTOMER INTELLIGENCE ANALYSIS
-- =====================================================
-- -----------------------------------------------------
-- REPEAT CUSTOMER ANALYSIS
-- -----------------------------------------------------
-- Business Question:
-- What percentage of customers are repeat customers?

-- Why This Matters:
-- Repeat customers indicate customer satisfaction,
-- retention strength, and long-term business sustainability.

WITH customer_orders AS (

    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id) AS total_orders

    FROM orders AS o

    JOIN customers AS c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
)

SELECT
    COUNT(*) AS total_customers,

    SUM(
        CASE
            WHEN total_orders > 1
            THEN 1
            ELSE 0
        END
    ) AS repeat_customers,

    ROUND(
        (
            SUM(
                CASE
                    WHEN total_orders > 1
                    THEN 1
                    ELSE 0
                END
            ) * 100.0
        ) / COUNT(*),
        2
    ) AS repeat_customer_percentage

FROM customer_orders;

-- -----------------------------------------------------
-- CUSTOMER PURCHASE FREQUENCY ANALYSIS
-- -----------------------------------------------------
-- Business Question:
-- How frequently do customers place orders?

-- Why This Matters:
-- Purchase frequency helps businesses understand
-- customer loyalty patterns and long-term customer engagement.

WITH customer_orders AS (

    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id) AS total_orders

    FROM orders AS o

    JOIN customers AS c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
)

SELECT
    total_orders,

    COUNT(*) AS number_of_customers,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage

FROM customer_orders

GROUP BY total_orders

ORDER BY total_orders;

-- -----------------------------------------------------
-- CUSTOMER LIFETIME VALUE ANALYSIS
-- -----------------------------------------------------
-- Business Question:
-- What is the average lifetime value of customers?

-- Why This Matters:
-- Customer Lifetime Value helps businesses understand
-- long-term customer revenue contribution and customer profitability potential.

WITH customer_ltv AS (

    SELECT
        c.customer_unique_id,

        ROUND(
            SUM(oi.price + oi.freight_value),
            2
        ) AS customer_lifetime_value,

        COUNT(DISTINCT o.order_id) AS total_orders

    FROM orders AS o

    JOIN customers AS c
        ON o.customer_id = c.customer_id

    JOIN order_items AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
)

SELECT
    ROUND(
        AVG(customer_lifetime_value),
        2
    ) AS avg_customer_ltv,

    ROUND(
        MAX(customer_lifetime_value),
        2
    ) AS highest_customer_ltv,

    ROUND(
        MIN(customer_lifetime_value),
        2
    ) AS lowest_customer_ltv

FROM customer_ltv;

-- -----------------------------------------------------
-- TOP CUSTOMER VALUE ANALYSIS
-- -----------------------------------------------------
-- Business Question:
-- Which customers generate the highest revenue?

-- Why This Matters:
-- Identifying high-value customers helps businesses
-- prioritize retention, loyalty programs, and personalized marketing strategies.

WITH customer_ltv AS (

    SELECT
        c.customer_unique_id,

        ROUND(
            SUM(oi.price + oi.freight_value),
            2
        ) AS customer_lifetime_value,

        COUNT(DISTINCT o.order_id) AS total_orders

    FROM orders AS o

    JOIN customers AS c
        ON o.customer_id = c.customer_id

    JOIN order_items AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
)

SELECT
    customer_unique_id,

    total_orders,

    customer_lifetime_value,

    DENSE_RANK() OVER (
        ORDER BY customer_lifetime_value DESC
    ) AS customer_rank

FROM customer_ltv

ORDER BY customer_lifetime_value DESC

LIMIT 10;

-- =====================================================
-- SECTION 4: DELIVERY PERFORMANCE ANALYSIS
-- =====================================================
-- -----------------------------------------------------
-- ORDER STATUS DISTRIBUTION ANALYSIS
-- -----------------------------------------------------
-- Business Question:
-- What is the distribution of order statuses?

-- Why This Matters:
-- Order status distribution helps businesses monitor
-- operational efficiency, fulfillment success, cancellations,
-- and customer delivery outcomes.

SELECT
    order_status,

    COUNT(*) AS total_orders,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS order_percentage

FROM orders

GROUP BY order_status

ORDER BY total_orders DESC;

-- -----------------------------------------------------
-- DELIVERY DELAY ANALYSIS
-- -----------------------------------------------------
-- Business Question:
-- What percentage of delivered orders were delayed?

-- Why This Matters:
-- Delivery delays negatively impact customer satisfaction,
-- reviews, retention, and overall marketplace trust.

SELECT
    COUNT(*) AS total_delivered_orders,

    SUM(
        CASE
            WHEN order_delivered_customer_date
                 > order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS delayed_orders,

    ROUND(
        (
            SUM(
                CASE
                    WHEN order_delivered_customer_date
                         > order_estimated_delivery_date
                    THEN 1
                    ELSE 0
                END
            ) * 100.0
        ) / COUNT(*),
        2
    ) AS delayed_order_percentage

FROM orders

WHERE order_status = 'delivered';

-- -----------------------------------------------------
-- AVERAGE DELIVERY DELAY ANALYSIS
-- -----------------------------------------------------
-- Business Question:
-- How severe are delivery delays on average?

-- Why This Matters:
-- Average delay duration helps businesses evaluate
-- operational efficiency and customer delivery experience quality.

SELECT 
    ROUND(AVG(delay_days), 2) AS avg_delay_days,
    MAX(delay_days) AS maximum_delay_days,
    MIN(delay_days) AS minimum_delay_days
FROM
    (SELECT 
        DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) AS delay_days
    FROM
        orders
    WHERE
        order_status = 'delivered'
            AND order_delivered_customer_date > order_estimated_delivery_date) AS delayed_orders
WHERE
    delay_days > 0;

-- -----------------------------------------------------
-- DELIVERY DELAY IMPACT ON CUSTOMER REVIEWS
-- -----------------------------------------------------
-- Business Question:
-- How do delivery delays impact customer review scores?

-- Why This Matters:
-- Understanding the relationship between delivery performance
-- and customer satisfaction helps businesses improve retention,
-- customer experience, and operational efficiency.

WITH delivery_analysis AS (

    SELECT
        o.order_id,

        r.review_score,

        CASE
            WHEN o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
            THEN 'Delayed'

            ELSE 'On Time'
        END AS delivery_status

    FROM orders AS o

    JOIN order_reviews AS r
        ON o.order_id = r.order_id

    WHERE o.order_status = 'delivered'
)

SELECT
    delivery_status,

    COUNT(*) AS total_orders,

    ROUND(
        AVG(review_score),
        2
    ) AS avg_review_score

FROM delivery_analysis

GROUP BY delivery_status;

-- =====================================================
-- SECTION 5: PRODUCT & CATEGORY INTELLIGENCE
-- =====================================================
-- -----------------------------------------------------
-- CATEGORY REVENUE CONTRIBUTION ANALYSIS
-- -----------------------------------------------------
-- Business Question:
-- Which product categories contribute the most revenue?

-- Why This Matters:
-- Revenue contribution analysis helps businesses identify
-- high-performing categories, prioritize inventory strategy,
-- and optimize product portfolio decisions.

SELECT 
    pct.product_category_name_english AS category_name,
    
    ROUND(
        SUM(oi.price + oi.freight_value),
        2
    ) AS total_revenue

FROM order_items AS oi

INNER JOIN products AS p
    ON oi.product_id = p.product_id

INNER JOIN product_category_translation AS pct
    ON p.product_category_name = pct.product_category_name

GROUP BY pct.product_category_name_english

ORDER BY total_revenue DESC

LIMIT 10;

/* =========================================================
   SECTION 6: ADVANCED BUSINESS ANALYSIS
   ========================================================= */
/* =========================================================
   1. SELLER PERFORMANCE ANALYSIS
   ========================================================= */
   /* Business Question:
Which sellers generate the highest revenue?
*/

SELECT
    s.seller_id,

    ROUND(
        SUM(oi.price + oi.freight_value),
        2
    ) AS total_revenue,

    COUNT(DISTINCT oi.order_id) AS total_orders,

    ROUND(
        AVG(oi.price + oi.freight_value),
        2
    ) AS avg_order_value

FROM order_items AS oi

INNER JOIN sellers AS s
    ON oi.seller_id = s.seller_id

GROUP BY s.seller_id

ORDER BY total_revenue DESC

LIMIT 10;

/* =========================================================
   Seller Revenue Contribution Analysis
   ========================================================= */

WITH seller_performance AS (

    SELECT

        s.seller_id,

        ROUND(
            SUM(oi.price + oi.freight_value),
            2
        ) AS total_revenue,

        COUNT(DISTINCT oi.order_id) AS total_orders,

        ROUND(
            AVG(oi.price + oi.freight_value),
            2
        ) AS avg_order_value

    FROM order_items AS oi

    INNER JOIN sellers AS s
        ON oi.seller_id = s.seller_id

    GROUP BY s.seller_id
)

SELECT

    seller_id,

    total_revenue,

    total_orders,

    avg_order_value,

    DENSE_RANK() OVER (
        ORDER BY total_revenue DESC
    ) AS seller_rank,

    ROUND(
        total_revenue * 100.0
        / SUM(total_revenue) OVER (),
        2
    ) AS revenue_contribution_percentage

FROM seller_performance

ORDER BY total_revenue DESC

LIMIT 10;

/* =========================================================
   2. GEOGRAPHIC PERFORMANCE ANALYSIS
   ========================================================= */
   /* Business Question:
Which states generate the highest revenue?
*/

SELECT

    c.customer_state,

    ROUND(
        SUM(oi.price + oi.freight_value),
        2
    ) AS total_revenue,

    COUNT(DISTINCT o.order_id) AS total_orders,

    COUNT(DISTINCT c.customer_unique_id) AS total_customers,

    ROUND(
        AVG(oi.price + oi.freight_value),
        2
    ) AS avg_order_value

FROM orders AS o

INNER JOIN customers AS c
    ON o.customer_id = c.customer_id

INNER JOIN order_items AS oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'delivered'

GROUP BY c.customer_state

ORDER BY total_revenue DESC;

/* =========================================================
   State Revenue Contribution Analysis
   ========================================================= */

WITH state_performance AS (

    SELECT

        c.customer_state,

        ROUND(
            SUM(oi.price + oi.freight_value),
            2
        ) AS total_revenue,

        COUNT(DISTINCT o.order_id) AS total_orders,

        COUNT(DISTINCT c.customer_unique_id) AS total_customers,

        ROUND(
            AVG(oi.price + oi.freight_value),
            2
        ) AS avg_order_value

    FROM orders AS o

    INNER JOIN customers AS c
        ON o.customer_id = c.customer_id

    INNER JOIN order_items AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_state
)

SELECT

    customer_state,

    total_revenue,

    total_orders,

    total_customers,

    avg_order_value,

    DENSE_RANK() OVER (
        ORDER BY total_revenue DESC
    ) AS state_rank,

    ROUND(
        total_revenue * 100.0
        / SUM(total_revenue) OVER (),
        2
    ) AS revenue_contribution_percentage

FROM state_performance

ORDER BY total_revenue DESC;

-- =========================================================
-- SECTION 8: PAYMENT ANALYSIS
-- =========================================================
-- =========================================================
-- BUSINESS QUESTION:
-- Which payment methods generate the highest revenue
-- and order volume?
-- =========================================================
-- =========================================================
-- WHY THIS MATTERS:
-- Payment behavior helps businesses understand:
-- - customer checkout preferences
-- - high performing payment methods
-- - average transaction behavior
-- - revenue dependency on payment types
-- =========================================================

WITH payment_analysis AS (

    SELECT

        op.payment_type,

        ROUND(
            SUM(op.payment_value),
            2
        ) AS total_revenue,

        COUNT(DISTINCT op.order_id) AS total_orders,

        ROUND(
            AVG(op.payment_value),
            2
        ) AS avg_payment_value

    FROM order_payments AS op

    GROUP BY op.payment_type
)

SELECT

    payment_type,

    total_revenue,

    total_orders,

    avg_payment_value,

    DENSE_RANK() OVER (
        ORDER BY total_revenue DESC
    ) AS payment_rank,

    ROUND(
        total_revenue * 100.0
        / SUM(total_revenue) OVER (),
        2
    ) AS revenue_contribution_percentage

FROM payment_analysis

ORDER BY total_revenue DESC;

-- =========================================================
-- SECTION 9: CUSTOMER SEGMENTATION ANALYSIS
-- =========================================================
-- =========================================================
-- BUSINESS QUESTION:
-- How are customers distributed across different
-- spending segments?
-- =========================================================
-- =========================================================
-- WHY THIS MATTERS:
-- Customer segmentation helps businesses:
-- - identify high-value customers
-- - improve targeted marketing strategies
-- - optimize customer retention efforts
-- - understand purchasing behavior patterns
-- =========================================================

WITH customer_spending AS (

    SELECT

        c.customer_unique_id,

        ROUND(
            SUM(oi.price + oi.freight_value),
            2
        ) AS total_customer_spending,

        COUNT(DISTINCT o.order_id) AS total_orders

    FROM customers AS c

    INNER JOIN orders AS o
        ON c.customer_id = o.customer_id

    INNER JOIN order_items AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
),

customer_segments AS (

    SELECT

        customer_unique_id,

        total_customer_spending,

        total_orders,

        CASE

            WHEN total_customer_spending >= 1000
                THEN 'High Value Customers'

            WHEN total_customer_spending >= 500
                THEN 'Medium Value Customers'

            ELSE 'Low Value Customers'

        END AS customer_segment

    FROM customer_spending
)

SELECT

    customer_segment,

    COUNT(*) AS total_customers,

    ROUND(
        AVG(total_customer_spending),
        2
    ) AS avg_customer_spending,

    ROUND(
        AVG(total_orders),
        2
    ) AS avg_orders_per_customer,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage

FROM customer_segments

GROUP BY customer_segment

ORDER BY avg_customer_spending DESC;

-- =========================================================
-- SECTION 10: CUSTOMER PURCHASE FREQUENCY ANALYSIS
-- =========================================================
-- =========================================================
-- BUSINESS QUESTION:
-- How frequently do customers place orders?
-- =========================================================
-- =========================================================
-- WHY THIS MATTERS:
-- Purchase frequency analysis helps businesses:
-- - identify loyal customers
-- - measure customer retention
-- - understand repeat purchase behavior
-- - improve long-term customer engagement
-- =========================================================

WITH customer_frequency AS (

    SELECT

        c.customer_unique_id,

        COUNT(DISTINCT o.order_id) AS total_orders

    FROM customers AS c

    INNER JOIN orders AS o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
),

frequency_segments AS (

    SELECT

        customer_unique_id,

        total_orders,

        CASE

            WHEN total_orders >= 5
                THEN 'Highly Frequent Customers'

            WHEN total_orders >= 2
                THEN 'Repeat Customers'

            ELSE 'One-Time Customers'

        END AS frequency_segment

    FROM customer_frequency
)

SELECT

    frequency_segment,

    COUNT(*) AS total_customers,

    ROUND(
        AVG(total_orders),
        2
    ) AS avg_orders_per_customer,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage

FROM frequency_segments

GROUP BY frequency_segment

ORDER BY avg_orders_per_customer DESC;

-- =========================================================
-- SECTION 11: ADVANCED REVENUE CONCENTRATION ANALYSIS
-- =========================================================
-- =========================================================
-- BUSINESS QUESTION:
-- Do a small percentage of customers contribute
-- most of the total revenue?
-- =========================================================
-- =========================================================
-- WHY THIS MATTERS:
-- Revenue concentration analysis helps businesses:
-- - identify VIP customers
-- - understand revenue dependency
-- - measure customer concentration risk
-- - improve customer retention strategies
-- =========================================================

WITH customer_revenue AS (

    SELECT

        c.customer_unique_id,

        ROUND(
            SUM(oi.price + oi.freight_value),
            2
        ) AS total_customer_revenue

    FROM customers AS c

    INNER JOIN orders AS o
        ON c.customer_id = o.customer_id

    INNER JOIN order_items AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
),

ranked_customers AS (

    SELECT

        customer_unique_id,

        total_customer_revenue,

        DENSE_RANK() OVER (
            ORDER BY total_customer_revenue DESC
        ) AS customer_rank,

        ROUND(
            total_customer_revenue * 100.0
            / SUM(total_customer_revenue) OVER (),
            4
        ) AS revenue_percentage

    FROM customer_revenue
)

SELECT

    customer_unique_id,

    total_customer_revenue,

    customer_rank,

    revenue_percentage,

    ROUND(
        SUM(revenue_percentage) OVER (
            ORDER BY total_customer_revenue DESC
        ),
        2
    ) AS cumulative_revenue_percentage

FROM ranked_customers

ORDER BY total_customer_revenue DESC

LIMIT 20;

-- =========================================================
-- SECTION 12: CUSTOMER RETENTION & REPEAT PURCHASE ANALYSIS
-- =========================================================
-- =========================================================
-- BUSINESS QUESTION:
-- How many customers are repeat buyers versus one-time buyers?
-- =========================================================
-- =========================================================
-- WHY THIS MATTERS:
-- Customer retention is one of the strongest indicators of business health. Repeat customers usually:
-- - cost less to retain
-- - spend more over time
-- - improve long-term profitability
-- =========================================================

WITH customer_orders AS (

    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id) AS total_orders

    FROM customers AS c

    INNER JOIN orders AS o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
),

customer_retention AS (

    SELECT
        CASE
            WHEN total_orders = 1 THEN 'One-Time Customers'
            ELSE 'Repeat Customers'
        END AS customer_type,

        total_orders

    FROM customer_orders
)

SELECT
    customer_type,

    COUNT(*) AS total_customers,

    ROUND(
        AVG(total_orders),
        2
    ) AS avg_orders_per_customer,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage

FROM customer_retention

GROUP BY customer_type

ORDER BY total_customers DESC;

-- ---------------------------------------------------------
-- 12.2 Top Repeat Customers by Order Frequency
-- ---------------------------------------------------------
-- Business Question:
-- Which customers place the highest number of repeat orders?
-- Why This Matters:
-- Highly engaged repeat buyers are extremely valuable because:
-- • they generate recurring revenue
-- • they improve customer lifetime value
-- • they indicate strong customer trust and satisfaction
-- • they are ideal targets for loyalty and retention campaigns
-- Identifying these customers helps businesses:
-- • build VIP customer programs
-- • create personalized marketing
-- • improve long-term retention strategies

WITH customer_frequency AS (

    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id) AS total_orders,

        ROUND(
            SUM(oi.price + oi.freight_value),
            2
        ) AS total_revenue

    FROM customers AS c

    INNER JOIN orders AS o
        ON c.customer_id = o.customer_id

    INNER JOIN order_items AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
),

ranked_customers AS (

    SELECT
        customer_unique_id,

        total_orders,

        total_revenue,

        DENSE_RANK() OVER (
            ORDER BY total_orders DESC
        ) AS frequency_rank

    FROM customer_frequency
)

SELECT
    customer_unique_id,

    total_orders,

    total_revenue,

    frequency_rank

FROM ranked_customers

ORDER BY total_orders DESC,
         total_revenue DESC

LIMIT 20;

-- ---------------------------------------------------------
-- 12.3 Revenue Contribution from Repeat Customers
-- ---------------------------------------------------------
-- Business Question:
-- How much revenue comes from repeat customers
-- compared to one-time customers?
-- Why This Matters:
-- A business becomes more stable when a larger
-- share of revenue comes from retained customers
-- rather than constantly acquiring new buyers.
-- This analysis helps identify:
-- • long-term customer value
-- • retention-driven revenue strength
-- • customer loyalty impact on profitability
-- • dependence on repeat buyers


WITH customer_orders AS (

    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id) AS total_orders,

        ROUND(
            SUM(oi.price + oi.freight_value),
            2
        ) AS total_revenue

    FROM customers AS c

    INNER JOIN orders AS o
        ON c.customer_id = o.customer_id

    INNER JOIN order_items AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
),

customer_segments AS (

    SELECT
        CASE
            WHEN total_orders = 1
                THEN 'One-Time Customers'

            ELSE 'Repeat Customers'
        END AS customer_type,

        total_revenue

    FROM customer_orders
)

SELECT
    customer_type,

    ROUND(
        SUM(total_revenue),
        2
    ) AS segment_revenue,

    ROUND(
        AVG(total_revenue),
        2
    ) AS avg_customer_revenue,

    ROUND(
        SUM(total_revenue) * 100.0
        / SUM(SUM(total_revenue)) OVER (),
        2
    ) AS revenue_contribution_percentage

FROM customer_segments

GROUP BY customer_type

ORDER BY segment_revenue DESC;

-- =========================================================
-- SECTION 13: ORDER & DELIVERY PERFORMANCE ANALYSIS
-- =========================================================
-- ---------------------------------------------------------
-- 13.1 Delivery Status Performance Analysis
-- ---------------------------------------------------------
-- Business Question:
-- What is the distribution of order delivery statuses
-- across the marketplace?
-- Why This Matters:
-- Delivery performance directly impacts:
-- • customer satisfaction
-- • operational efficiency
-- • marketplace reliability
-- • customer retention
-- Analyzing order statuses helps identify:
-- • successful fulfillment rates
-- • cancellation issues
-- • unavailable order patterns
-- • operational bottlenecks


SELECT
    order_status,

    COUNT(*) AS total_orders,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS order_percentage,

    DENSE_RANK() OVER (
        ORDER BY COUNT(*) DESC
    ) AS status_rank

FROM orders

GROUP BY order_status

ORDER BY total_orders DESC;

-- ---------------------------------------------------------
-- 13.2 Delayed Delivery Analysis
-- ---------------------------------------------------------
-- Business Question:
-- What percentage of delivered orders were delayed
-- beyond the estimated delivery date?
-- Why This Matters:
-- Delivery delays directly affect:
-- • customer satisfaction
-- • customer trust
-- • repeat purchase behavior
-- • seller reputation
-- • marketplace reliability
-- Analyzing delayed deliveries helps identify:
-- • logistics inefficiencies
-- • operational bottlenecks
-- • delivery performance quality
-- • customer experience risks

SELECT
    COUNT(*) AS total_delivered_orders,

    SUM(
        CASE
            WHEN order_delivered_customer_date
                 > order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS delayed_orders,

    ROUND(
        SUM(
            CASE
                WHEN order_delivered_customer_date
                     > order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) * 100.0
        / COUNT(*),
        2
    ) AS delayed_order_percentage

FROM orders

WHERE order_status = 'delivered';

-- ========================================================
-- 13.3 Average Delivery Time Analysis
-- =========================================================
-- Business Question:
-- What is the average, minimum, and maximum delivery time
-- for successfully delivered orders?
-- Why This Matters:
-- Delivery speed is one of the most important KPIs in e-commerce.
-- This analysis helps businesses evaluate operational efficiency,
-- logistics performance, customer satisfaction potential,
-- and delivery consistency across the platform.

WITH delivery_time_analysis AS (

    SELECT
        order_id,

        DATEDIFF(
            order_delivered_customer_date,
            order_purchase_timestamp
        ) AS delivery_days

    FROM orders

    WHERE order_status = 'delivered'

        AND order_delivered_customer_date IS NOT NULL

)

SELECT

    COUNT(*) AS total_delivered_orders,

    ROUND(
        AVG(delivery_days),
        2
    ) AS avg_delivery_days,

    MIN(delivery_days) AS minimum_delivery_days,

    MAX(delivery_days) AS maximum_delivery_days,

    ROUND(
        STDDEV(delivery_days),
        2
    ) AS delivery_time_stddev

FROM delivery_time_analysis;

-- =========================================================
-- 13.4 Delivery Performance Category Analysis
-- =========================================================

-- Business Question:
-- How many delivered orders were delivered early,
-- on time, or delayed compared to the estimated
-- delivery date?

-- Why This Matters:
-- This analysis helps evaluate logistics performance,
-- customer delivery experience, and operational reliability.
-- Businesses can monitor whether deliveries are consistently
-- meeting customer expectations or creating delays that may
-- impact satisfaction and retention.

WITH delivery_performance AS (

    SELECT

        order_id,

        DATEDIFF(
            order_delivered_customer_date,
            order_estimated_delivery_date
        ) AS delivery_gap_days,

        CASE

            WHEN order_delivered_customer_date
                 < order_estimated_delivery_date
            THEN 'Early Delivery'

            WHEN order_delivered_customer_date
                 = order_estimated_delivery_date
            THEN 'On-Time Delivery'

            ELSE 'Delayed Delivery'

        END AS delivery_status

    FROM orders

    WHERE order_status = 'delivered'

        AND order_delivered_customer_date IS NOT NULL

        AND order_estimated_delivery_date IS NOT NULL

)

SELECT

    delivery_status,

    COUNT(*) AS total_orders,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS delivery_percentage,

    RANK() OVER (
        ORDER BY COUNT(*) DESC
    ) AS delivery_rank

FROM delivery_performance

GROUP BY delivery_status

ORDER BY total_orders DESC;

-- =========================================================
-- 13.5 Estimated vs Actual Delivery Gap Analysis
-- =========================================================

-- Business Question:
-- On average, how many days earlier or later are
-- orders delivered compared to the estimated delivery date?

-- Why This Matters:
-- This analysis measures the accuracy of delivery estimation.
-- It helps businesses understand whether delivery promises
-- are realistic, conservative, or frequently delayed.
-- Accurate delivery estimation improves customer trust,
-- operational planning, and logistics reliability.

WITH delivery_gap_analysis AS (

    SELECT

        order_id,

        DATEDIFF(
            order_delivered_customer_date,
            order_estimated_delivery_date
        ) AS delivery_gap_days

    FROM orders

    WHERE order_status = 'delivered'

        AND order_delivered_customer_date IS NOT NULL

        AND order_estimated_delivery_date IS NOT NULL

)

SELECT

    COUNT(*) AS total_delivered_orders,

    ROUND(
        AVG(delivery_gap_days),
        2
    ) AS avg_delivery_gap_days,

    MIN(delivery_gap_days) AS earliest_delivery_gap,

    MAX(delivery_gap_days) AS maximum_delay_gap,

    ROUND(
        AVG(
            CASE
                WHEN delivery_gap_days < 0
                THEN ABS(delivery_gap_days)
            END
        ),
        2
    ) AS avg_early_delivery_days,

    ROUND(
        AVG(
            CASE
                WHEN delivery_gap_days > 0
                THEN delivery_gap_days
            END
        ),
        2
    ) AS avg_delay_days

FROM delivery_gap_analysis;

-- =========================================================
-- 13.6 Monthly Delivery Performance Trend Analysis
-- =========================================================
-- Business Question:
-- How has delivery performance changed over time
-- across different months?
-- Why This Matters:
-- This analysis helps businesses monitor operational
-- consistency and logistics performance trends over time.
-- It can reveal seasonal delivery issues, operational
-- improvements, or periods with increased delays.

WITH monthly_delivery_analysis AS (

    SELECT

        DATE_FORMAT(
            order_purchase_timestamp,
            '%Y-%m'
        ) AS order_month,

        COUNT(*) AS total_delivered_orders,

        SUM(

            CASE

                WHEN order_delivered_customer_date
                     > order_estimated_delivery_date
                THEN 1

                ELSE 0

            END

        ) AS delayed_orders

    FROM orders

    WHERE order_status = 'delivered'

        AND order_delivered_customer_date IS NOT NULL

        AND order_estimated_delivery_date IS NOT NULL

    GROUP BY order_month

)

SELECT

    order_month,

    total_delivered_orders,

    delayed_orders,

    ROUND(

        delayed_orders * 100.0
        / total_delivered_orders,

        2

    ) AS delayed_order_percentage,

    RANK() OVER (
                 ORDER BY ROUND(delayed_orders * 100.0 / total_delivered_orders, 2 ) DESC ) AS delay_rank

FROM monthly_delivery_analysis

ORDER BY order_month;

-- =========================================================
-- Subsection 13.7 : Seller Delivery Performance Analysis
-- =========================================================
-- Business Question:
-- Which sellers are contributing the most to delayed deliveries?
-- Why This Matters:
-- Helps identify unreliable sellers and improve
-- operational delivery performance.
-- =========================================================

WITH seller_delivery_analysis AS (

    SELECT

        oi.seller_id,

        COUNT(DISTINCT o.order_id) AS total_orders,

        SUM(
            CASE
                WHEN o.order_delivered_customer_date >
                     o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) AS delayed_orders

    FROM orders AS o

    INNER JOIN order_items AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY oi.seller_id

),

seller_performance AS (

    SELECT

        seller_id,

        total_orders,

        delayed_orders,

        ROUND(
            delayed_orders * 100.0
            / total_orders,
            2
        ) AS delayed_order_percentage,

        RANK() OVER (
            ORDER BY
            delayed_orders * 100.0
            / total_orders DESC
        ) AS seller_delay_rank

    FROM seller_delivery_analysis

    WHERE total_orders >= 50

)

SELECT *

FROM seller_performance

ORDER BY delayed_order_percentage DESC

LIMIT 20;

-- =========================================================
-- Subsection 13.8 : State-wise Delivery Delay Analysis
-- =========================================================
-- Business Question:
-- Which states experience the highest delivery delays?
--
-- Why This Matters:
-- Helps identify logistics bottlenecks and
-- regional delivery performance issues.
-- =========================================================

WITH state_delivery_analysis AS (

    SELECT

        c.customer_state,

        COUNT(DISTINCT o.order_id) AS total_delivered_orders,

        SUM(
            CASE
                WHEN o.order_delivered_customer_date >
                     o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) AS delayed_orders

    FROM orders AS o

    INNER JOIN customers AS c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_state

),

state_performance AS (

    SELECT

        customer_state,

        total_delivered_orders,

        delayed_orders,

        ROUND(
            delayed_orders * 100.0
            / total_delivered_orders,
            2
        ) AS delayed_order_percentage,

        RANK() OVER (
            ORDER BY
            delayed_orders * 100.0
            / total_delivered_orders DESC
        ) AS state_delay_rank

    FROM state_delivery_analysis

    WHERE total_delivered_orders >= 100

)

SELECT *

FROM state_performance

ORDER BY delayed_order_percentage DESC;

-- =========================================================
-- Subsection 13.9 : Monthly Delivery Performance Trend Analysis
-- =========================================================
-- Business Question:
-- How has delivery performance changed over time?
-- Why This Matters:
-- Helps track logistics consistency and
-- identify operational improvement trends.
-- =========================================================

WITH monthly_delivery_performance AS (

    SELECT

        DATE_FORMAT(
            order_purchase_timestamp,
            '%Y-%m'
        ) AS order_month,

        COUNT(DISTINCT order_id) AS total_delivered_orders,

        SUM(
            CASE
                WHEN order_delivered_customer_date >
                     order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) AS delayed_orders

    FROM orders

    WHERE order_status = 'delivered'

    GROUP BY DATE_FORMAT(
        order_purchase_timestamp,
        '%Y-%m'
    )

),

monthly_performance_analysis AS (

    SELECT

        order_month,

        total_delivered_orders,

        delayed_orders,

        ROUND(
            delayed_orders * 100.0
            / total_delivered_orders,
            2
        ) AS delayed_order_percentage,

        LAG(
            ROUND(
                delayed_orders * 100.0
                / total_delivered_orders,
                2
            )
        ) OVER (
            ORDER BY order_month
        ) AS previous_month_delay_percentage

    FROM monthly_delivery_performance

)

SELECT

    *,

    ROUND(
        delayed_order_percentage
        - previous_month_delay_percentage,
        2
    ) AS monthly_delay_change

FROM monthly_performance_analysis

ORDER BY order_month;

-- =========================================================
-- Subsection 13.10 : Delivery Performance by Payment Type
-- =========================================================
-- Business Question:
-- Do certain payment methods experience
-- higher delivery delays?
--
-- Why This Matters:
-- Helps analyze operational patterns between
-- payment behavior and logistics performance.
-- =========================================================

WITH payment_delivery_analysis AS (

    SELECT

        op.payment_type,

        COUNT(DISTINCT o.order_id) AS total_delivered_orders,

        SUM(
            CASE
                WHEN o.order_delivered_customer_date >
                     o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) AS delayed_orders

    FROM orders AS o

    INNER JOIN order_payments AS op
        ON o.order_id = op.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY op.payment_type

),

payment_performance AS (

    SELECT

        payment_type,

        total_delivered_orders,

        delayed_orders,

        ROUND(
            delayed_orders * 100.0
            / total_delivered_orders,
            2
        ) AS delayed_order_percentage,

        RANK() OVER (
            ORDER BY
            delayed_orders * 100.0
            / total_delivered_orders DESC
        ) AS payment_delay_rank

    FROM payment_delivery_analysis

)

SELECT *

FROM payment_performance

ORDER BY delayed_order_percentage DESC;

-- =========================================================
-- Subsection 13.11 : Delivery Performance by Product Category
-- =========================================================
-- Business Question:
-- Which product categories experience
-- the highest delivery delays?
-- Why This Matters:
-- Helps optimize category-wise logistics
-- and identify operational bottlenecks.
-- =========================================================

WITH category_delivery_analysis AS (

    SELECT

        pct.product_category_name_english
            AS category_name,

        COUNT(DISTINCT o.order_id)
            AS total_delivered_orders,

        SUM(
            CASE
                WHEN o.order_delivered_customer_date >
                     o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) AS delayed_orders

    FROM orders AS o

    INNER JOIN order_items AS oi
        ON o.order_id = oi.order_id

    INNER JOIN products AS p
        ON oi.product_id = p.product_id

    INNER JOIN product_category_translation AS pct
        ON p.product_category_name =
           pct.product_category_name

    WHERE o.order_status = 'delivered'

    GROUP BY pct.product_category_name_english

),

category_performance AS (

    SELECT

        category_name,

        total_delivered_orders,

        delayed_orders,

        ROUND(
            delayed_orders * 100.0
            / total_delivered_orders,
            2
        ) AS delayed_order_percentage,

        RANK() OVER (
            ORDER BY
            delayed_orders * 100.0
            / total_delivered_orders DESC
        ) AS category_delay_rank

    FROM category_delivery_analysis

    WHERE total_delivered_orders >= 50

)

SELECT *

FROM category_performance

ORDER BY delayed_order_percentage DESC

LIMIT 20;

-- =========================================================
-- Subsection 13.12 : Delivery Delay Trend by Day of Week
-- =========================================================
-- Business Question:
-- Which weekdays experience
-- the highest delivery delays?
-- Why This Matters:
-- Helps optimize logistics operations,
-- staffing, and delivery planning.
-- =========================================================

WITH weekday_delivery_analysis AS (

    SELECT

        DAYNAME(order_purchase_timestamp)
            AS weekday_name,

        COUNT(DISTINCT order_id)
            AS total_delivered_orders,

        SUM(

            CASE

                WHEN order_delivered_customer_date >
                     order_estimated_delivery_date

                THEN 1

                ELSE 0

            END

        ) AS delayed_orders

    FROM orders

    WHERE order_status = 'delivered'

    GROUP BY weekday_name

),

weekday_performance AS (

    SELECT

        weekday_name,

        total_delivered_orders,

        delayed_orders,

        ROUND(

            delayed_orders * 100.0
            / total_delivered_orders,

            2

        ) AS delayed_order_percentage,

        RANK() OVER (

            ORDER BY

            delayed_orders * 100.0
            / total_delivered_orders DESC

        ) AS weekday_delay_rank

    FROM weekday_delivery_analysis

)

SELECT *

FROM weekday_performance

ORDER BY delayed_order_percentage DESC;

-- =========================================================
-- Section 14 : Advanced Revenue & Growth Analytics
-- Subsection 14.1 : Monthly Revenue Trend Analysis
-- =========================================================
-- Business Question:
-- How is revenue changing month-over-month?
-- Why This Matters:
-- Helps identify growth trends,
-- seasonality patterns,
-- and business expansion over time.
-- =========================================================

WITH monthly_revenue AS (

    SELECT
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
        ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue,
        COUNT(DISTINCT o.order_id) AS total_orders

    FROM orders AS o

    INNER JOIN order_items AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY order_month

)

SELECT *
FROM monthly_revenue;

-- =========================================================
-- Subsection 14.2 : Cumulative Revenue Growth Analysis
-- =========================================================
-- Business Question:
-- How is cumulative revenue growing over time?
--
-- Why This Matters:
-- Helps monitor long-term growth,
-- business scaling,
-- and revenue accumulation trends.
-- =========================================================

WITH monthly_revenue_analysis AS (

    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,

        ROUND(
            SUM(oi.price + oi.freight_value),
            2
        ) AS total_revenue,

        COUNT(DISTINCT o.order_id) AS total_orders

    FROM orders AS o

    INNER JOIN order_items AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY order_month

),

cumulative_revenue_analysis AS (

    SELECT
        order_month,
        total_revenue,
        total_orders,

        ROUND(
            SUM(total_revenue) OVER (
                ORDER BY order_month
            ),
            2
        ) AS cumulative_revenue

    FROM monthly_revenue_analysis

)
SELECT *
FROM cumulative_revenue_analysis
ORDER BY order_month;

-- =========================================================
-- Subsection 14.3 : Monthly Revenue Growth Percentage Analysis
-- =========================================================
-- Business Question:
-- How much is revenue growing or declining
-- month-over-month?
-- Why This Matters:
-- Helps identify growth momentum,
-- performance fluctuations,
-- and business expansion trends.
-- =========================================================

WITH monthly_revenue_analysis AS (

    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue,
        COUNT(DISTINCT o.order_id) AS total_orders

    FROM orders AS o

    INNER JOIN order_items AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY order_month

),

monthly_growth_analysis AS (
    SELECT
        order_month,
        total_revenue,
        total_orders,

        LAG(total_revenue) OVER (
            ORDER BY order_month
        ) AS previous_month_revenue

    FROM monthly_revenue_analysis

)
SELECT
    order_month,
    total_revenue,
    total_orders,
    previous_month_revenue,

    ROUND(
        (
            (total_revenue - previous_month_revenue) * 100.0
        ) / previous_month_revenue,
        2
    ) AS monthly_revenue_growth_percentage

FROM monthly_growth_analysis
ORDER BY order_month;

-- =========================================================
-- Subsection 14.4 : Running Average Revenue Analysis
-- =========================================================
-- Business Question:
-- What is the smoothed monthly revenue trend over time
-- using a running average?
-- Why This Matters:
-- 1. Helps identify long-term revenue trends
-- 2. Smooths sudden revenue fluctuations
-- 3. Improves forecasting accuracy
-- 4. Widely used in executive KPI dashboards
-- 5. Common in real-world financial analytics

WITH monthly_revenue_analysis AS (

    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue,
        COUNT(DISTINCT o.order_id) AS total_orders

    FROM orders AS o
    INNER JOIN order_items AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY order_month

),

running_average_analysis AS (

    SELECT
        order_month,
        total_revenue,
        total_orders,

        ROUND(
            AVG(total_revenue) OVER (
                ORDER BY order_month
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ),
            2
        ) AS three_month_running_avg_revenue

    FROM monthly_revenue_analysis

)

SELECT
    order_month,
    total_revenue,
    total_orders,
    three_month_running_avg_revenue

FROM running_average_analysis

ORDER BY order_month;

-- =========================================================
-- Subsection 14.5 : Highest Revenue Growth Month Analysis
-- =========================================================
-- Business Question:
-- Which month experienced the highest revenue growth
-- compared to the previous month?
-- Why This Matters:
-- 1. Identifies peak growth periods
-- 2. Helps analyze business expansion trends
-- 3. Detects successful seasonal or campaign impact
-- 4. Supports forecasting and strategic planning
-- 5. Common in executive KPI reporting

WITH monthly_revenue_analysis AS (

    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue

    FROM orders AS o
    INNER JOIN order_items AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY order_month

),

monthly_growth_analysis AS (

    SELECT
        order_month,
        total_revenue,

        LAG(total_revenue) OVER (
            ORDER BY order_month
        ) AS previous_month_revenue

    FROM monthly_revenue_analysis

),

revenue_growth_analysis AS (

    SELECT
        order_month,
        total_revenue,
        previous_month_revenue,

        ROUND(
            (
                (total_revenue - previous_month_revenue) * 100.0
            ) / previous_month_revenue,
            2
        ) AS monthly_revenue_growth_percentage

    FROM monthly_growth_analysis

)

SELECT
    order_month,
    total_revenue,
    previous_month_revenue,
    monthly_revenue_growth_percentage,

    DENSE_RANK() OVER (
        ORDER BY monthly_revenue_growth_percentage DESC
    ) AS growth_rank

FROM revenue_growth_analysis

WHERE monthly_revenue_growth_percentage IS NOT NULL

ORDER BY monthly_revenue_growth_percentage DESC;

-- =========================================================
-- Subsection 14.6 : Highest Revenue Month Contribution Analysis
-- =========================================================

-- Business Question:
-- Which months contributed the highest percentage
-- of total platform revenue?

-- Why This Matters:
-- 1. Identifies strongest revenue periods
-- 2. Detects seasonal revenue concentration
-- 3. Helps improve business planning
-- 4. Supports inventory and marketing decisions
-- 5. Common in executive KPI reporting

WITH monthly_revenue_analysis AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue,
        COUNT(DISTINCT o.order_id) AS total_orders

    FROM orders AS o
    INNER JOIN order_items AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY order_month

),
revenue_contribution_analysis AS (

    SELECT
        order_month,
        total_revenue,
        total_orders,
        ROUND(
            (
                total_revenue * 100.0
            ) / SUM(total_revenue) OVER (),
            2
        ) AS revenue_contribution_percentage

    FROM monthly_revenue_analysis)
SELECT
    order_month,
    total_revenue,
    total_orders,
    revenue_contribution_percentage,
    DENSE_RANK() OVER (
        ORDER BY revenue_contribution_percentage DESC
    ) AS revenue_rank

FROM revenue_contribution_analysis
ORDER BY revenue_contribution_percentage DESC;

-- =========================================================
-- Subsection 14.7 : Revenue Per Order Trend Analysis
-- =========================================================
-- Business Question:
-- How is average revenue generated per order
-- changing month-by-month
-- Why This Matters:
-- 1. Tracks customer spending trends
-- 2. Measures average order value behavior
-- 3. Helps identify premium purchase periods
-- 4. Supports pricing and profitability analysis
-- 5. Common KPI in business dashboards

WITH monthly_order_revenue_analysis AS (

    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,

        ROUND(
            SUM(oi.price + oi.freight_value),
            2
        ) AS total_revenue,

        COUNT(DISTINCT o.order_id) AS total_orders

    FROM orders AS o
    INNER JOIN order_items AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY order_month

),

revenue_per_order_analysis AS (
    SELECT
        order_month,
        total_revenue,
        total_orders,
        ROUND(
            total_revenue / total_orders,
            2
        ) AS avg_revenue_per_order

    FROM monthly_order_revenue_analysis

)
SELECT
    order_month,
    total_revenue,
    total_orders,
    avg_revenue_per_order,

    DENSE_RANK() OVER (
        ORDER BY avg_revenue_per_order DESC
    ) AS avg_order_value_rank

FROM revenue_per_order_analysis

ORDER BY order_month;

-- =========================================================
-- 14.7 MONTHLY REVENUE CONTRIBUTION ANALYSIS
-- =========================================================
-- Business Question:
-- Which months contributed the highest percentage
-- to overall company revenue?
--
-- Why This Matters:
-- Helps identify peak-performing months contributing
-- most to company sales and overall business growth.
--
-- Business Use Cases:
-- • Seasonal sales analysis
-- • Inventory forecasting
-- • Campaign planning
-- • Revenue trend monitoring
-- • Peak business month identification
-- =========================================================

WITH monthly_revenue_analysis AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        ROUND(SUM(op.payment_value), 2) AS total_revenue,
        COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o

    JOIN order_payments op
        ON o.order_id = op.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY order_month
),

monthly_contribution_analysis AS (
    SELECT
        order_month,
        total_revenue,
        total_orders,

        ROUND(
            total_revenue * 100.0
            / SUM(total_revenue) OVER (),
            2
        ) AS revenue_contribution_percentage,

        DENSE_RANK() OVER (
            ORDER BY total_revenue DESC
        ) AS revenue_rank

    FROM monthly_revenue_analysis
)
SELECT *
FROM monthly_contribution_analysis
ORDER BY revenue_rank;

-- =========================================================
-- 14.8 TOP 5 HIGHEST REVENUE GENERATING MONTHS
-- =========================================================
-- Business Question:
-- Which months generated the highest overall revenue?
-- Why This Matters:
-- Helps identify strongest business-performing periods
-- for future strategic planning and forecasting.
-- Business Use Cases:
-- • Peak sales period analysis
-- • Marketing campaign timing
-- • Seasonal demand forecasting
-- • Revenue optimization strategy
-- • Inventory and logistics planning
-- =========================================================

	WITH monthly_revenue_analysis AS (
		SELECT
			DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
			ROUND(SUM(op.payment_value), 2) AS total_revenue,
			COUNT(DISTINCT o.order_id) AS total_orders
		FROM orders o
		JOIN order_payments op
			ON o.order_id = op.order_id

		WHERE o.order_status = 'delivered'

		GROUP BY order_month
	),

	top_revenue_months AS (
		SELECT
			order_month,
			total_revenue,
			total_orders,

			DENSE_RANK() OVER (
				ORDER BY total_revenue DESC
			) AS revenue_rank

		FROM monthly_revenue_analysis
	)
	SELECT *
	FROM top_revenue_months
	WHERE revenue_rank <= 5
	ORDER BY revenue_rank;
    
-- =========================================================
-- 14.9 LOWEST REVENUE GENERATING MONTHS
-- =========================================================
-- Business Question:
-- Which months generated the lowest overall revenue?
-- Why This Matters:
-- Helps identify weak-performing business periods
-- where sales and customer activity were low.
-- Business Use Cases:
-- • Off-season sales analysis
-- • Weak demand identification
-- • Business recovery planning
-- • Marketing optimization
-- • Revenue improvement strategy
-- =========================================================

WITH monthly_revenue_analysis AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        ROUND(SUM(op.payment_value), 2) AS total_revenue,
        COUNT(DISTINCT o.order_id) AS total_orders

    FROM orders o

    JOIN order_payments op
        ON o.order_id = op.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY order_month
),

lowest_revenue_months AS (
    SELECT
        order_month,
        total_revenue,
        total_orders,

        DENSE_RANK() OVER (
            ORDER BY total_revenue ASC
        ) AS low_revenue_rank

    FROM monthly_revenue_analysis
)
SELECT *
FROM lowest_revenue_months
WHERE low_revenue_rank <= 5
ORDER BY low_revenue_rank;

-- =========================================================
-- 14.10 MONTH-OVER-MONTH ORDER GROWTH ANALYSIS
-- =========================================================
-- Business Question:
-- How did total orders grow or decline month-over-month?
--
-- Why This Matters:
-- Helps measure business expansion, customer demand trends,
-- and operational growth over time.
--
-- Business Use Cases:
-- • Growth trend monitoring
-- • Demand forecasting
-- • Business expansion analysis
-- • Performance tracking
-- • Strategic planning and reporting
-- =========================================================

WITH monthly_orders_analysis AS (
    SELECT
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
        COUNT(DISTINCT order_id) AS total_orders

    FROM orders

    WHERE order_status = 'delivered'

    GROUP BY order_month
),

monthly_growth_analysis AS (
    SELECT
        order_month,
        total_orders,

        LAG(total_orders) OVER (
            ORDER BY order_month
        ) AS previous_month_orders,

        ROUND(
            ((total_orders - LAG(total_orders) OVER (ORDER BY order_month)) * 100.0) /
            LAG(total_orders) OVER (
                ORDER BY order_month
            ),
            2
        ) AS monthly_order_growth_percentage

    FROM monthly_orders_analysis
)
SELECT *
FROM monthly_growth_analysis
ORDER BY order_month;

-- =========================================================
-- 14.11 ADVANCED ANALYTICAL INSIGHT (OPTIONAL)
-- MONTHLY REVENUE VOLATILITY ANALYSIS
-- =========================================================
-- Business Question:
-- Which months showed the biggest increase or decrease
-- in revenue compared to the previous month?
-- Why This Matters:
-- Helps identify unstable business periods,
-- sudden growth spikes, or major revenue drops.
-- Business Use Cases:
-- • Revenue fluctuation monitoring
-- • Seasonal business analysis
-- • Campaign performance tracking
-- • Financial planning
-- • Business stability evaluation
-- =========================================================

WITH monthly_revenue_analysis AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        ROUND(SUM(op.payment_value), 2) AS total_revenue

    FROM orders o

    JOIN order_payments op
        ON o.order_id = op.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY order_month
),

revenue_volatility_analysis AS (
    SELECT
        order_month,
        total_revenue,

        LAG(total_revenue) OVER (
            ORDER BY order_month
        ) AS previous_month_revenue,

        ROUND(
            total_revenue
            -
            LAG(total_revenue) OVER (
                ORDER BY order_month
            ),
            2
        ) AS revenue_change

    FROM monthly_revenue_analysis
)

SELECT *,
    DENSE_RANK() OVER (
        ORDER BY ABS(revenue_change) DESC
    ) AS volatility_rank

FROM revenue_volatility_analysis
WHERE revenue_change IS NOT NULL
ORDER BY volatility_rank;

-- =========================================================
-- SECTION 15: CUSTOMER SEGMENTATION ANALYSIS
-- =========================================================
-- =========================================================
-- 15.1 RFM CUSTOMER SEGMENTATION ANALYSIS
-- =========================================================
-- Business Question:
-- Which customers are most valuable based on
-- their recent activity, purchase frequency,
-- and monetary contribution?
-- Why This Matters:
-- Helps businesses identify:
-- • Loyal customers
-- • High-value customers
-- • Potential churn-risk customers
-- • Customer purchasing behavior
-- • Marketing targeting opportunities
-- Business Use Cases:
-- • Customer retention strategy
-- • Personalized marketing campaigns
-- • VIP customer identification
-- • Churn prevention
-- • Revenue optimization
-- =========================================================

WITH customer_rfm_analysis AS (

    SELECT
        o.customer_id,

        MAX(DATE(o.order_purchase_timestamp)) AS last_purchase_date,

        DATEDIFF(
            (
                SELECT MAX(DATE(order_purchase_timestamp))
                FROM orders
            ),
            MAX(DATE(o.order_purchase_timestamp))
        ) AS recency_days,

        COUNT(DISTINCT o.order_id) AS frequency,

        ROUND(
            SUM(op.payment_value),
            2
        ) AS monetary_value

    FROM orders AS o

    INNER JOIN order_payments AS op
        ON o.order_id = op.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY o.customer_id

),

rfm_scores AS (

    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary_value,

        NTILE(5) OVER (
            ORDER BY recency_days DESC
        ) AS recency_score,

        NTILE(5) OVER (
            ORDER BY frequency DESC
        ) AS frequency_score,

        NTILE(5) OVER (
            ORDER BY monetary_value DESC
        ) AS monetary_score

    FROM customer_rfm_analysis

)

SELECT
    customer_id,
    recency_days,
    frequency,
    monetary_value,

    recency_score,
    frequency_score,
    monetary_score,

    CONCAT(
        recency_score,
        frequency_score,
        monetary_score
    ) AS rfm_segment

FROM rfm_scores

ORDER BY
    monetary_score DESC,
    frequency_score DESC,
    recency_score DESC;