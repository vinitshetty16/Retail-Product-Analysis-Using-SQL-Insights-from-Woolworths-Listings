
-- Woolworths Retail Sales Analysis
-- SQL Portfolio Project by Vinit Shetty
-- ----------------------------------------------------
-- This file contains 9 SQL queries used to analyze a Woolworthsmretail dataset.

-- 1. Product Count and Price Range by Category
-- Objective: Understand product variety and price trends per category
SELECT 
  [WOW_Category] AS Category,
  COUNT(*) AS Total_Products,
  ROUND(AVG([WOW_Price]), 2) AS Avg_Price_AUD,
  ROUND(MIN([WOW_Price]), 2) AS Min_Price_AUD,
  ROUND(MAX([WOW_Price]), 2) AS Max_Price_AUD
FROM [Woolworths].[dbo].[Woolworths]
WHERE [WOW_Category] IS NOT NULL
GROUP BY [WOW_Category]
ORDER BY Total_Products DESC;

-- 2. Top 5 Most Expensive Products by Category
-- Objective: Identify high-ticket items in each category
SELECT 
  [WOW_Category] AS Category,
  [Product_Name],
  [Brand],
  [WOW_Price] AS Price_AUD,
  [WOW_Size],
  [WOW_ppu] AS Price_Per_Unit,
  [Product_URL]
FROM (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY [WOW_Category] ORDER BY [WOW_Price] DESC) AS price_rank
  FROM [Woolworths].[dbo].[Woolworths]
  WHERE 
    [WOW_Category] IS NOT NULL AND 
    [WOW_Price] IS NOT NULL AND
    [Brand] IS NOT NULL AND
    [WOW_Size] IS NOT NULL AND
	[WOW_ppu] IS NOT NULL

) ranked
WHERE price_rank <= 5
ORDER BY Category, Price_AUD DESC;

-- 3. Products Without Price Per Unit (PPU)
-- Objective: Spot missing unit-level pricing to ensure data completeness

SELECT 
  [SKU], 
  [Brand_Product_Size], 
  [WOW_Price]
FROM [Woolworths].[dbo].[Woolworths]
WHERE [WOW_ppu] IS NULL OR [WOW_ppu] = '';

-- 4. Analyze Online-Only vs In-Store Products
-- Objective: Segment products by availability channel
SELECT 
  CASE 
    WHEN [Online_Only] = 'Yes' THEN 'Online Only'
    WHEN [Online_Only] IS NULL OR [Online_Only] = '' THEN 'In Store or Both'
    ELSE [Online_Only]  -- captures any edge case
  END AS Availability,
  COUNT(*) AS Product_Count
FROM [Woolworths].[dbo].[Woolworths]
GROUP BY 
  CASE 
    WHEN [Online_Only] = 'Yes' THEN 'Online Only'
    WHEN [Online_Only] IS NULL OR [Online_Only] = '' THEN 'In Store or Both'
    ELSE [Online_Only]
  END;

-- 5. Price Comparison: New vs Existing Products
-- Objective: Compare average prices of new and existing products
SELECT 
  ISNULL([New_Product], 'Existing') AS New_Product,
  COUNT(*) AS Product_Count,
  ROUND(AVG([WOW_Price]), 2) AS Avg_Price
FROM [Woolworths].[dbo].[Woolworths]
WHERE [WOW_Price] IS NOT NULL
GROUP BY ISNULL([New_Product], 'Existing');

-- 6. Identify Duplicate Products by Brand and Name
-- Objective: Detect duplicate entries with same brand and product name
SELECT 
  [Brand], 
  [Product_Name], 
  COUNT(*) AS Duplicate_Count
FROM [Woolworths].[dbo].[Woolworths]
GROUP BY [Brand], [Product_Name]
HAVING COUNT(*) > 1
ORDER BY Duplicate_Count DESC;

-- 7. Revenue Analysis by Category (Join with Sales Table)
-- Objective: Measure total revenue and units sold per category
SELECT 
  p.WOW_Category AS Category,
  COUNT(DISTINCT p.SKU) AS Unique_Products,
  SUM(s.Units_Sold) AS Total_Units_Sold,
  ROUND(SUM(p.WOW_Price * s.Units_Sold), 2) AS Total_Revenue_AUD,
  ROUND(AVG(p.WOW_Price), 2) AS Avg_Price_AUD,
  ROUND(SUM(p.WOW_Price * s.Units_Sold) * 100.0 / 
        SUM(SUM(p.WOW_Price * s.Units_Sold)) OVER (), 2) AS Revenue_Share_Percent
FROM [Woolworths].[dbo].[Woolworths] p
JOIN [Woolworths].[dbo].[Woolworths_Sales_Data] s ON p.SKU = s.SKU
WHERE p.WOW_Price IS NOT NULL AND p.WOW_Category IS NOT NULL
GROUP BY p.WOW_Category
ORDER BY Total_Revenue_AUD DESC;

-- 8. Top 10 Best-Selling Products by Revenue
-- Objective: Identify highest earning products
SELECT TOP 10
  p.Product_Name,
  p.Brand,
  p.WOW_Category AS Category,
  p.WOW_Price AS Unit_Price,
  s.Units_Sold,
  ROUND(p.WOW_Price * s.Units_Sold, 2) AS Revenue_AUD
FROM [Woolworths].[dbo].[Woolworths] p
JOIN [Woolworths].[dbo].[Woolworths_Sales_Data] s ON p.SKU = s.SKU
WHERE p.WOW_Price IS NOT NULL
ORDER BY Revenue_AUD DESC;

-- 9. Conversion Rate: Views vs Sales
-- Objective: Measure product effectiveness by view-to-sale ratio
SELECT 
  p.SKU,
  p.Product_Name,
  p.Brand,
  p.WOW_Category AS Category,
  p.WOW_Price AS Unit_Price,
  s.Views,
  s.Units_Sold,
  ROUND(CAST(s.Units_Sold AS FLOAT) / NULLIF(s.Views, 0), 2) AS Conversion_Rate
FROM [Woolworths].[dbo].[Woolworths] p
JOIN [Woolworths].[dbo].[Woolworths_Sales_Data] s ON p.SKU = s.SKU
WHERE s.Views IS NOT NULL AND s.Views > 0 AND s.Units_Sold > 0
ORDER BY Conversion_Rate DESC;
