#!/bin/sh
PREREQ="lvm"
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

. /usr/share/initramfs-tools/hook-functions
# Begin real processing below this line


#copy_exec /usr/bin/tar /sbin
#copy_exec /usr/bin/md5sum /sbin
#copy_exec /usr/bin/pv /sbin
#copy_exec /usr/bin/xz /sbin
copy_exec /usr/bin/rsync

exit 0
