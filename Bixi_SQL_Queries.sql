/*
Bixi Project Deliverable 1

Date: 2023 Apr 16
Author: Justina Nguyen
*/

-- Use Bixi Schema
use bixi;

-- Impressions of data

SELECT *
FROM stations
LIMIT 10;
SELECT *
FROM trips
LIMIT 10;

################
## Question 1 ##
################

-- Q1.1: The total number of trips in 2016.

SELECT
    COUNT(*) AS total_trips
FROM trips
WHERE YEAR(start_date) = 2016
GROUP BY YEAR(start_date);

-- Q1.2: The total number of trips in 2017.

SELECT
    COUNT(*) AS total_trips
FROM trips
WHERE YEAR(start_date) = 2017
GROUP BY YEAR(start_date);

-- Q1.3: The total number of trips in 2016 by month.

SELECT 
    MONTH(start_date), 
    COUNT(*) AS total_trips
FROM trips
WHERE YEAR(start_date) = 2016
GROUP BY MONTH(start_date);

-- Q1.4: The total number of trips in 2017 by month.

SELECT 
    MONTH(start_date), 
    COUNT(*) AS total_trips
FROM trips
WHERE YEAR(start_date) = 2017
GROUP BY MONTH(start_date);

-- Q1.5: The average number of trips a day for each year-month combination

SELECT 
    YEAR(start_date) AS year,
    MONTH(start_date) AS month,
    COUNT(DISTINCT DAY(start_date)), # Shows number of days in operation
    ROUND(COUNT(*) / COUNT(DISTINCT DAY(start_date))) AS avg_trips_per_day # Distinct Day finds the n days in each year-month combo
FROM trips
GROUP BY year, month
ORDER BY year, month;

-- Q1.6 Creating new table from previous question's query results.

DROP TABLE IF EXISTS working_table1;

CREATE TABLE working_table1 AS 
SELECT 
	YEAR(start_date) AS year,
    MONTH(start_date) AS month,
    ROUND(COUNT(*) / COUNT(DISTINCT DAY(start_date))) AS avg_trips_per_day 
FROM trips
GROUP BY year, month
ORDER BY year, month;

-- Impression of working_table1

SELECT *
FROM working_table1;

################
## Question 2 ##
################

-- Q2.1: The total number of trips in the year 2017 broken down by membership status.

SELECT 
    is_member, # Can change 0/1 to make it readable: IF (is_member, 'member', 'non-member')
    COUNT(*) AS total_trips
FROM trips
WHERE YEAR(start_date) = 2017
GROUP BY is_member;

-- Q2.2: The percentage of total trips by members for 2017 by month

SELECT
    MONTH(start_date) AS month, 
	AVG(is_member) AS pct_member_trips -- Booleans are useful!
FROM trips
WHERE YEAR(start_date) = 2017
GROUP BY month;

################
## Question 4 ##
################

-- Q4.1: The names of the 5 most popular starting stations without using a subquery.

SELECT 
    s.name AS station_name,
    COUNT(t.start_station_code) AS total_trips
FROM stations AS s
JOIN trips AS t 
ON s.code = t.start_station_code
GROUP BY station_name
ORDER BY total_trips DESC
LIMIT 5;

-- Q4.2: The names of the 5 most popular starting stations using subquery.

SELECT 
    s.name AS station_name, 
    total_trips
FROM
    (SELECT 
        start_station_code, 
        COUNT(*) AS total_trips
    FROM trips
    GROUP BY start_station_code
    ORDER BY total_trips
    LIMIT 5) AS t 
JOIN stations AS s 
ON t.start_station_code = s.code;

################
## Question 5 ##
################

-- Q5.1: How is the number of starts and ends distributed for the station Mackay / de Maisonneuve throughout the day?

SELECT 
    time_of_day,
    SUM(start_trips) AS start_trips,
    SUM(end_trips) AS end_trips
FROM
    (SELECT 
        CASE
            WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN 'morning'
            WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN 'afternoon'
            WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN 'evening'
            ELSE 'night'
        END AS time_of_day,
        1 AS start_trips,
        0 AS end_trips
    FROM trips AS t
    JOIN stations AS s ON t.start_station_code = s.code
    WHERE s.name = 'Mackay / de Maisonneuve'
    UNION ALL
    SELECT 
        CASE
            WHEN HOUR(end_date) BETWEEN 7 AND 11 THEN 'morning'
            WHEN HOUR(end_date) BETWEEN 12 AND 16 THEN 'afternoon'
            WHEN HOUR(end_date) BETWEEN 17 AND 21 THEN 'evening'
            ELSE 'night'
        END AS time_of_day,
        0 AS start_trips,
        1 AS end_trips
    FROM trips AS t
    JOIN stations AS s ON t.end_station_code = s.code
    WHERE s.name = 'Mackay / de Maisonneuve') AS subquery
GROUP BY time_of_day;

################
## Question 6 ##
################

-- Q6.1: Counts the number of starting trips per station.

SELECT 
    start_station_code AS station_code,
    COUNT(*) AS total_trips_per_station
FROM trips
GROUP BY station_code;

-- 6.2 Counts, for each station, the number of round trips.

SELECT 
    start_station_code, 
    COUNT(*) AS total_round_trips
FROM trips
WHERE start_station_code = end_station_code
GROUP BY start_station_code;

-- 6.3 Combine queries and calculate the fraction of round trips to the total number of starting trips for each station.

SELECT
	stations.name,
	ROUND(SUM(IF(start_station_code = end_station_code, 1, 0))/COUNT(*), 2) AS round_trips_fraction
FROM trips
JOIN stations
ON stations.code = start_station_code
GROUP BY stations.name
ORDER BY round_trips_fraction DESC;

-- 6.4 Filter down to stations with at least 500 trips orginating from them and having at least 10 percent of their trips as round trips.

SELECT 
    s.code,
    s.name,
    ROUND(COUNT(CASE WHEN t.start_station_code = t.end_station_code THEN 1 END) / COUNT(t.start_station_code), 2) AS percent_round_trips
FROM trips AS t
JOIN stations AS s ON t.start_station_code = s.code
GROUP BY s.code, s.name
HAVING COUNT(t.start_station_code) >= 500 AND percent_round_trips >= 0.1
ORDER BY percent_round_trips DESC;