#!/bin/sh
opt=~/src/kde/opt
export LD_LIBRARY_PATH=$opt/usr/lib:$opt/usr/lib/kde3
export KDEDIRS=$opt/usr
rsync -aP $opt/home/ $opt/home2
cp -f ~/.Xauthority $opt/home2
export HOME=$opt/home2
startx -- /usr/bin/Xnest :4 -geometry 800x600 &
