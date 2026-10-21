important Instruction: All three assignment themes must be executed using a distributed computing environment configured with a multi-node Hadoop cluster, rather than on a single system. Utilize the available college lab systems to set up and run the distributed environment.

Official Hadoop Cluster Setup Guide - For your reference: https://apache.github.io/hadoop/hadoop-project-dist/hadoop-common/ClusterSetup.html


1. Hardware and Network Setup
Utilize at least three lab systems connected to the same network.
Configure one Master Node and the remaining systems as Worker Nodes.
Configure hostnames, network connectivity, and SSH access.
Install compatible Java and the same Hadoop version on all nodes.

2. Configure and Start Hadoop

Configure the required Hadoop configuration files.
Add worker hostnames to the Hadoop `workers` file.
Configure HDFS storage directories and permissions.
Initialize the NameNode and start HDFS and YARN.
Verify that all worker nodes are registered and operational.
3. Execute the Assignment Themes


Theme 1 — MongoDB Analytics:Perform document ingestion, indexing, aggregation pipeline operations, and query performance profiling.
Theme 2 — Hadoop File Management & MapReduce:Perform HDFS file operations and execute Java or Python Streaming MapReduce jobs using YARN.
Theme 3 — Pig & Hive Analytics: Use Pig Latin for data transformation and Hive for Text and RCFile storage, analytical queries, and performance comparisons.

Ensure that all required technologies are configured to work with the shared distributed environment wherever applicable.

4. Verification
Verify HDFS and YARN services, confirm that the worker nodes are active, and execute a sample distributed MapReduce job before proceeding with the assignments.