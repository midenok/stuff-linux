#!/bin/sh
opt=/home/sigil/src/kde/opt-trinity
dcop_sess=$(dcop --list-sessions --user kdedebug|sed -n -e '/DCOP/{s/^\s*//;p;q}')
dcop_serv=$(sed -e 'q' $opt/home/$dcop_sess)
echo $dcop_serv


