# Big Data Analytics (BCS714D) — Track B
**Academic Year 2026–2027 | JSS Academy of Technical Education, Bengaluru**  
**Group 17:** Chetan Kishor C G (`1JS23CS032`) & Hongiran D (`1JS23CS062`)  
**Assigned Dataset:** NASA POWER Daily Weather — Bengaluru, 2024  
**Faculty:** Sandhiya B

---

## Quick Start (Run FastAPI Dashboard)

Run the interactive analytics dashboard with a single command using `uv`:

```bash
uv run uvicorn assignment2.backend.main:app --reload --port 8000
```

Then open your browser to:  
👉 **`http://localhost:8000`**

---

## Project Structure

```
.
├── assignment1/                               # Track B Part 1: Core Themes (15 Marks)
│   ├── data/
│   │   ├── prepare_data.py                   # Cleans raw NASA CSV, generates TSV, JSON, Scaled data
│   │   ├── bengaluru_weather_2024.csv        # Cleaned 366-day dataset with calendar dates & heat index
│   │   ├── bengaluru_weather_2024.tsv        # TSV format for Pig & Hive
│   │   ├── bengaluru_weather_2024.json       # JSON format for MongoDB
│   │   └── bengaluru_weather_scaled.tsv      # 50,000-record benchmark dataset for cluster stress tests
│   │
│   ├── theme1_mongodb/
│   │   ├── ingest_mongo.py                   # Ingestion script & index creations (date, temp, compound)
│   │   ├── aggregation_queries.py            # Pipelines ($match, $group, $project, $unwind, $facet)
│   │   ├── explain_profiling.py              # Performance profiling (.explain("executionStats"))
│   │   ├── aggregation_results.json          # Saved MongoDB aggregation results
│   │   └── profile.json                      # COLLSCAN vs IXSCAN execution metrics
│   │
│   ├── theme2_hadoop_mapreduce/
│   │   ├── hdfs_operations.sh                # HDFS mkdir, put, get, cat, rm commands
│   │   ├── mapper.py                         # Python Hadoop Streaming Mapper
│   │   ├── reducer.py                        # Python Hadoop Streaming Reducer
│   │   ├── run_mapreduce.sh                  # Execution script for YARN and local pipe
│   │   ├── execute_mapreduce.py              # Automated execution & benchmark harness
│   │   ├── mapreduce_output.tsv              # Monthly aggregates output
│   │   └── yarn_summary.json                 # MapReduce cluster summary
│   │
│   ├── theme3_pig_hive/
│   │   ├── clean_weather.pig                 # Pig Latin filtering & alert tagging script
│   │   ├── hive_tables.hql                   # DDL for Standard Text & RCFile Columnar tables
│   │   ├── hive_queries.hql                  # 5 analytical HQL queries executed across both formats
│   │   ├── hive_benchmark.py                 # Query execution & storage compression benchmark
│   │   └── benchmark.json                    # Saved benchmark results (2.1x speedup, 66% space saved)
│   │
│   ├── analytics_questions.py                # 5 distinct analytical inquiries on Bengaluru 2024 weather
│   └── analytical_questions.json             # Detailed answers & domain findings
│
├── assignment2/                               # Track B Part 2: Practical Extension (10 Marks)
│   ├── backend/
│   │   └── main.py                           # FastAPI REST service (/api/summary, /api/timeseries, ...)
│   └── frontend/
│       ├── index.html                        # Modern Bootstrap 5 + Chart.js analytics dashboard
│       ├── app.js                            # Interactive charting & API fetch logic
│       └── style.css                         # Custom styling & KPI cards
│
└── reports/                                   # Official VTU / JSSATE LaTeX Reports
    ├── assignment1_report.tex                # Assignment 1 LaTeX Report (Part 1 - 15 Marks)
    ├── assignment1_report.pdf                # Compiled Assignment 1 Report (8 pages)
    ├── assignment2_report.tex                # Assignment 2 LaTeX Report (Part 2 - 10 Marks)
    ├── assignment2_report.pdf                # Compiled Assignment 2 Report (8 pages)
    └── logos/                                # VTU & JSSATE logos for report covers
```

---

## Executing the Assignment Themes

### 1. Data Preparation
```bash
uv run python assignment1/data/prepare_data.py
```

### 2. Theme 1 (MongoDB)
```bash
uv run python assignment1/theme1_mongodb/ingest_mongo.py
uv run python assignment1/theme1_mongodb/aggregation_queries.py
uv run python assignment1/theme1_mongodb/explain_profiling.py
```

### 3. Theme 2 (Hadoop MapReduce)
```bash
# Local test or on Master Node:
uv run python assignment1/theme2_hadoop_mapreduce/execute_mapreduce.py

# Or on Hadoop YARN directly:
bash assignment1/theme2_hadoop_mapreduce/run_mapreduce.sh
```

### 4. Theme 3 (Pig & Hive)
```bash
uv run python assignment1/theme3_pig_hive/hive_benchmark.py
```

### 5. Compile Reports
```bash
cd reports
pdflatex -interaction=nonstopmode assignment1_report.tex
pdflatex -interaction=nonstopmode assignment2_report.tex
```
