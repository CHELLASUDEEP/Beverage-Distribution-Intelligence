-- Business Use Case 3: Seasonal Demand Planning
-- Question: Which months drive peak unit volume? How should
--           inventory and procurement be planned seasonally?

USE beverage_analytics;

-- ---------------------------------------------------------------
-- Q3.1 Monthly unit volume — all channels
-- Insight: July is the peak month (retail 94K, warehouse 418K).
--          January is second highest. September appears incomplete.
-- ---------------------------------------------------------------
SELECT
    sale_month,
    month_name,
    COUNT(*) AS record_count,
    ROUND(SUM(retail_sales), 2) AS retail_units,
    ROUND(SUM(warehouse_sales), 2) AS warehouse_units,
    ROUND(SUM(retail_transfers), 2) AS transfer_units,
    ROUND(SUM(total_units), 2) AS total_units_all_channels,
    ROUND(SUM(retail_sales) * 100.0
        / SUM(SUM(retail_sales)) OVER (), 1) AS retail_percent_of_all_months
FROM retail_warehouse_sales
GROUP BY sale_month, month_name
ORDER BY sale_month;

-- ---------------------------------------------------------------
-- Q3.2 Seasonal unit volume by item type
-- Insight: Which category spikes most in summer 
--          Helps with category-specific procurement planning.
-- ---------------------------------------------------------------
SELECT
    item_type_clean AS item_type,
    ROUND(SUM(CASE WHEN sale_month = 1 THEN retail_sales ELSE 0 END), 2)   AS jan_units,
    ROUND(SUM(CASE WHEN sale_month = 3 THEN retail_sales ELSE 0 END), 2)   AS mar_units,
    ROUND(SUM(CASE WHEN sale_month = 7 THEN retail_sales ELSE 0 END), 2)   AS jul_units,
    ROUND(SUM(CASE WHEN sale_month = 9 THEN retail_sales ELSE 0 END), 2)   AS sep_units,
    ROUND(SUM(retail_sales), 2) AS total_retail_units
FROM retail_warehouse_sales
GROUP BY item_type_clean
ORDER BY total_retail_units DESC;

-- ---------------------------------------------------------------
-- Q3.3 Year-to-date cumulative units by item type
-- Insight: Track how unit volume accumulates across months
--          for each category — useful for YTD target tracking
-- ---------------------------------------------------------------
WITH monthly_type AS (
    SELECT
        item_type_clean AS item_type,
        sale_month,
        month_name,
        ROUND(SUM(retail_sales), 2) AS retail_units
    FROM retail_warehouse_sales
    GROUP BY item_type_clean, sale_month, month_name
)
SELECT
    item_type,
    sale_month,
    month_name,
    retail_units,
    ROUND(SUM(retail_units) OVER (
        PARTITION BY item_type
        ORDER BY sale_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS ytd_retail_units
FROM monthly_type
ORDER BY item_type, sale_month;

-- ---------------------------------------------------------------
-- Q3.4 Month-over-month unit growth rate
-- Insight: Measure how much volume grew or declined between
--          available months — key input for demand forecasting
-- ---------------------------------------------------------------
WITH monthly_summary AS (
    SELECT
        sale_month,
        month_name,
        ROUND(SUM(retail_sales), 2) AS retail_units,
        ROUND(SUM(warehouse_sales), 2) AS warehouse_units
    FROM retail_warehouse_sales
    GROUP BY sale_month, month_name
)
SELECT
    sale_month,
    month_name,
    retail_units,
    warehouse_units,
    LAG(retail_units) OVER (ORDER BY sale_month) AS prev_month_retail_units,
    ROUND(
        (retail_units - LAG(retail_units) OVER (ORDER BY sale_month))
        * 100.0
        / NULLIF(LAG(retail_units) OVER (ORDER BY sale_month), 0)
    , 1) AS retail_mom_growth_percent,
    ROUND(
        (warehouse_units - LAG(warehouse_units) OVER (ORDER BY sale_month))
        * 100.0
        / NULLIF(LAG(warehouse_units) OVER (ORDER BY sale_month), 0)
    , 1) AS warehouse_mom_growth_percent
FROM monthly_summary
ORDER BY sale_month;

-- VIEW: seasonal trends 
CREATE OR REPLACE VIEW vw_seasonal_trends AS
SELECT
    sale_month,
    month_name,
    item_type_clean AS item_type,
    ROUND(SUM(retail_sales), 2) AS retail_units,
    ROUND(SUM(warehouse_sales), 2) AS warehouse_units,
    ROUND(SUM(retail_transfers), 2) AS transfer_units,
    ROUND(SUM(total_units), 2) AS total_units
FROM retail_warehouse_sales
GROUP BY sale_month, month_name, item_type_clean;