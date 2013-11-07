#!/bin/sh
mkdir obj-i486-linux-gnu
cd obj-i486-linux-gnu
PATH=${HOME}/src/kde/tqtinterface/qtinterface:${PATH}
../configure --enable-closure --enable-debug --disable-warnings --without-ssl --without-arts --with-gnu-ld \
    --with-extra-includes="${HOME}/src/kde/tqtinterface/qtinterface:${HOME}/src/kde/tqtinterface/qtinterface/private" \
    --with-extra-libs=${HOME}/src/kde/tqtinterface CFLAGS="-O0 -g3" CXXFLAGS="-O0 -g3" \
    --prefix=${HOME}/src/kde/opt-trinity INSTALL=${HOME}/src/scripts/misc/install-linker/install
