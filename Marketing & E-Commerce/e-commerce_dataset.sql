SELECT * FROM ecommerce_events;

ALTER TABLE ecommerce_events
RENAME COLUMN timestamp TO date_and_time;

ALTER TABLE ecommerce_events
ALTER COLUMN date_and_time TYPE TIMESTAMP USING date_and_time::TIMESTAMP;

SELECT TO_CHAR(date_and_time, 'FMMonth FMDD, YYYY'), customer_id, session_id
FROM ecommerce_events
LIMIT 1000;
 
SELECT TO_CHAR(date_and_time, 'Month') AS month_sales, COUNT(*)
FROM ecommerce_events
GROUP BY month_sales, EXTRACT(MONTH FROM date_and_time)
ORDER BY EXTRACT(MONTH FROM date_and_time);

SELECT TO_CHAR(date_and_time, 'YYYY')::INT AS year_sales, COUNT(*)
FROM ecommerce_events
GROUP BY year_sales;

SELECT DISTINCT traffic_source 
FROM ecommerce_events;

SELECT device_type, COUNT(*)
FROM ecommerce_events
GROUP BY device_type;

SELECT * FROM ecommerce_events
WHERE device_type IS NULL;

SELECT * FROM ecommerce_events
WHERE product_id IS NULL AND event_type!='bounce';

SELECT event_type, COUNT(*)
FROM ecommerce_events
WHERE product_id IS NULL
GROUP BY event_type;

SELECT page_category, COUNT(*)
FROM ecommerce_events
GROUP BY page_category;

DELETE FROM ecommerce_events
WHERE device_type IS NULL;

DELETE FROM ecommerce_events
WHERE product_id IS NULL AND event_type!='bounce';

UPDATE ecommerce_events
SET traffic_source=UPPER(LEFT(traffic_source, 1)) || 
LOWER(RIGHT(traffic_source, LENGTH(traffic_source)-1));

UPDATE ecommerce_events
SET product_id=0
WHERE product_id IS NULL;

SELECT * FROM ecommerce_events
LIMIT 1000;

CREATE OR REPLACE VIEW events_and_products AS
SELECT e.*,
p.category, p.brand, p.base_price, p.is_premium
FROM ecommerce_events AS e
JOIN products AS p USING (product_id);

SELECT * FROM events_and_products;

SELECT device_type, COUNT(CASE WHEN event_type='view' THEN 1 END) AS count_view,
COUNT(CASE WHEN event_type='add_to_cart' THEN 1 END) AS count_add_to_cart,
COUNT(CASE WHEN event_type='purchase' THEN 1 END) AS count_purchase,
COUNT(*) AS total_count
FROM ecommerce_events
GROUP BY device_type;

SELECT category,
COUNT(CASE WHEN traffic_source='Direct' THEN 1 END) AS direct,
COUNT(CASE WHEN traffic_source='Email' THEN 1 END) AS email,
COUNT(CASE WHEN traffic_source='Organic' THEN 1 END) AS organic,
COUNT(CASE WHEN traffic_source='Paid search' THEN 1 END) AS paid_search,
COUNT(CASE WHEN traffic_source='Social' THEN 1 END) AS social,
COUNT(*) AS total_count
FROM events_and_products
GROUP BY category;

SELECT page_category, COUNT(*)
FROM ecommerce_events
WHERE event_type='bounce'
GROUP BY page_category;

SELECT category,
COUNT(CASE WHEN TO_CHAR(date_and_time, 'FMDay')='Monday' THEN 1 END) as monday,
COUNT(CASE WHEN TO_CHAR(date_and_time, 'FMDay')='Tuesday' THEN 1 END) as tuesday,
COUNT(CASE WHEN TO_CHAR(date_and_time, 'FMDay')='Wednesday' THEN 1 END) as wednesday,
COUNT(CASE WHEN TO_CHAR(date_and_time, 'FMDay')='Thursday' THEN 1 END) as thurday,
COUNT(CASE WHEN TO_CHAR(date_and_time, 'FMDay')='Friday' THEN 1 END) as friday,
COUNT(CASE WHEN TO_CHAR(date_and_time, 'FMDay')='Saturday' THEN 1 END) as saturday,
COUNT(CASE WHEN TO_CHAR(date_and_time, 'FMDay')='Sunday' THEN 1 END) as sunday,
COUNT(*) as total
FROM events_and_products
GROUP BY category;

SELECT category,
COUNT(CASE WHEN date_and_time::TIME BETWEEN '00:00:00' AND '05:59:59' THEN 1 END) AS night,
COUNT(CASE WHEN date_and_time::TIME BETWEEN '06:00:00' AND '11:59:59' THEN 1 END) AS morning,
COUNT(CASE WHEN date_and_time::TIME BETWEEN '12:00:00' AND '17:59:59' THEN 1 END) AS afternoon,
COUNT(CASE WHEN date_and_time::TIME BETWEEN '18:00:00' AND '23:59:59' THEN 1 END) AS evening
FROM events_and_products
GROUP BY category;

WITH table1 AS (SELECT session_id,
COUNT(CASE WHEN page_category='PLP' THEN 1 END) AS product_list_page,
COUNT(CASE WHEN page_category='PDP' THEN 1 END) AS product_card
FROM events_and_products
GROUP BY session_id
HAVING MAX(CASE WHEN event_type='add_to_cart' THEN 1 END)>0)
SELECT ROUND(AVG(product_list_page), 2) AS product_list_page, 
ROUND(AVG(product_card), 2) AS product_card
FROM table1;

CREATE OR REPLACE VIEW table2 AS
SELECT DISTINCT e.*, t.gross_revenue
FROM ecommerce_events AS e
JOIN transactions AS t USING (product_id, customer_id);

SELECT traffic_source, 
ROUND(SUM(gross_revenue)::DECIMAL, 2) AS gross_revenue
FROM table2
WHERE event_type='purchase'
GROUP BY traffic_source;

CREATE OR REPLACE VIEW table3 AS 
SELECT brand, 
COUNT(CASE WHEN event_type='add_to_cart' THEN 1 END) AS add_to_cart,
COUNT(CASE WHEN event_type='purchase' THEN 1 END) AS purchase
FROM events_and_products
GROUP BY brand;

SELECT brand, add_to_cart FROM table3
ORDER BY add_to_cart DESC
LIMIT 10;

SELECT brand, purchase FROM table3
ORDER BY purchase DESC
LIMIT 10;

SELECT is_premium,
COUNT(CASE WHEN device_type='mobile' THEN 1 END) AS mobile,
COUNT(CASE WHEN device_type='tablet' THEN 1 END) AS tablet,
COUNT(CASE WHEN device_type='desktop' THEN 1 END) AS desktop
FROM events_and_products
GROUP BY is_premium;

SELECT c.campaign_id, 
COUNT(CASE WHEN e.event_type='view' THEN 1 END) AS total_view,
COUNT(CASE WHEN e.event_type='purchase' THEN 1 END) AS total_purchase,
ROUND((COUNT(CASE WHEN e.event_type='purchase' THEN 1 END)/
COUNT(CASE WHEN e.event_type='view' THEN 1 END)::DECIMAL)*100, 2) 
AS conversion_rate
FROM ecommerce_events AS e
LEFT JOIN campaigns AS c USING (campaign_id)
GROUP BY c.campaign_id;

SELECT c.customer_id, COUNT(t2.event_type) AS total_events, 
ROUND(SUM(t2.gross_revenue)::DECIMAL, 2) AS gross_revenue
FROM table2 AS t2
JOIN customers AS c USING (customer_id)
GROUP BY c.customer_id
ORDER BY gross_revenue DESC
LIMIT 10;

SELECT c.country,
COUNT(CASE WHEN e.event_type='click' THEN 1 END) AS total_click,
COUNT(CASE WHEN e.event_type='view' THEN 1 END) AS total_view,
COUNT(CASE WHEN e.event_type='add_to_cart' THEN 1 END) AS total_add_to_cart,
COUNT(CASE WHEN e.event_type='purchase' THEN 1 END) AS total_purchase,
COUNT(CASE WHEN e.event_type='bounce' THEN 1 END) AS total_bounce,
COUNT(*) AS total_events
FROM ecommerce_events AS e
JOIN customers AS c USING (customer_id)
GROUP BY c.country
UNION ALL
SELECT 'Total', COUNT(CASE WHEN event_type='click' THEN 1 END),
COUNT(CASE WHEN event_type='view' THEN 1 END),
COUNT(CASE WHEN event_type='add_to_cart' THEN 1 END),
COUNT(CASE WHEN event_type='purchase' THEN 1 END),
COUNT(CASE WHEN event_type='bounce' THEN 1 END), COUNT(*)
FROM ecommerce_events
ORDER BY total_events;

WITH table5 AS (SELECT DISTINCT p.category, c.country, 
SUM(gross_revenue) OVER(PARTITION BY p.category, c.country) AS gross_revenue
FROM products AS p
JOIN transactions AS t USING (product_id)
JOIN customers AS c USING (customer_id))
SELECT category, country, 
DENSE_RANK() OVER(
	PARTITION BY category
	ORDER BY gross_revenue DESC
)
FROM table5;