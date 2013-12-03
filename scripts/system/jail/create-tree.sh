#!/bin/bash
shopt -s compat31 # for \\b
IFS=""
shopt -s expand_aliases
alias read='IFS=" " read'

push_back()
{
    arr=$1; shift
    for val in "$@"
    do
        eval $arr[\${#$arr[@]}]=\$val
    done
}

name=$1

# TODO: validate $name

[ "$name" ] || name=custom

#mkdir ../$name
#mkdir $name
#cd $name

# TODO: read this from config or options
jail_home=/opt/jail

# jail_storage is where jail will hold its files (topmost branches of aufs filesystem)
jail_storage=$jail_home/${name}.trees

# jail_mountpoint is to where we mount jail and where we use chroot
jail_mountpoint=$jail_home/$name

# Jail will consist of following trees:
#
# 1. root fylesystem
# 2. system subtree bindings (like /dev /sys /proc)
# 3. additional filesystems if any (like /usr /opt /var /home)
# 4. direct bindings (like /tmp /run)

mounts=$(mount)

mounts_check=(/usr /opt /var /home)
declare -A mounts_check2
for m in ${mounts_check[@]}
do
    mounts_check2[$m]=1
done

# detect if additional filesystems are present (i.e. separate partitions)
declare -a partitions
while read src x dst x type opts
do
    [ $type != none -a "${mounts_check2[$dst]}" ] ||
        continue

    push_back partitions $dst
    # false
done <<< $mounts

# unwind jail_storage real location (i.e. before --bind)

# jail_storate overlap check:
# make separations in case jail_storage overlaps 1. or 3.
# separation is any non-empty sub-dir of tree which doesn't contain jail_storage
# in jail_storage tree is marked as separated with .separated stamp


echo
echo stage 2: overlap check

declare -a exclude_points
echo $jail_storage
while read src x dst x type opts
do
    [[ $jail_storage/ == $dst/* && $type == none && $opts =~ \\bbind\\b ]] ||
        continue
    push_back exclude_points $src
done <<< $mounts

echo
echo stage 3: create dirs in jail_storage

echo mkdir $jail_storage/root

for part in ${partitions[@]}
do
    jail_part=${jail_storage}${part}
    echo mkdir $jail_part
    for exclude in ${exclude_points[@]}
    do
        [[ $exclude/ == $part/* ]] ||
            continue
        echo touch $jail_part/.separated
        for include in $part/*
        do
            [[ $exclude/ == $include/* ]] &&
                continue
            jail_part=${jail_storage}${include}
            echo mkdir $jail_part
        done
    done
done

#mkdir -p root opt/kde3 var home usr/sbin usr/bin usr/lib32 usr/include usr/lib usr/share
