#!/bin/sh
PREREQ=""
prereqs()
{
        echo "$PREREQ"

}

case $1 in
prereqs)
        prereqs
        exit 0
        ;;
esac

. /scripts/functions
# Begin real processing below this line


LINE1="Updates file are available"
LINE2="Recived upgrade request"
LINE3="Staring upgrade at $(date)"
LINE4="Update files are not available"
LINE5="Upgrade complete at $(date)"
LINE7="Verifying upgrade files"


mount_partions() {
        sleep 1
        # Mount main rootfs as read write
        mount -o rw,remount ${rootmnt}/

        # Mount data partition on /overlay
        . ${rootmnt}/boot/boottime.rc
        if [[ -z "${DATA_fs}" ]]; then
                echo DATA_fs=$(readlink -f /dev/disk/by-label/data) >> ${rootmnt}/boot/boottime.rc
                sed -i 's/\/root//g' ${rootmnt}/boot/boottime.rc
        fi

        if [[ -z "${THINUX_fs}" ]]; then
                echo THINUX_fs=$(readlink -f /dev/disk/by-label/thinux) >> ${rootmnt}/boot/boottime.rc
                sed -i 's/\/root//g' ${rootmnt}/boot/boottime.rc
        fi

        # Start updating values in /boot/boottime.rc
        if [[ -z "${UPDATE_STATUS}" ]]; then
                echo UPDATE_STATUS=disk >> ${rootmnt}/boot/boottime.rc
        fi
        . ${rootmnt}/boot/boottime.rc
        fsck -a -C0 ${DATA_fs}
        mount ${DATA_fs} ${rootmnt}/overlay
        mount -o rw,remount ${rootmnt}/overlay

        # mount rootfs as read write
        mount -O ro ${THINUX_fs} ${rootmnt}/overlay/upgrade/ro/

        # mount overlay fs
        mount -t overlay -o lowerdir=${rootmnt}/overlay/upgrade/ro/,upperdir=${rootmnt}/overlay/upgrade/rw/,workdir=${rootmnt}/overlay/upgrade/wd/ overlay ${rootmnt}/overlay/upgrade/new/
        if [ "$?" != "0" ]; then
                echo "OVERLAY not mounted, Failed overlay"
                sleep 2
                exit 1
        fi
        mount -o rw,remount ${rootmnt}/overlay/upgrade/ro/
        # Change Update status in boottime.rc file
        . ${rootmnt}/boot/boottime.rc
        if [[ "$?" == 0 ]]; then
                sed -i -e "s/${UPDATE_STATUS}/mount/g" ${rootmnt}/boot/boottime.rc
                readonly TAR=$(ls ${rootmnt}/overlay | grep thinuxfs)
        else
                exit 1
        fi
}


clean_up() {
        echo ${LINE5} >> ${rootmnt}/boot/boottime.logs
        umount ${rootmnt}/overlay/upgrade/new/
        umount ${rootmnt}/overlay/upgrade/ro/
        umount -l ${rootmnt}/overlay/
        mount -o ro,remount ${rootmnt}/
}


start_update() {
        # Check UPGRADE value and install updates
        . ${rootmnt}/boot/boottime.rc

        if [ "$UPGRADE" == "1" ]; then
                # Call mount partition function
                mount_partions
                echo ${LINE2} >> ${rootmnt}/boot/boottime.logs
                #condition
                echo ${LINE3} >> ${rootmnt}/boot/boottime.logs
                clear
                echo "Starting upgrade......."
                rsync -ah --info=progress2 --delete --exclude 'boot/' ${rootmnt}/overlay/upgrade/new/ ${rootmnt}/overlay/upgrade/ro/
		rst=$?

                if [[ $rst -eq 0 ]]; then
                        sleep 1
                        sed -i 's/UPGRADE=1/UPGRADE=0/g' ${rootmnt}/boot/boottime.rc
                        echo ${LINE5} >> ${rootmnt}/boot/boottime.logs
                        sed -i -e "s/${UPDATE_STATUS}/update_complete/g" ${rootmnt}/boot/boottime.rc
                        rm -rf ${rootmnt}/overlay/upgrade/
                else
                        echo "Error during updates installation" >> ${rootmnt}/boot/boottime.logs
                fi
                clean_up && reboot -f

        else
                exit 0
        fi
}


start_update
