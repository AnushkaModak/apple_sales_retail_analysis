# Apple Sales Data Analysis (SQL Project)
## 📌 Project Overview

This project analyzes Apple’s global sales dataset (1M+ rows) using PostgreSQL.
It covers the full pipeline of database schema creation, data loading, and advanced SQL queries to extract insights into sales, product lifecycle, warranty claims, and store performance.

The aim is to demonstrate how SQL can be used to:

Model and manage sales data efficiently

Answer complex business questions

Track KPIs like revenue, product performance, warranty trends

Segment and analyze sales by product lifecycle

### 🗂️ Database Schema

The project consists of 5 core tables:

Stores – Store details (ID, Name, City, Country)

Category – Product categories

Products – Apple products, linked with categories

Sales – Transaction-level sales records

Warranty – Warranty claims linked to sales

### 📌 ER Diagram

Stores ───< Sales >─── Products ───< Category  
   │                        │  
   └──────< Warranty >──────┘

### ⚙️ Technologies Used

PostgreSQL – Query execution & database management

SQL (DDL + DML + DQL) – Table creation, data manipulation, analysis

Window Functions – Ranking, segmentation, trend analysis

Date Functions – Time-based filtering & lifecycle analysis

### 🔑 Key SQL Queries & Use Cases
#### 🏬 Store-Level Insights

Number of stores in each country
```sql
SELECT COUNT(store_id), country 
FROM stores 
GROUP BY country;
```

Stores with no warranty claims
```sql
SELECT COUNT(DISTINCT store_id) 
FROM sales 
LEFT JOIN warranty 
ON sales.sale_id = warranty.sale_id 
WHERE warranty.sale_id IS NULL;
```
#### 📊 Sales Insights

Total sales in December 2023
```sql
SELECT SUM(quantity) AS no_of_sale 
FROM sales 
WHERE EXTRACT(YEAR FROM sale_date) = 2023 
  AND EXTRACT(MONTH FROM sale_date) = 12;
```

Best-selling day per store
```sql
SELECT * FROM (
  SELECT store_id,
         SUM(quantity),
         EXTRACT(DOW FROM sale_date) AS best_selling_day,
         RANK() OVER (PARTITION BY store_id ORDER BY SUM(quantity) DESC) AS rank
  FROM sales 
  GROUP BY store_id, EXTRACT(DOW FROM sale_date)
) sub 
WHERE rank = 1;
```
#### 📦 Product Insights

Unique products sold last year
```sql
SELECT COUNT(DISTINCT product_name) 
FROM products
JOIN sales ON products.product_id = sales.product_id
WHERE EXTRACT(YEAR FROM sales.sale_date) = (
  SELECT MAX(EXTRACT(YEAR FROM sale_date)) FROM sales
);
```

Average price of products per category
```sql
SELECT c.category_name, AVG(p.price) AS avg_price
FROM products p
JOIN category c ON p.category_id = c.category_id
GROUP BY c.category_name;
```
#### 🛠️ Warranty Insights

Warranty claims in 2020
```swl
SELECT COUNT(claim_id)
FROM warranty
WHERE EXTRACT(YEAR FROM claim_date) = 2020;
```

Warranty claims filed within 180 days of purchase
```sql
SELECT COUNT(*) 
FROM warranty w
JOIN sales s ON w.sale_id = s.sale_id
WHERE w.claim_date <= s.sale_date + INTERVAL '180 days';
```
#### 📈 Advanced Analytics

Product lifecycle sales segmentation
```sql
SELECT 
    p.product_id,
    p.product_name,
    CASE 
        WHEN (s.sale_date - p.launch_date) <= 180 THEN '0-6 months'
        WHEN (s.sale_date - p.launch_date) <= 365 THEN '6-12 months'
        WHEN (s.sale_date - p.launch_date) <= 545 THEN '12-18 months'
        ELSE '18+ months'
    END AS periods,
    SUM(s.quantity) AS total_units_sold,
    SUM(s.quantity * p.price) AS total_revenue
FROM products p
JOIN sales s ON p.product_id = s.product_id
GROUP BY p.product_id, p.product_name, periods
ORDER BY p.product_id, periods;
```
📊 Example Insights

Global Stores: Present across multiple countries

December 2023 Sales: High seasonal demand spike

Best-Selling Days: Weekends dominate sales

Warranty Claims: Significant claims filed within 180 days of purchase

Lifecycle Trends: Majority of revenue comes within first 12 months of launch

-  END -
