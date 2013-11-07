#!/bin/sh
file=$1
device=$2
shift 2
VBoxManage internalcommands createrawvmdk -filename "${HOME}/.VirtualBox/${file}.vmdk" -rawdisk "$device" 
#-relative -partitions 3 "$@"
