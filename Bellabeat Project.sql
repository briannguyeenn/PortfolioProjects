-- Create table to merge all monthly tables into

CREATE TABLE [PortfolioProject].[dbo].[aggregate_table]
(ride_id nvarchar(50), rideable_type nvarchar(50), started_at datetime2(7), ended_at datetime2(7),
start_station_name nvarchar(max), end_station_name nvarchar(max), start_lat float, start_lng float,
end_lat float, end_lng float, member_casual nvarchar(50))


-- Merge all monthly tables into new table

INSERT INTO [PortfolioProject].[dbo].[aggregate_table] (ride_id, rideable_type, started_at, ended_at,
start_station_name, end_station_name, start_lat, start_lng, end_lat, end_lng, member_casual)
(
SELECT 
	ride_id, rideable_type, started_at, ended_at,
	start_station_name, end_station_name, start_lat, start_lng, end_lat, end_lng, member_casual
FROM
	[PortfolioProject].[dbo].[202201-divvy-tripdata]
UNION
SELECT
	ride_id, rideable_type, started_at, ended_at,
	start_station_name, end_station_name, start_lat, start_lng, end_lat, end_lng, member_casual
FROM
	[PortfolioProject].[dbo].[202202-divvy-tripdata]
UNION
SELECT
	ride_id, rideable_type, started_at, ended_at,
	start_station_name, end_station_name, start_lat, start_lng, end_lat, end_lng, member_casual
FROM
	[PortfolioProject].[dbo].[202203-divvy-tripdata]
UNION
SELECT
	ride_id, rideable_type, started_at, ended_at,
	start_station_name, end_station_name, start_lat, start_lng, end_lat, end_lng, member_casual
FROM
	[PortfolioProject].[dbo].[202204-divvy-tripdata]
UNION
SELECT
	ride_id, rideable_type, started_at, ended_at,
	start_station_name, end_station_name, start_lat, start_lng, end_lat, end_lng, member_casual
FROM
	[PortfolioProject].[dbo].[202205-divvy-tripdata]
UNION
SELECT
	ride_id, rideable_type, started_at, ended_at,
	start_station_name, end_station_name, start_lat, start_lng, end_lat, end_lng, member_casual
FROM
	[PortfolioProject].[dbo].[202206-divvy-tripdata]
UNION
SELECT
	ride_id, rideable_type, started_at, ended_at,
	start_station_name, end_station_name, start_lat, start_lng, end_lat, end_lng, member_casual
FROM
	[PortfolioProject].[dbo].[202207-divvy-tripdata]
UNION
SELECT
	ride_id, rideable_type, started_at, ended_at,
	start_station_name, end_station_name, start_lat, start_lng, end_lat, end_lng, member_casual
FROM
	[PortfolioProject].[dbo].[202208-divvy-tripdata]
UNION
SELECT
	ride_id, rideable_type, started_at, ended_at,
	start_station_name, end_station_name, start_lat, start_lng, end_lat, end_lng, member_casual
FROM
	[PortfolioProject].[dbo].[202209-divvy-publictripdata]
UNION
SELECT
	ride_id, rideable_type, started_at, ended_at,
	start_station_name, end_station_name, start_lat, start_lng, end_lat, end_lng, member_casual
FROM
	[PortfolioProject].[dbo].[202210-divvy-tripdata]
UNION
SELECT
	ride_id, rideable_type, started_at, ended_at,
	start_station_name, end_station_name, start_lat, start_lng, end_lat, end_lng, member_casual
FROM
	[PortfolioProject].[dbo].[202211-divvy-tripdata]
);


-- Check for duplicates (Total record count = 5,480,081)

Select
	COUNT(DISTINCT ride_id) AS distinct_id_count,
	COUNT(ride_id) AS total_id_count
FROM
	[PortfolioProject].[dbo].[aggregate_table]


-- Delete entries with inconsistent start and end datetimes (100 rows deleted)

SELECT
	*
FROM
	[PortfolioProject].[dbo].[aggregate_table]
WHERE
	ended_at < started_at

DELETE FROM 
	[PortfolioProject].[dbo].[aggregate_table]
WHERE
	ended_at < started_at;


-- Check for null values

SELECT *
FROM
	[PortfolioProject].[dbo].[aggregate_table]
WHERE
	start_lat IS NULL OR start_lng IS NULL OR end_lat = ' ' OR end_lat IS NULL;

-- Delete the coordinates records that are null

DELETE FROM [PortfolioProject].[dbo].[aggregate_table]
WHERE start_lat IS NULL OR start_lng IS NULL OR end_lat = ' ' OR end_lat IS NULL;


-- Figure out why only several "Green St & Madison Ave*" is 0

SELECT *
FROM
	[PortfolioProject].[dbo].[aggregate_table]
WHERE
	end_lat = ' '

SELECT *
FROM [PortfolioProject].[dbo].[aggregate_table]
WHERE end_station_name = 'Green St & Madison Ave*'


-- Update the columns where end_lat and end_lng contains 0

UPDATE [PortfolioProject].[dbo].[aggregate_table]
SET end_lat = '41.8818283081055', end_lng = '-87.6488342285156'
WHERE end_station_name = 'Green St & Madison Ave*'


-- Recheck to see if it's fixed

SELECT *
FROM
	[PortfolioProject].[dbo].[aggregate_table]
WHERE
	end_lat = ' '


-- Check new total count = 5,548,081

SELECT COUNT(*)
FROM [PortfolioProject].[dbo].[aggregate_table]


-- Add the day of week columns

ALTER TABLE
	[PortfolioProject].[dbo].[aggregate_table]
ADD 
	day_of_week nvarchar(50);
UPDATE 
	[PortfolioProject].[dbo].[aggregate_table]
SET 
	day_of_week = DATENAME(WEEKDAY, started_at)


-- Add a ride time column in minutes

ALTER TABLE
	[PortfolioProject].[dbo].[aggregate_table]
ADD 
	ride_time bigint;
UPDATE 
	[PortfolioProject].[dbo].[aggregate_table]
SET 
	ride_time = DATEDIFF(MINUTE, started_at, ended_at) 

	      


-- ANALYZE PHASE --



-- Count each member type (2,272,017 casuals(single-ride or full-day pass)) (3,208,064 members(annual pass))

SELECT
	member_casual,
	COUNT(member_casual) AS total_count
FROM
	[PortfolioProject].[dbo].[aggregate_table]
GROUP BY
	member_casual;


-- Find the average ride time of casual and member users

SELECT
	member_casual,
	AVG(DATEDIFF(minute, started_at, ended_at)) AS avg__duration
FROM
	[PortfolioProject].[dbo].[aggregate_table]
GROUP BY
	member_casual;


-- Finding how many 'casual' and 'member' cyclists use what type of bike, the total bikes and the average duration in minutes

SELECT
	DISTINCT(rideable_type) AS bike_type,
	member_casual,
	COUNT(rideable_type) AS total_bikes,
	AVG(DATEDIFF(minute, started_at, ended_at)) AS avg_min_duration
FROM 
	[PortfolioProject].[dbo].[aggregate_table]
GROUP BY
	member_casual,
	rideable_type
ORDER BY
	member_casual;


-- Finding the total bike used and the average time by member and bike type

SELECT 
	day_of_week,
	member_casual,
	rideable_type,
	AVG(ride_time) AS avg_ride_time,
	COUNT(rideable_type) AS total_bikes
FROM 
	[PortfolioProject].[dbo].[aggregate_table]
GROUP BY 
	rideable_type, member_casual, day_of_week
ORDER BY 
	member_casual,
	CASE 
		WHEN day_of_week = 'Monday' THEN 1
		WHEN day_of_week = 'Tuesday' THEN 2
		WHEN day_of_week = 'Wednesday' THEN 3
		WHEN day_of_week = 'Thursday' THEN 4
		WHEN day_of_week = 'Friday' THEN 5
		WHEN day_of_week = 'Saturday' THEN 6
		WHEN day_of_week = 'Sunday' THEN 7
	END ASC;
	

-- Finding the average ride time and total rides by member and the day of week

SELECT
	day_of_week, 
	member_casual,
	AVG(ride_time) AS avg_ride_time,
	COUNT(started_at) AS total_rides
FROM 
	[PortfolioProject].[dbo].[aggregate_table]
GROUP BY  
	member_casual, day_of_week
ORDER BY 
	CASE 
		WHEN day_of_week = 'Monday' THEN 1
		WHEN day_of_week = 'Tuesday' THEN 2
		WHEN day_of_week = 'Wednesday' THEN 3
		WHEN day_of_week = 'Thursday' THEN 4
		WHEN day_of_week = 'Friday' THEN 5
		WHEN day_of_week = 'Saturday' THEN 6
		WHEN day_of_week = 'Sunday' THEN 7
	END ASC,
	member_casual;


-- Find the total rides per month for casuals and members

SELECT
	month,
	member_casual,
	COUNT(month) as rides_per_month
FROM
(
	SELECT
		DATEPART(MONTH, started_at) AS month,
		member_casual
	FROM 
		[PortfolioProject].[dbo].[aggregate_table]
) AS X
GROUP BY
	month,
	member_casual
ORDER BY
	member_casual,
	month;


-- Find the average ride duration per month for casuals and members

SELECT
	month,
	member_casual,
	ROUND(AVG(DATEDIFF(MINUTE, started_at, ended_at)),0) AS avg_ride_duration
FROM
(
	SELECT
		DATEPART(MONTH, started_at) AS month,
		member_casual,
		started_at,
		ended_at
	FROM
		[PortfolioProject].[dbo].[aggregate_table]
) AS X
GROUP BY
	member_casual,
	month
ORDER BY
	month,
	member_casual;


-- Combining total rides per month and average ride duration per month

SELECT
	month,
	member_casual,
	COUNT(month) AS rides_by_month,
	ROUND(AVG(DATEDIFF(MINUTE, started_at, ended_at)),0) AS avg_ride_duration
FROM
(
	SELECT
		DATEPART(MONTH, started_at) AS month,
		member_casual,
		started_at,
		ended_at
	FROM
		[PortfolioProject].[dbo].[aggregate_table]
) AS X
GROUP BY
	member_casual,
	month
ORDER BY
	month,
	member_casual;


-- Finding the most used starting and ending stations for casuals

SELECT TOP 30
	member_casual,
	start_station_name,
	COUNT(start_station_name) AS total_rides
FROM
	[PortfolioProject].[dbo].[aggregate_table]
WHERE
	member_casual = 'casual'
GROUP BY
	member_casual,
	start_station_name
ORDER BY
	total_rides DESC;


SELECT TOP 30
	member_casual,
	end_station_name,
	COUNT(end_station_name) AS total_rides
FROM
	[PortfolioProject].[dbo].[aggregate_table]
WHERE
	member_casual = 'casual'
GROUP BY
	member_casual,
	end_station_name
ORDER BY
	total_rides DESC;


-- Finding the most used starting and ending stations for members

SELECT TOP 30
	member_casual,
	start_station_name,
	COUNT(start_station_name) AS total_rides
FROM
	[PortfolioProject].[dbo].[aggregate_table]
WHERE
	member_casual = 'member'
GROUP BY
	member_casual,
	start_station_name
ORDER BY
	total_rides DESC;


SELECT TOP 30
	member_casual,
	end_station_name,
	COUNT(end_station_name) AS total_rides
FROM
	[PortfolioProject].[dbo].[aggregate_table]
WHERE
	member_casual = 'member'
GROUP BY
	member_casual,
	end_station_name
ORDER BY
	total_rides DESC;


-- Top 50 Casual Start Stations

SELECT TOP 50
	member_casual,
	start_lat,
	start_lng,
	COUNT(start_station_name) AS total
FROM
	[PortfolioProject].[dbo].[aggregate_table]
WHERE
	member_casual = 'casual'
GROUP BY
	member_casual,
	start_lat,
	start_lng,
	start_station_name
ORDER BY
	total DESC;

