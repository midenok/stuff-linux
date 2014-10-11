queue()
{
    [ "$1" = '-l' ] && {
        [ -f ~/.batch.sh ] || {
            echo 'Queue empty!' >&2
            return 1
        }
        cat ~/.batch.sh
        return
    }
    local a=`pwd`
    a=\'${a//\'/\'\"\'\"\'}\'
    a="cd ${a} && "
    for s in "$@"
    do
        s=\'${s//\'/\'\"\'\"\'}\'
        a=${a:+$a }$s
    done
    echo $a >> ~/.batch.sh
}

skip()
{(
    set -e
    batch=~/.batch.sh
    tail -n +2 $batch > $batch.new
    mv $batch.new $batch
)}

commit()
{(
    set -e
    batch=~/.batch.sh
    [ -f "$batch" ] || {
        echo 'Queue empty!' >&2
        false
    }

    while [ -s "$batch" ]
    do
        line=$(head -n 1 "$batch")
        set -v
        eval $line || {
            echo 'Failed!' >&2
            false
        }
        set +v
        tail -n +2 $batch > $batch.new
        mv $batch.new $batch
    done
    rm $batch
)}
