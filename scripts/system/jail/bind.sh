#!/bin/sh

cmd()
{
    "$@" || {
        s=$?
        if [ $((s & 38)) -ne 0 ]
        then
            echo $@
            exit $s
        fi
        return $s
    }
}

set -e
dest=${1:-.}
op=${2:-mount}

for d in /proc /sys /dev /tmp /media /run
do
    case $op
    in
    mount)
        cmd mount --rbind $d ${dest}${d}
        ;;
    umount)
        cmd umount -l ${dest}${d}
        ;;
    esac
done
