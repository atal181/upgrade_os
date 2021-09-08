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
#Logs of tar in $rootmnt/boot/boottime.logs file

LINE1="Updates file are available"
LINE2="Recived upgrade request"
LINE3="Staring upgrade at $(date)"
LINE4="Update files are not available"
LINE5="Upgrade complete at $(date)"
LINE7="Verifying upgrade files"
LINE8="Verification passed. Starting upgrade"

mount_partions() {
    # Mount main rootfs as readonly
    mount -o rw,remount ${rootmnt}/

    # Check disk lable of data partions and mount it on overlay
    . ${rootmnt}/boot/boottime.rc
    if [[ -z "${DATA_fs}" ]]; then
        echo DATA_fs=$(readlink -f /dev/disk/by-label/data) >> ${rootmnt}/boot/boottime.rc
        sed -i 's/\/root//g' ${rootmnt}/boot/boottime.rc
    fi

    # Start updating values in /boot/boottime.rc
    if [[ -z "${UPDATE_STATUS}" ]]; then
        echo UPDATE_STATUS=disk >> ${rootmnt}/boot/boottime.rc
    fi
    fsck -a -C0 ${DATA_fs}
    mount ${DATA_fs} ${rootmnt}/overlay
    # Change Update status in boottime.rc file
    . ${rootmnt}/boot/boottime.rc
    if [[ "$?" == 0 ]]; then
        sed -i -e "s/${UPDATE_STATUS}/mount/g" ${rootmnt}/boot/boottime.rc
        readonly TAR=$(ls ${rootmnt}/overlay | grep thinuxfs)
    else
        exit 1
    fi

}


condition() {
    # find update files partition
    if [ -n "$TAR" ]; then
       echo ${LINE1} > ${rootmnt}/boot/boottime.logs
       echo ${LINE7} >> ${rootmnt}/boot/boottime.logs
       echo
       echo "Verifying update files......"
       md5sum -c ${rootmnt}/overlay/md5*
    else
       echo ${LINE4} > ${rootmnt}/boot/boottime.logs
       echo "Update file not found"
       echo "Aborting......."
       exit 0
    fi

    if [ "$?" == "0"  ]; then
       echo ${LINE8} >> ${rootmnt}/boot/boottime.logs
       sed -i -e "s/${UPDATE_STATUS}/checksum/g" ${rootmnt}/boot/boottime.rc
    else
       exit 1
    fi

}


clean_up() {
    echo ${LINE5} >> ${rootmnt}/boot/boottime.logs
    mount -o rw,remount ${rootmnt}/overlay
    rm -rf ${rootmnt}/overlay/${TAR}
    rm -rf ${rootmnt}/overlay/md5*
    umount -l ${rootmnt}/overlay
    mount -o ro,remount ${rootmnt}/
}


start_update() {
    # Check UPGRADE value and install updates
    . ${rootmnt}/boot/boottime.rc

    if [ "$UPGRADE" == "1" ]; then
        # Call mount partition function
        mount_partions
        echo ${LINE2} >> ${rootmnt}/boot/boottime.logs
        condition
        echo ${LINE3} >> ${rootmnt}/boot/boottime.logs
        clear
        echo "Verification passed. Starting upgrade."
        rm -rf ${rootmnt}/{bin,dev,home,lib*,media,opt,proc,run,sbin,sys,usr, \
        etc,lost+found,mnt,root,rw,srv,tmp,var}
        sleep .4
       # ( pv -n ${rootmnt}/overlay/${TAR} | tar -xvf - -C ${rootmnt} ) \
       # 2>&1 | dialog --gauge "Installing updates......" 6 50
        pv ${rootmnt}/overlay/${TAR} | tar xJf - -C ${rootmnt}
       # xz -dkc ${rootmnt}/overlay/${TAR} | tar -xv -C ${rootmnt}
       # Clean up of update files
       if [[ "$?" == "0" ]]; then
           echo ${LINE5} >> ${rootmnt}/boot/boottime.logs
           sed -i -e "s/${UPDATE_STATUS}/update_complete/g" ${rootmnt}/boot/boottime.rc
       else
           echo "Error during updates installation"
        fi
        sleep .2
        sed -i 's/UPGRADE=1/UPGRADE=0/g' ${rootmnt}/boot/boottime.rc
        clean_up
    else
        exit 0
    fi

}


# Program driven
start_update


exit 0
