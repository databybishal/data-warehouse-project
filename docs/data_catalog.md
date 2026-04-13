# DATA DICTIONARY OF GOLD LAYER

## Overview

The Gold Layer represents the final, business-ready layer of the data warehouse. It is designed using a star schema to support analytical queries, reporting, and decision-making. This layer contains curated dimension and fact tables with cleaned, standardized, and enriched data.

---

## Table: `gold.dim_customers`

### Description

The `dim_customers` table stores descriptive attributes related to customers. It is a dimension table used to provide context for sales transactions and enables slicing and dicing of data based on customer demographics and attributes.

### Columns

| Column Name     | Data Type    | Description                                                                       |
| --------------- | ------------ | --------------------------------------------------------------------------------- |
| customer_key    | bigint       | Surrogate primary key uniquely identifying each customer record in the warehouse. |
| customer_id     | int          | Original customer identifier from the source system.                              |
| customer_number | nvarchar(50) | Business-defined unique customer reference number.                                |
| first_name      | nvarchar(50) | Customer's given name.                                                            |
| last_name       | nvarchar(50) | Customer's family name.                                                           |
| country         | nvarchar(50) | Country of residence of the customer, used for geographical analysis.             |
| marital_status  | nvarchar(50) | Indicates the marital status of the customer for demographic segmentation.        |
| gender          | nvarchar(50) | Gender of the customer, used for analytical categorization.                       |
| birthdate       | date         | Customer's date of birth, used to derive age-based insights.                      |
| create_date     | date         | Date when the customer record was created in the system.                          |

---

## Table: `gold.dim_products`

### Description

The `dim_products` table contains detailed information about products. It enables categorization and analysis of sales data across different product hierarchies such as category and subcategory.

### Columns

| Column Name    | Data Type    | Description                                                          |
| -------------- | ------------ | -------------------------------------------------------------------- |
| product_key    | bigint       | Surrogate primary key uniquely identifying each product record.      |
| product_id     | int          | Source system identifier for the product.                            |
| product_number | nvarchar(50) | Unique product reference code used in business operations.           |
| product_name   | nvarchar(50) | Descriptive name of the product.                                     |
| category_id    | nvarchar(50) | Identifier representing the product category from the source system. |
| category       | nvarchar(50) | High-level classification of the product.                            |
| subcategory    | nvarchar(50) | More granular classification within a category.                      |
| maintenance    | nvarchar(50) | Indicates maintenance requirements or classification of the product. |
| cost           | int          | Cost incurred to produce or procure the product.                     |
| product_line   | nvarchar(50) | Product line grouping used for business segmentation.                |
| start_date     | date         | Date from which the product became available for sale.               |

---

## Table: `gold.fact_sales`

### Description

The `fact_sales` table is a fact table that captures transactional sales data. It records measurable business events and links to dimension tables to provide context for analysis.

### Columns

| Column Name   | Data Type    | Description                                         |
| ------------- | ------------ | --------------------------------------------------- |
| order_number  | nvarchar(50) | Unique identifier for each sales order transaction. |
| product_key   | bigint       | Foreign key referencing the `dim_products` table.   |
| customer_key  | bigint       | Foreign key referencing the `dim_customers` table.  |
| order_date    | date         | Date when the order was placed.                     |
| shipping_date | date         | Date when the order was shipped to the customer.    |
| due_date      | date         | Expected delivery or due date for the order.        |
| sales_amount  | int          | Total revenue generated from the transaction.       |
| quantity      | int          | Number of units sold in the transaction.            |
| price         | int          | Unit price of the product at the time of sale.      |

---

## Relationships

* `fact_sales.customer_key` references `dim_customers.customer_key`
* `fact_sales.product_key` references `dim_products.product_key`

These relationships form a star schema, enabling efficient joins between fact and dimension tables for analytical queries.

---

## Notes

* Surrogate keys are used in dimension tables to ensure consistency and improve join performance.
* The fact table stores quantitative measures, while dimension tables provide descriptive context.
* Data in the Gold Layer is fully transformed, validated, and optimized for reporting and business intelligence tools.

---

## Usage Examples

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

This document serves as a formal data dictionary for the Gold Layer, providing clear definitions and context for all tables and columns used in analytical workloads.
