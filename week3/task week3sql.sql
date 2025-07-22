
-- Task 1: Customer Spending Analysis
DECLARE @CustomerID INT = 1;
DECLARE @Total MONEY;
SELECT @Total = SUM(oi.quantity * p.list_price)
FROM sales.orders o
JOIN sales.order_items oi ON o.order_id = oi.order_id
JOIN production.products p ON oi.product_id = p.product_id
WHERE o.customer_id = @CustomerID;
IF @Total > 5000
    PRINT 'VIP Customer';
ELSE
    PRINT 'Regular Customer';
PRINT 'Total Spent: ' + CAST(@Total AS VARCHAR);

-- Task 2: Product Price Threshold Report
DECLARE @Threshold MONEY = 1500;
DECLARE @ProductCount INT;
SELECT @ProductCount = COUNT(*)
FROM production.products
WHERE list_price > @Threshold;
PRINT 'Threshold: $' + CAST(@Threshold AS VARCHAR);
PRINT 'Count: ' + CAST(@ProductCount AS VARCHAR);

-- Task 3: Staff Performance Calculator
DECLARE @StaffID INT = 2;
DECLARE @Year INT = 2017;
DECLARE @TotalSales MONEY;
SELECT @TotalSales = SUM(oi.quantity * p.list_price)
FROM sales.orders o
JOIN sales.order_items oi ON o.order_id = oi.order_id
JOIN production.products p ON oi.product_id = p.product_id
WHERE o.staff_id = @StaffID AND YEAR(o.order_date) = @Year;
PRINT 'Total Sales for Staff ' + CAST(@StaffID AS VARCHAR) + ' in ' + CAST(@Year AS VARCHAR) + ': $' + CAST(@TotalSales AS VARCHAR);

-- Task 4: Global Variables Info
SELECT @@SERVERNAME AS ServerName, @@VERSION AS SQLVersion, @@ROWCOUNT AS RowsAffected;

-- Task 5: Inventory Level Check
DECLARE @Qty INT;
SELECT @Qty = quantity FROM production.stocks WHERE product_id = 1 AND store_id = 1;
IF @Qty > 20
    PRINT 'Well stocked';
ELSE IF @Qty BETWEEN 10 AND 20
    PRINT 'Moderate stock';
ELSE
    PRINT 'Low stock - reorder needed';

-- Task 6: WHILE loop to update low-stock
DECLARE @Counter INT = 0;
WHILE @Counter < 3
BEGIN
    UPDATE TOP (3) production.stocks
    SET quantity = quantity + 10
    WHERE quantity < 5;
    SET @Counter = @Counter + 1;
    PRINT 'Batch ' + CAST(@Counter AS VARCHAR) + ' updated';
END

-- Task 7: Product Price Categorization
SELECT product_id, product_name, list_price,
    Category = CASE 
        WHEN list_price < 300 THEN 'Budget'
        WHEN list_price BETWEEN 300 AND 800 THEN 'Mid-Range'
        WHEN list_price BETWEEN 801 AND 2000 THEN 'Premium'
        ELSE 'Luxury' END
FROM production.products;

-- Task 8: Customer Order Validation
IF EXISTS (SELECT 1 FROM sales.customers WHERE customer_id = 5)
    SELECT COUNT(*) AS OrderCount FROM sales.orders WHERE customer_id = 5;
ELSE
    PRINT 'Customer not found';

-- Task 9: Scalar Function CalculateShipping
CREATE FUNCTION dbo.CalculateShipping(@OrderTotal MONEY)
RETURNS MONEY AS
BEGIN
    DECLARE @Shipping MONEY;
    IF @OrderTotal > 100 SET @Shipping = 0;
    ELSE IF @OrderTotal >= 50 SET @Shipping = 5.99;
    ELSE SET @Shipping = 12.99;
    RETURN @Shipping;
END;

-- Task 10: Inline TVF GetProductsByPriceRange
CREATE FUNCTION dbo.GetProductsByPriceRange(@MinPrice MONEY, @MaxPrice MONEY)
RETURNS TABLE
AS RETURN
SELECT p.product_id, p.product_name, p.list_price, b.brand_name, c.category_name
FROM production.products p
JOIN production.brands b ON p.brand_id = b.brand_id
JOIN production.categories c ON p.category_id = c.category_id
WHERE p.list_price BETWEEN @MinPrice AND @MaxPrice;

-- Task 11: Multi-statement Function GetCustomerYearlySummary
CREATE FUNCTION dbo.GetCustomerYearlySummary(@CustomerID INT)
RETURNS @Result TABLE (Year INT, TotalOrders INT, TotalSpent MONEY, AvgOrder MONEY)
AS
BEGIN
    INSERT INTO @Result
    SELECT YEAR(o.order_date),
           COUNT(DISTINCT o.order_id),
           SUM(oi.quantity * p.list_price),
           AVG(oi.quantity * p.list_price)
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    JOIN production.products p ON oi.product_id = p.product_id
    WHERE o.customer_id = @CustomerID
    GROUP BY YEAR(o.order_date);
    RETURN;
END;

-- Task 12: Scalar Function CalculateBulkDiscount
CREATE FUNCTION dbo.CalculateBulkDiscount(@Qty INT)
RETURNS INT
AS
BEGIN
    DECLARE @Discount INT;
    IF @Qty BETWEEN 1 AND 2 SET @Discount = 0;
    ELSE IF @Qty BETWEEN 3 AND 5 SET @Discount = 5;
    ELSE IF @Qty BETWEEN 6 AND 9 SET @Discount = 10;
    ELSE SET @Discount = 15;
    RETURN @Discount;
END;

-- Task 13: Procedure sp_GetCustomerOrderHistory
CREATE PROCEDURE sp_GetCustomerOrderHistory
    @CustomerID INT, @StartDate DATE = NULL, @EndDate DATE = NULL
AS
BEGIN
    SELECT o.order_id, o.order_date, SUM(oi.quantity * p.list_price) AS Total
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    JOIN production.products p ON oi.product_id = p.product_id
    WHERE o.customer_id = @CustomerID AND
          (@StartDate IS NULL OR o.order_date >= @StartDate) AND
          (@EndDate IS NULL OR o.order_date <= @EndDate)
    GROUP BY o.order_id, o.order_date;
END;

-- Task 14: Procedure sp_RestockProduct
CREATE PROCEDURE sp_RestockProduct
    @StoreID INT, @ProductID INT, @Qty INT,
    @OldQty INT OUTPUT, @NewQty INT OUTPUT, @Success BIT OUTPUT
AS
BEGIN
    SELECT @OldQty = quantity FROM production.stocks
    WHERE store_id = @StoreID AND product_id = @ProductID;

    UPDATE production.stocks
    SET quantity = quantity + @Qty
    WHERE store_id = @StoreID AND product_id = @ProductID;

    SELECT @NewQty = quantity FROM production.stocks
    WHERE store_id = @StoreID AND product_id = @ProductID;

    SET @Success = 1;
END;

-- Remaining tasks to be continued in next file due to length...
