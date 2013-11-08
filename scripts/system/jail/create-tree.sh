#!/bin/sh
name=$1
mkdir ../jail/$name
mkdir $name
cd $name
mkdir -p root opt/kde3 var home usr/sbin usr/bin usr/lib32 usr/include usr/lib usr/share 
