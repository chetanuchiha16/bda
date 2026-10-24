# =============================================================================
# Assignment 1 Makefile (Track B Part 1: Core Themes)
# =============================================================================

.DEFAULT_GOAL := all
PYTHON := uv run python

.PHONY: all data theme1 theme2 theme3 analytics clean

all: data theme1 theme2 theme3 analytics

data:
	$(PYTHON) data/prepare_data.py

theme1:
	$(PYTHON) theme1_mongodb/ingest_mongo.py
	$(PYTHON) theme1_mongodb/aggregation_queries.py
	$(PYTHON) theme1_mongodb/explain_profiling.py

theme2:
	$(PYTHON) theme2_hadoop_mapreduce/execute_mapreduce.py

theme3:
	$(PYTHON) theme3_pig_hive/hive_benchmark.py

analytics:
	$(PYTHON) analytics_questions.py

clean:
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
