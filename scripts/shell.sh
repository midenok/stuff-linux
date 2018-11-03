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

dd()
{
    local dd=$(which dd); [ "$dd" ] || {
        echo "'dd' is not installed!" >&2
        return 1
    }

    local pv=$(which pv); [ "$pv" ] || {
        echo "'pv' is not installed!" >&2
        "$dd" "$@"
        return $?
    }
    
    local arg arg2 infile
    local -a args
    for arg in "$@"
    do
        arg2=${arg#if=}
        if [ "$arg2" != "$arg" ]
        then
            infile=$arg2
        else
            args[${#args[@]}]=$arg
        fi
    done
    
    "$pv" -tpreb "$infile" | "$dd" "${args[@]}"
}

alias start='systemctl start'
alias stop='systemctl stop'
alias reload='systemctl reload'
alias restart='systemctl restart'
alias usctl='systemctl --user'
alias ustart='systemctl --user start'
alias ustop='systemctl --user stop'
alias ureload='systemctl --user reload'
alias urestart='systemctl --user restart'

mount()
{
    if [ -z "$1" ]
    then
        /bin/mount -t ext4,vfat,ntfs
        return $?
    fi
    if [ "$1" = -t -a -z "$2" ]
    then
        /bin/mount
        return $?
    fi
    /bin/mount "$@"
}

x()
{
    if [[ "$-" == *x* ]]; then
        echo Trace off
        set +x
    else
        echo Trace on
        set -x
    fi
}
