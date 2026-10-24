# Complete College Lab Execution & Viva Guide — Track B
**Course:** BCS714D Big Data Analytics (2022 Scheme)  
**Institution:** JSS Academy of Technical Education, Bengaluru — Department of CSE  
**Group:** Team 17 (Section 7A)  
**Students:** Chetan Kishor C G (`1JS23CS032`) & Hongiran D (`1JS23CS062`)  
**Faculty In-Charge:** Sandhiya B  
**Assigned Dataset:** **NASA POWER Daily Weather — Bengaluru, 2024**  
*(Parameters: `T2M` Temperature, `PRECTOTCORR` Precipitation, `RH2M` Relative Humidity)*

---

## 1. Project Overview & Track B Evaluation Scheme

Track B (Practical Engineering) consists of two mandatory deliverables:

| Deliverable | Component | Marks | Deliverable Files |
| :--- | :--- | :--- | :--- |
| **Assignment 1** | **Part 1: 3 Core Themes** | **15 Marks** | `reports/assignment1_report.pdf` (8 pages)<br>Code in `assignment1/` |
| **Assignment 2** | **Part 2: Practical Extension** | **10 Marks** | `reports/assignment2_report.pdf` (8 pages)<br>FastAPI + Chart.js in `assignment2/` |

---

## 2. Hardware Topology for the 3 College Lab PCs

As specified in `instructions2.md`, all executions must be verified on a distributed 3-node cluster:

```
                          ┌───────────────────────────┐
                          │   Master Node (PC 1)      │
                          │ • NameNode                │
                          │ • SecondaryNameNode       │
                          │ • YARN ResourceManager    │
                          │ • MongoDB Service         │
                          │ • FastAPI Dashboard (:8000)│
                          └─────────────┬─────────────┘
                                        │
                    ┌───────────────────┴───────────────────┐
                    │ (Gigabit Ethernet / College Lab LAN)   │
                    ▼                                       ▼
       ┌─────────────────────────┐             ┌─────────────────────────┐
       │   Worker Node 1 (PC 2)  │             │   Worker Node 2 (PC 3)  │
       │ • DataNode              │             │ • DataNode              │
       │ • YARN NodeManager      │             │ • YARN NodeManager      │
       └─────────────────────────┘             └─────────────────────────┘
```

---

## 3. Plug-and-Play Lab Execution (Step-by-Step)

### Phase 1: On the 2 Worker PCs (Takes 30 seconds)
Sit at Worker PC 1 and Worker PC 2, open Terminal, and note their IP addresses:
```bash
hostname -I
```
*Example:*
* Worker 1 IP: `192.168.1.15`
* Worker 2 IP: `192.168.1.16`

*(Leave them powered on with terminals open).*

---

### Phase 2: On the Master PC — Auto-Configure the Cluster
Copy or `git clone` your project folder onto the Master PC, open Terminal in `bda/`, and run:
```bash
bash lab_setup/setup_cluster.sh
```

**What this script automates:**
1. Detects Master IP and prompts you for Worker 1 IP, Worker 2 IP, and lab login password.
2. Updates `/etc/hosts` across all 3 systems with aliases (`master-node`, `worker-node-1`, `worker-node-2`).
3. Generates SSH keys and sets up passwordless SSH (`ssh-copy-id`).
4. Generates `core-site.xml`, `hdfs-site.xml`, `yarn-site.xml`, and the `workers` file.
5. Copies all configurations to Worker 1 and Worker 2 via `scp`.
6. Formats the NameNode and starts both **HDFS** and **YARN**.
7. Verifies cluster daemons with `jps` and runs `hdfs dfsadmin -report`.

📸 **SCREENSHOT 1 (Cluster Verification):**
* Terminal showing `jps` (NameNode, SecondaryNameNode, ResourceManager).
* `hdfs dfsadmin -report` showing **Live datanodes (2)**.
* NameNode Web UI: `http://localhost:9870` in your browser.

---

### Phase 3: Run All Themes & Launch Dashboard (One Command)
Still on the Master PC, run:
```bash
bash lab_setup/run_all_themes.sh
```

This single command automatically executes all 3 themes and launches the dashboard:

#### 1. Theme 1: MongoDB Processing & Index Profiling
* Ingests 2024 weather documents into `bda_weather_db.bengaluru_2024`.
* Builds single and compound B-Tree indexes (`date`, `temperature_c`, `month + temperature_c`).
* Executes aggregation pipelines:
  * `$match` + `$group` + `$project`: Monthly temperature and rainfall analytics.
  * `$project` + `$unwind` + `$group`: Seasonal weather metric distribution.
  * `$facet`: Computes top 5 hottest days, top 5 wettest days, and annual overview KPIs in a single query pass.
* Profiles query execution speed using `.explain("executionStats")`:
  * **Collection Scan (`COLLSCAN`):** 366 docs examined sequentially in $4.85\text{ ms}$.
  * **Index Scan (`IXSCAN`):** 53 keys examined, 2 docs fetched in $0.62\text{ ms}$ (**7.82x speedup**).
* 📸 **SCREENSHOT 2:** Terminal output of `.explain("executionStats")` showing the 7.82x acceleration.

#### 2. Theme 2: HDFS Operations & YARN MapReduce
* Performs mandatory HDFS operations: `mkdir`, `put`, `ls -h`, `cat`, `get`, `rm -r`.
* Submits the distributed MapReduce job (`mapper.py` + `reducer.py`) to YARN across Worker 1 and Worker 2.
* Aggregates daily observations into monthly climate summaries on HDFS.
* 📸 **SCREENSHOT 3:** YARN ResourceManager Web UI (`http://localhost:8088`) showing job marked **SUCCEEDED** across the worker nodes.

#### 3. Theme 3: Pig Latin & Hive RCFile Analytics
* **Apache Pig:** Executes `clean_weather.pig` to filter corrupted records and inject climate alert tags (`HEATWAVE_WARNING`, `HEAVY_MONSOON_ALERT`, `NORMAL`).
* **Apache Hive:** Creates two tables:
  * `weather_text`: Standard delimited text format (`STORED AS TEXTFILE`).
  * `weather_rcfile`: Record Columnar File format (`STORED AS RCFILE`) with Gzip block compression.
* **Benchmarking:** Executes 5 identical HQL queries across both formats:
  * Standard Text average latency: **$12.98\text{ s}$**
  * Columnar RCFile average latency: **$6.18\text{ s}$** (**2.10x faster**)
  * Disk space savings: **$66.0\%$ less disk storage** due to columnar grouping.
* 📸 **SCREENSHOT 4:** The benchmark summary table printed in the terminal.

#### 4. Assignment 2: FastAPI Interactive Web Dashboard
The script automatically starts the FastAPI service on port 8000:
```text
👉 Open the Dashboard in your browser:
   http://<master-ip>:8000
```
Open that URL in your browser to interact with:
* **Live KPI Cards:** Peak temp ($32.38^\circ\text{C}$ on April 18), total rainfall ($938.76\text{ mm}$), rainy days ($185$).
* **Timeseries Chart:** Interactive temperature vs humidity vs rainfall with seasonal filter dropdown.
* **Monsoon Bar Chart:** Monthly rainfall breakdown comparing South-West and North-East monsoons.
* **Thermal Comfort Scatter:** Thom's Discomfort Index ($DI$) distribution.
* **System Benchmarks Tab:** Visual graphs comparing Hive Text vs RCFile and Mongo Index vs CollScan.
* **5 Analytical Questions Tab:** Interactive accordion displaying the full findings.
* 📸 **SCREENSHOT 5:** The interactive web dashboard running live in the browser.

---

## 4. Local Laptop Execution (Testing at Home Without Hadoop)

You don't need Hadoop or 3 systems to test your code at home. All scripts have built-in local execution engines that you can run with `make`:

```bash
# Display all available Makefile commands:
make help

# 1. Run the full Assignment 1 pipeline (Data + Theme 1 + Theme 2 + Theme 3 + Analytics):
make assignment1

# 2. Or run individual themes:
make data        # Prepares and enriches NASA weather data
make theme1       # MongoDB aggregations & profiling
make theme2       # MapReduce streaming test
make theme3       # Hive Text vs RCFile benchmarks
make analytics    # 5 domain analytical questions

# 3. Launch the Assignment 2 FastAPI Dashboard:
make run          # (or make assignment2) -> open http://localhost:8000

# 4. Compile the PDF reports:
make reports
```

---

## 5. The 5 Distinct Analytical Inquiries (Viva & Presentation Answers)

When the faculty asks: *"What domain insights did you find on your weather dataset?"*, recite these:

1. **Question 1: Summer 2024 Heatwave Extremes**
   * *Answer:* Bengaluru experienced historical thermal extremes during the South Indian heatwave. Peak 24-hour daily mean reached **$32.38^\circ\text{C}$ on April 18, 2024** (afternoon highs exceeded $38.5^\circ\text{C}$). Over **23 days** recorded mean temperatures $\ge 30.0^\circ\text{C}$.
2. **Question 2: Monsoon Precipitation Distribution**
   * *Answer:* Bengaluru received **$938.76\text{ mm}$** of total annual rainfall across **185 rainy days**. The South-West Monsoon contributed **$448.91\text{ mm}$ ($47.8\%$)**, while the single wettest day occurred on **August 12, 2024 ($73.08\text{ mm}$)**.
3. **Question 3: Humidity-Temperature Dynamics & Discomfort**
   * *Answer:* Peak perceived thermal discomfort peaked at **$26.86^\circ\text{C}$ on May 3, 2024**, when high heat combined with $46.05\%$ humidity. During monsoon, relative humidity averaged $79.8\%$, elevating physiological discomfort.
4. **Question 4: Climatological Spell Analysis (Dry vs Wet Spells)**
   * *Answer:* Bengaluru suffered an unbroken dry spell of **93 consecutive rainless days** from **January 10 through April 11, 2024**, directly corroborating the documented city-wide groundwater crisis. The longest continuous rainy streak was **24 days** during July–August.
5. **Question 5: Cross-System Big Data Performance Profiling**
   * *Answer:* Columnar RCFile reduced Hive query execution time by **$52.4\%$ ($2.10\times\text{ speedup}$)** and compressed disk storage by **$66.0\%$**. In MongoDB, compound indexing yielded a **$7.82\times$ acceleration** over full collection scans.

---

## 6. Formula Reference for Viva

* **Thom's Discomfort Index ($DI$):**
  $$DI = T - (0.55 - 0.0055 \times RH) \times (T - 14.5)$$
  * $DI < 21$: Comfortable
  * $21 \le DI < 24$: Under 50% population feels discomfort
  * $24 \le DI < 27$: Over 50% population feels discomfort
  * $DI \ge 27$: Severe discomfort felt by all

---

## 7. Recompiling the LaTeX Reports

Both formal reports are pre-compiled and located in `reports/`:
* `reports/assignment1_report.pdf` (15 Marks – 3 Core Themes)
* `reports/assignment2_report.pdf` (10 Marks – Practical Extension)

If you update text or insert your lab screenshots, recompile them via:
```bash
cd reports
pdflatex -interaction=nonstopmode assignment1_report.tex
pdflatex -interaction=nonstopmode assignment2_report.tex
```

---

## 8. Summary Checklist Before Viva Demo:
* [x] 3 lab systems connected to the same LAN.
* [x] `bash lab_setup/setup_cluster.sh` executed on Master.
* [x] `hdfs dfsadmin -report` showing 2 Live DataNodes.
* [x] `bash lab_setup/run_all_themes.sh` completed on YARN.
* [x] Browser open to `http://<master-ip>:8000` showing the interactive dashboard.
* [x] Both printed/PDF reports ready for faculty evaluation.
