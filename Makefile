# =============================================================================
# Big Data Analytics (BCS714D) - Track B Automation Makefile
# Group 17: Chetan Kishor C G (1JS23CS032) & Hongiran D (1JS23CS062)
# Dataset: NASA POWER Daily Weather — Bengaluru, 2024
# =============================================================================

.DEFAULT_GOAL := help
SHELL := /bin/bash
PYTHON := uv run python
UVICORN := uv run uvicorn

# Colors for terminal output
BLUE   := \033[1;34m
GREEN  := \033[1;32m
YELLOW := \033[1;33m
CYAN   := \033[1;36m
RESET  := \033[0m

.PHONY: help install data theme1 theme2 theme3 analytics assignment1 assignment2 run reports clean lab-setup lab-run all cluster-up cluster-down cluster-status cluster-run cluster-sh

## Display this help message
help:
	@echo -e "$(BLUE)==================================================================$(RESET)"
	@echo -e "$(GREEN)  Big Data Analytics (BCS714D) - Group 17 Command Makefile$(RESET)"
	@echo -e "$(BLUE)==================================================================$(RESET)"
	@echo -e "Usage: $(CYAN)make [target]$(RESET)\n"
	@echo -e "$(YELLOW)Primary Workflow Targets:$(RESET)"
	@echo -e "  $(CYAN)make run$(RESET)            - Launch the Assignment 2 FastAPI Interactive Dashboard"
	@echo -e "  $(CYAN)make assignment1$(RESET)    - Execute all Theme 1, Theme 2, Theme 3 & Analytics pipelines"
	@echo -e "  $(CYAN)make assignment2$(RESET)    - Alias for 'make run' (launches the practical extension UI)"
	@echo -e "  $(CYAN)make reports$(RESET)        - Compile LaTeX reports (assignment1_report.pdf & assignment2_report.pdf)"
	@echo -e "  $(CYAN)make all$(RESET)            - Run full pipeline: data -> themes -> analytics -> reports\n"
	@echo -e "$(YELLOW)Docker 3-Node Virtual Cluster Targets (Alternative to 3 Physical PCs):$(RESET)"
	@echo -e "  $(CYAN)make cluster-up$(RESET)     - Build & start 3-node Hadoop cluster + MongoDB in Docker"
	@echo -e "  $(CYAN)make cluster-run$(RESET)    - Execute MapReduce & MongoDB jobs inside Docker cluster"
	@echo -e "  $(CYAN)make cluster-status$(RESET) - Check Docker containers and HDFS datanode report"
	@echo -e "  $(CYAN)make cluster-sh$(RESET)     - Open an interactive bash shell on Master Node container"
	@echo -e "  $(CYAN)make cluster-down$(RESET)   - Stop and remove the Docker cluster containers\n"
	@echo -e "$(YELLOW)Theme-Specific Targets:$(RESET)"
	@echo -e "  $(CYAN)make data$(RESET)           - Clean and prepare raw NASA weather CSV (TSV, JSON, Scaled)"
	@echo -e "  $(CYAN)make theme1$(RESET)         - Run MongoDB ingestion, aggregation pipelines, and profiling"
	@echo -e "  $(CYAN)make theme2$(RESET)         - Run Hadoop MapReduce Streaming (Mapper -> Sort -> Reducer)"
	@echo -e "  $(CYAN)make theme3$(RESET)         - Run Apache Hive (Text vs RCFile) performance benchmarks"
	@echo -e "  $(CYAN)make analytics$(RESET)      - Compute the 5 distinct climatological domain inquiries\n"
	@echo -e "$(YELLOW)College Lab Multi-Node Cluster Targets (Physical PCs):$(RESET)"
	@echo -e "  $(CYAN)make lab-setup$(RESET)      - Run interactive 3-node Hadoop cluster auto-configurator"
	@echo -e "  $(CYAN)make lab-run$(RESET)        - Run all themes on physical cluster & launch UI"
	@echo -e "  $(CYAN)make clean$(RESET)          - Remove cache files, logs, and LaTeX auxiliary files\n"

## Install and sync Python environment dependencies via uv
install:
	@echo -e "$(BLUE)[INFO] Installing and synchronizing dependencies via uv...$(RESET)"
	uv sync

## Clean and prepare the NASA 2024 Bengaluru weather dataset
data:
	@echo -e "$(BLUE)[1/4] Preparing dataset and computing Discomfort Index...$(RESET)"
	$(PYTHON) assignment1/data/prepare_data.py

## Theme 1: MongoDB document ingestion, aggregations, and profiling
theme1: data
	@echo -e "$(BLUE)[2/4] Executing Theme 1: MongoDB Pipelines and Index Profiling...$(RESET)"
	$(PYTHON) assignment1/theme1_mongodb/ingest_mongo.py
	$(PYTHON) assignment1/theme1_mongodb/aggregation_queries.py
	$(PYTHON) assignment1/theme1_mongodb/explain_profiling.py

## Theme 2: Hadoop File Management & MapReduce Streaming
theme2: data
	@echo -e "$(BLUE)[3/4] Executing Theme 2: Hadoop MapReduce Analytics...$(RESET)"
	$(PYTHON) assignment1/theme2_hadoop_mapreduce/execute_mapreduce.py

## Theme 3: Pig Latin & Hive RCFile vs Text Performance Benchmarking
theme3: data
	@echo -e "$(BLUE)[4/4] Executing Theme 3: Hive Storage Formats and Query Benchmarks...$(RESET)"
	$(PYTHON) assignment1/theme3_pig_hive/hive_benchmark.py

## Answer the 5 distinct analytical questions on Bengaluru weather
analytics: data
	@echo -e "$(BLUE)[INFO] Computing the 5 distinct analytical questions...$(RESET)"
	$(PYTHON) assignment1/analytics_questions.py

## Execute all components of Assignment 1 (Themes 1, 2, 3 + Analytics)
assignment1: data theme1 theme2 theme3 analytics
	@echo -e "\n$(GREEN)==================================================================$(RESET)"
	@echo -e "$(GREEN) [SUCCESS] Assignment 1 pipeline completed!$(RESET)"
	@echo -e "$(GREEN) Outputs generated:$(RESET)"
	@echo -e "  - assignment1/theme1_mongodb/aggregation_results.json"
	@echo -e "  - assignment1/theme1_mongodb/profile.json"
	@echo -e "  - assignment1/theme2_hadoop_mapreduce/mapreduce_output.tsv"
	@echo -e "  - assignment1/theme2_hadoop_mapreduce/yarn_summary.json"
	@echo -e "  - assignment1/theme3_pig_hive/benchmark.json"
	@echo -e "  - assignment1/analytical_questions.json"
	@echo -e "$(GREEN)==================================================================$(RESET)"

## Launch the Assignment 2 FastAPI Interactive Web Dashboard
run: assignment2

assignment2:
	@echo -e "$(GREEN)==================================================================$(RESET)"
	@echo -e "$(GREEN) Launching Assignment 2: FastAPI Interactive Analytics Dashboard$(RESET)"
	@echo -e "$(YELLOW) Open your browser at: http://localhost:8000$(RESET)"
	@echo -e "$(GREEN)==================================================================$(RESET)"
	$(UVICORN) assignment2.backend.main:app --reload --host 0.0.0.0 --port 8000

## Compile both VTU LaTeX PDF reports (Assignment 1 & Assignment 2)
reports:
	@echo -e "$(BLUE)[INFO] Compiling Assignment 1 & 2 LaTeX reports...$(RESET)"
	@$(MAKE) -C reports all
	@echo -e "$(GREEN)[SUCCESS] Reports generated in reports/:$(RESET)"
	@ls -lh reports/*.pdf

## Run interactive 3-node cluster auto-configurator in college lab
lab-setup:
	@echo -e "$(BLUE)[INFO] Launching 3-Node Hadoop Cluster Auto-Configurator...$(RESET)"
	bash lab_setup/setup_cluster.sh

## Run all themes and launch dashboard on college physical cluster
lab-run:
	@echo -e "$(BLUE)[INFO] Running full cluster suite on YARN and launching dashboard...$(RESET)"
	bash lab_setup/run_all_themes.sh

## Run the full end-to-end pipeline (Data -> Assignment 1 -> Reports)
all: assignment1 reports
	@echo -e "$(GREEN)[SUCCESS] Entire Big Data pipeline and PDF reports built successfully!$(RESET)"
	@echo -e "Run $(CYAN)make run$(RESET) to launch the interactive UI."

## Clean build caches, Python __pycache__, and LaTeX temp files
clean:
	@echo -e "$(YELLOW)[INFO] Cleaning build caches and temp files...$(RESET)"
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@$(MAKE) -C reports clean
	@echo -e "$(GREEN)[OK] Clean complete.$(RESET)"

# -----------------------------------------------------------------------------
# Docker 3-Node Virtual Cluster Targets
# -----------------------------------------------------------------------------

## Start the 3-node Hadoop cluster + MongoDB in Docker containers
cluster-up:
	@echo -e "$(BLUE)[INFO] Starting Docker 3-Node Hadoop Cluster (Master + Worker1 + Worker2 + MongoDB)...$(RESET)"
	DOCKER_BUILDKIT=0 docker compose up -d
	@echo -e "$(GREEN)[SUCCESS] Docker cluster containers started!$(RESET)"
	@echo -e "Waiting for NameNode & Worker daemons to initialize..."
	@sleep 6
	@docker compose ps
	@echo -e "\n$(YELLOW)UIs Available on Host:$(RESET)"
	@echo -e "  - NameNode HDFS Web UI : $(CYAN)http://localhost:9870$(RESET)"
	@echo -e "  - YARN Web UI          : $(CYAN)http://localhost:8088$(RESET)"
	@echo -e "  - MongoDB              : $(CYAN)localhost:27017$(RESET)"

## Check health of the Docker Hadoop cluster and live datanodes
cluster-status:
	@echo -e "$(BLUE)[INFO] Checking Docker containers status...$(RESET)"
	docker compose ps
	@echo -e "\n$(BLUE)[INFO] Querying HDFS live datanodes from master container...$(RESET)"
	docker exec -it bda-master-node hdfs dfsadmin -report || true

## Execute the MapReduce and MongoDB pipelines inside the Docker cluster
cluster-run:
	@echo -e "$(BLUE)[INFO] Executing distributed jobs inside Master Node container...$(RESET)"
	docker exec -it bda-master-node /workspace/docker/run_cluster_jobs.sh

## Open an interactive bash terminal inside the Master Node container
cluster-sh:
	@echo -e "$(BLUE)[INFO] Opening bash shell on bda-master-node...$(RESET)"
	docker exec -it bda-master-node bash

## Stop and tear down the Docker cluster containers
cluster-down:
	@echo -e "$(YELLOW)[INFO] Stopping Docker cluster containers...$(RESET)"
	docker compose down
	@echo -e "$(GREEN)[OK] Docker cluster stopped.$(RESET)"
