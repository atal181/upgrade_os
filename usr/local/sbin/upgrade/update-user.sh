#!/bin/bash

chng_value()
{
	mount -o rw,remount / || mount -o rw,remount /boot
	echo RESET=0 > /boot/boottime.rc
	echo UPGRADE=1 >> /boot/boottime.rc
}


ovrly_dir()
{
	if [ ! -d "/overlay/upgrade" ]; then
		mkdir -p /overlay/upgrade/{new,ro,rw,wd}
	fi
}


. /usr/local/sbin/upgrade/var/pw_rs
. /boot/boottime.rc
if [[ $UPGRADE -eq 0 && $update -eq 1 ]]; then
	echo "GDGD"
#	zenity --display=:0 --question --title="System update" --text \
#		"Do you want to download updates?" --ok-label="Download" --cancel-label="Later"
#	if [[ $? -eq 0 ]]; then
	if [[ 0 -eq 0 ]]; then

		# Prepairing rootfs before rsync
		ovrly_dir
		umount / &> /var/log/update_rsync.logs && sleep .1
		mount -L thinux -o ro /overlay/upgrade/ro/ &>> /var/log/update_rsync.logs
		mount -t overlay -o lowerdir=/overlay/upgrade/ro/,upperdir=/overlay/upgrade/rw/,workdir=/overlay/upgrade/wd/ overlay /overlay/upgrade/new/ &>> /var/log/update_rsync.logs

        # Start rsync
		sleep 1
		rsync -avpuzh --delete --exclude 'boot/' ${rsync_url} /overlay/upgrade/new/ &>> /var/log/update_rsync.logs && chng_value
		sleep 1
		umount /overlay/upgrade/new/
#		zenity --progress --title="System update" --text="Downloading" --percentage=0 --auto-kill
	fi
else
	echo "Update are not available"
fi
