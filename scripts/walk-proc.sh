#!/bin/sh

get_parent()
{
    pid=$1
    shift
    [ -z "$pid" ] && return 2
    st="/proc/${pid}/stat"
    [ -f $st ] || return 3
    read p comm s ppid etc < $st
    [ -z "$ppid" ] && return 5
    [ -z "${ppid##*[!0-9]*}" ] && return 6
    [ $ppid -eq 1 ] && return 1
    echo "$ppid $comm"
}

pid=$PPID

while pid=$(get_parent $pid)
do
    comm=${pid#* }; pid=${pid%% *}
    if [ "$comm" = "(sshd)" ]
    then
        agent=(/tmp/ssh-*${pid}/agent.${pid})
        if [ ${#agent[*]} -gt 0 ]
        then
            SSH_AUTH_SOCK=${agent[0]}
            break
        fi
    fi
done
