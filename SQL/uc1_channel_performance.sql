-- Business Use Case 1: Channel Performance Analysis
-- Question: How do Retail, Warehouse and Transfer channels compare
--           in unit volume? Where should the business focus?
-- Note: All figures are UNITS SOLD/TRANSFERRED, not USD

USE beverage_analytics;

-- ---------------------------------------------------------------
-- Q1.1 Overall channel volume summary
-- Insight: Warehouse dominates total unit volume (822K units).
--          Retail accounts for 208K units, Transfers for 197K units.
--          Warehouse is the primary distribution channel.
-- ---------------------------------------------------------------
SELECT
    'Retail Sales' AS channel,
    ROUND(SUM(retail_sales), 2) AS total_units,
    ROUND(SUM(retail_sales) * 100.0
        / (SELECT SUM(retail_sales + warehouse_sales + retail_transfers)
           FROM retail_warehouse_sales), 2) AS pct_of_total_units
FROM retail_warehouse_sales
WHERE retail_sales > 0

UNION ALL

SELECT
    'Warehouse Sales',
    ROUND(SUM(warehouse_sales), 2),
    ROUND(SUM(warehouse_sales) * 100.0
        / (SELECT SUM(retail_sales + warehouse_sales + retail_transfers)
           FROM retail_warehouse_sales), 2)
FROM retail_warehouse_sales
WHERE warehouse_sales > 0

UNION ALL

SELECT
    'Retail Transfers',
    ROUND(SUM(retail_transfers), 2),
    ROUND(SUM(retail_transfers) * 100.0
        / (SELECT SUM(retail_sales + warehouse_sales + retail_transfers)
           FROM retail_warehouse_sales), 2)
FROM retail_warehouse_sales
WHERE retail_transfers > 0;

-- ---------------------------------------------------------------
-- Q1.2 Channel unit volume by item type
-- Insight: Beer moves almost entirely via warehouse (697K units).
--          Liquor leads retail channel (81K units).
--          Wine is balanced across both channels.
-- ---------------------------------------------------------------
SELECT
    item_type_clean  AS item_type,
    ROUND(SUM(retail_sales), 2)  AS retail_units,
    ROUND(SUM(warehouse_sales), 2) AS warehouse_units,
    ROUND(SUM(retail_transfers), 2)  AS transfer_units,
    ROUND(SUM(retail_sales) * 100.0
        / NULLIF(SUM(retail_sales + warehouse_sales), 0), 1)AS retail_share_pct,
    ROUND(SUM(warehouse_sales) * 100.0
        / NULLIF(SUM(retail_sales + warehouse_sales), 0), 1)AS warehouse_share_pct
FROM retail_warehouse_sales
GROUP BY item_type_clean
ORDER BY retail_units DESC;

-- ---------------------------------------------------------------
-- Q1.3 Channel unit volume by month
-- Insight: July is peak for both retail (94K) and warehouse (418K).
--          September is very low — likely incomplete month data.
-- ---------------------------------------------------------------
SELECT
    sale_month,
    month_name,
    ROUND(SUM(retail_sales), 2) AS retail_units,
    ROUND(SUM(warehouse_sales), 2) AS warehouse_units,
    ROUND(SUM(retail_transfers), 2) AS transfer_units,
    ROUND(SUM(total_units), 2)AS total_units_all_channels,
    COUNT(*)  AS record_count
FROM retail_warehouse_sales
GROUP BY sale_month, month_name
ORDER BY sale_month;

-- ---------------------------------------------------------------
-- Q1.4 Transfer-to-Retail unit ratio by item type
-- Insight: ~97% of retail wine units are also transferred —
--          meaning nearly every unit sold is also transferred.
--          Strong channel coupling useful for demand forecasting.
-- ---------------------------------------------------------------
SELECT
    item_type_clean AS item_type,
    ROUND(SUM(retail_sales), 2)  AS retail_units,
    ROUND(SUM(retail_transfers), 2) AS transfer_units,
    ROUND(SUM(retail_transfers) * 100.0
        / NULLIF(SUM(retail_sales), 0), 1) AS transfer_to_retail_ratio_pct
FROM retail_warehouse_sales
WHERE item_type_clean IN ('WINE', 'BEER', 'LIQUOR')
GROUP BY item_type_clean
ORDER BY transfer_to_retail_ratio_pct DESC;

-- ---------------------------------------------------------------
-- Q1.5 Records with zero movement across all channels
-- Insight: Helps identify ghost records or data entry issues
-- ---------------------------------------------------------------
SELECT
    item_type_clean AS item_type,
    COUNT(*) AS zero_movement_records,
    COUNT(DISTINCT supplier) AS suppliers_affected
FROM retail_warehouse_sales
WHERE retail_sales = 0
  AND warehouse_sales = 0
  AND retail_transfers = 0
GROUP BY item_type_clean
ORDER BY zero_movement_records DESC;

-- VIEW: channel summary by type and month

CREATE OR REPLACE VIEW vw_channel_by_type AS
SELECT
    item_type_clean AS item_type,
    sale_month,
    month_name,
    ROUND(SUM(retail_sales), 2)  AS retail_units,
    ROUND(SUM(warehouse_sales), 2) AS warehouse_units,
    ROUND(SUM(retail_transfers), 2) AS transfer_units,
    ROUND(SUM(total_units), 2) AS total_units
FROM retail_warehouse_sales
GROUP BY item_type_clean, sale_month, month_name;