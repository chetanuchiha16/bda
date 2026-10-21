#!/usr/bin/env bash
# =============================================================================
# Plug-and-Play Hadoop 3-Node Cluster Auto-Configurator
# Group 17: Chetan Kishor C G (1JS23CS032) & Hongiran D (1JS23CS062)
# Course: BCS714D - Big Data Analytics
# =============================================================================

set -e

echo "=========================================================="
echo "  Hadoop 3-Node Cluster Setup - Group 17 (Plug & Play)  "
echo "=========================================================="

# 1. Prompt for Worker IP addresses
MASTER_IP=$(hostname -I | awk '{print $1}')
echo "[INFO] Detected Master Node IP: ${MASTER_IP}"

read -p "Enter Worker Node 1 IP: " WORKER1_IP
read -p "Enter Worker Node 2 IP: " WORKER2_IP
read -p "Enter Lab Username on all machines [default: $USER]: " LAB_USER
LAB_USER=${LAB_USER:-$USER}

# Detect HADOOP_HOME
HADOOP_DIR="${HADOOP_HOME:-/usr/local/hadoop}"
if [ ! -d "$HADOOP_DIR" ]; then
    echo "[WARN] Hadoop not found at ${HADOOP_DIR}. Checking ~/hadoop..."
    if [ -d "$HOME/hadoop" ]; then
        HADOOP_DIR="$HOME/hadoop"
    else
        echo "[ERROR] Hadoop directory not found. Please install Hadoop or set HADOOP_HOME."
        exit 1
    fi
fi
echo "[OK] Using Hadoop at: ${HADOOP_DIR}"
HADOOP_CONF="${HADOOP_DIR}/etc/hadoop"

# 2. Update /etc/hosts on Master
echo "[1/6] Configuring local /etc/hosts..."
sudo sed -i '/master-node/d;/worker-node-1/d;/worker-node-2/d' /etc/hosts
sudo tee -a /etc/hosts > /dev/null <<EOF
${MASTER_IP} master-node
${WORKER1_IP} worker-node-1
${WORKER2_IP} worker-node-2
EOF
echo "[OK] Updated /etc/hosts on Master."

# 3. Setup SSH Keys
echo "[2/6] Configuring Passwordless SSH..."
if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    ssh-keygen -t rsa -P "" -f "$HOME/.ssh/id_rsa"
fi
cat "$HOME/.ssh/id_rsa.pub" >> "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"

echo "Copying SSH keys to Worker Nodes (Enter passwords when prompted)..."
ssh-copy-id -o StrictHostKeyChecking=no "${LAB_USER}@worker-node-1" || true
ssh-copy-id -o StrictHostKeyChecking=no "${LAB_USER}@worker-node-2" || true

# Update /etc/hosts on workers via SSH
ssh "${LAB_USER}@worker-node-1" "echo '${MASTER_IP} master-node' | sudo tee -a /etc/hosts" || true
ssh "${LAB_USER}@worker-node-2" "echo '${MASTER_IP} master-node' | sudo tee -a /etc/hosts" || true

# 4. Generate core-site.xml
echo "[3/6] Generating core-site.xml..."
cat <<EOF > "${HADOOP_CONF}/core-site.xml"
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://master-node:9000</value>
    </property>
</configuration>
EOF

# 5. Generate hdfs-site.xml
echo "[4/6] Generating hdfs-site.xml..."
HDFS_DATA_DIR="$HOME/hadoop_cluster_data"
mkdir -p "${HDFS_DATA_DIR}/namenode" "${HDFS_DATA_DIR}/datanode"

cat <<EOF > "${HADOOP_CONF}/hdfs-site.xml"
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>2</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file://${HDFS_DATA_DIR}/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file://${HDFS_DATA_DIR}/datanode</value>
    </property>
</configuration>
EOF

# 6. Generate yarn-site.xml
echo "[5/6] Generating yarn-site.xml and workers..."
cat <<EOF > "${HADOOP_CONF}/yarn-site.xml"
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>master-node</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
</configuration>
EOF

# Update workers file
cat <<EOF > "${HADOOP_CONF}/workers"
worker-node-1
worker-node-2
EOF

# Distribute configs to workers
echo "Distributing configuration files to workers..."
scp "${HADOOP_CONF}/core-site.xml" "${HADOOP_CONF}/hdfs-site.xml" "${HADOOP_CONF}/yarn-site.xml" "${LAB_USER}@worker-node-1:${HADOOP_CONF}/" || true
scp "${HADOOP_CONF}/core-site.xml" "${HADOOP_CONF}/hdfs-site.xml" "${HADOOP_CONF}/yarn-site.xml" "${LAB_USER}@worker-node-2:${HADOOP_CONF}/" || true

# 7. Format & Start
echo "[6/6] Formatting NameNode and Starting Services..."
hdfs namenode -format -force || true
start-dfs.sh
start-yarn.sh

echo ""
echo "=========================================================="
echo "  CLUSTER STATUS VERIFICATION (Take Screenshot for Report)"
echo "=========================================================="
echo "Master Daemons:"
jps
echo ""
echo "HDFS Node Report:"
hdfs dfsadmin -report
echo ""
echo "[SUCCESS] Cluster is LIVE!"
echo "NameNode Web UI : http://${MASTER_IP}:9870"
echo "YARN Web UI     : http://${MASTER_IP}:8088"
