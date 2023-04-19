CREATE DATABASE `ambari_metrics` CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_general_ci';

CREATE TABLE metrics (
    id INT NOT NULL AUTO_INCREMENT COMMENT 'Primary Key',
    timestamp DATETIME NOT NULL COMMENT 'Timestamp of the metric value',
    hdfs_used_space FLOAT NOT NULL COMMENT 'HDFS used space (in GB)',
    hdfs_total_space FLOAT NOT NULL COMMENT 'HDFS total space (in TB)',
    namenode_count INT NOT NULL COMMENT 'Number of NameNodes',
    datanode_count INT NOT NULL COMMENT 'Number of DataNodes',
    cpu_total_cores INT NOT NULL COMMENT 'Total number of CPU cores in the cluster',
    memory_total_size FLOAT NOT NULL COMMENT 'Total memory size of all nodes in the cluster (in GB)',
    disk_total_size FLOAT NOT NULL COMMENT 'Total disk size of all nodes in the cluster (in TB)',
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Table for storing Ambari metric data';
