#!/bin/bash

chng_value()
{
	mount -o rw,remount / || mount -o rw,remount /boot
	echo RESET=0 > /boot/boottime.rc
	echo UPGRADE=1 >> /boot/boottime.rc
}

. /usr/local/sbin/upgrade/var/pw_rs

if [ $update -eq 1 ]; then
#	zenity --display=:0 --question --title="System update" --text \
#		"Do you want to download updates?" --ok-label="Download" --cancel-label="Later"
#	if [[ $? -eq 0 ]]; then
	if [[ 0 -eq 0 ]]; then

		# Prepairing rootfs before rsync
		umount / &> /tmp/update_rsync.logs && sleep .1
		mount -L thinux -o ro /overlay/upgrade/ro/ &>> /tmp/update_rsync.logs
		mount -t overlay -o lowerdir=/overlay/upgrade/ro/,upperdir=/overlay/upgrade/rw/,workdir=/overlay/upgrade/wd/ overlay /overlay/upgrade/new/ &>> /tmp/update_rsync.logs

        # Start rsync
		sleep 1
		rsync -avpuzh --delete --exclude 'boot/' ${rsync_url} /overlay/upgrade/new/ &>> /tmp/update_rsync.logs && chng_value
		sleep 1
		umount /overlay/upgrade/new/
#		zenity --progress --title="System update" --text="Downloading" --percentage=0 --auto-kill
	fi
else
	echo "Update are not available"
fi
