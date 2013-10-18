#!/bin/bash
version=4.4
priority=120
progs=(cpp gccbug gcov g++ i486-linux-gnu-gcc)

update-alternatives --remove-all cpp
update-alternatives --remove-all g++
update-alternatives --remove-all gcc

for p in ${progs[@]}
do
    slaves="${slaves:+$slaves }--slave /usr/bin/$p $p /usr/bin/$p-$version"
done

update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${version} ${priority} ${slaves}
 