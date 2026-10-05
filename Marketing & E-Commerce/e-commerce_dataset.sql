-- Selects all records from the ecommerce_events table.
-- Выборка всех записей из таблицы ecommerce_events.
SELECT * FROM ecommerce_events;

-- Renames the timestamp column to date_and_time.
-- Переименование столбца timestamp в date_and_time.
ALTER TABLE ecommerce_events
RENAME COLUMN timestamp TO date_and_time;

-- Changes the data type of the date_and_time column to TIMESTAMP.
-- Изменение типа данных столбца date_and_time на TIMESTAMP.
ALTER TABLE ecommerce_events
ALTER COLUMN date_and_time TYPE TIMESTAMP USING date_and_time::TIMESTAMP;

-- Counts unique customers and total events grouped by date. Returns top 100 records.
-- Подсчет уникальных клиентов и общего количества событий с группировкой по дате. Вывод первых 100 записей.
SELECT TO_CHAR(date_and_time, 'FMMonth FMDD, YYYY') AS datetime, 
COUNT(DISTINCT customer_id) AS total_customer_id, 
COUNT(event_type) AS total_events
FROM ecommerce_events
GROUP BY TO_CHAR(date_and_time, 'FMMonth FMDD, YYYY')
ORDER BY total_customer_id DESC, total_events DESC
LIMIT 100;

-- Counts the total number of events grouped by month.
-- Подсчет общего количества событий с группировкой по месяцам.
SELECT TO_CHAR(date_and_time, 'Month') AS month_sales, COUNT(*)
FROM ecommerce_events
GROUP BY month_sales, EXTRACT(MONTH FROM date_and_time)
ORDER BY EXTRACT(MONTH FROM date_and_time);

-- Returns distinct traffic sources from the table.
-- Вывод уникальных источников трафика из таблицы.
SELECT DISTINCT traffic_source 
FROM ecommerce_events;

-- Counts the number of events for each device type.
-- Подсчет количества событий для каждого типа устройства.
SELECT device_type, COUNT(*)
FROM ecommerce_events
GROUP BY device_type;

-- Selects records where the device type is missing.
-- Выборка записей с неопределенным типом устройства (NULL).
SELECT * FROM ecommerce_events
WHERE device_type IS NULL;

-- Selects records with missing product IDs, excluding 'bounce' events.
-- Выборка записей с пропущенным идентификатором продукта, исключая события типа 'bounce'.
SELECT * FROM ecommerce_events
WHERE product_id IS NULL AND event_type!='bounce';

-- Counts events with missing product IDs grouped by event type.
-- Подсчет количества событий с пропущенным идентификатором продукта по типам событий.
SELECT event_type, COUNT(*) AS count_product
FROM ecommerce_events
WHERE product_id IS NULL
GROUP BY event_type;

-- Deletes records with missing product IDs, excluding 'bounce' events.
-- Удаление записей с пропущенным идентификатором продукта, за исключением событий 'bounce'.
DELETE FROM ecommerce_events
WHERE product_id IS NULL AND event_type!='bounce';

-- Counts events for each page category.
-- Подсчет количества событий для каждой категории страниц.
SELECT page_category, COUNT(*)
FROM ecommerce_events
GROUP BY page_category;

-- Deletes events for customers who do not exist in the customers table.
-- Удаление событий по клиентам, отсутствующим в таблице customers.
DELETE FROM ecommerce_events
WHERE customer_id NOT IN 
(SELECT DISTINCT customer_id FROM customers);

-- Returns distinct customer IDs from the ecommerce_events table.
-- Вывод уникальных идентификаторов клиентов из таблицы ecommerce_events.
SELECT DISTINCT customer_id FROM ecommerce_events;

-- Creates a view for anomalous data where the device type is missing.
-- Создание представления для аномальных данных с отсутствующим типом устройства.
CREATE VIEW anomalies_table AS
SELECT * FROM ecommerce_events AS e
LEFT JOIN transactions AS t USING(customer_id, product_id, campaign_id)
WHERE device_type IS NULL;

-- Selects all data from the anomalies view.
-- Выборка всех данных из представления anomalies_table.
SELECT * FROM anomalies_table;

-- Finds transaction IDs that appear in the anomalies view.
-- Поиск идентификаторов транзакций, которые присутствуют в представлении аномалий.
SELECT DISTINCT transaction_id FROM transactions
WHERE transaction_id IN (SELECT transaction_id FROM anomalies_table);

-- Deletes transactions associated with the anomalies view.
-- Удаление транзакций, связанных с представлением аномалий.
DELETE FROM transactions
WHERE transaction_id IN (SELECT transaction_id FROM anomalies_table);

-- Selects all data from the transactions table.
-- Выборка всех данных из таблицы transactions.
SELECT * FROM transactions;

-- Deletes records from ecommerce_events where the device type is missing.
-- Удаление записей из таблицы ecommerce_events с неопределенным типом устройства.
DELETE FROM ecommerce_events
WHERE device_type IS NULL;

-- Capitalizes the first letter of the traffic source values.
-- Преобразование регистра: первая буква источника трафика становится заглавной.
UPDATE ecommerce_events
SET traffic_source=UPPER(LEFT(traffic_source, 1)) || 
LOWER(RIGHT(traffic_source, LENGTH(traffic_source)-1));

-- Replaces missing product IDs with a zero value.
-- Замена пропущенных значений (NULL) в идентификаторах продуктов на значение 0.
UPDATE ecommerce_events
SET product_id=0
WHERE product_id IS NULL;

-- Selects the first 1000 rows from the ecommerce_events table.
-- Вывод первых 1000 строк из таблицы ecommerce_events.
SELECT * FROM ecommerce_events
LIMIT 1000;

-- Counts the total number of records in the ecommerce_events table.
-- Подсчет общего количества записей в таблице ecommerce_events.
SELECT COUNT(*) FROM ecommerce_events;

-- Creates or replaces a view that combines events with product details.
-- Создание или обновление представления, объединяющего события с данными о продуктах.
CREATE OR REPLACE VIEW events_and_products AS
SELECT e.*,
p.category, p.brand, p.base_price, p.is_premium
FROM ecommerce_events AS e
JOIN products AS p USING (product_id);

-- Selects all records from the events and products view.
-- Выборка всех записей из представления events_and_products.
SELECT * FROM events_and_products;

-- Counts specific event types and total events for each device type.
-- Подсчет определенных типов событий и общего количества взаимодействий для каждого типа устройства.
SELECT device_type, COUNT(CASE WHEN event_type='view' THEN 1 END) AS count_view,
COUNT(CASE WHEN event_type='add_to_cart' THEN 1 END) AS count_add_to_cart,
COUNT(CASE WHEN event_type='purchase' THEN 1 END) AS count_purchase,
COUNT(*) AS total_count
FROM ecommerce_events
GROUP BY device_type;

-- Counts traffic sources for each product category.
-- Подсчет источников трафика в разрезе категорий продуктов.
SELECT category,
COUNT(CASE WHEN traffic_source='Direct' THEN 1 END) AS direct,
COUNT(CASE WHEN traffic_source='Email' THEN 1 END) AS email,
COUNT(CASE WHEN traffic_source='Organic' THEN 1 END) AS organic,
COUNT(CASE WHEN traffic_source='Paid search' THEN 1 END) AS paid_search,
COUNT(CASE WHEN traffic_source='Social' THEN 1 END) AS social,
COUNT(*) AS total_count
FROM events_and_products
GROUP BY category;

-- Counts 'bounce' events for each page category.
-- Подсчет количества событий типа 'bounce' для каждой категории страниц.
SELECT page_category, COUNT(*)
FROM ecommerce_events
WHERE event_type='bounce'
GROUP BY page_category;

-- Counts events by days of the week for each product category.
-- Подсчет количества событий по дням недели для каждой категории продуктов.
SELECT category,
COUNT(CASE WHEN TO_CHAR(date_and_time, 'FMDay')='Monday' THEN 1 END) as monday,
COUNT(CASE WHEN TO_CHAR(date_and_time, 'FMDay')='Tuesday' THEN 1 END) as tuesday,
COUNT(CASE WHEN TO_CHAR(date_and_time, 'FMDay')='Wednesday' THEN 1 END) as wednesday,
COUNT(CASE WHEN TO_CHAR(date_and_time, 'FMDay')='Thursday' THEN 1 END) as thursday,
COUNT(CASE WHEN TO_CHAR(date_and_time, 'FMDay')='Friday' THEN 1 END) as friday,
COUNT(CASE WHEN TO_CHAR(date_and_time, 'FMDay')='Saturday' THEN 1 END) as saturday,
COUNT(CASE WHEN TO_CHAR(date_and_time, 'FMDay')='Sunday' THEN 1 END) as sunday,
COUNT(*) as total
FROM events_and_products
GROUP BY category;

-- Counts events by time of day for each product category.
-- Подсчет количества событий по времени суток для каждой категории продуктов.
SELECT category,
COUNT(CASE WHEN date_and_time::TIME BETWEEN '00:00:00' AND '05:59:59' THEN 1 END) AS night,
COUNT(CASE WHEN date_and_time::TIME BETWEEN '06:00:00' AND '11:59:59' THEN 1 END) AS morning,
COUNT(CASE WHEN date_and_time::TIME BETWEEN '12:00:00' AND '17:59:59' THEN 1 END) AS afternoon,
COUNT(CASE WHEN date_and_time::TIME BETWEEN '18:00:00' AND '23:59:59' THEN 1 END) AS evening
FROM events_and_products
GROUP BY category;

-- Calculates the average number of viewed pages and product cards per session with cart additions.
-- Расчет среднего количества просмотров страниц списков и карточек товаров для сессий с добавлением в корзину.
WITH table1 AS (SELECT session_id,
COUNT(CASE WHEN page_category='PLP' THEN 1 END) AS product_list_page,
COUNT(CASE WHEN page_category='PDP' THEN 1 END) AS product_card
FROM events_and_products
GROUP BY session_id
HAVING MAX(CASE WHEN event_type='add_to_cart' THEN 1 END)>0)
SELECT ROUND(AVG(product_list_page), 2) AS product_list_page, 
ROUND(AVG(product_card), 2) AS product_card
FROM table1;

-- Creates or replaces a view for purchase events, then sums revenue by traffic source.
-- Создание или обновление представления для покупок с последующим расчетом выручки по источникам трафика.
CREATE OR REPLACE VIEW table2 AS
CREATE OR REPLACE VIEW table2 AS
SELECT DISTINCT e.*, t.gross_revenue
FROM ecommerce_events AS e
JOIN transactions AS t USING (product_id, customer_id)
WHERE event_type='purchase';

-- Calculate total gross revenue for each traffic source based on purchase data.
-- Расчет совокупной валовой выручки для каждого источника трафика на основе данных о покупках.
SELECT traffic_source, 
ROUND(SUM(gross_revenue)::DECIMAL, 2) AS gross_revenue
FROM table2
GROUP BY traffic_source;

-- Creates a view for brand events, then selects top 10 brands by cart additions and purchases.
-- Создание представления для событий брендов с выводом топ-10 марок по добавлениям в корзину и покупкам.
CREATE OR REPLACE VIEW table3 AS 
SELECT brand, 
COUNT(CASE WHEN event_type='add_to_cart' THEN 1 END) AS add_to_cart,
COUNT(CASE WHEN event_type='purchase' THEN 1 END) AS purchase
FROM events_and_products
GROUP BY brand;

-- Display the top 10 brands with the highest number of cart additions.
-- Вывод топ-10 брендов с наибольшим количеством добавлений в корзину.
SELECT brand, add_to_cart FROM table3
ORDER BY add_to_cart DESC
LIMIT 10;

-- Display the top 10 brands with the highest number of completed purchases.
-- Вывод топ-10 брендов с наибольшим количеством совершенных покупок.
SELECT brand, purchase FROM table3
ORDER BY purchase DESC
LIMIT 10;

-- Analyze the distribution of premium product interactions across device types.
-- Анализ распределения взаимодействий с премиум-продуктами по типам устройств.
SELECT is_premium,
COUNT(CASE WHEN device_type='mobile' THEN 1 END) AS mobile,
COUNT(CASE WHEN device_type='tablet' THEN 1 END) AS tablet,
COUNT(CASE WHEN device_type='desktop' THEN 1 END) AS desktop
FROM events_and_products
GROUP BY is_premium;

-- Calculate the conversion rate from views to purchases for each campaign.
-- Расчет коэффициента конверсии (conversion rate) из просмотров в покупки для каждой маркетинговой кампании.
SELECT c.campaign_id, 
COUNT(CASE WHEN e.event_type='view' THEN 1 END) AS total_view,
COUNT(CASE WHEN e.event_type='purchase' THEN 1 END) AS total_purchase,
ROUND((COUNT(CASE WHEN e.event_type='purchase' THEN 1 END)/
COUNT(CASE WHEN e.event_type='view' THEN 1 END)::DECIMAL)*100, 2) 
AS conversion_rate
FROM ecommerce_events AS e
LEFT JOIN campaigns AS c USING (campaign_id)
GROUP BY c.campaign_id;

-- Identify the top 10 customers based on total generated gross revenue.
-- Определение топ-10 клиентов по объему сгенерированной валовой выручки.
SELECT c.customer_id, COUNT(t2.event_type) AS total_events, 
ROUND(SUM(t2.gross_revenue)::DECIMAL, 2) AS gross_revenue
FROM table2 AS t2
JOIN customers AS c USING (customer_id)
GROUP BY c.customer_id
ORDER BY gross_revenue DESC
LIMIT 10;

-- Analyze annual trends for each event type, sorted by year.
-- Анализ ежегодной динамики по каждому типу событий сортировкой по годам.
SELECT TO_CHAR(date_and_time, 'YYYY')::INT AS year_sales, 
COUNT(CASE WHEN event_type='click' THEN 1 END) AS total_click,
COUNT(CASE WHEN event_type='view' THEN 1 END) AS total_view,
COUNT(CASE WHEN event_type='add_to_cart' THEN 1 END) AS total_add_to_cart,
COUNT(CASE WHEN event_type='purchase' THEN 1 END) AS total_purchase,
COUNT(CASE WHEN event_type='bounce' THEN 1 END) AS total_bounce,
COUNT(*) AS total_events
FROM ecommerce_events
GROUP BY year_sales
ORDER BY year_sales;

-- Compare event distribution by customer country and provide a total summary.
-- Сравнение распределения событий по странам клиентов с выводом строки общего итога.
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

-- Rank countries by gross revenue within each product category using window functions.
-- Ранжирование стран по объему валовой выручки внутри каждой категории продуктов с использованием оконных функций.
WITH table4 AS (SELECT DISTINCT p.category, c.country, 
SUM(t.gross_revenue) OVER(PARTITION BY p.category, c.country) AS gross_revenue
FROM products AS p
JOIN transactions AS t USING (product_id)
JOIN customers AS c USING (customer_id))
SELECT category, country, ROUND(gross_revenue::NUMERIC, 2) AS gross_revenue,
DENSE_RANK() OVER(
	PARTITION BY category
	ORDER BY gross_revenue DESC
)
FROM table4;

-- Determine the top 3 product categories by annual gross revenue using ranking functions.
-- Определение топ-3 категорий продуктов по годовой валовой выручке с использованием функций ранжирования.
WITH table5 AS (
	SELECT DISTINCT EXTRACT(YEAR FROM t.datetime_transaction) AS year_events,
	p.category, SUM(t.gross_revenue) OVER(PARTITION BY 
		EXTRACT(YEAR FROM t.datetime_transaction), p.category) AS gross_revenue
FROM products AS p
JOIN transactions AS t USING (product_id)),
ranked_table5 AS (
SELECT year_events, category,
DENSE_RANK() OVER(
	PARTITION BY year_events
	ORDER BY gross_revenue DESC) AS rating_rank
FROM table5)
SELECT year_events, 
MAX(CASE WHEN rating_rank=1 THEN category END) AS first_place,
MAX(CASE WHEN rating_rank=2 THEN category END) AS second_place,
MAX(CASE WHEN rating_rank=3 THEN category END) AS third_place
FROM ranked_table5
GROUP BY year_events;

-- Generate a monthly revenue report breakdown by device types and total sums.
-- Формирование ежемесячного отчета по выручке в разрезе типов устройств и общих сумм.
WITH table6 AS (SELECT EXTRACT(YEAR FROM date_and_time),
EXTRACT(MONTH FROM date_and_time),
TO_CHAR(date_and_time, 'FMMonth, YYYY') AS month_year,
SUM(CASE WHEN device_type='mobile' THEN gross_revenue END) AS mobile,
SUM(CASE WHEN device_type='tablet' THEN gross_revenue END) AS tablet,
SUM(CASE WHEN device_type='desktop' THEN gross_revenue END) AS desktop,
SUM(gross_revenue) AS total
FROM table2
GROUP BY EXTRACT(YEAR FROM date_and_time),
EXTRACT(MONTH FROM date_and_time),
TO_CHAR(date_and_time, 'FMMonth, YYYY')
ORDER BY EXTRACT(YEAR FROM date_and_time),
EXTRACT(MONTH FROM date_and_time))
SELECT month_year, ROUND(mobile::NUMERIC, 2) AS mobile,
ROUND(tablet::NUMERIC, 2) AS tablet,
ROUND(desktop::NUMERIC, 2) AS desktop,
ROUND(total::NUMERIC, 2) AS total
FROM table6;

-- Create a dedicated view for ecommerce events that occurred specifically in the year 2021.
-- Создание отдельного представления для событий электронной коммерции, зафиксированных исключительно в 2021 году.
CREATE OR REPLACE VIEW events2021 AS
SELECT event_id::INTEGER, date_and_time, customer_id::INTEGER,
session_id::INTEGER, event_type, product_id::INTEGER, device_type, 
traffic_source, campaign_id::INTEGER, page_category, session_duration_sec::DECIMAL 
FROM ecommerce_events
WHERE EXTRACT(YEAR FROM date_and_time)=2021;

-- Verify the content of the newly created view for the year 2021 data.
-- Проверка содержимого вновь созданного представления с данными за 2021 год.
SELECT * FROM events2021;