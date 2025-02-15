--1. What are the top 5 brands by receipts scanned for the most recent month?
SELECT 
    b.name AS brand_name,
    COUNT(DISTINCT r._id) AS receipts_scanned
FROM 
    Receipts r
JOIN 
    ReceiptItems ri ON r._id = ri.receiptId
JOIN 
    Brands b ON ri.brandId = b._id
WHERE 
    DATE_TRUNC('month', r.dateScanned) = DATE_TRUNC('month', CURRENT_DATE)
GROUP BY 
    b.name
ORDER BY 
    receipts_scanned DESC
LIMIT 5;


--2. How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?
WITH RecentMonth AS (
    SELECT 
        b.name AS brand_name,
        COUNT(DISTINCT r._id) AS receipts_scanned
    FROM 
        Receipts r
    JOIN 
        ReceiptItems ri ON r._id = ri.receiptId
    JOIN 
        Brands b ON ri.brandId = b._id
    WHERE 
        DATE_TRUNC('month', r.dateScanned) = DATE_TRUNC('month', CURRENT_DATE)
    GROUP BY 
        b.name
),
PreviousMonth AS (
    SELECT 
        b.name AS brand_name,
        COUNT(DISTINCT r._id) AS receipts_scanned
    FROM 
        Receipts r
    JOIN 
        ReceiptItems ri ON r._id = ri.receiptId
    JOIN 
        Brands b ON ri.brandId = b._id
    WHERE 
        DATE_TRUNC('month', r.dateScanned) = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
    GROUP BY 
        b.name
)
SELECT 
    rm.brand_name,
    rm.receipts_scanned AS recent_month_count,
    pm.receipts_scanned AS previous_month_count,
    RANK() OVER (ORDER BY rm.receipts_scanned DESC) AS recent_month_rank,
    RANK() OVER (ORDER BY pm.receipts_scanned DESC) AS previous_month_rank
FROM 
    RecentMonth rm
FULL OUTER JOIN 
    PreviousMonth pm ON rm.brand_name = pm.brand_name
ORDER BY 
    recent_month_rank
LIMIT 5;


-- 3. When considering average spend from receipts with 'rewardsReceiptStatus' of 'Accepted' or 'Rejected', which is greater?
SELECT 
    rewardsReceiptStatus,
    AVG(totalSpent) AS average_spend
FROM 
    Receipts
WHERE 
    rewardsReceiptStatus IN ('Accepted', 'Rejected')
GROUP BY 
    rewardsReceiptStatus
ORDER BY 
    average_spend DESC limit 1;


--4. When considering the total number of items purchased from receipts with 'rewardsReceiptStatus' of 'Accepted' or 'Rejected', which is greater?
SELECT 
    r.rewardsReceiptStatus,
    SUM(ri.quantity) AS total_items_purchased
FROM 
    Receipts r
JOIN 
    ReceiptItems ri ON r._id = ri.receiptId
WHERE 
    r.rewardsReceiptStatus IN ('Accepted', 'Rejected')
GROUP BY 
    r.rewardsReceiptStatus
ORDER BY 
    total_items_purchased DESC limit 1;


--5. Which brand has the most spend among users who were created within the past 6 months?
SELECT 
    b.name AS brand_name,
    COUNT(DISTINCT r._id) AS transaction_count
FROM 
    Receipts r
JOIN 
    ReceiptItems ri ON r._id = ri.receiptId
JOIN 
    Brands b ON ri.brandId = b._id
JOIN 
    Users u ON r.userId = u._id
WHERE 
    u.createdDate >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY 
    b.name
ORDER BY 
    transaction_count DESC
LIMIT 1;






