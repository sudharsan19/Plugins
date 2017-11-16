#command[kafka_lag_count]=sudo /bin/bash /usr/lib64/nagios/plugins/check_kafka_lag -g $ARG1$ -z $ARG2$ -T $ARG3$ -w $ARG4$ -c $ARG5$

#!/bin/bash

# Return codes:
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3


usage() {
        echo "Script to monitor the kafka Partition Status"
        echo "Usage:"
        echo "$0 [-g groupname] [-z zookeeper] [-T topic)] [-c critical count ]"
        echo " Sample Run : bash check_kafka_lag -g kafka2hdfs -z internal.sandbox.net:2181 -T clean.xxxxx.xxxx.EnrichedEvent -w 219357981 -c 30000000"
        exit $STATE_UNKNOWN
}

#decalring global variable
declare -i count=0
WARNING_LAG_COUNT=3000000
CRITICAL_LAG_COUNT=6000000
while getopts ":g:z:T:w:c:" opt; do
        case $opt in
                g )     GROUP=$OPTARG ;;
                z )     ZK=$OPTARG ;;
                T )     TOPIC=$OPTARG ;;
                w )     WARNING_LAG_COUNT=$OPTARG ;;
                c )     CRITICAL_LAG_COUNT=$OPTARG ;;
                \?)     usage
                        exit $STATE_UNKNOWN
        esac
done

if [ $# -lt 5 ] ; then
        usage
        exit $STATE_UNKNOWN
fi

while read -r output;
do
        LAG_PARTITION=$( echo "$output" | awk '{print $3}' | sed 's/,$//' )
        LAG_COUNT=$( echo "$output" | awk '{print $6}' | sed 's/,$//')
        GROUP_NAME=$( echo "$output" | awk '{print $1}' | sed 's/,$//')
        TOPIC_NAME=$( echo "$output" | awk '{print $2}' | sed 's/,$//' )
        NODE_NAME=$( echo "$output" | awk '{print $7}' )
        if [[ $LAG_COUNT -gt $CRITICAL_LAG_COUNT ]]; then
                echo "CRITICAL: Partition: $LAG_PARTITION is Lagging with Lag Count: $LAG_COUNT, Group Name: $GROUP_NAME , Topic Name: $TOPIC_NAME, Node: $NODE_NAME"
                count=1
        fi
        if [[ $LAG_COUNT -ge $WARNING_LAG_COUNT && $LAG_COUNT -lt $CRITICAL_LAG_COUNT ]]; then
                echo "WARNING : Partition: $LAG_PARTITION is Lagging with Lag Count: $LAG_COUNT, Group Name: $GROUP_NAME , Topic Name: $TOPIC_NAME, Node: $NODE_NAME"
                count=2
        fi

done< <( sudo /opt/kafka/bin/kafka-consumer-groups.sh --describe --group "$GROUP" --zookeeper "$ZK" | grep -i "$TOPIC" |column -t )

if [ $count -eq 1 ]; then
        exit $STATE_CRITICAL
fi

if [ $count -eq 2 ]; then
        exit $STATE_WARNING
fi

if [[ $count -eq 0 && $LAG_COUNT -lt $CRITICAL_LAG_COUNT ]]; then
        echo "OK: All the Kafka Partitions are healthy and no lag in the partition table"
        exit $STATE_OK
fi
