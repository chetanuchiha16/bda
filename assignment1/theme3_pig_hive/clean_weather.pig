-- =============================================================================
-- Theme 3: Pig Latin Data Cleaning and Transformation Script
-- Group 17: Chetan Kishor C G (1JS23CS032) & Hongiran D (1JS23CS062)
-- Dataset: NASA POWER Daily Weather - Bengaluru, 2024
-- =============================================================================

-- Load raw daily weather data
raw_weather = LOAD '$INPUT' USING PigStorage('\t') AS (
    record_id:int,
    weather_date:chararray,
    year:int,
    month:int,
    day:int,
    season:chararray,
    temperature_c:double,
    precipitation_mm:double,
    relative_humidity_pct:double,
    heat_index_c:double,
    rain_category:chararray
);

-- Filter out nulls, corrupted records, or NASA missing value markers (-999)
clean_weather = FILTER raw_weather BY
    weather_date IS NOT NULL AND
    temperature_c IS NOT NULL AND temperature_c > -50.0 AND
    relative_humidity_pct IS NOT NULL AND relative_humidity_pct >= 0.0 AND relative_humidity_pct <= 100.0 AND
    precipitation_mm IS NOT NULL AND precipitation_mm >= 0.0;

-- Transformation: Add automated climate alert tag
transformed_weather = FOREACH clean_weather GENERATE
    record_id,
    weather_date,
    year,
    month,
    day,
    season,
    temperature_c,
    precipitation_mm,
    relative_humidity_pct,
    heat_index_c,
    rain_category,
    (CASE
        WHEN temperature_c >= 35.0 THEN 'HEATWAVE_WARNING'
        WHEN precipitation_mm >= 30.0 THEN 'HEAVY_MONSOON_ALERT'
        WHEN temperature_c <= 15.0 THEN 'COLD_WEATHER'
        ELSE 'NORMAL'
    END) AS weather_alert:chararray;

-- Store cleaned and transformed dataset for Hive ingestion
STORE transformed_weather INTO '$OUTPUT' USING PigStorage('\t');
