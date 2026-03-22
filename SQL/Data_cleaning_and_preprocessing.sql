-- A1. Check for NULL or empty values in critical columns
SELECT
    SUM(supplier = ''  OR supplier  IS NULL)   AS null_supplier,
    SUM(item_code = '' OR item_code IS NULL)   AS null_item_code,
    SUM(item_desc = '' OR item_desc IS NULL)   AS null_item_desc,
    SUM(item_type = '' OR item_type IS NULL)   AS null_item_type
FROM retail_warehouse_sales;

-- A2. Check all distinct item types
SELECT
    item_type,
    COUNT(*)  AS record_count,
    ROUND(COUNT(*) * 100.0 / 29998, 2)  AS percent_of_total
FROM retail_warehouse_sales
GROUP BY item_type
ORDER BY record_count DESC;

-- A3. Check for negative unit values (returns or adjustments)
SELECT
    'retail_sales' AS channel,
    COUNT(*)  AS negative_entries,
    SUM(retail_sales) AS total_negative_units
FROM retail_warehouse_sales
WHERE retail_sales < 0

UNION ALL

SELECT
    'warehouse_sales',
    COUNT(*),
    SUM(warehouse_sales)
FROM retail_warehouse_sales
WHERE warehouse_sales < 0

UNION ALL

SELECT
    'retail_transfers',
    COUNT(*),
    SUM(retail_transfers)
FROM retail_warehouse_sales
WHERE retail_transfers < 0;

-- A4. Records where ALL three channels = 0 (no movement at all)
SELECT COUNT(*) AS zero_all_channels
FROM retail_warehouse_sales
WHERE retail_sales     = 0
  AND warehouse_sales  = 0
  AND retail_transfers = 0;
  
-- A5. Months available in the dataset
SELECT
    sale_month,
    COUNT(*) AS record_count
FROM retail_warehouse_sales
GROUP BY sale_month
ORDER BY sale_month;

-- A6. Duplicate check: same supplier + item_code + month
SELECT
    supplier,
    item_code,
    sale_month,
    COUNT(*) AS occurrences
FROM retail_warehouse_sales
GROUP BY supplier, item_code, sale_month
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 10;

-- B1. Readable month name
ALTER TABLE retail_warehouse_sales
    ADD COLUMN month_name VARCHAR(15) GENERATED ALWAYS AS (
        CASE sale_month
            WHEN 1 THEN 'January'
            WHEN 3 THEN 'March'
            WHEN 7 THEN 'July'
            WHEN 9 THEN 'September'
            ELSE 'Unknown'
        END
    ) STORED;
    
-- B2. Total units across all three channels
ALTER TABLE retail_warehouse_sales
    ADD COLUMN total_units DECIMAL(12,2) GENERATED ALWAYS AS (
        retail_sales + retail_transfers + warehouse_sales
    ) STORED;
    
-- B3. Dominant channel per record
ALTER TABLE retail_warehouse_sales
    ADD COLUMN dominant_channel VARCHAR(20) GENERATED ALWAYS AS (
        CASE
            WHEN warehouse_sales >= retail_sales
             AND warehouse_sales >= retail_transfers THEN 'Warehouse'
            WHEN retail_sales >= retail_transfers    THEN 'Retail'
            ELSE 'Transfer'
        END
    ) STORED;

-- B4. Clean item type — group rare types (REF, DUNNAGE, STR_SUPPLIES) as OTHER
ALTER TABLE retail_warehouse_sales
    ADD COLUMN item_type_clean VARCHAR(30) GENERATED ALWAYS AS (
        CASE
            WHEN item_type IN ('WINE','BEER','LIQUOR','KEGS','NON-ALCOHOL')
                THEN item_type
            ELSE 'OTHER'
        END
    ) STORED;
    
ALTER TABLE retail_warehouse_sales
    ADD COLUMN is_return TINYINT(1) GENERATED ALWAYS AS (
        CASE WHEN retail_sales < 0 OR warehouse_sales < 0 THEN 1 ELSE 0 END
    ) STORED,

    ADD COLUMN is_dead_stock TINYINT(1) GENERATED ALWAYS AS (
        CASE WHEN warehouse_sales > 0 AND retail_sales = 0 THEN 1 ELSE 0 END
    ) STORED;
    
-- Verify all new columns were added correctly
DESCRIBE retail_warehouse_sales;