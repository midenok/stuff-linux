#!/bin/sh
. /home/sigil/src/kde/opt-trinity/environment.sh
set -x
$opt/bin/kicker --nofork --sync --display $xnest_display
set +x
