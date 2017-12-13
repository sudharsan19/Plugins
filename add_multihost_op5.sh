#!/bin/bash
#
        #The hosts.txt file should consists of hostname and ipaddress as below:
        #HOSTNAME:IPADDRESS:FILEID:HOSTGROUP
        #hostname:1.2.3.4:etc\/hosts.cfg:hostgroup
#
#set -x
if [ -f hosts.txt ];then

        USER="ldap_username"
        PASS="ldap_passwd"
        hosts=`cat hosts.txt`
        for x in $hosts
        do
            HOST=`echo $x | cut -d":" -f1`
            ALIAS=`echo $x | cut -d":" -f1`
            IPADDRESS=`echo $x | cut -d":" -f2`
            FILEID=`echo $x | cut -d":" -f3`
            HOST_GROUP=`echo $x | cut -d":" -f4`
            OP5_MASTER= 127.0.0.1 ##<< Op5 master IP / CNAME 
            IFS='_' read -ra HG <<< "${HOST_GROUP}"
            echo "`date '+%D %T'` :- Adding host $HOST to OP5 Monitoring."
            echo "+++++++++++++++++++++++++++++++++++++++++++"
            echo HOST = ${HOST}
            echo ALIAS = ${HOST}
            echo FILEID = ${FILEID}
            echo IPADDRESS = ${IPADDRESS}
            echo HOSTGROUP = ${HOST_GROUP}
            echo MASTER = ${OP5_MASTER}
            echo "+++++++++++++++++++++++++++++++++++++++++++"
            curl -k -H 'content-type: application/json' -d '{"template": "hoststatus", "host_name": "'"$HOST"'", "file_id": "'"$FILEID"'","alias": "'"$ALIAS"'","address": "'"$IPADDRESS"'","hostgroups": ["'"$HOST_GROUP"'"],"_SEV": "4", "_VMOWNER": "[UNKNOWN]","_PARTNER": "'"${HG[0]}"'","_ECO": "'"${HG[1]}"'","_DC":"'"${HG[2]}"'","_REGION":"'"${HG[3]}"'","_MARKET":"'"${HG[4]}"'","_COMPONENT":"'"${HG[5]}"'","_SUB_COMP":"'"${HG[6]}"'" }' "https://$OP5_MASTER/api/config/host" -u "$USER\$LDAP:$PASS"
        done
            curl -k -X POST "https://$OP5_MASTER/api/config/change" -u "$USER\$LDAP:$PASS"
fi
