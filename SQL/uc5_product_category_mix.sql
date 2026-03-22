-- Business Use Case 5: Product Category Mix Optimisation
-- Question: Which categories deliver the best retail unit volume
--           per SKU? Are any categories over-stocked or
--           consistently underperforming in retail?

USE beverage_analytics;

-- ---------------------------------------------------------------
-- Q5.1 Category performance scorecard
-- Insight: Full picture — unit volume, SKU count, and average
--          units per SKU for each beverage category
-- ---------------------------------------------------------------
SELECT
    item_type_clean AS item_type,
    COUNT(DISTINCT item_code) AS unique_skus,
    COUNT(*) AS total_records,
    ROUND(SUM(retail_sales), 2) AS total_retail_units,
    ROUND(SUM(warehouse_sales), 2) AS total_warehouse_units,
    ROUND(SUM(retail_transfers), 2) AS total_transfer_units,
    ROUND(AVG(retail_sales), 4) AS avg_retail_units_per_record,
    ROUND(SUM(retail_sales)
        / NULLIF(COUNT(DISTINCT item_code), 0), 2) AS retail_units_per_sku
FROM retail_warehouse_sales
GROUP BY item_type_clean
ORDER BY total_retail_units DESC;

-- ---------------------------------------------------------------
-- Q5.2 Top 20 SKUs by retail unit volume
-- Insight: Star products — best-selling individual items
--          across all months and suppliers
-- ---------------------------------------------------------------
SELECT
    item_code,
    item_desc,
    item_type_clean AS item_type,
    supplier,
    ROUND(SUM(retail_sales), 2) AS total_retail_units,
    ROUND(SUM(warehouse_sales), 2) AS total_warehouse_units,
    COUNT(DISTINCT sale_month) AS months_active,
    RANK() OVER (
        ORDER BY SUM(retail_sales) DESC
    )  AS overall_rank
FROM retail_warehouse_sales
WHERE retail_sales > 0
GROUP BY item_code, item_desc, item_type_clean, supplier
ORDER BY total_retail_units DESC
LIMIT 20;

-- ---------------------------------------------------------------
-- Q5.3 Top SKUs within each category
-- Insight: Best performing product per beverage type 
-- ---------------------------------------------------------------
WITH sku_totals AS (
    SELECT
        item_code,
        item_desc,
        item_type_clean AS item_type,
        supplier,
        ROUND(SUM(retail_sales), 2) AS retail_units,
        RANK() OVER (
            PARTITION BY item_type_clean
            ORDER BY SUM(retail_sales) DESC
        )  AS rank_in_category
    FROM retail_warehouse_sales
    WHERE retail_sales > 0
    GROUP BY item_code, item_desc, item_type_clean, supplier
)
SELECT *
FROM sku_totals
WHERE rank_in_category <= 5
ORDER BY item_type, rank_in_category;

-- ---------------------------------------------------------------
-- Q5.4 Category unit volume across months
-- Insight: Which category is most sensitive to seasonal shifts?
--          Beer and Wine show strong July spikes.
-- ---------------------------------------------------------------
SELECT
    item_type_clean AS item_type,
    ROUND(SUM(CASE WHEN sale_month = 1 THEN retail_sales ELSE 0 END), 2)   AS jan_retail_units,
    ROUND(SUM(CASE WHEN sale_month = 3 THEN retail_sales ELSE 0 END), 2)   AS mar_retail_units,
    ROUND(SUM(CASE WHEN sale_month = 7 THEN retail_sales ELSE 0 END), 2)   AS jul_retail_units,
    ROUND(SUM(CASE WHEN sale_month = 9 THEN retail_sales ELSE 0 END), 2)   AS sep_retail_units,
    ROUND(SUM(retail_sales), 2) AS total_retail_units
FROM retail_warehouse_sales
GROUP BY item_type_clean
ORDER BY total_retail_units DESC;

-- ---------------------------------------------------------------
-- Q5.5 Warehouse-only categories (no retail movement at all)
-- Insight: KEGS, DUNNAGE, REF have zero retail units.
--          These are operational/logistics items, not consumer products.
--          Should be excluded from retail performance reports.
-- ---------------------------------------------------------------
SELECT
    item_type,
    item_desc,
    supplier,
    sale_month,
    month_name,
    ROUND(retail_sales, 2) AS retail_units,
    ROUND(warehouse_sales, 2) AS warehouse_units,
    dominant_channel
FROM retail_warehouse_sales
WHERE item_type IN ('KEGS', 'DUNNAGE', 'REF', 'STR_SUPPLIES')
ORDER BY warehouse_sales DESC
LIMIT 20;

-- VIEW: product category mix 
CREATE OR REPLACE VIEW vw_product_category_mix AS
SELECT
    item_type_clean AS item_type,
    item_code,
    item_desc,
    supplier,
    sale_month,
    month_name,
    ROUND(SUM(retail_sales), 2) AS retail_units,
    ROUND(SUM(warehouse_sales), 2) AS warehouse_units,
    ROUND(SUM(retail_transfers), 2) AS transfer_units,
    ROUND(SUM(total_units), 2) AS total_units,
    dominant_channel
FROM retail_warehouse_sales
GROUP BY item_type_clean, item_code, item_desc, supplier,
         sale_month, month_name, dominant_channel;