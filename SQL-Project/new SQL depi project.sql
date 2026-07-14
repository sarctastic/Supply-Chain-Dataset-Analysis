CREATE DATABASE IF NOT EXISTS supply_chain_db;
USE supply_chain_db;

CREATE TABLE IF NOT EXISTS raw_supply_chain (
    Type VARCHAR(50),
    `Days for shipping (real)` INT,
    `Days for shipment (scheduled)` INT,
    `Benefit per order` DOUBLE,
    `Sales per customer` DOUBLE,
    `Delivery Status` VARCHAR(100),
    Late_delivery_risk INT,
    `Category Id` INT,
    `Category Name` VARCHAR(100),
    `Customer City` VARCHAR(100),
    `Customer Country` VARCHAR(100),
    `Customer Email` VARCHAR(100),
    `Customer Fname` VARCHAR(100),
    `Customer Id` INT,
    `Customer Lname` VARCHAR(100),
    `Customer Password` VARCHAR(100),
    `Customer Segment` VARCHAR(100),
    `Customer State` VARCHAR(50),
    `Customer Street` VARCHAR(255),
    `Customer Zipcode` VARCHAR(50),
    `Department Id` INT,
    `Department Name` VARCHAR(100),
    Latitude DOUBLE,
    Longitude DOUBLE,
    Market VARCHAR(100),
    `Order City` VARCHAR(100),
    `Order Country` VARCHAR(100),
    `Order Customer Id` INT,
    `order date (DateOrders)` VARCHAR(100),
    `Order Id` INT,
    `Order Item Cardprod Id` INT,
    `Order Item Discount` DOUBLE,
    `Order Item Discount Rate` DOUBLE,
    `Order Item Id` INT,
    `Order Item Product Price` DOUBLE,
    `Order Item Profit Ratio` DOUBLE,
    `Order Item Quantity` INT,
    Sales DOUBLE,
    `Order Item Total` DOUBLE,
    `Order Profit Per Order` DOUBLE,
    `Order Region` VARCHAR(100),
    `Order State` VARCHAR(100),
    `Order Status` VARCHAR(100),
    `Order Zipcode` VARCHAR(50),
    `Product Card Id` INT,
    `Product Category Id` INT,
    `Product Description` VARCHAR(255),
    `Product Image` VARCHAR(255),
    `Product Name` VARCHAR(255),
    `Product Price` DOUBLE,
    `Product Status` INT,
    `shipping date (DateOrders)` VARCHAR(100),
    `Shipping Mode` VARCHAR(100)
);

-- select * from raw_supply_chain;
-- 1. إيقاف فحص المفاتيح الخارجية مؤقتاً
SET FOREIGN_KEY_CHECKS = 0;

-- 2. مسح كل الجداول القديمة والجديدة بدون أي أخطاء
DROP TABLE IF EXISTS sales_facts, customers, products;

-- 3. إعادة تشغيل فحص المفاتيح الخارجية تاني عشان الحماية
SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- 2.Preprocessing
-- =====================================================================
-- إضافة عمود جديد للتاريخ
-- 1. إيقاف الحماية المؤقتة
SET SQL_SAFE_UPDATES = 0;

-- 2. إضافة عواميد التواريخ الجديدة
ALTER TABLE raw_supply_chain ADD COLUMN Order_Date DATETIME;
ALTER TABLE raw_supply_chain ADD COLUMN Shipping_Date DATETIME;

-- 3. تحويل التواريخ النصية لتواريخ حقيقية يفهمها الكمبيوتر
UPDATE raw_supply_chain 
SET Order_Date = STR_TO_DATE(`order date (DateOrders)`, '%m/%d/%Y %H:%i'),
    Shipping_Date = STR_TO_DATE(`shipping date (DateOrders)`, '%m/%d/%Y %H:%i');

-- =====================================================================
-- 3.Data Modeling
-- =====================================================================
-- ==========================================
-- 1. DIMENSION TABLES (جداول الأبعاد)
-- ==========================================

-- جدول العملاء
CREATE TABLE Dim_Customer AS
SELECT DISTINCT 
    `Customer Id` AS Customer_Key,
    `Customer Fname`, `Customer Lname`, `Customer Segment`, 
    `Customer City`, `Customer State`, `Customer Country`, `Customer Zipcode`, `Customer Street`
FROM raw_supply_chain;

-- جدول المنتجات
CREATE TABLE Dim_Product AS
SELECT DISTINCT 
    `Product Card Id` AS Product_Key,
    `Product Name`, `Product Price`, `Category Name`, `Department Id`, `Department Name`, `Product Category Id`
FROM raw_supply_chain;

-- جدول طرق الدفع (مع توليد Payment_Key)
CREATE TABLE Dim_Payment AS
SELECT 
    ROW_NUMBER() OVER(ORDER BY Type) AS Payment_Key,
    Type
FROM (SELECT DISTINCT Type FROM raw_supply_chain WHERE Type IS NOT NULL) t;

-- جدول حالة الشحن والتوصيل (مع توليد Fulfillment_Key)
CREATE TABLE Dim_Fulfillment_Status AS
SELECT 
    ROW_NUMBER() OVER(ORDER BY Shipping_Mode, Delivery_Status, Order_Status) AS Fulfillment_Key,
    Shipping_Mode, Delivery_Status, Order_Status
FROM (
    SELECT DISTINCT `Shipping Mode` AS Shipping_Mode, `Delivery Status` AS Delivery_Status, `Order Status` AS Order_Status 
    FROM raw_supply_chain
) t;

-- جدول الجغرافيا والمناطق (مع توليد Location_Key)
CREATE TABLE Dim_Order_Geography AS
SELECT 
    ROW_NUMBER() OVER(ORDER BY Order_Country, Order_City) AS Location_Key,
    Order_City, Order_Country, Order_Region, Order_State, Market, Latitude, Longitude
FROM (
    SELECT DISTINCT `Order City` AS Order_City, `Order Country` AS Order_Country, `Order Region` AS Order_Region, `Order State` AS Order_State, Market, Latitude, Longitude 
    FROM raw_supply_chain
) t;

-- جدول التواريخ (Dim_Order_Date)
CREATE TABLE Dim_Order_Date AS
SELECT DISTINCT
    DATE(Order_Date) AS Date,
    DAYNAME(Order_Date) AS Day_of_Week,
    MONTHNAME(Order_Date) AS Month_Name,
    MONTH(Order_Date) AS Month_Number,
    QUARTER(Order_Date) AS Quarter,
    YEAR(Order_Date) AS Year
FROM raw_supply_chain
WHERE Order_Date IS NOT NULL;


-- ==========================================
-- 2. FACT TABLES (جداول الحقائق)
-- ==========================================

-- جدول رأس الفاتورة (Fact_Order_Headers)
CREATE TABLE Fact_Order_Headers AS
SELECT DISTINCT
    r.`Order Id`,
    r.`Customer Id` AS Customer_Key,
    r.Order_Date,
    r.Shipping_Date,
    r.`Days for shipment (scheduled)`,
    r.`Days for shipping (real)`,
    (r.`Days for shipping (real)` - r.`Days for shipment (scheduled)`) AS Transit_Variance,
    r.Late_delivery_risk,
    p.Payment_Key,
    f.Fulfillment_Key,
    g.Location_Key
FROM raw_supply_chain r
LEFT JOIN Dim_Payment p ON r.Type = p.Type
LEFT JOIN Dim_Fulfillment_Status f 
    ON r.`Shipping Mode` = f.Shipping_Mode 
    AND r.`Delivery Status` = f.Delivery_Status 
    AND r.`Order Status` = f.Order_Status
LEFT JOIN Dim_Order_Geography g
    ON r.`Order City` = g.Order_City
    AND r.`Order Country` = g.Order_Country
    AND r.`Order Region` = g.Order_Region
    AND r.`Order State` = g.Order_State
    AND r.Market = g.Market
    AND r.Latitude = g.Latitude
    AND r.Longitude = g.Longitude;

-- جدول تفاصيل الفاتورة والمنتجات (Fact_Order_Line_Items)
CREATE TABLE Fact_Order_Line_Items AS
SELECT 
    `Order Item Id`,
    `Order Id`,
    `Product Card Id` AS Product_Key,
    `Order Item Quantity`,
    `Order Item Product Price`,
    `Order Item Discount`,
    `Order Item Discount Rate`,
    `Order Item Total`,
    `Order Profit Per Order`,
    `Order Item Profit Ratio`,
    Sales
FROM raw_supply_chain;
-- ====================================================================================
-- =========================================================
-- أولاً: تعريف المفاتيح الأساسية (PRIMARY KEYS) للجداول
-- =========================================================

-- 1. المفاتيح الأساسية لجداول الأبعاد (Dimensions)
ALTER TABLE Dim_Customer MODIFY Customer_Key INT PRIMARY KEY;
ALTER TABLE Dim_Product MODIFY Product_Key INT PRIMARY KEY;
ALTER TABLE Dim_Payment MODIFY Payment_Key INT PRIMARY KEY;
ALTER TABLE Dim_Fulfillment_Status MODIFY Fulfillment_Key INT PRIMARY KEY;
ALTER TABLE Dim_Order_Geography MODIFY Location_Key INT PRIMARY KEY;
ALTER TABLE Dim_Order_Date MODIFY Date DATE PRIMARY KEY;

-- 2. المفاتيح الأساسية لجداول الحقائق (Fact Tables)
ALTER TABLE Fact_Order_Headers MODIFY `Order Id` INT PRIMARY KEY;
ALTER TABLE Fact_Order_Line_Items MODIFY `Order Item Id` INT PRIMARY KEY;


-- =========================================================
-- ثانياً: تعريف العلاقات والمفاتيح الخارجية (FOREIGN KEYS)
-- =========================================================
-- 1. إيقاف الحماية مؤقتاً لضمان تنفيذ التعديل
SET SQL_SAFE_UPDATES = 0;

-- 2. توحيد أنواع البيانات (Data Types) في جدول الأبعاد وجدول الحقائق لضمان التطابق
ALTER TABLE Dim_Payment MODIFY Payment_Key INT;
ALTER TABLE Fact_Order_Headers MODIFY Payment_Key INT;

ALTER TABLE Dim_Fulfillment_Status MODIFY Fulfillment_Key INT;
ALTER TABLE Fact_Order_Headers MODIFY Fulfillment_Key INT;

ALTER TABLE Dim_Order_Geography MODIFY Location_Key INT;
ALTER TABLE Fact_Order_Headers MODIFY Location_Key INT;

ALTER TABLE Dim_Customer MODIFY Customer_Key INT;
ALTER TABLE Fact_Order_Headers MODIFY Customer_Key INT;

ALTER TABLE Dim_Product MODIFY Product_Key INT;
ALTER TABLE Fact_Order_Line_Items MODIFY Product_Key INT;

-- 4. تنفيذ الربط (FOREIGN KEYS) بعد التأكد من تطابق العواميد 100%
ALTER TABLE Fact_Order_Headers
ADD CONSTRAINT fk_header_customer 
    FOREIGN KEY (Customer_Key) REFERENCES Dim_Customer(Customer_Key),
ADD CONSTRAINT fk_header_payment 
    FOREIGN KEY (Payment_Key) REFERENCES Dim_Payment(Payment_Key),
ADD CONSTRAINT fk_header_fulfillment 
    FOREIGN KEY (Fulfillment_Key) REFERENCES Dim_Fulfillment_Status(Fulfillment_Key),
ADD CONSTRAINT fk_header_geography 
    FOREIGN KEY (Location_Key) REFERENCES Dim_Order_Geography(Location_Key),
ADD CONSTRAINT fk_header_date 
    FOREIGN KEY (Order_Date_Only) REFERENCES Dim_Order_Date(Date);

-- 5. ربط جدول تفاصيل الفاتورة
ALTER TABLE Fact_Order_Line_Items
ADD CONSTRAINT fk_line_order 
    FOREIGN KEY (`Order Id`) REFERENCES Fact_Order_Headers(`Order Id`),
ADD CONSTRAINT fk_line_product 
    FOREIGN KEY (Product_Key) REFERENCES Dim_Product(Product_Key);
-- ====================================================================================
-- 4: Insights
-- ==========================================
-- 1) OVERALL KPIs (مؤشرات الأداء الرئيسية)
SELECT 
    ROUND(SUM(Sales), 0) AS total_revenue,
    ROUND(SUM(`Order Profit Per Order`), 0) AS total_profit,
    ROUND(100.0 * SUM(`Order Profit Per Order`) / SUM(Sales), 2) AS margin_pct,
    COUNT(*) AS total_line_items
FROM Fact_Order_Line_Items;

-- 2) TOP 10 PRODUCTS BY REVENUE (أعلى 10 منتجات)
SELECT 
    p.`Product Name`,
    p.`Category Name`,
    ROUND(SUM(l.Sales), 0) AS revenue,
    ROUND(SUM(l.`Order Profit Per Order`), 0) AS profit,
    SUM(l.`Order Item Quantity`) AS units_sold
FROM Fact_Order_Line_Items l
JOIN Dim_Product p ON l.Product_Key = p.Product_Key
GROUP BY p.Product_Key, p.`Product Name`, p.`Category Name`
ORDER BY revenue DESC
LIMIT 10;

-- 3) CATEGORY PERFORMANCE (أداء الأقسام)
SELECT 
    p.`Category Name`,
    ROUND(SUM(l.Sales), 0) AS revenue,
    ROUND(SUM(l.`Order Profit Per Order`), 0) AS profit,
    ROUND(100.0 * SUM(l.`Order Profit Per Order`) / SUM(l.Sales), 2) AS margin_pct
FROM Fact_Order_Line_Items l
JOIN Dim_Product p ON l.Product_Key = p.Product_Key
GROUP BY p.`Category Name`
ORDER BY revenue DESC;

-- 4) WORST-MARGIN CATEGORIES (أسوأ الأقسام في الربحية)
SELECT 
    p.`Category Name`,
    ROUND(SUM(l.Sales), 0) AS revenue,
    ROUND(SUM(l.`Order Profit Per Order`), 0) AS profit,
    ROUND(100.0 * SUM(l.`Order Profit Per Order`) / SUM(l.Sales), 2) AS margin_pct
FROM Fact_Order_Line_Items l
JOIN Dim_Product p ON l.Product_Key = p.Product_Key
GROUP BY p.`Category Name`
ORDER BY margin_pct ASC
LIMIT 8;

-- 5) CUSTOMER SEGMENT PERFORMANCE (أداء فئات العملاء)
SELECT 
    c.`Customer Segment`,
    COUNT(DISTINCT h.Customer_Key) AS n_customers,
    ROUND(SUM(l.Sales), 0) AS total_revenue
FROM Fact_Order_Headers h
JOIN Fact_Order_Line_Items l ON h.`Order Id` = l.`Order Id`
JOIN Dim_Customer c ON h.Customer_Key = c.Customer_Key
GROUP BY c.`Customer Segment`
ORDER BY total_revenue DESC;

-- 6) TOP 10 CITIES BY REVENUE (أعلى 10 مدن)
SELECT 
    g.Order_City,
    g.Order_Country,
    ROUND(SUM(l.Sales), 0) AS total_revenue
FROM Fact_Order_Headers h
JOIN Fact_Order_Line_Items l ON h.`Order Id` = l.`Order Id`
JOIN Dim_Order_Geography g ON h.Location_Key = g.Location_Key
GROUP BY g.Order_City, g.Order_Country
ORDER BY total_revenue DESC
LIMIT 10;

-- 7) SHIPPING MODE ANALYSIS (تحليل طرق الشحن)
SELECT 
    f.Shipping_Mode,
    COUNT(h.`Order Id`) AS total_orders,
    ROUND(AVG(h.`Days for shipping (real)`), 2) AS avg_real_days,
    ROUND(SUM(l.Sales), 0) AS revenue
FROM Fact_Order_Headers h
JOIN Fact_Order_Line_Items l ON h.`Order Id` = l.`Order Id`
JOIN Dim_Fulfillment_Status f ON h.Fulfillment_Key = f.Fulfillment_Key
GROUP BY f.Shipping_Mode
ORDER BY revenue DESC;

-- 8) LATE DELIVERY RISK (مخاطر تأخير الشحن باستخدام التباين)
SELECT 
    Late_delivery_risk,
    COUNT(*) AS total_orders,
    ROUND(AVG(`Days for shipping (real)`), 2) AS avg_real_days,
    ROUND(AVG(`Days for shipment (scheduled)`), 2) AS avg_scheduled_days,
    ROUND(AVG(Transit_Variance), 2) AS avg_variance_days
FROM Fact_Order_Headers
GROUP BY Late_delivery_risk;

-- 9) MONTHLY REVENUE TREND (تريند المبيعات الشهري)
SELECT 
    DATE_FORMAT(h.Order_Date, '%Y-%m') AS order_month, 
    ROUND(SUM(l.Sales), 0) AS revenue, 
    COUNT(DISTINCT h.`Order Id`) AS n_orders 
FROM Fact_Order_Headers h
JOIN Fact_Order_Line_Items l ON h.`Order Id` = l.`Order Id`
WHERE h.Order_Date IS NOT NULL
GROUP BY order_month 
ORDER BY order_month;

-- 10) LOSS-MAKING LINE ITEMS (العمليات الخاسرة)
SELECT 
    p.`Category Name`,
    COUNT(l.`Order Item Id`) AS loss_making_items,
    ROUND(SUM(l.`Order Profit Per Order`), 0) AS total_loss
FROM Fact_Order_Line_Items l
JOIN Dim_Product p ON l.Product_Key = p.Product_Key
WHERE l.`Order Profit Per Order` < 0
GROUP BY p.`Category Name`
ORDER BY total_loss ASC
LIMIT 10;