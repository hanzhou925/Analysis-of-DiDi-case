
--1. share of trips with electric vehicles (EV) in this period
---- browse the data
SELECT * FROM [dbo].[vehicles];

SELECT COUNT(vehicle_id) FROM [dbo].[vehicles]

SELECT 100* COUNT(DISTINCT  [vehicle_id])/ (SELECT COUNT(vehicle_id) FROM [dbo].[vehicles]) 
FROM [dbo].[vehicles]
WHERE [is_electric]=1
----31%
---- CHECK
SELECT [is_electric], COUNT (DISTINCT [vehicle_id]) FROM [dbo].[vehicles]
GROUP BY [is_electric]

--2. weekly growth rate of trips
----aggregate and group the orders by week
SELECT COUNT(DISTINCT order_id) as COUNT_week_num, DATEPART(week, order_date) AS week_num
FROM orders WHERE status = 'completed' 
GROUP BY DATEPART(week, order_date)
ORDER BY week_num

----Create temporary table to store the results above
DROP TABLE temp

CREATE TABLE temp (
count_week_num bigint,
week_num bigint
)

INSERT INTO temp
SELECT COUNT(DISTINCT order_id) as COUNT_week_num, DATEPART(week, order_date) as week_num
FROM orders WHERE status = 'completed' 
GROUP BY DATEPART(week, order_date)

SELECT * FROM temp ORDER BY week_num

----use lag() Function to retrieve the trips in the previous week 
SELECT lag(count_week_num,1) over (order by week_num) as previous, count_week_num, week_num
FROM temp

SELECT max(order_date) FROM orders

--- count the weekly growth rate
SELECT dateadd (week, week_num-1,dateadd(year, 2020 - 1900 ,0)) + 1 -
				datepart(dw, dateadd(week, week_num-1, dateadd(year, 2020 - 1900,0))) +1 as week_start,
				week_num, count_week_num, cast(100*(count_week_num - lag(count_week_num,1) over (order by week_num))/lag(count_week_num,1,0) over (order by week_num) as varchar) + '%' as growth_rate
FROM temp


-- 3. unique active passengers and drivers on week 30
SELECT * FROM orders
SELECT COUNT(DISTINCT driver_id) AS unique_active_driver, COUNT(DISTINCT passenger_id) AS unique_active_passenger
FROM orders 
WHERE status = 'completed' 
and order_date BETWEEN '2020-07-20' and '2020-07-26'

--4. PASSENGERS: conversion rate
---4.1 conversion rate from signup to first_trip - 66%
SELECT * FROM passengers2

SELECT CAST(100 * (SELECT COUNT(DISTINCT passenger_id) 
FROM passengers2 
WHERE first_trip_date IS NOT NULL) / 
(SELECT COUNT(DISTINCT passenger_id) 
FROM passengers2 ) AS VARCHAR) + '%'
AS Conversion_rate_passengers

---4.2 3-day conversion rate compared with all - 66%
SELECT 100 * (SELECT COUNT(DISTINCT passenger_id)
FROM passengers2
WHERE datediff(day, first_trip_date, signup_date) <= 3) /
(SELECT COUNT(DISTINCT passenger_id) 
FROM passengers2 )
AS THREE_DAY_CONVERSION

---4.2 3-day conversion rate among those who had first trip - 100%
SELECT 100 * (SELECT COUNT(DISTINCT passenger_id)
FROM passengers2
WHERE datediff(day, first_trip_date, signup_date) <= 3) /
(SELECT COUNT(DISTINCT passenger_id) 
FROM passengers2 
WHERE first_trip_date IS NOT NULL)
AS THREE_DAY_CONVERSION

---4.3.1 Comparison between passengers with/without loyalty program among all (26% VS 40%)
SELECT CAST(100 * (SELECT COUNT(DISTINCT passenger_id) 
FROM passengers2 
WHERE first_trip_date IS NOT NULL AND is_loyalty_program = 1) / 
(SELECT COUNT(DISTINCT passenger_id) 
FROM passengers2 ) AS VARCHAR) + '%'
AS LOYAL_Conversion_rate_passengers,
CAST(100 * (SELECT COUNT(DISTINCT passenger_id) 
FROM passengers2 
WHERE first_trip_date IS NOT NULL AND is_loyalty_program = 0) / 
(SELECT COUNT(DISTINCT passenger_id) 
FROM passengers2 ) AS VARCHAR) + '%'
AS NOTLOYAL_Conversion_rate_passengers

---4.3.2 Comparison between passengers with/without loyalty program among those who had their first trip (39% VS 60%)
SELECT CAST(100 * (SELECT COUNT(DISTINCT passenger_id) 
FROM passengers2 
WHERE first_trip_date IS NOT NULL AND is_loyalty_program = 1) / 
(SELECT COUNT(DISTINCT passenger_id) 
FROM passengers2 WHERE first_trip_date IS NOT NULL
) 
AS VARCHAR) + '%'
AS LOYAL_Conversion_rate_passengers,
CAST(100 * (SELECT COUNT(DISTINCT passenger_id) 
FROM passengers2 
WHERE first_trip_date IS NOT NULL AND is_loyalty_program = 0) / 
(SELECT COUNT(DISTINCT passenger_id) 
FROM passengers2 WHERE first_trip_date IS NOT NULL
) 
AS VARCHAR) + '%'
AS NOTLOYAL_Conversion_rate_passengers

--5. average trips per passenger for all passengers £¿£¿
SELECT SUM(distance)/COUNT(DISTINCT passenger_id)
AS AVG_distance, SUM(duration)/COUNT(DISTINCT passenger_id)
AS AVG_duration
FROM orders


---comparison between passengers with and without loyalty program
CREATE TABLE TEMP3 (
duration smallint,
distance smallint,
status VARCHAR(MAX),
driver_id bigint,
passenger_id bigint,
is_loyalty_program int)

INSERT INTO TEMP3
SELECT duration, distance, status, driver_id, orders.passenger_id, is_loyalty_program
FROM orders, passengers2
WHERE orders.passenger_id = passengers2.passenger_id

SELECT * FROM TEMP3
SELECT SUM(distance) / 
(SELECT COUNT( DISTINCT passenger_id ) FROM TEMP3 WHERE is_loyalty_program = 1)
AS LOYAL_DISTANCE_AVG,
SUM(duration) / (SELECT COUNT( DISTINCT passenger_id ) FROM TEMP3 WHERE is_loyalty_program = 1)
AS LOYAL_DURATION_AVG,
SUM(distance) / 
(SELECT COUNT( DISTINCT passenger_id ) FROM TEMP3 WHERE is_loyalty_program = 0)
AS NOTLOYAL_DISTANCE_AVG,
SUM(duration) / (SELECT COUNT( DISTINCT passenger_id ) FROM TEMP3 WHERE is_loyalty_program = 0)
AS NOTLOYAL_DURATION_AVG
FROM TEMP3

--6. NOT RECOMMEND the company to continue to invest in expanding loyalty program