CREATE OR REPLACE PROCEDURE check_data_quality()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    -- Log start of data quality check
    SYSTEM$LOG_INFO('Data Quality Check Started');

    -- Check data quality for Users table
    SYSTEM$LOG_INFO('Checking Users Table...');
    BEGIN
        LET users_quality STRING;
        users_quality := (
            SELECT OBJECT_CONSTRUCT(
                'table_name', 'Users',
                'total_rows', COUNT(*),
                'missing_user_id', SUM(CASE WHEN _id IS NULL THEN 1 ELSE 0 END),
                'missing_state', SUM(CASE WHEN state IS NULL THEN 1 ELSE 0 END),
                'missing_createdDate', SUM(CASE WHEN createdDate IS NULL THEN 1 ELSE 0 END),
                'missing_lastLogin', SUM(CASE WHEN lastLogin IS NULL THEN 1 ELSE 0 END),
                'missing_role', SUM(CASE WHEN role IS NULL THEN 1 ELSE 0 END),
                'missing_active', SUM(CASE WHEN active IS NULL THEN 1 ELSE 0 END),
                'invalid_role_count', (SELECT COUNT(*) FROM Users WHERE role != 'CONSUMER'),
                'future_createdDate_count', (SELECT COUNT(*) FROM Users WHERE createdDate > CURRENT_DATE)
            )::STRING
            FROM Users
        );
        SYSTEM$LOG_INFO('Users Table Quality: ' || users_quality);
    END;

    -- Check data quality for Receipts table
    SYSTEM$LOG_INFO('Checking Receipts Table...');
    BEGIN
        LET receipts_quality STRING;
        receipts_quality := (
            SELECT OBJECT_CONSTRUCT(
                'table_name', 'Receipts',
                'total_rows', COUNT(*),
                'missing_receipt_id', SUM(CASE WHEN _id IS NULL THEN 1 ELSE 0 END),
                'missing_userId', SUM(CASE WHEN userId IS NULL THEN 1 ELSE 0 END),
                'missing_dateScanned', SUM(CASE WHEN dateScanned IS NULL THEN 1 ELSE 0 END),
                'missing_totalSpent', SUM(CASE WHEN totalSpent IS NULL THEN 1 ELSE 0 END),
                'missing_rewardsReceiptStatus', SUM(CASE WHEN rewardsReceiptStatus IS NULL THEN 1 ELSE 0 END),
                'invalid_status_count', (SELECT COUNT(*) FROM Receipts WHERE rewardsReceiptStatus NOT IN ('Accepted', 'Rejected')),
                'future_date_count', (SELECT COUNT(*) FROM Receipts WHERE dateScanned > CURRENT_DATE OR purchaseDate > CURRENT_DATE OR finishedDate > CURRENT_DATE)
            )::STRING
            FROM Receipts
        );
        SYSTEM$LOG_INFO('Receipts Table Quality: ' || receipts_quality);
    END;

    -- Check data quality for Brands table
    SYSTEM$LOG_INFO('Checking Brands Table...');
    BEGIN
        LET brands_quality STRING;
        brands_quality := (
            SELECT OBJECT_CONSTRUCT(
                'table_name', 'Brands',
                'total_rows', COUNT(*),
                'missing_brand_id', SUM(CASE WHEN _id IS NULL THEN 1 ELSE 0 END),
                'missing_name', SUM(CASE WHEN name IS NULL THEN 1 ELSE 0 END),
                'missing_brandCode', SUM(CASE WHEN brandCode IS NULL THEN 1 ELSE 0 END),
                'missing_category', SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END),
                'duplicate_name_count', (SELECT COUNT(*) FROM (SELECT name, COUNT(*) FROM Brands GROUP BY name HAVING COUNT(*) > 1)),
                'invalid_topBrand_count', (SELECT COUNT(*) FROM Brands WHERE topBrand NOT IN (TRUE, FALSE))
            )::STRING
            FROM Brands
        );
        SYSTEM$LOG_INFO('Brands Table Quality: ' || brands_quality);
    END;

    -- Check data quality for ReceiptItems table
    SYSTEM$LOG_INFO('Checking ReceiptItems Table...');
    BEGIN
        LET receipt_items_quality STRING;
        receipt_items_quality := (
            SELECT OBJECT_CONSTRUCT(
                'table_name', 'ReceiptItems',
                'total_rows', COUNT(*),
                'missing_item_id', SUM(CASE WHEN _id IS NULL THEN 1 ELSE 0 END),
                'missing_receiptId', SUM(CASE WHEN receiptId IS NULL THEN 1 ELSE 0 END),
                'missing_brandId', SUM(CASE WHEN brandId IS NULL THEN 1 ELSE 0 END),
                'missing_itemName', SUM(CASE WHEN itemName IS NULL THEN 1 ELSE 0 END),
                'missing_quantity', SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END),
                'missing_price', SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END),
                'invalid_quantity_count', (SELECT COUNT(*) FROM ReceiptItems WHERE quantity <= 0),
                'invalid_price_count', (SELECT COUNT(*) FROM ReceiptItems WHERE price <= 0),
                'orphaned_receiptId_count', (SELECT COUNT(*) FROM ReceiptItems ri LEFT JOIN Receipts r ON ri.receiptId = r._id WHERE r._id IS NULL),
                'orphaned_brandId_count', (SELECT COUNT(*) FROM ReceiptItems ri LEFT JOIN Brands b ON ri.brandId = b._id WHERE b._id IS NULL)
            )::STRING
            FROM ReceiptItems
        );
        SYSTEM$LOG_INFO('ReceiptItems Table Quality: ' || receipt_items_quality);
    END;

    -- Log completion of data quality check
    SYSTEM$LOG_INFO('Data Quality Check Completed');
    RETURN 'Data Quality Check Completed Successfully';
END;
$$;