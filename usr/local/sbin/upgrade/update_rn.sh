#!/bin/bash

# Run by systemd
scriptname=/usr/local/sbin/upgrade/update-user.sh

# This script check pw_rs for changes then call update-user.sh
filename=/usr/local/sbin/upgrade/var


#inotifywait -mr \
#  -e modify $filename |
#while read -r dir file; do
#       changed_abs=${dir}${file}
#       changed_rel=${changed_abs#"$cwd"/}

#       rsync --progress --relative -vrae 'ssh -p 22' "$changed_rel" \
#           usernam@example.com:/backup/root/dir && \
#       echo "At ${time} on ${date}, file $changed_abs was backed up via rsync" >&2
#       . $scriptname
#done

inotifywait -mr -e modify $filename | read -r dir file
while $dir; do
	. $scriptname
done
