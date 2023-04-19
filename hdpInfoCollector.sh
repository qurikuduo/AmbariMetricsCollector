#/bin/bash

# Please change the ambari ip address, port number, 
# ambari user and password and mysql configuration at first.
# MySQL config
DB_HOST="localhost"
DB_PORT=3306
DB_USER="root"
DB_PASS="password"
DB_NAME="ambari_metrics"

# ambari username
username='admin'
# ambari password
password='admin'

#default cluster 0
clusterIndex=0
#default ambari manager host
ambariHost='192.168.88.144'
#default ambari manager port
ambariPort=8080
#default ambari manager URL
ambariUrl='http://'${ambariHost}':'${ambariPort}'/api/v1/clusters/'

#
cmd_base='curl --silent -X GET -u '${username}':'${password}' '${ambariUrl}

#echo ${cmd_base}



cmd_get_cluster=" | jq '.items[0].Clusters.cluster_name'"
#default cluster 0
cmd_tmp=${cmd_base}' '${cmd_get_cluster}
#base url of all request 
cmd_cluster_base=$(eval "$cmd_tmp")


#delete all quator
cmd_cluster_base=`echo ${cmd_cluster_base#\"} | sed 's/\"$//'`
cmd_cluster_base=${cmd_base}${cmd_cluster_base}'/'
#echo $cmd_cluster_base

function dtNow {
	echo $(eval "date +%Y-%m-%d'-'%H-%M-%S.%N")
}

# get now datetime
# dt=$(dtNow)
#echo $dt

# get all nodes
function getNodeInfo {
	#echo $1
	_cmd_tmp=$1
	_cmd_tmp=$_cmd_tmp"hosts/  | jq -r '.items[].href'"
	#echo $_cmd_tmp
	echo $(eval "$_cmd_tmp")
}

allNodes=$(getNodeInfo "$cmd_cluster_base")

# Convert String to Array
arrNodes=($allNodes)

# Get the number of elements of the array
#array_length=${#arrNodes[@]}

# print the number of elements of the array
#echo "the number of elements of the array: $array_length"

#cpu cores
cpu_cores=0
#num in MBs
ram_total=0
#total in KB
disk_total=0

# Loop through all nodes
for i in "${arrNodes[@]}"
do
	########获取CPU核数#######
	#echo $i
	dt=$(dtNow)
	_file='/tmp/hadoop_dn_info_'$dt
	`curl --silent -X GET -u ${username}':'${password} -o $_file $i`
	_cpu_cores=`cat $_file | jq ".Hosts.cpu_count"`
	#echo $_cpu_cores
	cores=$((_cpu_cores+0))
	#echo $cores
	cpu_cores=$(($cpu_cores + $cores))
	#echo $cpu_cores
	########获取CPU核数#######
	
	########获取内存数#######
	#echo $i	
	_ram_total=`cat $_file | jq ".Hosts.total_mem"`
	#echo $_ram_total
	ram=$((_ram_total+0))
	#echo $cores
	ram_total=$(($ram_total + $ram))
	#echo $ram_total
	########获取内存数#######
		
	########获取磁盘大小#######
	#echo $i	
	_disk_list=`cat $_file | jq -r ".Hosts.disk_info[].size"`
	_arrDisks=($_disk_list)
	_disk_total=0
	# 循环打印数组元素
	for j in "${_arrDisks[@]}"
	do
		_disk_total=$(($j+0))
		
	done
	disk_total=$(($disk_total + $_disk_total))
	#echo $disk_total
	
	#echo $ram_total
	########获取磁盘大小#######
	#删除文件
	`rm -rf $_file`
done

echo "disk_total: "$disk_total"KB"
echo "ram_total: "$ram_total"KB"
echo "cpu_cores: "$cpu_cores


# Get the number of master nodes
#services/HDFS/components/NAMENODE

dt=$(dtNow)
_file='/tmp/hadoop_nn_info_'$dt
#echo $cmd_cluster_base"services/HDFS/components/NAMENODE"
`$cmd_cluster_base"services/HDFS/components/NAMENODE"  -o $_file `


# Get the number of NameNode Nodes
allNameNodesCount=`cat $_file | jq '.ServiceComponentInfo.total_count'`


# Get HDFS info

# HDFS capacity
allHdfsSize=`cat $_file | jq  '.ServiceComponentInfo.CapacityTotal'`
echo "allHdfsSize: "$allHdfsSize'Bytes'

# HDFS capacity used 
usedHdfsSize=`cat $_file | jq  '.ServiceComponentInfo.CapacityUsed'`
echo "usedHdfsSize: "$usedHdfsSize'Bytes'

# delete file
`rm -rf $_file`
echo "allNameNodesCount: "$allNameNodesCount



# Get the number of DataNode Nodes
#services/HDFS/components/DATANODE
dt=$(dtNow)
_file='/tmp/hadoop_dn_info_'$dt
#echo $cmd_cluster_base"services/HDFS/components/DATANODE"
`$cmd_cluster_base"services/HDFS/components/DATANODE"  -o $_file `
# All DataNode Nodes
allDataNodesCount=`cat $_file | jq ".ServiceComponentInfo.total_count"`

echo "allDataNodesCount: "$allDataNodesCount

# delete file
`rm -rf $_file`

# get now datetime
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
#echo "disk_total: "$disk_total"KB"
#echo "ram_total: "$ram_total"KB"
#echo "cpu_cores: "$cpu_cores
#$allNameNodesCount
#$allHdfsSize'Bytes'
#$usedHdfsSize'Bytes'

disk_total=$(echo "scale=2;($disk_total / 1024 / 1024  / 1024)" | bc)
ram_total=$(echo "scale=2;($ram_total / 1024 / 1024 )" | bc)
allHdfsSize=$(echo "scale=2;($allHdfsSize / 1024 / 1024 / 1024 / 1024)" | bc)
usedHdfsSize=$(echo "scale=2;($usedHdfsSize / 1024 / 1024 / 1024 )" | bc)
echo "disk_total: "$disk_total"TB ram_total: "$ram_total"GB allHdfsSize: "$allHdfsSize"TB usedHdfsSize: "$usedHdfsSize"GB"

# insert into database
mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME -e "INSERT INTO metrics (timestamp, hdfs_used_space, hdfs_total_space, namenode_count, datanode_count, cpu_total_cores, memory_total_size, disk_total_size) VALUES ('$TIMESTAMP', $usedHdfsSize,$allHdfsSize,$allNameNodesCount,$allDataNodesCount,$cpu_cores,$ram_total,$disk_total);"


#echo $allNodes

