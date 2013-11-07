#!/bin/sh
make install prefix=$HOME/src/kde/opt/usr sysconfdir=$HOME/src/kde/opt/etc INSTALL="$HOME/bin/linked-install/install -p -c"
