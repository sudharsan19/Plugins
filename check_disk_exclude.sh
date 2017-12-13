#!/bin/bash

j=0; ok=0
warn=0; crit=0
TEMP_FILE="/tmp/df.$RANDOM.log"

## Help funcion
help() {
cat << END
Usage :
        check_disk.sh -w [VALUE] -c [VALUE] -x [Exclude]

        OPTION          DESCRIPTION
        ----------------------------------
        -h              Help
        -w [VALUE]      Warning Threshold
        -c [VALUE]      Critical Threshold
        -x [STRING]     Partition that needs to be excluded.
        ----------------------------------
Note : [VALUE] must be an integer.
END
}

## Validating and setting the variables and the input args
if [ $# -ne 6 ]
then
        help;
        exit 3;
fi

while getopts "x:n:w:c:" OPT
do
        case $OPT in
        w) WARN=$(echo "$OPTARG" | sed 's/%//g');;
        c) CRIT=$(echo "$OPTARG" | sed 's/%//g');;
        x) EXCLUDE="$OPTARG" ;;
        *) help ;;
        esac
done

COMMAND="/bin/df -Ph | grep -v $EXCLUDE"
## Sending the ssh request command and store the result into local log file
eval "$COMMAND"  > $TEMP_FILE.tmp
echo "`cat $TEMP_FILE.tmp | grep -v Used `" > $TEMP_FILE
EQP_FS="`cat $TEMP_FILE | grep -v Used | wc -l`"  # determine how many FS are in the server


FILE=$TEMP_FILE                 # read $file using file descriptors
exec 3<&0                       # save current stdin
exec 0<"$FILE"                  # change it to read from file.

  while read LINE; do           # use $LINE variable to process each line of file
      j=$((j+1))
                        FULL[$j]=`echo $LINE | awk '{print $2}'`
                        USED[$j]=`echo $LINE | awk '{print $3}'`
                        FREE[$j]=`echo $LINE | awk '{print $4}'`
                        FSNAME[$j]=`echo $LINE | awk '{print $6}'`
                        PERCENT[$j]=`echo $LINE | awk '{print $5}' | sed 's/[%]//g'`
                        FREEPERCENT[$j]=$(( 100 - ${PERCENT[$j]} ))
  done
exec 3<&0
rm $TEMP_FILE.tmp $TEMP_FILE

## According with the number of FS determine if the traceholds are reached (one by one)
for (( i=1; i<=$EQP_FS; i++ )); do

        if [ "${FREEPERCENT[$i]}" -gt "${WARN}" ]; then
                ok=$((ok+1))
        elif [ "${FREEPERCENT[$i]}" -eq "${WARN}" -o "${FREEPERCENT[$i]}" -lt "${WARN}" -a "${FREEPERCENT[$i]}" -gt "${CRIT}" ]; then
                warn=$((warn+1))
                WARN_DISKS[$warn]="${FSNAME[$i]} has ${PERCENT[$i]}% of utilization or ${USED[$i]} of ${FULL[$i]},"
        elif [ "${FREEPERCENT[$i]}" -eq "${CRIT}" -o "${FREEPERCENT[$i]}" -lt "${CRIT}" ]; then
                crit=$((crit+1))
                CRIT_DISKS[$crit]="${FSNAME[$i]} has ${PERCENT[$i]}% of utilization or ${USED[$i]} of ${FULL[$i]},"
        fi

done

## Set the data to show in the nagios service status
for (( i=1; i<=$EQP_FS; i++ )); do
        DATA[$i]="${FSNAME[$i]} ${PERCENT[$i]}% of ${FULL[$i]},"
        perf[$i]="${FSNAME[$i]}=${PERCENT[$i]}%;${WARN};${CRIT};0;;"
done

## Just validate and adjust the nagios output
if [ "$ok" -eq "$EQP_FS" -a "$warn" -eq 0 -a "$crit" -eq 0 ]; then
    echo "OK: DISK STATS: ${DATA[@]} | ${perf[@]}"
    exit 0
  elif [ "$warn" -gt 0 -a "$crit" -eq 0 ]; then
    echo "WARNING: DISK STATS: ${DATA[@]}_ Warning ${WARN_DISKS[@]}| ${perf[@]}"
    exit 1
  elif [ "$crit" -gt 0 ]; then
      #Validate if the Warning array is empty if so remove the Warning leyend
      if [ ${#WARN_DISKS[@]} -eq 0 ]; then
          echo "CRITICAL: DISK STATS: ${DATA[@]}_ Critical ${CRIT_DISKS[@]}| ${perf[@]}"
          exit 2
      else
          echo "CRITICAL: DISK STATS: ${DATA[@]}_ Warning ${WARN_DISKS[@]}_ Critical ${CRIT_DISKS[@]}| ${perf[@]}"
          exit 2
      fi
else
      echo "Unknown"
      exit 3
fi

