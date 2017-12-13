#!/bin/bash
#----------------------------------------------------------------------------------------------------------------------------
#Nagios Return codes:
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
#----------------------------------------------------------------------------------------------------------------------------
help () {
 echo "===================================="
 echo "MemSQL Hung Time Check"
 echo "===================================="
 echo "Author  : Sudharsan Soundararajan "
 echo "Version : 2.0"
 echo "Date    : 23/Aug/2017"
 echo "===================================="
 echo "Option:-"
 echo " -h host, "
 echo " -u username, "
 echo " -p password, "
 echo " -w Warning, "
 echo " -c Crtical, )"
 echo " -? help, "
 exit 0
}
#----------------------------------------------------------------------------------------------------------------------------
if [ $# -lt 3 ]
then
   help
   exitstatus=$STATE_UNKNOWN
   exit $exitstatus
fi
#----------------------------------------------------------------------------------------------------------------------------
# Argument Parse
while getopts ":u:p:h:w:c:" Option
do
 case $Option in
   u )
     USER=$OPTARG
     ;;
   p )
     PASSWORD=$OPTARG
     ;;
   h )
     HOST=$OPTARG
     ;;
   w )
     WARN=$OPTARG
     ;;
   c )
     CRIT=$OPTARG
     ;;
   ? )
     help
     ;;
 esac
done
#----------------------------------------------------------------------------------------------------------------------------
if ! type mysql > /dev/null ; then
        echo "Mysql command not found"
        exit $STATE_UNKNOWN
fi
#----------------------------------------------------------------------------------------------------------------------------
# Global Variable Declaration
declare -i count=0
HOST=0
ConnectionResult=`mysql -h $HOST -u $USER -p$PASSWORD -s -e "show databases;" 2>&1`
if [ "`echo "$ConnectionResult" | awk ' {print $1}'`" == "ERROR" ]; then
        echo -e "CRITICAL: Unable to connect to server $HOST with user-name '$USER' and given password"
        exit $STATE_CRITICAL
fi
#----------------------------------------------------------------------------------------------------------------------------
mysql -h $HOST -u $USER -p$PASSWORD -e "show processlist;" | sed 1d > /tmp/processlist
#----------------------------------------------------------------------------------------------------------------------------
# Lopping
while read i
do
host_name=$(echo $i | awk '{print $3}')
db_name=$(echo $i | awk '{print $4}')
command_name=$(echo $i | awk '{print $5}')
hungtime=$(echo $i | awk '{print $6}')
process_state=$(echo $i | awk '{print $7}')
	if [ "$hungtime" -ge "$WARN" -a "$hungtime" -lt "$CRIT" ]; then
		perfdata="'hungtime'=$hungtime ;$WARN;$CRIT;;"
		warndata="WARNING: Queries executing over $WARN seconds: HungTime - $hungtime (host_name: $host_name,db: $db_name,command: $command_name)"
		RESULT["WARNING"]="${RESULT["WARNING"]}${RESULT["WARNING"]:+,}$perfdata"
                count=1
        elif [ "$hungtime" -ge "$CRIT" ]; then
		perfdata="'hungtime'=$hungtime ;$WARN;$CRIT;;"
                critdata="CRITICAL: Queries executing over $CRIT Seconds: HungTime - $hungtime (host_name: $host_name,db: $db_name,command: $command_name)"
		RESULT["CRITICAL"]="${RESULT["CRITICAL"]}${RESULT["CRITICAL"]:+,}$perfdata"
                count=2
        else
		perfdata="'hungtime'=$hungtime ;$WARN;$CRIT;;"
		RESULT["OK"]="${RESULT["OK"]}${RESULT["OK"]:+,}$perfdata"
	fi
done< <( cat /tmp/processlist )
#----------------------------------------------------------------------------------------------------------------------------
# Condition Checks

if [ $count -eq 2 ]; then
    echo "$critdata | ${RESULT["CRITICAL"]}"
    exit $STATE_CRITICAL
fi

if [ $count -eq 1 ]; then
    echo "$warndata | ${RESULT["WARNING"]}"
    exit $STATE_WARNING
fi

if [ $count -eq 0 ]; then
    echo "OK: No Process Running Over the Threshold | ${RESULT["OK"]}"
    exit $STATE_OK
fi
#----------------------------------------------------------------------------------------------------------------------------
