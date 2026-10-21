-- =============================================================================
-- Theme 3: Hive Table Definitions (Text vs RCFile Format)
-- Group 17: Chetan Kishor C G (1JS23CS032) & Hongiran D (1JS23CS062)
-- =============================================================================

CREATE DATABASE IF NOT EXISTS bda_weather_db;
USE bda_weather_db;

-- 1. Standard External Text Table
DROP TABLE IF EXISTS weather_text;
CREATE EXTERNAL TABLE weather_text (
    record_id INT,
    weather_date STRING,
    year INT,
    month INT,
    day INT,
    season STRING,
    temperature_c DOUBLE,
    precipitation_mm DOUBLE,
    relative_humidity_pct DOUBLE,
    heat_index_c DOUBLE,
    rain_category STRING,
    weather_alert STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '${hivevar:INPUT_DIR}';

-- 2. RCFile (Record Columnar File) Format Table
DROP TABLE IF EXISTS weather_rcfile;
CREATE TABLE weather_rcfile (
    record_id INT,
    weather_date STRING,
    year INT,
    month INT,
    day INT,
    season STRING,
    temperature_c DOUBLE,
    precipitation_mm DOUBLE,
    relative_humidity_pct DOUBLE,
    heat_index_c DOUBLE,
    rain_category STRING,
    weather_alert STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.columnar.ColumnarSerDe'
STORED AS RCFILE;

-- 3. Ingest Data from Text into RCFile with Compression
SET hive.exec.compress.output=true;
SET mapred.output.compression.codec=org.apache.hadoop.io.compress.GzipCodec;
SET mapreduce.output.fileoutputformat.compress.codec=org.apache.hadoop.io.compress.GzipCodec;

INSERT OVERWRITE TABLE weather_rcfile SELECT * FROM weather_text;

-- Compute column and table statistics
ANALYZE TABLE weather_text COMPUTE STATISTICS;
ANALYZE TABLE weather_rcfile COMPUTE STATISTICS;
