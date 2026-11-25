
CREATE TABLE customers (
    customerid VARCHAR(10) PRIMARY KEY,
    companyname VARCHAR(100),
    contactname VARCHAR(100),
    contacttitle VARCHAR(100),
    city VARCHAR(50),
    country VARCHAR(50)
);

CREATE TABLE employees (
    employeeid INT PRIMARY KEY,
    employeename VARCHAR(100),
    title VARCHAR(100),
    city VARCHAR(50),
    country VARCHAR(50),
    reportsto INT
);

CREATE TABLE shippers (
    shipperid INT PRIMARY KEY,
    companyname VARCHAR(100)
);

CREATE TABLE categories (
    categoryid INT PRIMARY KEY,
    categoryname VARCHAR(100),
    description TEXT
);

CREATE TABLE products (
    productid INT PRIMARY KEY,
    productname VARCHAR(100),
    quantityperunit VARCHAR(100),
    unitprice NUMERIC(10,2),
    discontinued INT,
    categoryid INT REFERENCES categories(categoryid)
);

CREATE TABLE orders (
    orderid INT PRIMARY KEY,
    customerid VARCHAR(10) REFERENCES customers(customerid),
    employeeid INT REFERENCES employees(employeeid),
    orderdate DATE,
    requireddate DATE,
    shippeddate DATE,
    shipperid INT REFERENCES shippers(shipperid),
    freight NUMERIC(10,2)
);

CREATE TABLE order_details (
    orderid INT REFERENCES orders(orderid),
    productid INT REFERENCES products(productid),
    unitprice NUMERIC(10,2),
    quantity INT,
    discount NUMERIC(5,4),
    PRIMARY KEY (orderid, productid)
);


SELECT 'customers' AS table_name, COUNT(*) FROM customers
UNION ALL
SELECT 'employees', COUNT(*) FROM employees
UNION ALL
SELECT 'shippers', COUNT(*) FROM shippers
UNION ALL
SELECT 'categories', COUNT(*) FROM categories
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_details', COUNT(*) FROM order_details;


SELECT
    COUNT(*) AS total_orders,
    COUNT(customerid) AS orders_with_customer,
    COUNT(employeeid) AS orders_with_employee,
    COUNT(orderdate) AS orders_with_date
FROM orders;

SELECT
    orderid,
    COUNT(*) AS duplicate_count
FROM orders
GROUP BY orderid
HAVING COUNT(*) > 1;

SELECT *
FROM products
WHERE unitprice < 0
   OR unitprice IS NULL;


   SELECT *
FROM order_details
WHERE quantity <= 0
   OR unitprice < 0
   OR discount < 0
   OR discount > 1;


   SELECT
    ROUND(
        SUM(unitprice * quantity * (1 - discount)),
        2
    ) AS total_revenue
FROM order_details;


SELECT
    COUNT(DISTINCT orderid) AS total_orders,
    SUM(quantity) AS total_units_sold,
    ROUND(
        SUM(unitprice * quantity * (1-discount)), 2
    ) AS total_revenue,
    ROUND(
        SUM(unitprice * quantity * (1-discount))
        / COUNT(DISTINCT orderid), 2
    ) AS average_order_value
FROM order_details;



~Monthly sales analysis
SELECT
    TO_CHAR(o.orderdate, 'YYYY-MM') AS sales_month,
    COUNT(DISTINCT o.orderid) AS total_orders,
    ROUND(
        SUM(od.unitprice * od.quantity * (1-od.discount)), 2
    ) AS monthly_revenue
FROM orders o
JOIN order_details od
    ON o.orderid = od.orderid
GROUP BY TO_CHAR(o.orderdate, 'YYYY-MM')
ORDER BY monthly_revenue DESC;




SELECT
    c.customerid,
    c.companyname,
    COUNT(DISTINCT o.orderid) AS total_orders,
    ROUND(
        SUM(od.unitprice * od.quantity * (1-od.discount)), 2
    ) AS total_revenue
FROM customers c
JOIN orders o
    ON c.customerid = o.customerid
JOIN order_details od
    ON o.orderid = od.orderid
GROUP BY c.customerid, c.companyname
ORDER BY total_revenue DESC
LIMIT 10;



SELECT
    c.categoryname,
    COUNT(DISTINCT p.productid) AS total_products,
    SUM(od.quantity) AS units_sold,
    ROUND(
        SUM(od.unitprice * od.quantity * (1-od.discount)), 2
    ) AS category_revenue
FROM categories c
JOIN products p
    ON c.categoryid = p.categoryid
JOIN order_details od
    ON p.productid = od.productid
GROUP BY c.categoryname
ORDER BY category_revenue DESC;



~Top 10 Prdocucts
SELECT
    p.productname,
    SUM(od.quantity) AS units_sold,
    ROUND(
        SUM(od.unitprice * od.quantity * (1-od.discount)), 2
    ) AS total_revenue
FROM products p
JOIN order_details od
    ON p.productid = od.productid
GROUP BY p.productid, p.productname
ORDER BY total_revenue DESC
LIMIT 10;


WITH customer_sales AS (
    SELECT
        c.customerid,
        c.companyname,
        SUM(od.unitprice * od.quantity * (1-od.discount))
            AS total_revenue
    FROM customers c
    JOIN orders o
        ON c.customerid = o.customerid
    JOIN order_details od
        ON o.orderid = od.orderid
    GROUP BY c.customerid, c.companyname
)
SELECT *
FROM customer_sales
ORDER BY total_revenue DESC;




SELECT
    productname,
    unitprice
FROM products
WHERE unitprice > (
    SELECT AVG(unitprice)
    FROM products
)
ORDER BY unitprice DESC;


SELECT
    c.customerid,
    c.companyname,
    ROUND(
        SUM(od.unitprice * od.quantity * (1-od.discount)), 2
    ) AS revenue,
    RANK() OVER (
        ORDER BY SUM(od.unitprice * od.quantity * (1-od.discount)) DESC
    ) AS customer_rank
FROM customers c
JOIN orders o
    ON c.customerid = o.customerid
JOIN order_details od
    ON o.orderid = od.orderid
GROUP BY c.customerid, c.companyname;


WITH employee_sales AS (
    SELECT
        e.employeeid,
        e.employeename,
        COUNT(DISTINCT o.orderid) AS total_orders,
        SUM(od.unitprice * od.quantity * (1-od.discount))
            AS total_revenue
    FROM employees e
    JOIN orders o
        ON e.employeeid = o.employeeid
    JOIN order_details od
        ON o.orderid = od.orderid
    GROUP BY e.employeeid, e.employeename
)
SELECT
    *,
    DENSE_RANK() OVER (
        ORDER BY total_revenue DESC
    ) AS performance_rank
FROM employee_sales
ORDER BY performance_rank;



BEGIN;

UPDATE products
SET unitprice = unitprice * 1.05
WHERE productid = 1;

-- Check the updated value
SELECT productid, productname, unitprice
FROM products
WHERE productid = 1;

-- Undo the change
ROLLBACK;


SELECT
    TO_CHAR(o.orderdate, 'YYYY-MM') AS sales_month,
    COUNT(DISTINCT o.orderid) AS total_orders,
    ROUND(
        SUM(od.unitprice * od.quantity * (1-od.discount)), 2
    ) AS monthly_revenue
FROM orders o
JOIN order_details od
    ON o.orderid = od.orderid
GROUP BY DATE_TRUNC('month', o.orderdate),
         TO_CHAR(o.orderdate, 'YYYY-MM')
ORDER BY DATE_TRUNC('month', o.orderdate);



SELECT
    c.categoryname,
    COUNT(DISTINCT p.productid) AS total_products,
    SUM(od.quantity) AS units_sold,
    ROUND(
        SUM(
            od.unitprice * od.quantity * (1-od.discount)
        ), 2
    ) AS category_revenue
FROM categories c
JOIN products p
    ON c.categoryid = p.categoryid
JOIN order_details od
    ON p.productid = od.productid
GROUP BY c.categoryid, c.categoryname
ORDER BY category_revenue DESC;


SELECT
    p.productname,
    c.categoryname,
    SUM(od.quantity) AS units_sold,
    ROUND(
        SUM(od.unitprice * od.quantity * (1-od.discount)), 2
    ) AS total_revenue
FROM products p
JOIN categories c
    ON p.categoryid = c.categoryid
JOIN order_details od
    ON p.productid = od.productid
GROUP BY p.productid, p.productname, c.categoryname
ORDER BY total_revenue DESC
LIMIT 10;


SELECT
    c.customerid,
    c.companyname,
    COUNT(DISTINCT o.orderid) AS total_orders,
    SUM(od.quantity) AS total_units,
    ROUND(
        SUM(od.unitprice * od.quantity * (1-od.discount)), 2
    ) AS total_revenue
FROM customers c
JOIN orders o
    ON c.customerid = o.customerid
JOIN order_details od
    ON o.orderid = od.orderid
GROUP BY c.customerid, c.companyname
ORDER BY total_revenue DESC
LIMIT 10;

SELECT
    e.employeeid,
    e.employeename,
    COUNT(DISTINCT o.orderid) AS total_orders,
    ROUND(
        SUM(od.unitprice * od.quantity * (1-od.discount)), 2
    ) AS total_revenue
FROM employees e
JOIN orders o
    ON e.employeeid = o.employeeid
JOIN order_details od
    ON o.orderid = od.orderid
GROUP BY e.employeeid, e.employeename
ORDER BY total_revenue DESC;
