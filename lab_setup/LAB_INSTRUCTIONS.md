# College Lab Quick Execution Guide (Plug & Play)
**Group 17:** Chetan Kishor C G (`1JS23CS032`) & Hongiran D (`1JS23CS062`)  
**Assigned Dataset:** NASA POWER Daily Weather — Bengaluru, 2024

---

## What to Do When You Sit at the 3 College Lab Computers

### Step 1: On the 2 Worker PCs (Takes 30 seconds)
1. Turn on the PC and open Terminal.
2. Note its IP address:
   ```bash
   hostname -I
   ```
   *(e.g., Worker 1 is `192.168.1.15`, Worker 2 is `192.168.1.16`)*.

---

### Step 2: On the Master PC (Your Main Computer)
1. Clone or copy your `bda` folder to the Master PC.
2. Open Terminal in `bda/` and run the cluster auto-configurator:
   ```bash
   bash lab_setup/setup_cluster.sh
   ```
   * It will ask for:
     * **Worker 1 IP**
     * **Worker 2 IP**
     * **Lab user password** (to copy SSH keys)
   * It will configure `/etc/hosts`, generate Hadoop XML files (`core-site.xml`, `hdfs-site.xml`, `yarn-site.xml`, `workers`), distribute them to both workers via `scp`, format NameNode, and start HDFS + YARN.

3. **Take Screenshot #1**: The script will print `jps` and `hdfs dfsadmin -report` showing **Live datanodes (2)**! Also open `http://localhost:9870` in browser.

---

### Step 3: Run All Themes & Launch Dashboard (One Command)
Still on the Master PC, run:
```bash
bash lab_setup/run_all_themes.sh
```
* **Theme 1:** Ingests weather documents into MongoDB, builds indexes, runs `$match`, `$group`, `$project`, `$unwind`, `$facet` pipelines, and profiles `COLLSCAN` vs `IXSCAN` (Take Screenshot #2).
* **Theme 2:** Uploads to HDFS and submits the MapReduce job to YARN across Worker 1 and Worker 2 (Take Screenshot #3 from `http://localhost:8088`).
* **Theme 3:** Runs Hive RCFile vs Standard Text benchmarks (Take Screenshot #4).
* **Assignment 2:** Starts the FastAPI dashboard and prints:
  ```text
  👉 Open the Dashboard in your browser:
     http://<master-ip>:8000
  ```

Open that link on the Master PC (or from your phone/laptop on lab Wi-Fi) to view and demo the live interactive weather dashboard!
