# Re-Ordered Data Cleaning for the Interstate Data Set

# Preliminary Steps:

/* 
CREATE DATABASE IF NOT EXISTS transport; -- Create a new database
USE transport;

CREATE TABLE IF NOT EXISTS interstate
(
	holiday VARCHAR(25),
    temp DECIMAL(6,3),
    rain_1h DECIMAL(6,2),
    snow_1h DECIMAL(3,2),
    clouds_all TINYINT UNSIGNED,
    weather_main VARCHAR(12),
    weather_description VARCHAR(35),
    date_time DATETIME,
    traffic_volume SMALLINT UNSIGNED
    
); -- Create a table to store interstate dataset

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Metro_Interstate_Traffic_Volume.csv'
INTO TABLE interstate
FIELDS TERMINATED BY ','
ENCLOSED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@holiday, @temp, @rain_1h, @snow_1h, @clouds_all, @weather_main, @weather_description, @date_time, @traffic_volume)
SET
holiday = IF(@holiday = '', NULL, @holiday),
temp = IF(@temp = '', NULL, @temp),
rain_1h = IF(@rain_1h = '', NULL, @rain_1h),
snow_1h = IF(@snow_1h = '', NULL, @snow_1h),
clouds_all = IF(@clouds_all = '', NULL, @clouds_all),
weather_main = IF(@weather_main = '', NULL, @weather_main),
weather_description = IF(@weather_description = '', NULL, @weather_description),
date_time = IF(@date_time = '', NULL, @date_time),
traffic_volume = IF(@traffic_volume = '', NULL, @traffic_volume); -- Load the interstate data set

*/

CREATE OR REPLACE VIEW interstate_view_all AS
    SELECT 
        *
    FROM
        interstate; -- Create a view to access all of the data set
        
# Data Cleaning:

## date_time:
SELECT 
    *
FROM
    interstate
WHERE
    date_time IS NULL; -- Find NULLs in date_time

SELECT 
    YEAR(date_time) AS yr,
    MONTH(date_time) AS mo,
    DAY(date_time) AS d,
    COUNT(date_time) AS no_of_hours
FROM
    interstate
GROUP BY yr , mo , d
ORDER BY yr, mo, d; -- year, month, day, and number of hours recorded per day

/* Observations:
1. Range of Dates
- 2012: 10/2 - 12/31
- 2013: 1/1 - 12/31
- 2014: 1/1 - 8/8
- 2015: 6/11 - 12/31
- 2016: 1/1 - 12/31
- 2017: 1/1 - 12/31
- 2018: 1/1 - 9/8
2. no_of_hours > 24 or no_of_hours < 24 indicates duplicate and/or missing hours
*/
SELECT 
    *
FROM
    interstate
WHERE
    date_time IN (SELECT DISTINCT
            date_time
        FROM
            interstate
        GROUP BY date_time
        HAVING COUNT(date_time) = 1); -- Records with unique date_time (35130)

SELECT 
    *
FROM
    interstate
WHERE
    date_time IN (SELECT 
            date_time
        FROM
            interstate
        GROUP BY date_time
        HAVING COUNT(date_time) > 1); -- Records with non-unique date_time (Total of 13074 rows with at least one duplicate date_time)

SELECT 
    holiday,
    temp,
    rain_1h,
    snow_1h,
    clouds_all,
    weather_main,
    weather_description,
    date_time,
    traffic_volume
FROM
    interstate
GROUP BY holiday , temp , rain_1h , snow_1h , clouds_all , weather_main , weather_description , date_time , traffic_volume
ORDER BY date_time; -- Data Set with no duplicate rows (while leaving those rows with duplicate date_time but not perfect duplicates)

CREATE TABLE interstate_dup
AS SELECT * FROM interstate; -- Duplicate the interstate table

TRUNCATE TABLE interstate; -- Delete all records from interstate table

INSERT INTO interstate (holiday, temp, rain_1h, snow_1h, 
clouds_all, weather_main, weather_description, date_time, traffic_volume)
	SELECT z.* FROM
	(SELECT 
    holiday,
    temp,
    rain_1h,
    snow_1h,
    clouds_all,
    weather_main,
    weather_description,
    date_time,
    traffic_volume
FROM
    interstate_dup
GROUP BY holiday , temp , rain_1h , snow_1h , clouds_all , weather_main , weather_description , date_time , traffic_volume
ORDER BY date_time) 
	as z; -- Insert new data set with no duplicates (Subquery drawn from interstate_dup).


## holiday:
SELECT 
    *
FROM
    interstate
WHERE
    holiday IS NULL; -- No NULLs in holiday

CREATE OR REPLACE VIEW view_list_of_holidays AS
SELECT DISTINCT
    holiday
FROM
    interstate; -- Create a view to list distinct entries in holiday

CREATE OR REPLACE VIEW view_dates_hours_holidays AS
    SELECT 
        YEAR(date_time),
        MONTH(date_time),
        DAY(date_time),
        HOUR(date_time),
        holiday
    FROM
        interstate
    GROUP BY YEAR(date_time) , MONTH(date_time) , DAY(date_time) , HOUR(date_time) , holiday
    ORDER BY YEAR(date_time) , MONTH(date_time) , DAY(date_time) , HOUR(date_time); -- Create view to list date, hour, and holiday

CREATE OR REPLACE VIEW view_dates_holidays AS
    SELECT 
        YEAR(date_time), MONTH(date_time), DAY(date_time), holiday
    FROM
        interstate
    GROUP BY YEAR(date_time) , MONTH(date_time) , DAY(date_time) , holiday
    ORDER BY YEAR(date_time) , MONTH(date_time) , DAY(date_time); -- Create a view to list date and holiday
/* Observations:
1. There are non-None holidays whose hours are only zeros.
2. Some dates do not have a holiday even though it is supposed to.
*/ 

COMMIT; -- Save progress
/*
DELIMITER $$
CREATE PROCEDURE update_holiday (IN p_holiday VARCHAR(25), IN p_date DATETIME)
BEGIN
	UPDATE interstate
	SET holiday = p_holiday
	WHERE date_format(date_time,
		'%Y-%m-%d') = date_format(p_date, '%Y-%m-%d');
END$$ -- Solution Create a procedure to update holidays for corresponding date.
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE yearly_holidays (IN p_year INT)
BEGIN

SELECT DISTINCT
    holiday, DATE(date_time)
FROM
    interstate
WHERE
    YEAR(date_time) = p_year
    AND holiday <> 'None'
ORDER BY date_time;

END$$
DELIMITER ; -- Create procedure to get existing holidays by year


CALL yearly_holidays(2012); -- View 2012 holidays

CALL update_holiday('Columbus Day', '2012-10-08 00:00:00');
CALL update_holiday('Veterans Day', '2012-11-12 00:00:00');
CALL update_holiday('Thanksgiving Day', '2012-11-22 00:00:00');
CALL update_holiday('Christmas Day', '2012-12-25 00:00:00'); -- Update 2012 holidays

CALL yearly_holidays(2013); -- View 2013 holidays

CALL update_holiday('New Years Day', '2013-01-01 00:00:00');
CALL update_holiday('Martin Luther King Jr Day', '2013-01-21 00:00:00');
CALL update_holiday('Washingtons Birthday', '2013-02-18 00:00:00');
CALL update_holiday('Memorial Day', '2013-05-27 00:00:00');
CALL update_holiday('Independence Day', '2013-07-04 00:00:00');
CALL update_holiday('State Fair', '2013-08-22 00:00:00');
CALL update_holiday('Labor Day', '2013-09-02 00:00:00');
CALL update_holiday('Columbus Day', '2013-10-14 00:00:00');
CALL update_holiday('Veterans Day', '2013-11-11 00:00:00');
CALL update_holiday('Thanksgiving Day', '2013-11-28 00:00:00');
CALL update_holiday('Christmas Day', '2013-12-25 00:00:00'); -- -- Update 2013 holidays

CALL yearly_holidays(2014);  -- View 2014 holidays

CALL update_holiday('New Years Day', '2014-01-01 00:00:00');
CALL update_holiday('Martin Luther King Jr Day', '2014-01-20 00:00:00');
CALL update_holiday('Washingtons Birthday', '2014-02-17 00:00:00');
CALL update_holiday('Memorial Day', '2014-05-26 00:00:00');
CALL update_holiday('Independence Day', '2014-07-04 04:00:00'); -- Update 2014 holidays

CALL yearly_holidays(2015); -- View 2014 holidays

CALL update_holiday('Independence Day', '2015-07-03 00:00:00');
CALL update_holiday('State Fair', '2015-08-27 00:00:00');
CALL update_holiday('Labor Day', '2015-09-07 00:00:00');
CALL update_holiday('Columbus Day', '2015-10-12 00:00:00');
CALL update_holiday('Veterans Day', '2015-11-11 00:00:00');
CALL update_holiday('Thanksgiving Day', '2015-11-26 00:00:00');
CALL update_holiday('Christmas Day', '2015-12-25 00:00:00'); -- Update 2015 holidays

CALL yearly_holidays(2016); -- View 2016 holidays

CALL update_holiday('New Years Day', '2016-01-01 00:00:00');
CALL update_holiday('Martin Luther King Jr Day', '2016-01-18 00:00:00');
CALL update_holiday('Washingtons Birthday', '2016-02-15 00:00:00');
CALL update_holiday('Memorial Day', '2016-05-30 00:00:00');
CALL update_holiday('Independence Day', '2016-07-04 00:00:00');
CALL update_holiday('State Fair', '2016-08-25 00:00:00');
CALL update_holiday('Labor Day', '2016-09-05 00:00:00');
CALL update_holiday('Columbus Day', '2016-10-10 00:00:00');
CALL update_holiday('Veterans Day', '2016-11-11 00:00:00');
CALL update_holiday('Thanksgiving Day', '2016-11-24 00:00:00');
CALL update_holiday('Christmas Day', '2016-12-26 00:00:00'); -- Update 2016 holidays

CALL yearly_holidays(2017); -- View 2017 holidays

CALL update_holiday('New Years Day', '2017-01-02 00:00:00');
CALL update_holiday('Martin Luther King Jr Day', '2017-01-16 00:00:00');
CALL update_holiday('Washingtons Birthday', '2017-02-20 00:00:00');
CALL update_holiday('Memorial Day', '2017-05-29 00:00:00');
CALL update_holiday('Independence Day', '2017-07-04 00:00:00');
CALL update_holiday('State Fair', '2017-08-24 00:00:00');
CALL update_holiday('Labor Day', '2017-09-04 00:00:00');
CALL update_holiday('Columbus Day', '2017-10-09 00:00:00');
CALL update_holiday('Veterans Day', '2017-11-10 00:00:00');
CALL update_holiday('Thanksgiving Day', '2017-11-23 00:00:00');
CALL update_holiday('Christmas Day', '2017-12-25 00:00:00');

CALL yearly_holidays(2018); -- View 2018 holidays

CALL update_holiday('New Years Day', '2018-01-01 00:00:00');
CALL update_holiday('Martin Luther King Jr Day', '2018-01-15 00:00:00');
CALL update_holiday('Washingtons Birthday', '2018-02-19 00:00:00');
CALL update_holiday('Memorial Day', '2018-05-28 00:00:00');
CALL update_holiday('Independence Day', '2018-07-04 00:00:00');
CALL update_holiday('State Fair', '2018-08-23 00:00:00');
CALL update_holiday('Labor Day', '2018-09-03 00:00:00'); -- Update 2018 holidays

COMMIT; -- Save changes
*/

ALTER TABLE interstate
ADD COLUMN columbus TINYINT UNSIGNED
AFTER holiday,
ADD COLUMN veterans TINYINT UNSIGNED
AFTER columbus,
ADD COLUMN thanksgiving TINYINT UNSIGNED
AFTER veterans,
ADD COLUMN christmas TINYINT UNSIGNED
AFTER thanksgiving,
ADD COLUMN new_year TINYINT UNSIGNED
AFTER christmas,
ADD COLUMN washington TINYINT UNSIGNED
AFTER new_year,
ADD COLUMN memorial TINYINT UNSIGNED
AFTER washington,
ADD COLUMN indep TINYINT UNSIGNED
AFTER memorial,
ADD COLUMN state_fair TINYINT UNSIGNED
AFTER indep,
ADD COLUMN labor TINYINT UNSIGNED
AFTER state_fair,
ADD COLUMN MLK TINYINT UNSIGNED
AFTER labor;-- Add a column for each holiday, except "None"

UPDATE interstate 
SET 
    columbus = IF(holiday = 'Columbus Day', 1, 0),
    veterans = IF(holiday = 'Veterans Day', 1, 0),
    thanksgiving = IF(holiday = 'Thanksgiving Day', 1, 0),
    christmas = IF(holiday = 'Christmas Day', 1, 0),
    new_year = IF(holiday = 'New Years Day', 1, 0),
    washington = IF(holiday = 'Washingtons Birthday',
        1,
        0),
    memorial = IF(holiday = 'Memorial Day', 1, 0),
    indep = IF(holiday = 'Independence Day', 1, 0),
    state_fair = IF(holiday = 'State Fair', 1, 0),
    labor = IF(holiday = 'Labor Day', 1, 0),
    MLK = IF(holiday = 'Martin Luther King Jr Day',
        1,
        0);-- Fill in the holiday indicator variables
    
SELECT 
    *
FROM
    interstate
WHERE
    temp IS NULL;-- Find NULLs in temp

SELECT 
    MIN(temp), AVG(temp), MAX(temp)
FROM
    interstate;-- minimum, average, maximum temp
    
DELETE FROM interstate 
WHERE
    temp = 0; -- Delete outlier(s)

## rain_1h: 
SELECT 
    *
FROM
    interstate
WHERE
    rain_1h IS NULL;-- Find NULLs in rain_1h

SELECT 
    MIN(rain_1h), AVG(rain_1h), MAX(rain_1h)
FROM
    interstate;-- minimum, average, maximum rainfall
    
DELETE FROM interstate 
WHERE
    rain_1h = 9831.30; -- Delete outlier(s)

## snow_1h:
SELECT 
    *
FROM
    interstate
WHERE
    snow_1h IS NULL;-- Find NULLs in snow_1h
    
SELECT 
    MIN(snow_1h), AVG(snow_1h), MAX(snow_1h)
FROM
    interstate;-- minimum, average, maximum snowfall

## cloud_all:
SELECT 
    *
FROM
    interstate
WHERE
    clouds_all IS NULL;-- Find NULLs in clouds_all
    
SELECT 
    MIN(clouds_all), AVG(clouds_all), MAX(clouds_all)
FROM
    interstate;-- minimum, average, maximum cloud coverage

## weather_main & weather_description: 
SELECT 
    *
FROM
    interstate
WHERE
    weather_main IS NULL;-- Find NULLs in weather_main

SELECT DISTINCT
    weather_main
FROM
    interstate;-- List distinct entries in weather_main
    
SELECT 
    *
FROM
    interstate
WHERE
    weather_description IS NULL;-- No NULLs in weather_description

SELECT DISTINCT
    weather_description
FROM
    interstate;-- List distinct entries in weather_description

DELIMITER $$
CREATE PROCEDURE weather_details (IN p_weather_main VARCHAR(12))
BEGIN
SELECT 
    weather_main, weather_description, 
    MIN(temp), 
    AVG(temp),
    MAX(temp),
    MIN(rain_1h), 
    avg(rain_1h),
    max(rain_1h),
    min(snow_1h),
    avg(snow_1h),
    max(snow_1h),
    min(clouds_all),
    avg(clouds_all),
    max(clouds_all)
FROM
    interstate
WHERE
	weather_main = p_weather_main
GROUP BY weather_main, weather_description
ORDER BY weather_main, weather_description;
END$$ -- Create a procedure to examine the weather pattern for each weather_main and weather_description
DELIMITER ;

CALL weather_details("Clouds"); -- Weather details for Clouds
CALL weather_details('Clear'); -- Weather details for Clear
/*
Note: 0% <= cloud coverage <= 100%... How?
*/

SELECT 
    clouds_all, COUNT(clouds_all)
FROM
    interstate
WHERE
    weather_main = 'Clear'
GROUP BY clouds_all
ORDER By clouds_all; -- Cloud coverage values
/*
Note:  Majority are 0-8 %. Others are POSSIBLY misentries on either weather_main, weather_description, and/or cloud_all
*/


CALL weather_details('Rain');
/* Important Note (Please Read):
Weather_description = %rain has 0 precipitation... Why?

Because of the records with duplicate date_time but different weather_main and weather_description,
the the last two fields are often inconsistent while other fields are consistent.
This might be because of rain (or even snow) was restricted to a certain area such that the measuring
instrument(s) did not pick up the precipitation. It might also be because a combination of weather phenomena
occurred but whoever recorded did not update other fields properly. Or it might be an input error (that is,
the recorder wrongly identified the weather phenomenon). This is not clear from the data source.

For the purpose of the analysis, especially the linear regression analysis, I will make a strong (but a fairly reasonable) assumption.
I will assume that the precipitation level and cloud coverage are accurate but the word description of weather phenomenon may
not be. The main reason for this is that for those records with duplicate date_time but different weather description have the same
precipitation level. This appear to point to the fact that precipitation reading is accurate and consistently recorded.
In addition, once the word description is disregarded, we can also reduce the data set further.
This suggests that precipitation reading is accurate and consistently recorded.
However, this is just an assumption. This may be the test of the validity of my data analysis
*/

ALTER TABLE interstate
DROP COLUMN weather_main, 
DROP COLUMN weather_description; -- Drop word descriptions from the data set

-- Also: Dropped weather_details and interstate_view_all from the Schema pane in MySQL Workbench

SELECT *
FROM interstate
GROUP BY holiday, columbus, veterans, thanksgiving, christmas, new_year, 
washington, memorial, indep, state_fair, labor, MLK, temp, rain_1h, snow_1h, 
clouds_all, date_time, traffic_volume; -- Obtain a set without duplicate rows

CREATE TABLE interstate_new AS
SELECT *
FROM interstate
GROUP BY holiday, columbus, veterans, thanksgiving, christmas, new_year, 
washington, memorial, indep, state_fair, labor, MLK, temp, rain_1h, snow_1h, 
clouds_all, date_time, traffic_volume; -- Obtain a new table

SELECT 
    *
FROM
    interstate_new
WHERE
    traffic_volume IS NULL; -- Find NULLs in traffic_volume
    
SELECT 
    MIN(traffic_volume),
    AVG(traffic_volume),
    MAX(traffic_volume)
FROM
    interstate_new;
/* Note: 
1. 0 traffic_volume is interesting.
2. Is 7280 an unreasonably high volume?
*/

SELECT *
FROM interstate_new
WHERE traffic_volume = 0; -- See rows with traffic volume of 0
/* Note:
	Possible misentry of data
*/

SELECT 
    traffic_volume, COUNT(traffic_volume)
FROM
    interstate_new
GROUP BY traffic_volume; -- See the traffic volume distribution
/* Note:
General uniformity of frequency does not suggest that 7280 (or values around it) is an outlier.
*/

# Note: interstate_new will be the data set to analyze.

COMMIT;