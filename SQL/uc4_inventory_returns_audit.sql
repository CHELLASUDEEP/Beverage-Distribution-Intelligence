-- Business Use Case 4: Inventory & Returns Audit
-- Question: How many SKUs sit in the warehouse with no retail
--           movement? How significant are unit returns and
--           negative adjustments?

USE beverage_analytics;

-- ---------------------------------------------------------------
-- Q4.1 Dead stock summary by item type
-- Insight: 13,401 records have warehouse units moved but
--          zero retail. Beer and Wine dominate dead stock volume.
--          These are bulk-only or unretailed SKUs — flag for review.
-- ---------------------------------------------------------------
SELECT
    item_type_clean AS item_type,
    COUNT(*)  AS dead_stock_records,
    ROUND(SUM(warehouse_sales), 2) AS warehouse_units_no_retail,
    COUNT(DISTINCT supplier) AS suppliers_affected,
    COUNT(DISTINCT item_code) AS unique_skus_affected
FROM retail_warehouse_sales
WHERE is_dead_stock = 1
GROUP BY item_type_clean
ORDER BY warehouse_units_no_retail DESC;

-- ---------------------------------------------------------------
-- Q4.2 Top 20 dead stock items by warehouse unit volume
-- Insight: Highest-volume unretailed items — prioritise
--          these for redistribution or discontinuation decisions
-- ---------------------------------------------------------------
SELECT
    supplier,
    item_code,
    item_desc,
    item_type_clean AS item_type,
    sale_month,
    month_name,
    ROUND(warehouse_sales, 2) AS warehouse_units
FROM retail_warehouse_sales
WHERE is_dead_stock = 1
ORDER BY warehouse_sales DESC
LIMIT 20;

-- ---------------------------------------------------------------
-- Q4.3 Returns and negative adjustment entries
-- Insight: Negative values = returns or write-offs.
--          KEGS and DUNNAGE have large negative warehouse entries —
--          likely empty container returns (kegs returned to supplier)
-- ---------------------------------------------------------------
SELECT
    item_type_clean AS item_type,
    supplier,
    item_desc,
    sale_month,
    month_name,
    ROUND(retail_sales, 2) AS retail_units,
    ROUND(warehouse_sales, 2) AS warehouse_units,
    ROUND(retail_transfers, 2) AS transfer_units
FROM retail_warehouse_sales
WHERE is_return = 1
ORDER BY warehouse_sales ASC   -- most negative first
LIMIT 20;

-- ---------------------------------------------------------------
-- Q4.4 Return rate by supplier
-- Insight: Which suppliers have the highest proportion of
--          return/adjustment records? Signals quality or
--          logistics issues with that supplier.
-- ---------------------------------------------------------------
SELECT
    supplier,
    COUNT(*)  AS total_records,
    SUM(is_return) AS return_records,
    ROUND(SUM(is_return) * 100.0 / COUNT(*), 2)  AS return_rate_percent,
    ROUND(SUM(CASE WHEN is_return = 1
              THEN warehouse_sales ELSE 0 END), 2) AS total_return_units
FROM retail_warehouse_sales
WHERE supplier != ''
GROUP BY supplier
HAVING return_records > 0
ORDER BY total_return_units ASC    -- worst (most negative) first
LIMIT 15;

-- ---------------------------------------------------------------
-- Q4.5 Monthly dead stock trend
-- Insight: Is dead stock a consistent problem or concentrated
--          in specific months? Helps target investigation.
-- ---------------------------------------------------------------
SELECT
    sale_month,
    month_name,
    COUNT(*) AS dead_stock_records,
    ROUND(SUM(warehouse_sales), 2) AS dead_stock_warehouse_units,
    COUNT(DISTINCT item_code) AS unique_skus_unretailed
FROM retail_warehouse_sales
WHERE is_dead_stock = 1
GROUP BY sale_month, month_name
ORDER BY sale_month;

-- VIEW: inventory audit 

CREATE OR REPLACE VIEW vw_inventory_audit AS
SELECT
    supplier,
    item_code,
    item_desc,
    item_type_clean AS item_type,
    sale_month,
    month_name,
    ROUND(retail_sales, 2) AS retail_units,
    ROUND(warehouse_sales, 2) AS warehouse_units,
    ROUND(retail_transfers, 2) AS transfer_units,
    ROUND(total_units, 2) AS total_units,
    is_dead_stock,
    is_return,
    dominant_channel
FROM retail_warehouse_sales;
