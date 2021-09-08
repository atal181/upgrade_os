#!/bin/bash

. pw_rs

if [ $update -eq 0 ]; then
	zenity --question --title="System update" --text \
		"Do you want to download updates?" --ok-label="Download" --cancel-label="Later"
	if [[ $? -eq 0 ]]; then

		# Prepairing rootfs before rsync
		umount -l /
		mount -l thinux -o ro /overlay/upgrade/ro/
		mount -t overlay -o lowerdir=/overlay/upgrade/ro/,upperdir=/overlay/upgrade/rw/,workdir=/overlay/upgrade/wd/ \ 
            overlay /overlay/upgrade/new/

        # Start rsync

		echo rsync -avnpuzh --delete --exclude 'boot/' ${rsync_url} /overlay/upgrade/new/

		zenity --progress --title="System update" --text="Downloading" --percentage=0 --auto-kill
		
	fi
else
	echo "Update are not available"
fi
