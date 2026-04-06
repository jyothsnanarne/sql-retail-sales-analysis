"""
Retail Sales Analysis Runner
Loads Superstore CSV into SQLite and executes all 10 analysis sections.
"""

import sqlite3
import pandas as pd

CSV_FILE = "Sample - Superstore.csv"
DB_FILE  = ":memory:"

# ── Load CSV ──────────────────────────────────────────────────────────────────
print("Loading dataset...")
df = pd.read_csv(CSV_FILE, encoding="latin1")

# Normalise column names: lowercase + underscores
df.columns = [c.strip().lower().replace(" ", "_").replace("-", "_") for c in df.columns]

# Parse dates
df["order_date"] = pd.to_datetime(df["order_date"])
df["ship_date"]  = pd.to_datetime(df["ship_date"])

# SQLite can't store datetime objects — store as ISO strings
df["order_date"] = df["order_date"].dt.strftime("%Y-%m-%d")
df["ship_date"]  = df["ship_date"].dt.strftime("%Y-%m-%d")

con = sqlite3.connect(DB_FILE)
df.to_sql("superstore", con, if_exists="replace", index=False)
print(f"Loaded {len(df):,} rows into SQLite.\n")

def run(title, sql):
    print("=" * 60)
    print(title)
    print("=" * 60)
    try:
        result = pd.read_sql_query(sql, con)
        print(result.to_string(index=False))
    except Exception as e:
        print(f"ERROR: {e}")
    print()


# ── Section 1: Data Quality Checks ───────────────────────────────────────────
run("SECTION 1: DATA QUALITY CHECKS", """
SELECT
    COUNT(*)                                            AS total_rows,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END)  AS null_order_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN sales IS NULL THEN 1 ELSE 0 END)     AS null_sales,
    SUM(CASE WHEN profit IS NULL THEN 1 ELSE 0 END)    AS null_profit,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS null_order_date
FROM superstore
""")

run("SECTION 1b: DATE RANGE", """
SELECT
    MIN(order_date) AS earliest_order,
    MAX(order_date) AS latest_order
FROM superstore
""")

run("SECTION 1c: DUPLICATE ORDER-PRODUCT PAIRS", """
SELECT COUNT(*) AS duplicate_pairs FROM (
    SELECT order_id, product_id, COUNT(*) AS cnt
    FROM superstore
    GROUP BY order_id, product_id
    HAVING COUNT(*) > 1
)
""")


# ── Section 2: Executive KPIs ─────────────────────────────────────────────────
run("SECTION 2: EXECUTIVE KPI SUMMARY", """
SELECT
    COUNT(DISTINCT order_id)                                    AS total_orders,
    COUNT(DISTINCT customer_id)                                 AS total_customers,
    ROUND(SUM(sales), 2)                                        AS total_revenue,
    ROUND(SUM(profit), 2)                                       AS total_profit,
    ROUND(SUM(profit) * 100.0 / SUM(sales), 2)                 AS profit_margin_pct,
    ROUND(AVG(sales), 2)                                        AS avg_order_line_value,
    COUNT(DISTINCT product_id)                                  AS total_products
FROM superstore
""")


# ── Section 3: Year-over-Year Trends ─────────────────────────────────────────
run("SECTION 3: YEAR-OVER-YEAR REVENUE & PROFIT", """
SELECT
    strftime('%Y', order_date)                  AS order_year,
    ROUND(SUM(sales), 2)                        AS total_revenue,
    ROUND(SUM(profit), 2)                       AS total_profit,
    ROUND(SUM(profit) * 100.0 / SUM(sales), 2) AS profit_margin_pct,
    COUNT(DISTINCT order_id)                    AS total_orders
FROM superstore
GROUP BY order_year
ORDER BY order_year
""")


# ── Section 4: Monthly Seasonality ───────────────────────────────────────────
run("SECTION 4: MONTHLY REVENUE (last 2 years)", """
SELECT
    strftime('%Y', order_date)  AS yr,
    strftime('%m', order_date)  AS mo,
    ROUND(SUM(sales), 2)        AS monthly_revenue,
    ROUND(SUM(profit), 2)       AS monthly_profit,
    COUNT(DISTINCT order_id)    AS orders
FROM superstore
WHERE strftime('%Y', order_date) >= '2016'
GROUP BY yr, mo
ORDER BY yr, mo
""")


# ── Section 5: Regional Performance ──────────────────────────────────────────
run("SECTION 5: REGIONAL PERFORMANCE", """
SELECT
    region,
    COUNT(DISTINCT order_id)                            AS total_orders,
    COUNT(DISTINCT customer_id)                         AS unique_customers,
    ROUND(SUM(sales), 2)                                AS total_revenue,
    ROUND(SUM(profit), 2)                               AS total_profit,
    ROUND(SUM(profit) * 100.0 / SUM(sales), 2)         AS profit_margin_pct,
    ROUND(SUM(sales) / COUNT(DISTINCT customer_id), 2) AS revenue_per_customer
FROM superstore
GROUP BY region
ORDER BY total_revenue DESC
""")

run("SECTION 5b: TOP 10 STATES BY REVENUE", """
SELECT
    state,
    region,
    ROUND(SUM(sales), 2)        AS total_revenue,
    ROUND(SUM(profit), 2)       AS total_profit,
    COUNT(DISTINCT order_id)    AS order_count
FROM superstore
GROUP BY state, region
ORDER BY total_revenue DESC
LIMIT 10
""")


# ── Section 6: Category & Product Profitability ───────────────────────────────
run("SECTION 6: CATEGORY & SUB-CATEGORY PROFITABILITY", """
SELECT
    category,
    sub_category,
    ROUND(SUM(sales), 2)                        AS total_revenue,
    ROUND(SUM(profit), 2)                       AS total_profit,
    ROUND(SUM(profit) * 100.0 / SUM(sales), 2) AS profit_margin_pct,
    ROUND(AVG(discount), 4)                     AS avg_discount,
    COUNT(DISTINCT product_id)                  AS product_count
FROM superstore
GROUP BY category, sub_category
ORDER BY total_profit DESC
""")

run("SECTION 6b: TOP 10 MOST PROFITABLE PRODUCTS", """
SELECT
    product_name,
    category,
    ROUND(SUM(sales), 2)                        AS total_revenue,
    ROUND(SUM(profit), 2)                       AS total_profit,
    ROUND(SUM(profit) * 100.0 / SUM(sales), 2) AS margin_pct
FROM superstore
GROUP BY product_id, product_name, category
ORDER BY total_profit DESC
LIMIT 10
""")

run("SECTION 6c: DISCOUNT IMPACT ON PROFIT", """
SELECT
    CASE
        WHEN discount = 0       THEN '0% - No Discount'
        WHEN discount <= 0.10   THEN '1-10%'
        WHEN discount <= 0.20   THEN '11-20%'
        WHEN discount <= 0.30   THEN '21-30%'
        ELSE '30%+'
    END                                         AS discount_tier,
    COUNT(*)                                    AS order_lines,
    ROUND(SUM(sales), 2)                        AS total_revenue,
    ROUND(SUM(profit), 2)                       AS total_profit,
    ROUND(SUM(profit) * 100.0 / SUM(sales), 2) AS profit_margin_pct
FROM superstore
GROUP BY discount_tier
ORDER BY MIN(discount)
""")


# ── Section 7: Customer Segmentation ─────────────────────────────────────────
run("SECTION 7: REVENUE BY CUSTOMER SEGMENT", """
SELECT
    segment,
    COUNT(DISTINCT customer_id)                         AS customer_count,
    ROUND(SUM(sales), 2)                                AS total_revenue,
    ROUND(SUM(profit), 2)                               AS total_profit,
    ROUND(AVG(sales), 2)                                AS avg_order_line_value,
    ROUND(SUM(sales) / COUNT(DISTINCT customer_id), 2) AS revenue_per_customer
FROM superstore
GROUP BY segment
ORDER BY total_revenue DESC
""")

run("SECTION 7b: TOP 10 CUSTOMERS BY LIFETIME VALUE", """
SELECT
    customer_id,
    customer_name,
    segment,
    region,
    COUNT(DISTINCT order_id)    AS total_orders,
    ROUND(SUM(sales), 2)        AS lifetime_value,
    ROUND(SUM(profit), 2)       AS total_profit,
    MIN(order_date)             AS first_order,
    MAX(order_date)             AS last_order
FROM superstore
GROUP BY customer_id, customer_name, segment, region
ORDER BY lifetime_value DESC
LIMIT 10
""")

run("SECTION 7c: RFM SEGMENTATION", """
WITH rfm_base AS (
    SELECT
        customer_id,
        customer_name,
        CAST(julianday('2017-12-31') - julianday(MAX(order_date)) AS INTEGER) AS recency_days,
        COUNT(DISTINCT order_id)    AS frequency,
        ROUND(SUM(sales), 2)        AS monetary
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
    customer_name,
    recency_days,
    frequency,
    monetary,
    (r_score + f_score + m_score) AS rfm_total,
    CASE
        WHEN (r_score + f_score + m_score) >= 13 THEN 'Champions'
        WHEN (r_score + f_score + m_score) >= 10 THEN 'Loyal Customers'
        WHEN (r_score + f_score + m_score) >= 7  THEN 'Potential Loyalists'
        WHEN r_score >= 4                         THEN 'Recent Customers'
        WHEN f_score >= 4                         THEN 'At Risk'
        ELSE 'Lost / Churned'
    END AS customer_segment
FROM rfm_scored
ORDER BY rfm_total DESC
LIMIT 20
""")


# ── Section 8: Shipping Analysis ──────────────────────────────────────────────
run("SECTION 8: SHIPPING MODE PERFORMANCE", """
SELECT
    ship_mode,
    COUNT(DISTINCT order_id)                            AS order_count,
    ROUND(AVG(julianday(ship_date) - julianday(order_date)), 1) AS avg_ship_days,
    ROUND(SUM(sales), 2)                                AS total_revenue,
    ROUND(SUM(profit) * 100.0 / SUM(sales), 2)         AS profit_margin_pct
FROM superstore
GROUP BY ship_mode
ORDER BY avg_ship_days
""")


# ── Section 9: Window Functions ───────────────────────────────────────────────
run("SECTION 9: IN-SEGMENT CUSTOMER RANK (top 5 per segment)", """
SELECT * FROM (
    SELECT
        customer_name,
        segment,
        ROUND(SUM(sales), 2) AS total_revenue,
        RANK() OVER (PARTITION BY segment ORDER BY SUM(sales) DESC) AS rank_in_segment,
        ROUND(SUM(sales) * 100.0 / SUM(SUM(sales)) OVER (PARTITION BY segment), 2) AS pct_of_segment
    FROM superstore
    GROUP BY customer_id, customer_name, segment
)
WHERE rank_in_segment <= 5
ORDER BY segment, rank_in_segment
""")


# ── Section 10: Loss Risk Detection ──────────────────────────────────────────
run("SECTION 10: HIGH-DISCOUNT LOSS-MAKING PRODUCTS", """
SELECT
    product_name,
    category,
    sub_category,
    ROUND(AVG(discount), 2)     AS avg_discount,
    ROUND(SUM(sales), 2)        AS total_sales,
    ROUND(SUM(profit), 2)       AS total_profit,
    COUNT(*)                    AS transaction_count
FROM superstore
WHERE profit < 0
GROUP BY product_id, product_name, category, sub_category
HAVING AVG(discount) > 0.20
ORDER BY total_profit ASC
LIMIT 15
""")

con.close()
print("Analysis complete.")
