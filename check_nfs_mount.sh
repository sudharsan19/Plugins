#!/bin/bash
declare -a nfs_mounts=( $(grep -v ^\# /etc/fstab |grep nfs |awk '{print $2}') )
declare -a MNT_STATUS
declare -a SFH_STATUS
for mount_type in ${nfs_mounts[@]} ; do
	if [ $(stat -f -c '%T' ${mount_type}) = nfs ]; then
		read -t3 < <(stat -t ${mount_type})
			if [ $? -ne 0 ]; then
			SFH_STATUS=("${SFH_STATUS[@]}" "ERROR: ${mount_type} might be stale.")
			else
			MNT_STATUS=("${MNT_STATUS[@]}" "OK: ${mount_type} is ok.")
			fi
		else
		MNT_STATUS=("${MNT_STATUS[@]}" "ERROR: ${mount_type} is not properly mounted.")
fi
done
echo ${MNT_STATUS[@]} ${SFH_STATUS[@]} |grep -q ERROR
	if [ $? -eq 0 ]; then
		RETVAL=2
        echo "CRITICAL - NFS mounts may be stale or unavailable"
	else
		RETVAL=0
        echo "OK - NFS mounts are functioning within normal operating parameters"
	fi
unset -v MNT_STATUS
unset -v SFH_STATUS
exit ${RETVAL}
