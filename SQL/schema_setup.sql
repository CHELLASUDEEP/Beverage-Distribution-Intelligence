CREATE DATABASE IF NOT EXISTS beverage_analytics;
USE beverage_analytics;

DROP TABLE IF EXISTS retail_warehouse_sales;

CREATE TABLE retail_warehouse_sales (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    sale_year           SMALLINT        NOT NULL,
    sale_month          TINYINT         NOT NULL,
    supplier            VARCHAR(150)    NOT NULL,
    item_code           VARCHAR(20)     NOT NULL,
    item_desc           VARCHAR(255)    NOT NULL,
    item_type           VARCHAR(30)     NOT NULL,
    retail_sales        DECIMAL(12,2)   DEFAULT 0.00,
    retail_transfers    DECIMAL(12,2)   DEFAULT 0.00,
    warehouse_sales     DECIMAL(12,2)   DEFAULT 0.00
);

SELECT COUNT(*) AS total_rows FROM retail_warehouse_sales;

SELECT * FROM retail_warehouse_sales LIMIT 5;

