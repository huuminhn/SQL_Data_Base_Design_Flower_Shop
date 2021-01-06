/* These are the queries used according to the demand of the flower shop */
USE mm_cpsc5910team03;

/* Find the customer buying the most expensive combo in a single time. */
SELECT 
	c.cust_id AS 'CustomerID',
CONCAT(c.f_name, ' ', c.l_name) AS 'Customer Name', 
    	o.total_price AS 'Product of Highest Price'
 FROM 
	cust_info c, 
	order_info o
 WHERE c.cust_id = o.cust_id
	    AND o.total_price = (
			SELECT 
				MAX(o.total_price) 
			FROM 
				order_info o);


/* Show all people who received the flowers instead of the customers. */
SELECT 
	CONCAT(c.f_name, ' ', c.l_name) AS 'Customer Name', 
	CONCAT(s.recipient_f_name, ' ', s.recipient_l_name) AS 'Recipient Name', 
	s.est_arrive_time AS 'Estimated Arrival Time'
FROM 
	cust_info c, 
	order_info o, 
	shipping s
WHERE s.ship_id = o.ship_id
	 AND o.cust_id = c.cust_id
	 AND c.f_name != s. recipient_f_name
	 AND c.l_name != s.recipient_l_name
     	AND s.est_arrive_time > 0;

/* Show all next-day delivery orders. */
SELECT 
	CONCAT(c.f_name, ' ', c.l_name) AS 'Customer Name',
	o.order_id AS 'Order ID', 
	c.last_order_time AS 'Last order time', 
	s.est_arrive_time AS 'Estimated Arrival Time' 
FROM 
	cust_info c, 
	order_info o, 
	shipping s
WHERE c.cust_id = o.cust_id
	And o.ship_id = s.ship_id
	And YEAR(c.last_order_time) = YEAR(s.est_arrive_time)
	AND MONTH(c.last_order_time) = MONTH(s.est_arrive_time)
	AND DAY(c.last_order_time) +1 = DAY(s.est_arrive_time); 

/* Overview of total sales amount for each year */
CREATE VIEW SalesYearComparison AS
SELECT 
	YEAR(o.order_date) AS 'Sales Year', 
	SUM(d.price_after_disc) AS 'Current Sales Amount', 
	SUM(d.sale_price) AS 'Sales Amount Before Discount',
	LEAD(sum(d.price_after_disc), 1, NULL) 
	OVER (order by o.order_date) AS 'Next Year Sales Amount',
	LEAD(sum(d.sale_price), 1, NULL) 
	OVER (order by o.order_date) AS 'Next Year Sales Amount Before Discount'
FROM 
	order_info o, 
	order_detail d
WHERE o.order_id = d.order_id
GROUP BY YEAR(o.order_date);
 
SELECT * FROM SalesYearComparison;

/* Show the age group with the most popular product. */
SELECT 
p.product_name AS 'Product Name', 
COUNT(d.product_id) AS 'Product Quantity',
CONCAT(TRUNCATE(YEAR(CURDATE()) - YEAR(c.dob), -1), 
		'-',
	   TRUNCATE(YEAR(CURDATE()) - YEAR(c.dob),-1)+9) AS 'Age Group',

CASE 
WHEN p.category = 'Event' THEN 'Event Service'
		ELSE 'In-Home Delivery'
END AS 'Product Category'

FROM 
cust_info c, 
order_detail d, 
product p
WHERE c.cust_id = d.cust_id 
	AND d.product_id = p.product_id
GROUP BY d.product_id, 'Age Group'
ORDER BY 'Product Quantity';

/* Show the manager who has the highest review score. */
SELECT e.manager_id AS 'Manager ID', 
	CONCAT(e.f_name, ' ', e.l_name) AS 'Manager Name', 
    	e.specialty AS 'Specialty', 
    	ROUND(AVG(r.score),1) AS 'Average Review Score',
        COUNT(r.score) AS 'Number of Reviews'
FROM
event_manager e, 
cust_review r, 
event_service s, 
order_info o,
 cust_info c
WHERE e.manager_id = s.manager_id 
	AND s.service_id = o.service_id 
	AND o.cust_id = c.cust_id 
    	AND c.cust_id = r.cust_id 
    	AND o.order_type = 'event service' 
   	 AND o.order_status = 'Completed'
GROUP BY e.manager_id
ORDER BY AVG(r.score) DESC LIMIT 1;

/* Find the lowest price of each product and the corresponding supplier? */
SELECT DISTINCT 
w.product_id,
(SELECT 
product_name 
FROM 
product p 
WHERE p.product_id = w.product_id ) AS 'Product Name',
MIN(w.warehousing_price) AS 'Min Price Of Product',
s.supplier_name AS 'Supplier Name'
FROM
 warehousing AS w
JOIN supplier AS s ON w.supplier_id = s.supplier_id
GROUP BY product_id;

/* How much of each product do we have in our warehouse?*/
SELECT DISTINCT 
product_id AS 'Product ID',
(SELECT 
product_name 
FROM
product p 
WHERE p.product_id = w.product_id ) AS 'Product Name',
SUM(warehousing_amt) AS Amount
FROM
warehousing as w
GROUP BY product_id
ORDER BY SUM(warehousing_amt) DESC;

/* How many suppliers do we have per product? */
SELECT 
	product_id AS 'Product ID',
		(SELECT 
		product_name 
		FROM
		product p
		WHERE p.product_id = w.product_id ) AS 'Product Name',
	COUNT(*) AS 'Number of Suppliers per product'
FROM 
	warehousing as w
GROUP BY product_id;

/* How many members joined our website per year? */ 
SELECT 
	YEAR(mem_since) AS YEAR,
	COUNT(*) AS 'Num of Member Joined Per Year'
FROM 
	cust_info
GROUP BY YEAR(mem_since)
ORDER BY COUNT(*) DESC;

/* Stroed Procedure 1*/
DELIMITER $$
CREATE PROCEDURE ProductSalesByYearMonth
		(IN ProductName Varchar(60), 
         		 IN SalesYear INT,
         		 IN SalesMonth INT)
BEGIN
SELECT 
	p.product_id AS 'Product ID',
	p.product_name AS 'Product Name',
	p.category AS 'Category',
	YEAR(o.order_date) AS 'Sales Year',
	MONTH(o.order_date) AS 'Sales Month',
	o.order_type AS 'Order Type',
	sum((o.total_price + s.shippment_fee)) AS 'Total Sales Amount'
FROM
	product p, 
	order_info o, 
	shipment_fee s,
	order_detail d
WHERE
	p.product_id = d.product_id
	AND o.order_id = d.order_id
	AND o.shipment_fee_id = s.shipment_fee_id
	AND p.product_name = ProductName
	AND YEAR(o.order_date) = SalesYear
	AND MONTH(o.order_date) = SalesMonth
GROUP BY d.product_id;
END$$
DELIMITER ;

/* Test trial for getting sales amount for Rose in Feb 2020*/
CALL ProductSalesByYearMonth('Rose', 2020, 02);

/*Stored Procedure 2*/
DELIMITER $$
CREATE PROCEDURE FindCustomerInfo
		(IN ID int)
BEGIN
SELECT 
	c.cust_id AS 'Customer ID',
	CONCAT(c.f_name, ' ', c.l_name) AS 'Customer Name',
	COUNT(*) AS 'Total Order Number'
FROM 
	cust_info c, 
	order_info o 
WHERE 
	c.cust_id = o.cust_id
	And o.cust_id = ID
GROUP BY c.cust_id;
END$$
DELIMITER ;

/*Test trial for getting total shipping fee for cust_id = 1*/
CALL FindCustomerInfo(1);
