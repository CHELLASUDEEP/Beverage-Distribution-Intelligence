-- Business Use Case 2: Supplier Performance Ranking
-- Question: Which suppliers drive the most unit volume?
--           Who are weak performers? What is the channel preference of each supplier?

USE beverage_analytics;

-- ---------------------------------------------------------------
-- Q2.1 Top 20 suppliers by total retail units sold
-- Insight: Diageo leads retail (13,840 units), Anheuser Busch
--          leads warehouse. Top 10 suppliers drive majority of
--          total unit volume across both channels.
-- ---------------------------------------------------------------
SELECT
    supplier,
    COUNT(DISTINCT item_code) AS unique_skus,
    ROUND(SUM(retail_sales), 2) AS retail_units,
    ROUND(SUM(warehouse_sales), 2) AS warehouse_units,
    ROUND(SUM(retail_transfers), 2) AS transfer_units,
    ROUND(SUM(total_units), 2) AS total_units_all_channels
FROM retail_warehouse_sales
WHERE supplier != ''
GROUP BY supplier
ORDER BY retail_units DESC
LIMIT 20;

-- ---------------------------------------------------------------
-- Q2.2 Supplier ranking within each item type
-- Insight: Identify the category leader for each beverage type.
--          Useful for category management and contract decisions.
-- ---------------------------------------------------------------
SELECT
    supplier,
    item_type_clean  AS item_type,
    ROUND(SUM(retail_sales), 2) AS retail_units,
    RANK() OVER (
        PARTITION BY item_type_clean
        ORDER BY SUM(retail_sales) DESC
    ) AS rank_in_category
FROM retail_warehouse_sales
WHERE supplier != ''
  AND item_type_clean IN ('WINE', 'BEER', 'LIQUOR')
GROUP BY supplier, item_type_clean
ORDER BY item_type_clean, rank_in_category;

-- ---------------------------------------------------------------
-- Q2.3 cumulative supplier contribution
-- Insight: Find how many suppliers account for 80% of total retail unit volume
-- ---------------------------------------------------------------
WITH supplier_totals AS (
    SELECT
        supplier,
        ROUND(SUM(retail_sales), 2) AS retail_units
    FROM retail_warehouse_sales
    WHERE supplier != ''
    GROUP BY supplier
),
ranked AS (
    SELECT
        supplier,
        retail_units,
        SUM(retail_units) OVER (ORDER BY retail_units DESC)  AS running_total_units,
        SUM(retail_units) OVER () AS grand_total_units,
        RANK() OVER (ORDER BY retail_units DESC)  AS rnk
    FROM supplier_totals
)
SELECT
    rnk AS supplier_rank,
    supplier,
    retail_units,
    ROUND(running_total_units, 2) AS cumulative_units
FROM ranked
WHERE rnk <= 30
ORDER BY rnk;

-- ---------------------------------------------------------------
-- Q2.4 Supplier channel preference
-- Insight: Classify each supplier as Retail-dominant or
--          Warehouse-dominant — helps tailor partnership strategy
-- ---------------------------------------------------------------
SELECT
    supplier,
    ROUND(SUM(retail_sales), 2) AS retail_units,
    ROUND(SUM(warehouse_sales), 2) AS warehouse_units,
    ROUND(SUM(total_units), 2) AS total_units,
    CASE
        WHEN SUM(retail_sales) > SUM(warehouse_sales)  THEN 'Retail-dominant'
        WHEN SUM(warehouse_sales) > SUM(retail_sales)  THEN 'Warehouse-dominant'
        ELSE 'Balanced'
    END AS channel_preference,
    COUNT(DISTINCT item_type_clean) AS uniq_items
FROM retail_warehouse_sales
WHERE supplier != ''
GROUP BY supplier
HAVING total_units > 100
ORDER BY retail_units DESC
LIMIT 25;

-- ---------------------------------------------------------------
-- Q2.5 Supplier unit volume across available months
-- Insight: Which suppliers peaked vs which declined?
--          Helps forecast procurement needs per supplier.
-- ---------------------------------------------------------------
SELECT
    supplier,
    ROUND(SUM(CASE WHEN sale_month = 1 THEN retail_sales ELSE 0 END), 2) AS jan_retail_units,
    ROUND(SUM(CASE WHEN sale_month = 3 THEN retail_sales ELSE 0 END), 2) AS mar_retail_units,
    ROUND(SUM(CASE WHEN sale_month = 7 THEN retail_sales ELSE 0 END), 2) AS jul_retail_units,
    ROUND(SUM(CASE WHEN sale_month = 9 THEN retail_sales ELSE 0 END), 2) AS sep_retail_units,
    ROUND(SUM(retail_sales), 2) AS total_retail_units
FROM retail_warehouse_sales
WHERE supplier != ''
GROUP BY supplier
HAVING total_retail_units > 500
ORDER BY total_retail_units DESC
LIMIT 20;

-- ---------------------------------------------------------------
-- Q2.6 Suppliers with high warehouse but near-zero retail units
-- Insight: Identify wholesale-only suppliers — they may never
--          appear in retail reports but are critical to warehouse ops
-- ---------------------------------------------------------------
SELECT
    supplier,
    ROUND(SUM(retail_sales), 2) AS retail_units,
    ROUND(SUM(warehouse_sales), 2)  AS warehouse_units,
    COUNT(DISTINCT item_code) AS unique_skus
FROM retail_warehouse_sales
WHERE supplier != ''
GROUP BY supplier
HAVING retail_units = 0
   AND warehouse_units > 0
ORDER BY warehouse_units DESC
LIMIT 15;

-- VIEW: supplier performance summary 
CREATE OR REPLACE VIEW vw_supplier_performance AS
SELECT
    supplier,
    item_type_clean AS item_type,
    sale_month,
    month_name,
    COUNT(DISTINCT item_code) AS unique_skus,
    ROUND(SUM(retail_sales), 2) AS retail_units,
    ROUND(SUM(warehouse_sales), 2) AS warehouse_units,
    ROUND(SUM(retail_transfers), 2) AS transfer_units,
    ROUND(SUM(total_units), 2) AS total_units,
    RANK() OVER (ORDER BY SUM(retail_sales) DESC) AS retail_rank
FROM retail_warehouse_sales
WHERE supplier != ''
GROUP BY supplier, item_type_clean, sale_month, month_name;