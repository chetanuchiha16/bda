#!/bin/bash
# =============================================================================
# Theme 2: HDFS File Operations Script
# Group 17: Chetan Kishor C G (1JS23CS032) & Hongiran D (1JS23CS062)
# Dataset: NASA POWER Daily Weather - Bengaluru, 2024
# =============================================================================

set -e

HDFS_DIR="/user/bda/weather"
LOCAL_DATA="../data/bengaluru_weather_2024.tsv"
SCALED_DATA="../data/bengaluru_weather_scaled.tsv"

echo "=== 1. Creating HDFS Directories ==="
hdfs dfs -mkdir -p ${HDFS_DIR}/input
hdfs dfs -mkdir -p ${HDFS_DIR}/output_archive
echo "[OK] Created directory: ${HDFS_DIR}/input"

echo ""
echo "=== 2. Uploading Dataset to HDFS (hdfs dfs -put) ==="
hdfs dfs -put -f ${LOCAL_DATA} ${HDFS_DIR}/input/bengaluru_weather_2024.tsv
hdfs dfs -put -f ${SCALED_DATA} ${HDFS_DIR}/input/bengaluru_weather_scaled.tsv
echo "[OK] Uploaded datasets to HDFS."

echo ""
echo "=== 3. Verifying Files in HDFS (hdfs dfs -ls -h) ==="
hdfs dfs -ls -h ${HDFS_DIR}/input/

echo ""
echo "=== 4. Viewing File Content (hdfs dfs -cat | head) ==="
hdfs dfs -cat ${HDFS_DIR}/input/bengaluru_weather_2024.tsv | head -n 5

echo ""
echo "=== 5. Testing HDFS File Retrieval (hdfs dfs -get) ==="
mkdir -p /tmp/hdfs_verify
hdfs dfs -get -f ${HDFS_DIR}/input/bengaluru_weather_2024.tsv /tmp/hdfs_verify/
ls -lh /tmp/hdfs_verify/bengaluru_weather_2024.tsv
rm -rf /tmp/hdfs_verify
echo "[OK] Successfully retrieved and verified file from HDFS."

echo ""
echo "=== 6. Cleanup of Old MapReduce Output (hdfs dfs -rm -r) ==="
hdfs dfs -rm -r -f ${HDFS_DIR}/output || true
echo "[OK] Cleaned prior output directory."
