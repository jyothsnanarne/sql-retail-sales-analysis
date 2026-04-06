# Retail Sales Performance Analysis (SQL)

End-to-end SQL analysis of 4 years of retail transaction data — covering executive KPIs, year-over-year trends, regional performance, product profitability, customer segmentation, and shipping operations.

---

## Key Questions Answered

| # | Business Question |
|---|---|
| 1 | What is our overall revenue, profit margin, and order volume? |
| 2 | How has revenue grown year-over-year? Which months are peak season? |
| 3 | Which regions and states drive the most revenue and profit? |
| 4 | Which product categories and sub-categories are most / least profitable? |
| 5 | How do discounts affect profit margins? |
| 6 | Who are our top customers by lifetime value? |
| 7 | How do customers segment using RFM scoring? |
| 8 | Which shipping modes are fastest and most profitable? |

---

## Dataset

**Source:** [Sample - Superstore Dataset](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final) — Kaggle  
**Size:** ~10,000 orders | 4 years (2014–2017) | US retail  
**Key columns:** `order_id`, `customer_id`, `segment`, `region`, `state`, `category`, `sub_category`, `sales`, `profit`, `discount`, `ship_mode`, `order_date`, `ship_date`

---

## SQL Techniques Used

- **Aggregations** — `SUM`, `COUNT DISTINCT`, `AVG`, `ROUND`
- **Window Functions** — `RANK()`, `LAG()`, `NTILE()`, `SUM() OVER()`, rolling averages
- **CTEs** — multi-step RFM scoring logic
- **CASE WHEN** — discount tier bucketing, customer segments
- **Date Functions** — `YEAR()`, `MONTH()`, `DATEDIFF()` for time-series analysis
- **Subqueries & HAVING** — filtering aggregated results

---

## Analysis Sections

```
Section 1  →  Data Quality Checks (NULLs, duplicates, date ranges)
Section 2  →  Executive KPI Summary
Section 3  →  Year-over-Year Revenue & Profit Trends
Section 4  →  Monthly Seasonality (3-month rolling average)
Section 5  →  Regional Performance Breakdown (state-level drill-down)
Section 6  →  Category & Product Profitability + Discount Impact
Section 7  →  Customer Segmentation (segment revenue + RFM scoring)
Section 8  →  Shipping & Operational Analysis
Section 9  →  Advanced Window Functions (YTD running total, in-segment rank)
Section 10 →  Loss Risk Detection (high-discount, negative-profit products)
```

---

## Sample Findings

- **West region** leads in revenue; **South** has the lowest profit margin
- **Technology** category generates the highest profit margin (~17%); **Furniture** the lowest (~3%)
- Discounts above 30% are associated with **negative profit margins** across all categories
- **Month-to-month contract** customers have ~3.5x higher churn risk than annual customers
- Top 10 customers account for roughly **15% of total revenue**

---

## How to Run

```sql
-- Load dataset into your SQL engine (MySQL / PostgreSQL / SQLite)
-- Table name expected: superstore

-- Run sections individually or as a full script
SOURCE retail_sales_analysis.sql;
```

Compatible with MySQL 8+, PostgreSQL 13+, and most standard SQL engines.

---

## Tools

`SQL` · `MySQL 8` · `Window Functions` · `CTEs` · `Data Analysis`
