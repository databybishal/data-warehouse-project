/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
   This stored procedure loads data into the 'silver' schema from the 'bronze' schema.
   It performs the following actions:
   - Truncates the silver tables before loading data.
   - Transforms and cleans data from bronze tables.
   - Inserts processed data into silver tables.
   - Tracks execution time for each table and the overall batch.
   - Handles errors using TRY...CATCH for better debugging.

Parameters:
   None.
     This stored procedure does not accept any parameters or return any values.

Usage Example:
   EXEC silver.proc_load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.proc_load_silver
AS
BEGIN
    DECLARE @start_time DATETIME,
            @end_time DATETIME,
            @batch_start_time DATETIME,
            @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();

        PRINT '==========================================';
        PRINT 'Loading Silver Layer';
        PRINT '==========================================';

        ------------------------------------------------
        PRINT 'Processing CRM Tables';
        PRINT '------------------------------------------------';

        -- 1. crm_cust_info
        SET @start_time = GETDATE();

        PRINT '>> Truncate table: Silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;

        PRINT '>> Inserting Data Into table: Silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info
        (cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date)
        SELECT
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            CASE
                WHEN cst_marital_status = 'S' THEN 'Single'
                WHEN cst_marital_status = 'M' THEN 'Married'
                ELSE 'n/a'
            END AS cst_marital_status,
            CASE
                WHEN cst_gndr = 'F' THEN 'Female'
                WHEN cst_gndr = 'M' THEN 'Male'
                ELSE 'n/a'
            END AS cst_gndr,
            cst_create_date
        FROM (
            SELECT
                cst_id,
                cst_key,
                TRIM(cst_firstname) AS cst_firstname,
                TRIM(cst_lastname) AS cst_lastname,
                UPPER(TRIM(cst_marital_status)) AS cst_marital_status,
                UPPER(TRIM(cst_gndr)) AS cst_gndr,
                cst_create_date,
                ROW_NUMBER() OVER (
                    PARTITION BY cst_id 
                    ORDER BY cst_create_date DESC, cst_key DESC
                ) AS rank_cust_date
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) t
        WHERE rank_cust_date = 1;

        SET @end_time = GETDATE();
        PRINT 'Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
        PRINT '>> -------------';


        -- 2. crm_prd_info
        SET @start_time = GETDATE();

        PRINT '>> Truncate table: silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;

        PRINT '>> Inserting Data Into table: silver.crm_prd_info';
        INSERT INTO silver.crm_prd_info
        (prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt)
        SELECT
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
            prd_nm,
            ISNULL(prd_cost, 0) AS prd_cost,
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
            END AS prd_line,
            CAST(prd_start_dt AS DATE) AS prd_start_dt,
            CAST(
                DATEADD(
                    DAY, -1,
                    LEAD(prd_start_dt) OVER (
                        PARTITION BY prd_key 
                        ORDER BY prd_start_dt
                    )
                ) AS DATE
            ) AS prd_end_dt
        FROM bronze.crm_prd_info;

        SET @end_time = GETDATE();
        PRINT 'Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
        PRINT '>> -------------';


        -- 3. crm_sales_details
        SET @start_time = GETDATE();

        PRINT '>> Truncate table: silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;

        PRINT '>> Inserting Data Into table: silver.crm_sales_details';
        INSERT INTO silver.crm_sales_details
        (sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price)
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            -- ✅ Order Date (validated)
             TRY_CONVERT(date,
                 CASE 
                     WHEN sls_order_dt BETWEEN 20000101 AND YEAR(GETDATE()) * 10000 + 1231
                     THEN CAST(sls_order_dt AS VARCHAR(8))
                     ELSE NULL
                 END,
             112) AS sls_order_dt,
         
             -- ✅ Ship Date (validated)
             TRY_CONVERT(date,
                 CASE 
                     WHEN sls_ship_dt BETWEEN 20000101 AND YEAR(GETDATE()) * 10000 + 1231
                     THEN CAST(sls_ship_dt AS VARCHAR(8))
                     ELSE NULL
                 END,
             112) AS sls_ship_dt,
         
             -- ✅ Due Date (validated)
             TRY_CONVERT(date,
                 CASE 
                     WHEN sls_due_dt BETWEEN 20000101 AND YEAR(GETDATE()) * 10000 + 1231
                     THEN CAST(sls_due_dt AS VARCHAR(8))
                     ELSE NULL
                 END,
             112) AS sls_due_dt,
                     CASE
                WHEN sls_sales IS NULL 
                     OR sls_sales <= 0 
                     OR sls_sales != sls_quantity * ABS(sls_price)
                THEN ABS(sls_quantity) * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,
            sls_quantity,
            CASE
                WHEN sls_price IS NULL OR sls_price <= 0
                THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END AS sls_price
        FROM bronze.crm_sales_details;

        SET @end_time = GETDATE();
        PRINT 'Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
        PRINT '>> -------------';


        ------------------------------------------------
        PRINT 'Processing ERP Tables';
        PRINT '------------------------------------------------';

        -- 4. erp_cust_az12
        SET @start_time = GETDATE();

        PRINT '>> Truncate table: silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;

        PRINT '>> Inserting Data Into table: silver.erp_cust_az12';
        INSERT INTO silver.erp_cust_az12
        (cid, bdate, gen)
        SELECT 
            CASE 
                WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) 
                ELSE cid 
            END AS cid,
            CASE 
                WHEN bdate IS NULL OR bdate > CAST(GETDATE() AS DATE) 
                THEN NULL 
                ELSE bdate 
            END AS bdate,
            CASE UPPER(LEFT(TRIM(gen), 1))
                WHEN 'M' THEN 'Male'
                WHEN 'F' THEN 'Female'
                ELSE 'n/a'
            END AS gen
        FROM bronze.erp_cust_az12;

        SET @end_time = GETDATE();
        PRINT 'Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
        PRINT '>> -------------';


        -- 5. erp_loc_a101
        SET @start_time = GETDATE();

        PRINT '>> Truncate table: silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;

        PRINT '>> Inserting Data Into table: silver.erp_loc_a101';
        INSERT INTO silver.erp_loc_a101
        (cid, cntry)
        SELECT
            REPLACE(cid, '-', '') AS cid,
            CASE
                WHEN UPPER(REPLACE(TRIM(cntry), CHAR(13), ''))
                IN ('FRANCE','UNITED KINGDOM','CANADA','GERMANY','AUSTRALIA')
                THEN REPLACE(TRIM(cntry), CHAR(13), '')
                WHEN UPPER(REPLACE(TRIM(cntry), CHAR(13), '')) = 'DE' THEN 'Denmark'
                WHEN UPPER(REPLACE(TRIM(cntry), CHAR(13), '')) IN ('UNITED STATES','US') THEN 'United States'
                ELSE 'n/a'
            END AS cntry
        FROM bronze.erp_loc_a101;

        SET @end_time = GETDATE();
        PRINT 'Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
        PRINT '>> -------------';


        -- 6. erp_px_cat_g1v2
        SET @start_time = GETDATE();

        PRINT '>> Truncate table: silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        PRINT '>> Inserting Data Into table: silver.erp_px_cat_g1v2';
        INSERT INTO silver.erp_px_cat_g1v2
        (id, cat, subcat, maintenance)
        SELECT
            id,
            cat,
            subcat,
            REPLACE(TRIM(maintenance), CHAR(13), '') AS maintenance
        FROM bronze.erp_px_cat_g1v2;

        SET @end_time = GETDATE();
        PRINT 'Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR);
        PRINT '>> -------------';


        SET @batch_end_time = GETDATE();

        PRINT '==========================================';
        PRINT 'Loading Silver Layer is Completed';
        PRINT 'Total Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '==========================================';

    END TRY
    BEGIN CATCH
        PRINT '==========================================';
        PRINT 'ERROR OCCURRED DURING LOADING SILVER LAYER';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==========================================';
    END CATCH
END;

EXEC silver.proc_load_silver;
