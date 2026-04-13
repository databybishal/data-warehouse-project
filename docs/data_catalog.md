# 📊 Data Catalog – Gold Layer

This document describes the structure of the **Gold Layer** in the data warehouse. It includes dimension and fact tables used for analytics and reporting.

---

## 🧑‍💼 Table: `gold.dim_customers`

### Description

Stores customer-related attributes for analytical purposes.

### Columns

| Column Name     | Data Type    | Description                 |
| --------------- | ------------ | --------------------------- |
| customer_key    | bigint       | Surrogate key (Primary Key) |
| customer_id     | int          | Source system customer ID   |
| customer_number | nvarchar(50) | Unique customer number      |
| first_name      | nvarchar(50) | Customer first name         |
| last_name       | nvarchar(50) | Customer last name          |
| country         | nvarchar(50) | Customer country            |
| marital_status  | nvarchar(50) | Marital status              |
| gender          | nvarchar(50) | Gender                      |
| birthdate       | date         | Date of birth               |
| create_date     | date         | Record creation date        |

---

## 📦 Table: `gold.dim_products`

### Description

Stores product-related attributes for reporting and categorization.

### Columns

| Column Name    | Data Type    | Description                     |
| -------------- | ------------ | ------------------------------- |
| product_key    | bigint       | Surrogate key (Primary Key)     |
| product_id     | int          | Source system product ID        |
| product_number | nvarchar(50) | Unique product number           |
| product_name   | nvarchar(50) | Name of the product             |
| category_id    | nvarchar(50) | Category identifier             |
| category       | nvarchar(50) | Product category                |
| subcategory    | nvarchar(50) | Product subcategory             |
| maintenance    | nvarchar(50) | Maintenance info                |
| cost           | int          | Cost of product                 |
| product_line   | nvarchar(50) | Product line                    |
| start_date     | date         | Product availability start date |

---

## 💰 Table: `gold.fact_sales`

### Description

Stores transactional sales data and links to dimension tables.

### Columns

| Column Name   | Data Type    | Description                  |
| ------------- | ------------ | ---------------------------- |
| order_number  | nvarchar(50) | Order identifier             |
| product_key   | bigint       | Foreign key to dim_products  |
| customer_key  | bigint       | Foreign key to dim_customers |
| order_date    | date         | Date of order                |
| shipping_date | date         | Date of shipment             |
| due_date      | date         | Due date for delivery        |
| sales_amount  | int          | Total sales amount           |
| quantity      | int          | Quantity sold                |
| price         | int          | Price per unit               |

---

## 🔗 Relationships

- `fact_sales.customer_key` → `dim_customers.customer_key`
- `fact_sales.product_key` → `dim_products.product_key`

---

## 📌 Notes

- All dimension tables use **surrogate keys** for better performance and flexibility.
- Fact table stores measurable metrics (sales, quantity, price).
- Designed using a **star schema** for analytical queries.

---

## ✅ Usage Examples

### Total Sales by Country

```sql
SELECT c.country, SUM(f.sales_amount) AS total_sales
FROM gold.fact_sales f
JOIN gold.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.country;
```

### Top Products by Revenue

```sql
SELECT p.product_name, SUM(f.sales_amount) AS revenue
FROM gold.fact_sales f
JOIN gold.dim_products p ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY revenue DESC;
```

---

🚀 This catalog helps analysts and engineers understand and use the Gold Layer efficiently.
