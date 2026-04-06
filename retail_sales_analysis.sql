-- =============================================================
-- RETAIL SALES PERFORMANCE ANALYSIS
-- Dataset: Superstore Sales (Kaggle)
-- Author: Jyothsna Narne
-- Description: End-to-end SQL analysis covering KPIs, trends,
--              regional performance, and customer segmentation
-- =============================================================


-- =============================================================
-- SECTION 1: DATA QUALITY CHECKS
-- =============================================================

-- Check for NULL values in critical columns
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END)      AS null_order_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END)   AS null_customer_id,
    SUM(CASE WHEN sales IS NULL THEN 1 ELSE 0 END)         AS null_sales,
    SUM(CASE WHEN profit IS NULL THEN 1 ELSE 0 END)        AS null_profit,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END)    AS null_order_date
FROM superstore;

-- Check for duplicate order-product combinations
SELECT order_id, product_id, COUNT(*) AS occurrences
FROM superstore
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;

-- Validate date ranges
SELECT
    MIN(order_date) AS earliest_order,
    MAX(order_date) AS latest_order,
    COUNT(DISTINCT YEAR(order_date)) AS years_covered
FROM superstore;

-- Check for negative sales or profit outliers
SELECT COUNT(*) AS negative_sales_count
FROM superstore
WHERE sales < 0;

SELECT
    MIN(profit) AS min_profit,
    MAX(profit) AS max_profit,
    AVG(profit) AS avg_profit
FROM superstore;


-- =============================================================
-- SECTION 2: EXECUTIVE KPI SUMMARY
-- =============================================================

SELECT
    COUNT(DISTINCT order_id)                                    AS total_orders,
    COUNT(DISTINCT customer_id)                                 AS total_customers,
    ROUND(SUM(sales), 2)                                        AS total_revenue,
    ROUND(SUM(profit), 2)                                       AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2)        AS profit_margin_pct,
    ROUND(AVG(sales), 2)                                        AS avg_order_value,
    COUNT(DISTINCT product_id)                                  AS total_products
FROM superstore;


-- =============================================================
-- SECTION 3: YEAR-OVER-YEAR REVENUE & PROFIT TRENDS
-- =============================================================

SELECT
    YEAR(order_date)                                                AS order_year,
    ROUND(SUM(sales), 2)                                            AS total_revenue,
    ROUND(SUM(profit), 2)                                           AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2)            AS profit_margin_pct,
    COUNT(DISTINCT order_id)                                        AS total_orders,
    LAG(ROUND(SUM(sales), 2)) OVER (ORDER BY YEAR(order_date))     AS prev_year_revenue,
    ROUND(
        (SUM(sales) - LAG(SUM(sales)) OVER (ORDER BY YEAR(order_date)))
        / NULLIF(LAG(SUM(sales)) OVER (ORDER BY YEAR(order_date)), 0) * 100, 2
    )                                                               AS yoy_revenue_growth_pct
FROM superstore
GROUP BY YEAR(order_date)
ORDER BY order_year;


-- =============================================================
-- SECTION 4: MONTHLY SEASONALITY ANALYSIS
-- =============================================================

SELECT
    YEAR(order_date)    AS order_year,
    MONTH(order_date)   AS order_month,
    ROUND(SUM(sales), 2) AS monthly_revenue,
    ROUND(SUM(profit), 2) AS monthly_profit,
    COUNT(DISTINCT order_id) AS order_count,
    -- 3-month rolling average to smooth seasonality
    ROUND(AVG(SUM(sales)) OVER (
        ORDER BY YEAR(order_date), MONTH(order_date)
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_3m_avg_revenue
FROM superstore
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY order_year, order_month;


-- =============================================================
-- SECTION 5: REGIONAL PERFORMANCE BREAKDOWN
-- =============================================================

SELECT
    region,
    COUNT(DISTINCT order_id)                                    AS total_orders,
    COUNT(DISTINCT customer_id)                                 AS unique_customers,
    ROUND(SUM(sales), 2)                                        AS total_revenue,
    ROUND(SUM(profit), 2)                                       AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2)        AS profit_margin_pct,
    ROUND(SUM(sales) / COUNT(DISTINCT customer_id), 2)         AS revenue_per_customer,
    -- Region rank by revenue
    RANK() OVER (ORDER BY SUM(sales) DESC)                     AS revenue_rank
FROM superstore
GROUP BY region
ORDER BY total_revenue DESC;

-- State-level drill-down (top 10 states by revenue)
SELECT
    state,
    region,
    ROUND(SUM(sales), 2)    AS total_revenue,
    ROUND(SUM(profit), 2)   AS total_profit,
    COUNT(DISTINCT order_id) AS order_count
FROM superstore
GROUP BY state, region
ORDER BY total_revenue DESC
LIMIT 10;


-- =============================================================
-- SECTION 6: CATEGORY & PRODUCT PROFITABILITY
-- =============================================================

-- Category-level summary
SELECT
    category,
    sub_category,
    ROUND(SUM(sales), 2)                                    AS total_revenue,
    ROUND(SUM(profit), 2)                                   AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2)    AS profit_margin_pct,
    ROUND(AVG(discount), 4)                                 AS avg_discount,
    COUNT(DISTINCT product_id)                              AS product_count
FROM superstore
GROUP BY category, sub_category
ORDER BY total_profit DESC;

-- Top 10 most profitable products
SELECT
    product_id,
    product_name,
    category,
    ROUND(SUM(sales), 2)    AS total_revenue,
    ROUND(SUM(profit), 2)   AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS margin_pct
FROM superstore
GROUP BY product_id, product_name, category
ORDER BY total_profit DESC
LIMIT 10;

-- Bottom 10 loss-making products
SELECT
    product_id,
    product_name,
    category,
    ROUND(SUM(sales), 2)    AS total_revenue,
    ROUND(SUM(profit), 2)   AS total_profit
FROM superstore
GROUP BY product_id, product_name, category
ORDER BY total_profit ASC
LIMIT 10;

-- Impact of discounts on profit margin
SELECT
    CASE
        WHEN discount = 0            THEN '0% - No Discount'
        WHEN discount <= 0.10        THEN '1-10%'
        WHEN discount <= 0.20        THEN '11-20%'
        WHEN discount <= 0.30        THEN '21-30%'
        ELSE '30%+'
    END                                                         AS discount_tier,
    COUNT(*)                                                    AS order_lines,
    ROUND(SUM(sales), 2)                                        AS total_revenue,
    ROUND(SUM(profit), 2)                                       AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2)        AS profit_margin_pct
FROM superstore
GROUP BY discount_tier
ORDER BY MIN(discount);


-- =============================================================
-- SECTION 7: CUSTOMER SEGMENTATION & VALUE
-- =============================================================

-- Revenue distribution by customer segment
SELECT
    segment,
    COUNT(DISTINCT customer_id)                                 AS customer_count,
    ROUND(SUM(sales), 2)                                        AS total_revenue,
    ROUND(SUM(profit), 2)                                       AS total_profit,
    ROUND(AVG(sales), 2)                                        AS avg_order_value,
    ROUND(SUM(sales) / COUNT(DISTINCT customer_id), 2)         AS revenue_per_customer
FROM superstore
GROUP BY segment
ORDER BY total_revenue DESC;

-- Top 10 customers by lifetime value
SELECT
    customer_id,
    customer_name,
    segment,
    region,
    COUNT(DISTINCT order_id)            AS total_orders,
    ROUND(SUM(sales), 2)                AS lifetime_value,
    ROUND(SUM(profit), 2)               AS total_profit,
    MIN(order_date)                     AS first_order_date,
    MAX(order_date)                     AS last_order_date
FROM superstore
GROUP BY customer_id, customer_name, segment, region
ORDER BY lifetime_value DESC
LIMIT 10;

-- RFM Scoring (Recency, Frequency, Monetary)
WITH rfm_base AS (
    SELECT
        customer_id,
        customer_name,
        DATEDIFF('2017-12-31', MAX(order_date))     AS recency_days,
        COUNT(DISTINCT order_id)                     AS frequency,
        ROUND(SUM(sales), 2)                         AS monetary
    FROM superstore
    GROUP BY customer_id, customer_name
),
rfm_scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days ASC)   AS r_score,
        NTILE(5) OVER (ORDER BY frequency DESC)     AS f_score,
        NTILE(5) OVER (ORDER BY monetary DESC)      AS m_score
    FROM rfm_base
)
SELECT
    customer_id,
    customer_name,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    (r_score + f_score + m_score)                   AS rfm_total,
    CASE
        WHEN (r_score + f_score + m_score) >= 13    THEN 'Champions'
        WHEN (r_score + f_score + m_score) >= 10    THEN 'Loyal Customers'
        WHEN (r_score + f_score + m_score) >= 7     THEN 'Potential Loyalists'
        WHEN r_score >= 4                           THEN 'Recent Customers'
        WHEN f_score >= 4                           THEN 'At Risk - High Frequency'
        ELSE 'Lost / Churned'
    END                                             AS customer_segment
FROM rfm_scored
ORDER BY rfm_total DESC;


-- =============================================================
-- SECTION 8: SHIPPING & OPERATIONAL ANALYSIS
-- =============================================================

-- Shipping mode performance
SELECT
    ship_mode,
    COUNT(DISTINCT order_id)                                AS order_count,
    ROUND(AVG(DATEDIFF(ship_date, order_date)), 1)         AS avg_ship_days,
    ROUND(SUM(sales), 2)                                   AS total_revenue,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2)   AS profit_margin_pct
FROM superstore
GROUP BY ship_mode
ORDER BY avg_ship_days;

-- Orders shipped late (more than expected days by mode)
SELECT
    ship_mode,
    COUNT(*) AS late_shipments,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_all_orders
FROM superstore
WHERE
    (ship_mode = 'Same Day'      AND DATEDIFF(ship_date, order_date) > 0)
    OR (ship_mode = 'First Class'  AND DATEDIFF(ship_date, order_date) > 2)
    OR (ship_mode = 'Second Class' AND DATEDIFF(ship_date, order_date) > 4)
    OR (ship_mode = 'Standard Class' AND DATEDIFF(ship_date, order_date) > 7)
GROUP BY ship_mode;


-- =============================================================
-- SECTION 9: ADVANCED WINDOW FUNCTIONS
-- =============================================================

-- Running total revenue by year
SELECT
    order_date,
    order_id,
    ROUND(sales, 2)                                                     AS order_revenue,
    ROUND(SUM(sales) OVER (
        PARTITION BY YEAR(order_date)
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2)                                                               AS ytd_revenue
FROM superstore
ORDER BY order_date;

-- Customer purchase rank within each segment
SELECT
    customer_id,
    customer_name,
    segment,
    ROUND(SUM(sales), 2)                                                AS total_revenue,
    RANK() OVER (PARTITION BY segment ORDER BY SUM(sales) DESC)        AS rank_within_segment,
    ROUND(SUM(sales) / SUM(SUM(sales)) OVER (PARTITION BY segment) * 100, 2) AS pct_of_segment_revenue
FROM superstore
GROUP BY customer_id, customer_name, segment
ORDER BY segment, rank_within_segment;


-- =============================================================
-- SECTION 10: PRODUCT RETURN / LOSS RISK DETECTION
-- =============================================================

-- Products with high discount AND negative profit (return/loss risk)
SELECT
    product_id,
    product_name,
    category,
    sub_category,
    ROUND(AVG(discount), 2)         AS avg_discount,
    ROUND(SUM(sales), 2)            AS total_sales,
    ROUND(SUM(profit), 2)           AS total_profit,
    COUNT(*)                        AS transaction_count
FROM superstore
WHERE profit < 0
GROUP BY product_id, product_name, category, sub_category
HAVING AVG(discount) > 0.20
ORDER BY total_profit ASC
LIMIT 15;
