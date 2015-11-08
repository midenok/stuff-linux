#!/bin/sh
script=`mktemp`
cat <<EOF > $script
set logging file stack.log
set pagination off
set logging on
thread apply all bt
quit
EOF

for f in core.*
do
    executable=$(file $f | sed "s/^.*from '\(.\+\)'.*$/\1/")
    if [ -n "$executable" ]
    then
	[ -x $(which $executable) ] || {
	    echo "'$executable' not found!" >&2
	    exit 1
	}
        gdb $executable $f -x $script &> /dev/null    
        mv stack.log stack.${f##core.}
        echo "$f ($executable) processed"
    else
        echo "$f (unknown) skipped"
    fi
done

rm $script
grep -5 '<signal handler called>' stack.* > signals.txt
