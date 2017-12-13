#!/bin/bash
#####################################################
#Author: Sudharsan Soundararajan
#Version: 1.2
#Date: March 22 2017
#Description: This Plugin used to check for the MySQLDB
#version 1.1 - added the warning and critical threshold in seconds.
######################################################
#Return codes:
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
if ! type mysql > /dev/null ; then
	echo "Mysql command not found"
	exit $STATE_UNKNOWN
fi
#declaring global variable
declare -i count=0
HOST=0
#####################################################
usage()
{ echo "Script to monitor the MySQLDB DDL process status" echo "Usage:" echo "$0 [-u username] [-p password] [-h hostname (default:0)] -w 900 (in seconds) -c 1200 (in seconds) " echo "Examples:" echo "$0 -u root -p xxxx -h 127.0.0.1 -w 900 -c 1200" exit $STATE_UNKNOWN }
#####################################################
while getopts ":u:p:h:w:c:" opt; do
	case $opt in
		u ) USER=$OPTARG ;;
		p ) PASSWORD=$OPTARG
		if [[ $OPTARG == "-h" || $OPTARG == "" || $OPTARG == "-u" ]] ; then
			usage
			exit $STATE_UNKNOWN
		fi
		;;
		h ) HOST=$OPTARG ;;
		w ) WARNING=$OPTARG ;;
		c ) CRITICAL=$OPTARG ;;
		?) usage
		exit $STATE_UNKNOWN
	esac
done
#####################################################
if [ $# -lt 5 ] ; then
	usage
	exit $STATE_UNKNOWN
fi
#####################################################
ConnectionResult=`mysql -h $HOST -u $USER -p$PASSWORD -s -e "show databases;" 2>&1`
if [ "`echo "$ConnectionResult" | awk ' {print $1}'`" == "ERROR" ]; then
	echo -e "CRITICAL: Unable to connect to server $HOST with user-name '$USER' and given password"
	exit $STATE_CRITICAL
fi
#########################################################################################################
mysql -h $HOST -u $USER -p$PASSWORD -e "show processlist;" | sed 1d > /tmp/processlist
##########################################################################################################
while read i
do
	host_name=$(echo $i | awk '{print $3}')
	db_name=$(echo $i | awk '{print $4}')
	command_name=$(echo $i | awk '{print $5}')
	hungtime=$(echo $i | awk '{print $6}')
	process_state=$(echo $i | awk '{print $7}')
	if [ "$hungtime" -ge "$WARNING" -a "$hungtime" -lt "$CRITICAL" -a "$process_state" == "executing" ]; then
		echo "WARNING: Queries executing over $WARNING seconds: HungTime - $hungtime (host_name: $host_name,db: $db_name,command: $command_name)"
		count=1
	elif [ "$hungtime" -ge "$CRITICAL" -a "$process_state" == "executing" ]; then
		echo "CRITICAL: Queries executing over $CRITICAL Seconds: HungTime - $hungtime (host_name: $host_name,db: $db_name,command: $command_name)"
		count=2
	fi
done< <( cat /tmp/processlist )
##########################################################################################################
if [ $count -eq 1 ]; then
exit $STATE_WARNING
fi
if [ $count -eq 2 ]; then
exit $STATE_CRITICAL
fi
if [ $count -eq 0 ]; then
echo "OK:No Process Running Over the Threshold"
exit $STATE_OK
fi
