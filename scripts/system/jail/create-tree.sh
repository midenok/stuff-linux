#!/bin/bash
shopt -s compat31 # for \\b
IFS=""
shopt -s expand_aliases
alias read='IFS=" " read'

name=$1
#mkdir ../$name
#mkdir $name
#cd $name

# jail_mountpoint is to where we mount jail and where we use chroot
jail_mountpoint=$(pwd)

# jail_storage is where jail will hold its files (topmost branches of aufs filesystem)
jail_storage=$jaildir

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

while read src x dst x type opts
do
    [ $type != none -a "${mounts_check2[$dst]}" ] ||
        continue
    
    echo $src $dst $type
    # false
done <<< $mounts

# unwind jail_storage real location (i.e. before --bind)

# jail_storate overlap check:
# make separations in case jail_storage overlaps 1. or 3.
# separation is any non-empty sub-dir of tree which doesn't contain jail_storage
# in jail_storage tree is marked as separated with .separated stamp


echo
echo stage 2

while read src x dst x type opts
do
    [[ $jaildir == $dst/* && $type == none && $opts =~ \\bbind\\b ]] ||
        continue
    echo $src
done <<< $mounts

#mkdir -p root opt/kde3 var home usr/sbin usr/bin usr/lib32 usr/include usr/lib usr/share
