-- =============================================================================
-- Theme 3: Benchmark Queries Executed on Both Text and RCFile
-- Group 17: Chetan Kishor C G (1JS23CS032) & Hongiran D (1JS23CS062)
-- =============================================================================

USE bda_weather_db;

-- -----------------------------------------------------------------------------
-- Query 1: Monthly Temperature and Rainfall Aggregation
-- -----------------------------------------------------------------------------
-- Format: TEXT
SELECT month, season,
       ROUND(AVG(temperature_c), 2) AS avg_temp,
       MAX(temperature_c) AS max_temp,
       ROUND(SUM(precipitation_mm), 2) AS total_rain,
       ROUND(AVG(relative_humidity_pct), 2) AS avg_humidity
FROM weather_text
GROUP BY month, season
ORDER BY month;

-- Format: RCFILE
SELECT month, season,
       ROUND(AVG(temperature_c), 2) AS avg_temp,
       MAX(temperature_c) AS max_temp,
       ROUND(SUM(precipitation_mm), 2) AS total_rain,
       ROUND(AVG(relative_humidity_pct), 2) AS avg_humidity
FROM weather_rcfile
GROUP BY month, season
ORDER BY month;


-- -----------------------------------------------------------------------------
-- Query 2: Peak Monsoon and High-Humidity Weather Window
-- -----------------------------------------------------------------------------
-- Format: TEXT
SELECT weather_date, temperature_c, precipitation_mm, relative_humidity_pct, rain_category
FROM weather_text
WHERE precipitation_mm >= 25.0 AND relative_humidity_pct >= 75.0
ORDER BY precipitation_mm DESC;

-- Format: RCFILE
SELECT weather_date, temperature_c, precipitation_mm, relative_humidity_pct, rain_category
FROM weather_rcfile
WHERE precipitation_mm >= 25.0 AND relative_humidity_pct >= 75.0
ORDER BY precipitation_mm DESC;


-- -----------------------------------------------------------------------------
-- Query 3: Seasonal Climate Profile and Extreme Weather Counts
-- -----------------------------------------------------------------------------
-- Format: TEXT
SELECT season,
       COUNT(*) AS total_days,
       SUM(CASE WHEN precipitation_mm > 0.1 THEN 1 ELSE 0 END) AS rainy_days,
       ROUND(AVG(heat_index_c), 2) AS avg_heat_index,
       ROUND(SUM(precipitation_mm), 2) AS seasonal_rain
FROM weather_text
GROUP BY season;

-- Format: RCFILE
SELECT season,
       COUNT(*) AS total_days,
       SUM(CASE WHEN precipitation_mm > 0.1 THEN 1 ELSE 0 END) AS rainy_days,
       ROUND(AVG(heat_index_c), 2) AS avg_heat_index,
       ROUND(SUM(precipitation_mm), 2) AS seasonal_rain
FROM weather_rcfile
GROUP BY season;


-- -----------------------------------------------------------------------------
-- Query 4: Heat Stress Analysis (Top Days by Thom's Discomfort Index)
-- -----------------------------------------------------------------------------
-- Format: TEXT
SELECT weather_date, season, temperature_c, relative_humidity_pct, heat_index_c
FROM weather_text
ORDER BY heat_index_c DESC
LIMIT 10;

-- Format: RCFILE
SELECT weather_date, season, temperature_c, relative_humidity_pct, heat_index_c
FROM weather_rcfile
ORDER BY heat_index_c DESC
LIMIT 10;


-- -----------------------------------------------------------------------------
-- Query 5: Rain Severity Distribution and Frequency Analysis
-- -----------------------------------------------------------------------------
-- Format: TEXT
SELECT rain_category,
       COUNT(*) AS day_count,
       ROUND(SUM(precipitation_mm), 2) AS total_rainfall,
       ROUND(AVG(temperature_c), 2) AS avg_temp
FROM weather_text
GROUP BY rain_category
ORDER BY day_count DESC;

-- Format: RCFILE
SELECT rain_category,
       COUNT(*) AS day_count,
       ROUND(SUM(precipitation_mm), 2) AS total_rainfall,
       ROUND(AVG(temperature_c), 2) AS avg_temp
FROM weather_rcfile
GROUP BY rain_category
ORDER BY day_count DESC;
