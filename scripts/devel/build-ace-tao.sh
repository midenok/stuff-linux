#!/bin/bash

if [ -d "$1" ]
then
    ACE_ROOT=$1
    shift
elif [ -d ACE ]
then
    ACE_ROOT=$(pwd)/ACE
else
    ACE_ROOT=$(pwd)
fi

export ACE_ROOT
export TAO_ROOT=$ACE_ROOT/TAO
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$ACE_ROOT/lib

cat > $ACE_ROOT/ace/config.h <<EOF
#include "ace/config-linux.h"
EOF

cat > $ACE_ROOT/include/makeinclude/platform_macros.GNU <<EOF
OCCFLAGS = -O0 -g3
OCFLAGS = -O0 -g3
include $ACE_ROOT/include/makeinclude/platform_linux.GNU
INSTALL_PREFIX = ${opt_dir:-$(pwd)/opt}${opt_dir}
EOF

(
    cd $ACE_ROOT
    make "$@"
    cd $TAO_ROOT
    make "$@"
)