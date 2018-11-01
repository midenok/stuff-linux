#!/bin/sh
iso_file=$(cat /proc/cmdline|sed -e 's|^.*iso-scan/filename=\(\S\+\).*$|\1|')
mount|sed -ne '/type vfat/ {s/^\S\+ on \(\S\+\) type.*$/\1/; p}'|
while read mp
do
    iso=$mp/${iso_file#/}
    if [ -f "$iso" ]
    then
        losetup /dev/loop0 "$iso"
        break
    fi
done

sed -ie "s/'^ID_CDROM='/'^ID_FS_TYPE=iso9660'/" /bin/list-devices
