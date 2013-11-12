#!/bin/bash
# TODO: merge /var/lib/dpkg/status & available with diff-n-patch

cmd()
{
    "$@" || {
        s=$?
        if [ $((s & 38)) -ne 0 ]
        then
            echo $@
            exit $s
        fi
    }
}

[ -n "$1" ] || exit 1
host=/opt/jail-trees/$1
dest=/opt/jail/$1
base2=""
[ -n "$2" ] && base2=/opt/jail-trees/$2

if [ $(basename $0) = "mount.sh" ]
then
    op=mount
else
    op=umount
fi



if [ $op = mount ]
then
    cmd mount -t aufs -o br:$host/root${base2:+:$base2/root}:/ none $dest
fi

if [ $op = umount ]
then
    for d in /var/cache/apt/archives /run
    do
        cmd umount ${dest}${d}
    done
fi

# FIXME: why usr/* and then ln -s?

exclude=/opt/kde3

for d in $host/usr/* $host/opt/* $host/var $host/home
do
    # wildcard was not matched
    [[ $d =~ \* ]] && continue

    d=${d#$host}

    [ "$d" = "$exclude" ] && continue

    case $op
    in
    mount)
        [ -d ${dest}${d} ] || mkdir ${dest}${d} || exit 1
        if [ -d ${host}${d} ]
        then
            cmd mount -t aufs -o br:${host}${d}${base2:+:$base2$d}:${d} none ${dest}${d}
        else
            cmd mount --bind ${src}${d} ${dest}${d}
        fi
        ;;
    umount)
        cmd umount ${dest}${d}
        ;;
    esac
done

if [ $op = mount ]
then
    for d in /var/cache/apt/archives /run
    do
        cmd mount --bind ${d} ${dest}${d}
    done
fi

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

case $op
in
mount)
    [ -L ${dest}/usr/lib64 ] || cmd ln -s lib ${dest}/usr/lib64
    ;;
umount)
    cmd umount $dest
    ;;
esac
