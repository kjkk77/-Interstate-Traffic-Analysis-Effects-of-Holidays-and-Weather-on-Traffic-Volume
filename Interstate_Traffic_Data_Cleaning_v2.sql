-- Note: (MySQL Workbench Setting) Safe UPDATES disabled (Edit > Preferences > SQL Editor)

# Preliminary Steps:

CREATE DATABASE IF NOT EXISTS transport; -- Create a new database

USE transport; -- Use the DB

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
        
# Data Cleaning:

## date_time:
SELECT 
    *
FROM
    interstate
WHERE
    date_time IS NULL; -- Find NULLs in date_time

CREATE OR REPLACE VIEW date_range AS
SELECT 
    YEAR(date_time) AS yr,
    MONTH(date_time) AS mo,
    DAY(date_time) AS d,
    COUNT(date_time) AS no_of_hours
FROM
    interstate
GROUP BY yr , mo , d
ORDER BY yr, mo, d; -- Create view to see year, month, day, and number of hours recorded per day

/* Observations:
1. General Range of Dates (with at least one record)
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
        HAVING COUNT(date_time) = 1); -- Records with unique date_time (35,130 Records)

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
        HAVING COUNT(date_time) > 1); /* Records with non-unique date_time 
        (Total of 13,074 rows with at least one duplicate date_time) */
        
/* Note: Clearly, majority of the records from the query above are not perfect duplicates*/

SELECT 
    *
FROM
    interstate
GROUP BY holiday , temp , rain_1h , snow_1h , clouds_all , weather_main , weather_description , date_time, traffic_volume
ORDER BY date_time; -- Data set with no perfect duplicate rows

CREATE TABLE interstate_dup
AS SELECT * FROM interstate; -- Duplicate the interstate table

TRUNCATE
 TABLE interstate; -- Delete all records from the interstate table

INSERT INTO interstate (holiday, temp, rain_1h, snow_1h, 
clouds_all, weather_main, weather_description, date_time, traffic_volume)
	SELECT z.* FROM
	(SELECT 
    *
	FROM
    interstate_dup
	GROUP BY holiday , temp , rain_1h , snow_1h , clouds_all , weather_main , weather_description, date_time, traffic_volume
	ORDER BY date_time) 
	as z; -- Insert new data set with no perfect duplicates
    
DROP TABLE interstate_dup; -- Drop duplicate table

## holidays:

SELECT 
    *
FROM
    interstate
WHERE
    holiday IS NULL; -- No NULLs in holiday

CREATE OR REPLACE VIEW view_all_holidays AS
    SELECT DISTINCT
        holiday
    FROM
        interstate
    WHERE
        holiday <> 'None'
    ORDER BY MONTH(date_time) , DAY(date_time); /* Create a view to list distinct entries in 
    holiday in order */
    
CREATE OR REPLACE VIEW view_dates_holidays AS
    SELECT 
        YEAR(date_time), MONTH(date_time), DAY(date_time), holiday
    FROM
        interstate
    GROUP BY YEAR(date_time) , MONTH(date_time) , DAY(date_time) , holiday
    ORDER BY YEAR(date_time) , MONTH(date_time) , DAY(date_time); /* Create a view to list date and 
    holiday */
    
CREATE OR REPLACE VIEW view__hours_holidays AS
    SELECT 
        YEAR(date_time),
        MONTH(date_time),
        DAY(date_time),
        HOUR(date_time),
        holiday
    FROM
        interstate
    GROUP BY YEAR(date_time) , MONTH(date_time) , DAY(date_time) , HOUR(date_time) , holiday
    ORDER BY YEAR(date_time) , MONTH(date_time) , DAY(date_time) , HOUR(date_time); /* Create view to 
    list date, hour, and holiday */

/* Observations:
1. There are non-'None' holidays whose hours are only zeros.
2. Some dates do not have a holiday even though it is supposed to.
*/ 

ALTER TABLE interstate
ADD id INT NOT NULL AUTO_INCREMENT PRIMARY KEY; -- Add a primary key for the interstate table

DELIMITER $$
CREATE PROCEDURE update_holiday (IN p_holiday VARCHAR(25), IN p_date DATETIME)
BEGIN
	UPDATE interstate AS a, (SELECT id FROM interstate
    WHERE date_format(date_time,'%Y-%m-%d') = date_format(p_date, '%Y-%m-%d')) AS b
	SET a.holiday = p_holiday
	WHERE a.id = b.id;
END$$ -- Create a procedure to update holidays for corresponding date.
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE yearly_holidays (IN p_year INT)
BEGIN
	SELECT DISTINCT holiday, date_time
    FROM interstate
    WHERE
    YEAR(date_time) = p_year AND holiday <> 'None'
    ORDER BY date_time;
END$$ -- Check holidays and its datetime by an inputted year
DELIMITER ;

CALL yearly_holidays(2012); -- View 2012 holidays and their hours

CALL update_holiday('Columbus Day', '2012-10-08 00:00:00');
CALL update_holiday('Veterans Day', '2012-11-12 00:00:00');
CALL update_holiday('Thanksgiving Day', '2012-11-22 00:00:00');
CALL update_holiday('Christmas Day', '2012-12-25 00:00:00'); /* Update holidays for each hour of 
each holiday in 2012 */

CALL yearly_holidays(2013); -- View 2013 holidays and their hours (Note: 10 / 11 holidays shown)

CALL update_holiday('New Years Day', '2013-01-01 00:00:00');
CALL update_holiday('Martin Luther King Jr Day', '2013-01-21 00:00:00'); -- Missing Holiday
CALL update_holiday('Washingtons Birthday', '2013-02-18 00:00:00');
CALL update_holiday('Memorial Day', '2013-05-27 00:00:00');
CALL update_holiday('Independence Day', '2013-07-04 00:00:00');
CALL update_holiday('State Fair', '2013-08-22 00:00:00');
CALL update_holiday('Labor Day', '2013-09-02 00:00:00');
CALL update_holiday('Columbus Day', '2013-10-14 00:00:00');
CALL update_holiday('Veterans Day', '2013-11-11 00:00:00');
CALL update_holiday('Christmas Day', '2013-12-25 00:00:00');
CALL update_holiday('Thanksgiving Day', '2013-11-28 00:00:00'); /* Update holidays for each hour of 
each holiday in 2013 */

CALL yearly_holidays(2014); -- View 2014 holidays and their hours (Note: 4 / 11 holidays shown)

CALL update_holiday('New Years Day', '2014-01-01 00:00:00');
CALL update_holiday('Martin Luther King Jr Day', '2014-01-20 00:00:00'); 
CALL update_holiday('Washingtons Birthday', '2014-02-17 00:00:00');
CALL update_holiday('Memorial Day', '2014-05-26 00:00:00');
CALL update_holiday('Independence Day', '2014-07-04 00:00:00'); -- Missing holiday 
/* Update holidays for each hour of each holiday in 2014 */

CALL yearly_holidays(2015); -- View 2015 holidays and their hours (Note: 7 / 11 holidays shown)

CALL update_holiday('Independence Day', '2015-07-03 00:00:00'); -- Note: Federal holiday
CALL update_holiday('State Fair', '2015-08-27 00:00:00');
CALL update_holiday('Labor Day', '2015-09-07 00:00:00');
CALL update_holiday('Columbus Day', '2015-10-12 00:00:00');
CALL update_holiday('Veterans Day', '2015-11-11 00:00:00');
CALL update_holiday('Thanksgiving Day', '2015-11-26 00:00:00');
CALL update_holiday('Christmas Day', '2015-12-25 00:00:00'); /* Update holidays for each hour of 
each holiday in 2015 */

CALL yearly_holidays(2016); -- View 2016 holidays and their hours (Note: 10 / 11 holidays shown)

CALL update_holiday('New Years Day', '2016-01-01 00:00:00');
CALL update_holiday('Martin Luther King Jr Day', '2016-01-18 00:00:00'); -- Missing Holiday
CALL update_holiday('Washingtons Birthday', '2016-02-15 00:00:00');
CALL update_holiday('Memorial Day', '2016-05-30 00:00:00');
CALL update_holiday('Independence Day', '2016-07-04 00:00:00');
CALL update_holiday('State Fair', '2016-08-25 00:00:00');
CALL update_holiday('Labor Day', '2016-09-05 00:00:00');
CALL update_holiday('Columbus Day', '2016-10-10 00:00:00');
CALL update_holiday('Veterans Day', '2016-11-11 00:00:00');
CALL update_holiday('Thanksgiving Day', '2016-11-24 00:00:00');
CALL update_holiday('Christmas Day', '2016-12-26 00:00:00'); -- Federal Holiday 
/* Update holidays for each hour of each holiday in 2016 */

CALL yearly_holidays(2017); -- View 2017 holidays and their hours (Note: 11 / 11 holidays shown)

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
CALL update_holiday('Christmas Day', '2017-12-25 00:00:00'); /* Update holidays for each hour of 
each holiday in 2017 */

CALL yearly_holidays(2018); -- View 2018 holidays and their hours (Note: 7 / 11 holidays shown)

CALL update_holiday('New Years Day', '2018-01-01 00:00:00');
CALL update_holiday('Martin Luther King Jr Day', '2018-01-15 00:00:00');
CALL update_holiday('Washingtons Birthday', '2018-02-19 00:00:00');
CALL update_holiday('Memorial Day', '2018-05-28 00:00:00');
CALL update_holiday('Independence Day', '2018-07-04 00:00:00');
CALL update_holiday('State Fair', '2018-08-23 00:00:00');
CALL update_holiday('Labor Day', '2018-09-03 00:00:00'); /* Update holidays for each hour of 
each holiday in 2018 */

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
    washington = IF(holiday = 'Washingtons Birthday',1,0),
    memorial = IF(holiday = 'Memorial Day', 1, 0),
    indep = IF(holiday = 'Independence Day', 1, 0),
    state_fair = IF(holiday = 'State Fair', 1, 0),
    labor = IF(holiday = 'Labor Day', 1, 0),
    MLK = IF(holiday = 'Martin Luther King Jr Day',1,0);-- Fill in the holiday indicator variables
        
## temp

SELECT 
    temp
FROM
    interstate
WHERE
    temp IS NULL; -- Check for NULLs

SELECT 
    ROUND((MIN(temp)- 273.15) * (9/5) + 32, 2) as min_temp_f,
    ROUND((AVG(temp)- 273.15) * (9/5) + 32, 2) as avg_temp_f, 
    ROUND((MAX(temp)- 273.15) * (9/5) + 32, 2) as max_temp_f
FROM
    interstate;-- minimum, average, maximum temp (in fahrenheit)
    
SELECT 
    *
FROM
    interstate
WHERE
    temp = 0; -- Inspect 0 Kelvin records
    
DELETE FROM interstate 
WHERE
    temp = 0; -- Delete clear outlier (since no 'natural' place on Earth is 0 degrees Kelvin)
    
SELECT 
    a.*
FROM
    interstate a
        CROSS JOIN
    interstate b
WHERE
    a.holiday = b.holiday
        AND a.temp <> b.temp
        AND a.rain_1h = b.rain_1h
        AND a.snow_1h = b.snow_1h
        AND a.clouds_all = b.clouds_all
        AND a.weather_main = b.weather_main
        AND a.weather_description = b.weather_description
        AND a.date_time = b.date_time
        AND a.traffic_volume = b.traffic_volume; /* Show duplicate records with slightly different 
        temperatures */

SELECT MIN(c.id) 
FROM
(SELECT 
    a.*
FROM
    interstate a
        CROSS JOIN
    interstate b
WHERE
    a.holiday = b.holiday
        AND a.temp <> b.temp
        AND a.rain_1h = b.rain_1h
        AND a.snow_1h = b.snow_1h
        AND a.clouds_all = b.clouds_all
        AND a.weather_main = b.weather_main
        AND a.weather_description = b.weather_description
        AND a.date_time = b.date_time
        AND a.traffic_volume = b.traffic_volume) AS c
GROUP BY c.holiday, c.columbus, c.veterans, c.thanksgiving, c.christmas, c.new_year, c.washington, 
c.memorial, c.indep, c.state_fair, c.labor, c.MLK, c.rain_1h, c.snow_1h, c.clouds_all, c.weather_main,
 c.weather_description, c.date_time, c.traffic_volume; -- Get the minimum id number of each near-duplicates

DELETE FROM interstate 
WHERE
    id IN (SELECT 
        MIN(c.id)
    FROM
        (SELECT 
            a.*
        FROM
            interstate a
        CROSS JOIN interstate b
        
        WHERE
            a.holiday = b.holiday
            AND a.temp <> b.temp
            AND a.rain_1h = b.rain_1h
            AND a.snow_1h = b.snow_1h
            AND a.clouds_all = b.clouds_all
            AND a.weather_main = b.weather_main
            AND a.weather_description = b.weather_description
            AND a.date_time = b.date_time
            AND a.traffic_volume = b.traffic_volume) AS c
    GROUP BY c.holiday , c.columbus , c.veterans , c.thanksgiving , c.christmas , c.new_year , 
    c.washington , c.memorial , c.indep , c.state_fair , c.labor , c.MLK , c.rain_1h , c.snow_1h , 
    c.clouds_all , c.weather_main , c.weather_description , c.date_time , 
    c.traffic_volume); -- Delete the rows specified in the query above.

## rain_1h

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

SELECT *
FROM interstate
WHERE 
	rain_1h = 9831.30; -- Examine outlier
    
DELETE FROM interstate 
WHERE
    rain_1h = 9831.30; -- Delete outlier
    
## snow_1h

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
    
## cloud_all

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
    
## weather_main & weather_description
 
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
    weather_description IS NULL;-- Check for NULLs in weather_description

SELECT DISTINCT
    weather_description
FROM
    interstate;-- List distinct entries in weather_description
    
SELECT DISTINCT
    weather_main, weather_description
FROM
    interstate
ORDER BY weather_main, weather_description; /* List each weather_description value 
grouped by its respective weather_main */

## Traffic Volume

SELECT 
    *
FROM
    interstate
WHERE
    traffic_volume IS NULL; -- Find records with NULL traffic_volume values

SELECT 
    MIN(traffic_volume),
    AVG(traffic_volume),
    MAX(traffic_volume)
FROM
    interstate; -- See some summary statistics of traffic_volume
    
SELECT *
FROM interstate
WHERE traffic_volume = 0; -- See records with 0 vehicles per hour (possible outliers?)

SELECT *
FROM interstate
WHERE traffic_volume = 7280; -- See records with 7280 vehicles per hour (possible outlier?)

COMMIT;