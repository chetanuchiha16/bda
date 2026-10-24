#!/usr/bin/env bash
set -e

# Export environment variables for non-interactive SSH sessions and Hadoop root daemons
export HDFS_NAMENODE_USER=root
export HDFS_DATANODE_USER=root
export HDFS_SECONDARYNAMENODE_USER=root
export YARN_RESOURCEMANAGER_USER=root
export YARN_NODEMANAGER_USER=root

env | grep -E "JAVA_HOME|HADOOP_HOME|HADOOP_CONF_DIR|HDFS_|YARN_|PATH" >> /etc/environment

# Start SSH daemon
service ssh start

if [ "$ROLE" = "master" ]; then
    echo "=========================================================="
    echo "  Starting Master Node (NameNode + ResourceManager)..."
    echo "=========================================================="
    
    # Wait for workers to be reachable via SSH
    echo "Waiting for worker nodes to become reachable..."
    until ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no root@worker-node-1 hostname > /dev/null 2>&1; do
        sleep 2
    done
    until ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no root@worker-node-2 hostname > /dev/null 2>&1; do
        sleep 2
    done
    echo "[OK] All worker nodes reachable via SSH."

    # Format NameNode if not formatted
    if [ ! -d "/hadoop/data/hdfs/namenode/current" ]; then
        echo "[INFO] Formatting NameNode for the first time..."
        $HADOOP_HOME/bin/hdfs namenode -format -force
    fi

    # Start DFS and YARN
    $HADOOP_HOME/sbin/start-dfs.sh
    $HADOOP_HOME/sbin/start-yarn.sh

    echo "[SUCCESS] Distributed Hadoop Cluster is active!"
    echo "Active Daemons on Master:"
    jps

    # Ensure log directory exists and keep container alive
    mkdir -p $HADOOP_HOME/logs
    touch $HADOOP_HOME/logs/master.log
    tail -f $HADOOP_HOME/logs/*.log 2>/dev/null || sleep infinity

elif [ "$ROLE" = "worker" ]; then
    echo "=========================================================="
    echo "  Worker Node ($HOSTNAME) Ready. Waiting for Master..."
    echo "=========================================================="
    tail -f /dev/null
else
    exec "$@"
fi
