#!/bin/sh
script=`mktemp`
cat <<EOF > $script
set logging file stack.log
set pagination off
set logging on
thread apply all bt
quit
EOF

EXEC=${1:-~/src/httpd/.libs/lt-httpd}

for f in core.*
do
    gdb $EXEC $f -x $script &> /dev/null
    mv stack.log stack.${f##core.}
    echo $f
done

rm $script
