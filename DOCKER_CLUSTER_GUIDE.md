# 3-Node Virtual Hadoop Cluster on Docker Guide
**Group 17:** Chetan Kishor C G (`1JS23CS032`) & Hongiran D (`1JS23CS062`)  
**Course:** BCS714D — Big Data Analytics  
**Dataset:** NASA POWER Daily Weather — Bengaluru, 2024

---

## Why Use Docker Instead of 3 Physical Lab PCs?

Using Docker allows you to run the **exact same 3-node distributed architecture** on your own laptop without needing to borrow 3 physical computers in the lab:

1. **3 Isolated Virtual Systems on a Dedicated Subnet (`172.20.0.0/16`):**
   * **`bda-master-node` (`172.20.0.10`):** NameNode, SecondaryNameNode, YARN ResourceManager.
   * **`bda-worker-node-1` (`172.20.0.11`):** DataNode, NodeManager.
   * **`bda-worker-node-2` (`172.20.0.12`):** DataNode, NodeManager.
   * **`bda-mongodb` (`172.20.0.20`):** MongoDB 7.0 database service.
2. **Identical Output:**
   * Running `hdfs dfsadmin -report` inside the master container outputs:
     `Live datanodes (2): worker-node-1, worker-node-2`
   * The NameNode UI (`http://localhost:9870`) shows **2 Live DataNodes**.
   * The YARN UI (`http://localhost:8088`) displays **2 Active NodeManagers**.
   * The screenshots you capture from these UIs look **100% identical** to those taken from 3 physical computers.

---

## Step 1: Ensure Docker Daemon is Running

On your Fedora laptop, Docker might be stopped. Start it with:

```bash
sudo systemctl start docker
```
*(To enable it automatically on boot: `sudo systemctl enable docker`)*

---

## Step 2: Build & Start the Cluster

From your `bda/` project root directory, run:

```bash
make cluster-up
```
*(Or manually: `docker compose up -d --build`)*

**What happens automatically:**
* Builds the `bda-hadoop:3.3.6` container image with Java 11 and Hadoop 3.3.6.
* Configures passwordless root SSH keys between master and workers.
* Formats the HDFS NameNode automatically.
* Boots `master-node`, `worker-node-1`, `worker-node-2`, and `mongodb`.
* Launches HDFS (`start-dfs.sh`) and YARN (`start-yarn.sh`).

---

## Step 3: Check Cluster Health & Web UIs

To check the cluster status and verify the 2 worker datanodes:

```bash
make cluster-status
```

Open these links in your laptop browser:
* **HDFS NameNode UI:** [http://localhost:9870](http://localhost:9870)  
  *(Shows Live Datanodes = 2, total cluster capacity, block distribution)*
* **YARN ResourceManager UI:** [http://localhost:8088](http://localhost:8088)  
  *(Shows Active Nodes = 2, cluster memory, and CPU virtual cores)*

📸 **SCREENSHOT #1:** Capture `http://localhost:9870` showing **Live Nodes: 2**.

---

## Step 4: Run All Themes Inside the Distributed Cluster

To submit the distributed MapReduce job to YARN across `worker-node-1` and `worker-node-2` and ingest into MongoDB:

```bash
make cluster-run
```

**What this executes inside the cluster:**
1. Checks `hdfs dfsadmin -report`.
2. Creates HDFS directory `/user/bda/weather/input` and uploads the weather TSV.
3. Submits the Python Streaming MapReduce job to YARN:
   * Maps daily records to `Month` and `Season`.
   * YARN schedules and runs mapper and reducer containers on the worker nodes.
   * Outputs aggregated monthly results to HDFS.
4. Ingests weather documents into the containerized MongoDB service (`mongodb://mongodb:27017`), creates B-Tree indexes, and runs `.explain("executionStats")` profiling.

📸 **SCREENSHOT #2:** Terminal showing `.explain("executionStats")` indexing speedup.  
📸 **SCREENSHOT #3:** YARN UI at [http://localhost:8088](http://localhost:8088) showing job marked **SUCCEEDED**.

---

## Step 5: Launch the Assignment 2 Web Dashboard

Start the FastAPI frontend on your host machine:

```bash
make run
```

Then open your browser to:  
👉 **[http://localhost:8000](http://localhost:8000)**

📸 **SCREENSHOT #4 & #5:** Capture the interactive dashboard showing the KPI cards, daily timeseries chart, monthly rain distribution, and the 5 analytical questions!

---

## Useful Helper Commands

| Command | Description |
| :--- | :--- |
| **`make cluster-up`** | Starts all 4 containers in the background |
| **`make cluster-status`** | Displays container state and runs `hdfs dfsadmin -report` |
| **`make cluster-run`** | Executes distributed MapReduce and MongoDB jobs |
| **`make cluster-sh`** | Drops into an interactive bash shell inside the master container |
| **`make cluster-down`** | Stops and tears down the virtual cluster containers |
| **`make clean`** | Cleans build caches and temporary logs |
