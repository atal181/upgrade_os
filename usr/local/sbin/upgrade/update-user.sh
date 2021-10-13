#!/bin/bash

chng_value()
{
	mount -o rw,remount / || mount -o rw,remount /boot
	echo RESET=0 > /boot/boottime.rc
	echo UPGRADE=1 >> /boot/boottime.rc
	mount -o ro,remount / || mount -o ro,remount /boot
	zenity --question --default-cancel --ellipsize --title="System update" --text \
		"Restart system to install updates?" --ok-label="Restart" --cancel-label="Later" && reboot
}


ovrly_dir()
{
	if [ ! -d "/overlay/upgrade" ]; then
		mkdir -p /overlay/upgrade/{new,ro,rw,wd}
	fi
}


. /tmp/pw_rs
. /boot/boottime.rc
if [[ $UPGRADE -eq 0 && $update -eq 1 ]]; then
	echo "GDGD"
#	zenity --display=:0 --question --title="System update" --text \
#		"Do you want to download updates?" --ok-label="Download" --cancel-label="Later"
#	if [[ $? -eq 0 ]]; then
	if [[ 0 -eq 0 ]]; then

		# Prepairing rootfs before rsync
		if [[ -z "${THINUX_fs}" ]]; then
			echo THINUX_fs=$(readlink -f /dev/disk/by-label/thinux) > /tmp/disk_labels
			sed -i 's/\/root//g' /tmp/disk_labels
			. /tmp/disk_labels
		fi

		ovrly_dir
		sleep 1
		umount / &> /var/log/update_rsync.logs && sleep 1
		mount -o ro $THINUX_fs /overlay/upgrade/ro/
		mou=$?
		mount -t overlay -o lowerdir=/overlay/upgrade/ro/,upperdir=/overlay/upgrade/rw/,workdir=/overlay/upgrade/wd/ overlay /overlay/upgrade/new/ &>> /var/log/update_rsync.logs
		mouover=$?

        # Start rsync
		sleep 1
		if [[ $mou -eq 0 ]] && [[ $mouover -eq 0 ]];  then
			rsync -avpuzh --delete --exclude 'boot/' ${rsync_url} /overlay/upgrade/new/ &>> /var/log/update_rsync.logs \
				&& chng_value || echo "Rsync error check /var/log/update_rsync.logs"
			sleep 1
			umount /overlay/upgrade/new/
			umount /overlay/upgrade/ro/
		else
			echo "Rootfs mounting error or Overlay mounting error, check /var/log/update-check.log"
		fi
#		zenity --progress --title="System update" --text="Downloading" --percentage=0 --auto-kill
	fi
else
	echo "Update are not available"
fi

