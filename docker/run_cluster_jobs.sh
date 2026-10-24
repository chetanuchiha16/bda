#!/usr/bin/env bash
# =============================================================================
# Run All Themes Inside the Docker 3-Node Hadoop Cluster
# =============================================================================

set -e

echo "=========================================================="
echo " 1. Checking 3-Node Distributed Cluster Health in Docker  "
echo "=========================================================="
hdfs dfsadmin -report

echo ""
echo "=========================================================="
echo " 2. Theme 2: HDFS File Operations & YARN MapReduce"
echo "=========================================================="
hdfs dfs -mkdir -p /user/bda/weather/input || true
hdfs dfs -put -f /workspace/assignment1/data/bengaluru_weather_2024.tsv /user/bda/weather/input/
hdfs dfs -rm -r -f /user/bda/weather/output_yarn || true

STREAMING_JAR=$(find $HADOOP_HOME -name "hadoop-streaming*.jar" | head -n 1)

echo "[INFO] Submitting MapReduce Streaming Job to YARN across worker-node-1 and worker-node-2..."
hadoop jar "${STREAMING_JAR}" \
    -files /workspace/assignment1/theme2_hadoop_mapreduce/mapper.py,/workspace/assignment1/theme2_hadoop_mapreduce/reducer.py \
    -mapper "python3 mapper.py" \
    -reducer "python3 reducer.py" \
    -input /user/bda/weather/input/bengaluru_weather_2024.tsv \
    -output /user/bda/weather/output_yarn

echo ""
echo "[OK] Distributed MapReduce Output from HDFS:"
hdfs dfs -cat /user/bda/weather/output_yarn/part-* | head -n 14

echo ""
echo "=========================================================="
echo " 3. Theme 1: MongoDB Processing (Container Network)"
echo "=========================================================="
pip3 install -q pymongo
python3 /workspace/assignment1/theme1_mongodb/ingest_mongo.py mongodb://mongodb:27017
python3 /workspace/assignment1/theme1_mongodb/aggregation_queries.py mongodb://mongodb:27017
python3 /workspace/assignment1/theme1_mongodb/explain_profiling.py mongodb://mongodb:27017

echo ""
echo "=========================================================="
echo " [SUCCESS] 3-Node Distributed Cluster Run Complete!       "
echo "=========================================================="
echo "  NameNode UI (Cluster Storage) : http://localhost:9870"
echo "  YARN UI (Job Execution)       : http://localhost:8088"
echo "=========================================================="
