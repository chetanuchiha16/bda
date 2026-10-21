#!/bin/bash
# =============================================================================
# Theme 2: MapReduce Execution Script (Hadoop Streaming on YARN)
# Group 17: Chetan Kishor C G (1JS23CS032) & Hongiran D (1JS23CS062)
# =============================================================================

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${DIR}"

echo "=========================================================="
echo " Mode 1: Local MapReduce Pipeline Simulation (Unix Pipe)"
echo "=========================================================="
cat ../data/bengaluru_weather_2024.tsv | python3 mapper.py | sort | python3 reducer.py > mapreduce_output.tsv
echo "[OK] Local MapReduce execution completed. Output saved to mapreduce_output.tsv"
head -n 14 mapreduce_output.tsv

echo ""
echo "=========================================================="
echo " Mode 2: Distributed Hadoop Streaming on YARN"
echo "=========================================================="
echo "Checking for HADOOP_HOME..."

if command -v hadoop &> /dev/null; then
    STREAMING_JAR=$(find ${HADOOP_HOME:-/usr/local/hadoop}/share/hadoop/tools/lib/ -name "hadoop-streaming-*.jar" | head -n 1)
    if [ -z "$STREAMING_JAR" ]; then
        echo "[WARN] hadoop-streaming jar not found in HADOOP_HOME. Ensure Hadoop tools are installed."
    else
        echo "[INFO] Found streaming jar: ${STREAMING_JAR}"
        hdfs dfs -rm -r -f /user/bda/weather/output || true
        
        hadoop jar "${STREAMING_JAR}" \
            -files mapper.py,reducer.py \
            -mapper "python3 mapper.py" \
            -reducer "python3 reducer.py" \
            -input /user/bda/weather/input/bengaluru_weather_2024.tsv \
            -output /user/bda/weather/output

        echo "[OK] YARN Job completed. Retrieving results from HDFS:"
        hdfs dfs -cat /user/bda/weather/output/part-* | head -n 20
    fi
else
    echo "[INFO] Hadoop CLI not in PATH on this system. To run on the multi-node lab cluster, execute this script on the Master Node."
fi
