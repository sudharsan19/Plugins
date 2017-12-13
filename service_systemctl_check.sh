#!/bin/bash

PLUGINDIR=$(dirname $0)
. $PLUGINDIR/utils.sh


if [[ $# -ne 1 ]]; then
    echo "Usage: ${0##*/} <service name>"
    exit $STATE_UNKNOWN
fi

service=$1


status=$(systemctl is-enabled $service 2>/dev/null)
r=$?
if [[ -z "$status" ]]; then
    echo "ERROR: service $service doesn't exist"
    exit $STATE_CRITICAL
fi

if [[ $r -ne 0 ]]; then
    echo "ERROR: service $service is $status"
    exit $STATE_CRITICAL
fi


systemctl --quiet is-active $service
if [[ $? -ne 0 ]]; then
    echo "ERROR: service $service is not running"
    exit $STATE_CRITICAL
fi

echo "OK: service $service is running"
exit $STATE_OK
