#!/bin/sh
. /home/sigil/src/kde/opt-trinity/environment.sh
cp -f ~sigil/.Xauthority $HOME
startx -- /usr/bin/Xnest $xnest_display -geometry 800x600 &
