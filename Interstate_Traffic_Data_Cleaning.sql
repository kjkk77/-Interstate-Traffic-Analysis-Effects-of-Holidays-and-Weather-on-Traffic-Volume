/* Note:
1. MySQL Workbench Auto-COMMIT mode disabled.
2. Safe UPDATEs disabled (See Edit > Preferences > SQL Editor)
*/
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

ALTER TABLE interstate
ADD COLUMN record_no MEDIUMINT UNSIGNED AUTO_INCREMENT PRIMARY KEY FIRST; -- Added key column

COMMIT;

CREATE OR REPLACE VIEW interstate_view_all AS
    SELECT 
        *
    FROM
        interstate; -- Create a view to access all of the data set

/* holiday */
SELECT 
    holiday
FROM
    interstate
WHERE
    holiday IS NULL; -- No NULLs in holiday
    
SELECT DISTINCT
    holiday
FROM
    interstate; -- List distinct entries in holiday
    
DELIMITER $$
CREATE PROCEDURE update_holiday (IN p_holiday VARCHAR(25), IN p_date DATETIME)
BEGIN
	UPDATE interstate
	SET holiday = p_holiday
	WHERE date_format(date_time,
		'%Y-%m-%d') = date_format(p_date, '%Y-%m-%d');
END$$ -- Create a procedure to update holidays for corresponding date.
DELIMITER ;

CALL update_holiday('Columbus Day', '2012-10-08 00:00:00');
CALL update_holiday('Veterans Day', '2012-11-12 00:00:00');
CALL update_holiday('Thanksgiving Day', '2012-11-22 00:00:00');
CALL update_holiday('Christmas Day', '2012-12-25 00:00:00');
CALL update_holiday('New Years Day', '2013-01-01 00:00:00');
CALL update_holiday('Washingtons Birthday', '2013-02-18 00:00:00');
CALL update_holiday('Memorial Day', '2013-05-27 00:00:00');
CALL update_holiday('Independence Day', '2013-07-04 00:00:00');
CALL update_holiday('State Fair', '2013-08-22 00:00:00');
CALL update_holiday('Labor Day', '2013-09-02 00:00:00');
CALL update_holiday('Labor Day', '2013-09-02 00:00:00');
CALL update_holiday('Columbus Day', '2013-10-14 00:00:00');
CALL update_holiday('Veterans Day', '2013-11-11 00:00:00');
CALL update_holiday('Thanksgiving Day', '2013-11-28 00:00:00');
CALL update_holiday('Christmas Day', '2013-12-25 00:00:00');
CALL update_holiday('New Years Day', '2014-01-01 00:00:00');
CALL update_holiday('Martin Luther King Jr Day', '2014-01-20 00:00:00');
CALL update_holiday('Washingtons Birthday', '2014-02-17 00:00:00');
CALL update_holiday('Memorial Day', '2014-05-26 00:00:00');
CALL update_holiday('Independence Day', '2015-07-03 00:00:00');
CALL update_holiday('State Fair', '2015-08-27 00:00:00');
CALL update_holiday('Labor Day', '2015-09-07 00:00:00');
CALL update_holiday('Columbus Day', '2015-10-12 00:00:00');
CALL update_holiday('Veterans Day', '2015-11-11 00:00:00');
CALL update_holiday('Thanksgiving Day', '2015-11-26 00:00:00');
CALL update_holiday('Christmas Day', '2015-12-25 00:00:00');
CALL update_holiday('New Years Day', '2016-01-01 00:00:00');
CALL update_holiday('Washingtons Birthday', '2016-02-15 00:00:00');
CALL update_holiday('Memorial Day', '2016-05-30 00:00:00');
CALL update_holiday('Independence Day', '2016-07-04 00:00:00');
CALL update_holiday('State Fair', '2016-08-25 00:00:00');
CALL update_holiday('Labor Day', '2016-09-05 00:00:00');
CALL update_holiday('Columbus Day', '2016-10-10 00:00:00');
CALL update_holiday('Veterans Day', '2016-11-11 00:00:00');
CALL update_holiday('Thanksgiving Day', '2016-11-24 00:00:00');
CALL update_holiday('Thanksgiving Day', '2016-11-24 00:00:00');
CALL update_holiday('Christmas Day', '2016-12-26 00:00:00');
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
CALL update_holiday('New Years Day', '2018-01-01 00:00:00');
CALL update_holiday('Martin Luther King Jr Day', '2018-01-15 00:00:00');
CALL update_holiday('Washingtons Birthday', '2018-02-19 00:00:00');
CALL update_holiday('Memorial Day', '2018-05-28 00:00:00');
CALL update_holiday('Independence Day', '2018-07-04 00:00:00');
CALL update_holiday('State Fair', '2018-08-23 00:00:00');
CALL update_holiday('Labor Day', '2018-09-03 00:00:00'); -- Update holidays to corresponding date_time

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
AFTER labor; -- Add a column for each holiday, except "None"

UPDATE interstate -- R seems to be way better at this in writing than SQL is... (R with for-loop might be better)
SET columbus = IF(holiday = 'Columbus Day', 1, 0),
	veterans = IF(holiday = 'Veterans Day', 1, 0),
    thanksgiving = IF(holiday = 'Thanksgiving Day', 1, 0),
    christmas = IF(holiday = 'Christmas Day', 1, 0),
    new_year = IF(holiday = 'New Years Day', 1, 0),
    washington = IF(holiday = 'Washingtons Birthday', 1, 0),
    memorial = IF(holiday = 'Memorial Day', 1, 0),
    indep = IF(holiday = 'Independence Day', 1, 0),
    state_fair = IF(holiday = 'State Fair', 1, 0),
    labor = IF(holiday = 'Labor Day', 1, 0),
    MLK = IF(holiday = 'Martin Luther King Jr Day', 1, 0); -- Fill in the holiday indicator variables

/* temp */
SELECT 
    temp
FROM
    interstate
WHERE
    temp IS NULL; -- Find NULLs in temp

    
/* rain_1h */
SELECT 
    rain_1h
FROM
    interstate
WHERE
    rain_1h IS NULL; -- Find NULLs in rain_1h
    
/* snow_1h */
SELECT 
    snow_1h
FROM
    interstate
WHERE
    snow_1h IS NULL; -- Find NULLs in snow_1h
    
/* clouds_all */
SELECT 
    clouds_all
FROM
    interstate
WHERE
    clouds_all IS NULL; -- Find NULLs in clouds_all
    
/* weather_main */
SELECT 
    weather_main
FROM
    interstate
WHERE
    weather_main IS NULL; -- Find NULLs in weather_main

SELECT DISTINCT
    weather_main
FROM
    interstate; -- List distinct entries in

/* weather_description */
SELECT 
    weather_description
FROM
    interstate
WHERE
    weather_description IS NULL; -- Find NULLs in weather_description

SELECT DISTINCT
    weather_description
FROM
    interstate; -- List distinct entries in

/* traffic_volume */
SELECT 
    traffic_volume
FROM
    interstate
WHERE
    traffic_volume IS NULL; -- Find NULLs in traffic_volume
    
/* date_time */
SELECT 
    date_time
FROM
    interstate
WHERE
    date_time IS NULL; -- Find NULLs in date_time

SELECT * from interstate where date_time IN
(
	SELECT date_time
    FROM interstate
    GROUP BY date_time
    HAVING COUNT(date_time) > 1
); -- Records with non-unique date_time (13074)

SELECT * from interstate where date_time IN
(
	SELECT DISTINCT date_time
    FROM interstate
    GROUP BY date_time
    HAVING COUNT(date_time) = 1
); -- Records with unique date_time (35130)


SELECT z.* FROM
(SELECT holiday, columbus, veterans, thanksgiving, christmas, new_year,
washington, memorial, indep, state_fair, labor, MLK, temp, rain_1h, snow_1h, 
clouds_all, weather_main, weather_description, date_time, traffic_volume
FROM interstate
GROUP BY holiday, columbus, veterans, thanksgiving, christmas, new_year,
washington, memorial, indep, state_fair, labor, MLK, temp, rain_1h, snow_1h, 
clouds_all, weather_main, weather_description, date_time, traffic_volume
ORDER BY date_time) as z; -- Data Set with no duplicate rows

CREATE TABLE IF NOT EXISTS interstate_new
(
	record_no MEDIUMINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    holiday VARCHAR(25),
    columbus TINYINT, 
    veterans TINYINT, 
    thanksgiving TINYINT,
    christmas TINYINT, 
    new_year TINYINT, 
    washington TINYINT, 
    memorial TINYINT, 
    indep TINYINT, 
    state_fair TINYINT, 
    labor TINYINT, 
    MLK TINYINT,
    temp DECIMAL(6,3),
    rain_1h DECIMAL(6,2),
    snow_1h DECIMAL(3,2),
    clouds_all TINYINT UNSIGNED,
    weather_main VARCHAR(12),
    weather_description VARCHAR(35),
    date_time DATETIME,
    traffic_volume SMALLINT UNSIGNED
); -- Create a table to store newer interstate dataset

INSERT INTO interstate_new (holiday, columbus, veterans, thanksgiving, christmas, new_year,
washington, memorial, indep, state_fair, labor, MLK, temp, rain_1h, snow_1h, 
clouds_all, weather_main, weather_description, date_time, traffic_volume)
	SELECT z.* FROM
	(SELECT holiday, columbus, veterans, thanksgiving, christmas, new_year,
	washington, memorial, indep, state_fair, labor, MLK, temp, rain_1h, snow_1h, 
	clouds_all, weather_main, weather_description, date_time, traffic_volume
	FROM interstate
	GROUP BY holiday, columbus, veterans, thanksgiving, christmas, new_year,
	washington, memorial, indep, state_fair, labor, MLK, temp, rain_1h, snow_1h, 
	clouds_all, weather_main, weather_description, date_time, traffic_volume
	ORDER BY date_time) 
	as z; -- Insert new data set with no duplicates.

ALTER TABLE interstate_new
ADD COLUMN day_wk VARCHAR(9) NULL
AFTER date_time; -- Add new column for days of the week

UPDATE interstate_new SET day_wk = DAYNAME(date_time); -- Update w/ days of the week.

ALTER TABLE interstate_new
ADD COLUMN day_no VARCHAR(9) NULL
AFTER date_time; -- Add new column for day number

UPDATE interstate_new SET day_no = day(date_time); -- Update w/ days number

ALTER TABLE interstate_new
ADD COLUMN month_no VARCHAR(9) NULL
AFTER date_time; -- Add new column for month

UPDATE interstate_new SET month_no = MONTH(date_time); -- Update w/ month

ALTER TABLE interstate_new
ADD COLUMN year_no VARCHAR(9) NULL
AFTER date_time; -- Add new column for year

UPDATE interstate_new SET year_no = YEAR(date_time); -- Update w/ year

ALTER TABLE interstate_new
ADD COLUMN wk_no VARCHAR(9) NULL
AFTER day_wk; -- Add new column for week of year

UPDATE interstate_new SET wk_no = substring(yearweek(date_time),5,2); -- Update w/ week of year

COMMIT;

CREATE VIEW interstate_new_view AS
SELECT 
    *
FROM
    interstate_new; -- Create a view for future reference
    
select * from interstate_new;

/* Changes as Analysis is going on */
SELECT 
    MIN(temp), MAX(temp)
FROM
    interstate_new; -- Check for minimum and maximum temperatures

DELETE FROM interstate_new
WHERE temp = 0; -- Remove outlying temperature

ALTER TABLE interstate_new
CHANGE COLUMN year_no year_no SMALLINT;
ALTER TABLE interstate_new
CHANGE COLUMN month_no month_no SMALLINT;
ALTER TABLE interstate_new
CHANGE COLUMN day_no day_no SMALLINT; -- Change these columns into SMALLINT