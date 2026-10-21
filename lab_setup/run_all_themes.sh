#!/usr/bin/env bash
# =============================================================================
# Automated Run of All 3 Themes + Dashboard Launch (Plug & Play)
# Group 17: Chetan Kishor C G (1JS23CS032) & Hongiran D (1JS23CS062)
# =============================================================================

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${DIR}"

echo "=========================================================="
echo " 1. Executing Theme 1: MongoDB Processing & Profiling"
echo "=========================================================="
uv run python assignment1/theme1_mongodb/ingest_mongo.py
uv run python assignment1/theme1_mongodb/aggregation_queries.py
uv run python assignment1/theme1_mongodb/explain_profiling.py

echo ""
echo "=========================================================="
echo " 2. Executing Theme 2: HDFS Operations & YARN MapReduce"
echo "=========================================================="
# Run HDFS Operations
hdfs dfs -mkdir -p /user/bda/weather/input || true
hdfs dfs -put -f assignment1/data/bengaluru_weather_2024.tsv /user/bda/weather/input/
hdfs dfs -rm -r -f /user/bda/weather/output_yarn || true

# Find streaming jar
STREAMING_JAR=$(find ${HADOOP_HOME:-/usr/local/hadoop} -name "hadoop-streaming*.jar" 2>/dev/null | head -n 1)

if [ -n "$STREAMING_JAR" ]; then
    echo "[INFO] Submitting MapReduce job to YARN Cluster..."
    hadoop jar "${STREAMING_JAR}" \
        -files assignment1/theme2_hadoop_mapreduce/mapper.py,assignment1/theme2_hadoop_mapreduce/reducer.py \
        -mapper "python3 mapper.py" \
        -reducer "python3 reducer.py" \
        -input /user/bda/weather/input/bengaluru_weather_2024.tsv \
        -output /user/bda/weather/output_yarn

    echo "[OK] MapReduce Job Completed on YARN. Sample Results:"
    hdfs dfs -cat /user/bda/weather/output_yarn/part-* | head -n 10
else
    echo "[INFO] Running MapReduce via Python harness..."
    uv run python assignment1/theme2_hadoop_mapreduce/execute_mapreduce.py
fi

echo ""
echo "=========================================================="
echo " 3. Executing Theme 3: Pig Latin & Hive Benchmarking"
echo "=========================================================="
uv run python assignment1/theme3_pig_hive/hive_benchmark.py
uv run python assignment1/analytics_questions.py

echo ""
echo "=========================================================="
echo " 4. Launching Assignment 2: FastAPI Web Analytics UI"
echo "=========================================================="
MASTER_IP=$(hostname -I | awk '{print $1}')
echo "[SUCCESS] All themes executed and benchmarks recorded!"
echo ""
echo "👉 Open the Dashboard in your browser:"
echo "   http://${MASTER_IP}:8000"
echo "=========================================================="

# Start FastAPI server
uv run uvicorn assignment2.backend.main:app --host 0.0.0.0 --port 8000
