#!/bin/bash

# Common functions (moved to common.sh)

set -o pipefail
shopt -s expand_aliases

alias if_subshell='if [ "$_" = /bin/bash -o "$0" = "$BASH_SOURCE" ]'
#alias if_subshell='if [ "$0" = "$BASH_SOURCE" ]'
alias if_source='if [ "$_" != /bin/bash -a "$0" != "$BASH_SOURCE" ]'

declare_command()
{
    eval cmd_${module}[$1]=$1
}

setup_module()
{
    module=$(basename $(readlink -e "$BASH_SOURCE"))
    module=${module//./_}
    eval declare -A cmd_${module}
}

get_options()
{
    getopt -o "$1" --long "$2" --name "${FUNCNAME[1]}" -- "$@"
}

die()
{
    if [ -n "$1" ]
    then
        echo "$1" >&2
    else
        echo "" >&2
    fi

    echo _= $_
    echo 0= $0
    echo BASH_SOURCE= $BASH_SOURCE

    if_subshell; then
        echo exit 1
    fi
    set -e
    false
}
export -f die

help()
{
    # TODO: list all commands
    # help -m <module> list commands in module
    # help -M list all modules
    local opts= $(get_options m:Mh module:,all-modules,help)
    local opt_module=
    local opt_modules=

    eval set -- "$opts"

    while true
    do
        case "$1" in
            -m|--module)
                opt_module=$2
                shift 2;;
            -M|--all-modules)
                opt_modules=true
                shift;;
            -h|--help)
                cat <<EOF
Usage: $func [OPTIONS] [PARAMS]
Options:
-c, --configure             Force configuration phace
-L, --no-linked             Force copy instead of symlink in installation phase
-r, --r, --remote REMOTE    Set REMOTE (or default) for project build commands
-t, --trunk                 Work on trunk instead of dev branch
-d, --debug                 Trace commands with set -x
-v, --verbose               Run configuration, compilation and installation verbosely
EOF
                exit
                shift;;
            --) shift; break;;
            *)
        esac
    done
}

# TODO: collect all commands from various scripts into one place.
# Make short description (mandatory) and --help (optional) for each command.
# Commands can be sourced or executed from script if it is symlink by the name of command.

# /home/midenok/src/stuff-linux/scripts/devel

setup_module

valgrind-badmem()
{
    valgrind \
            --leak-check=no \
            --track-origins=yes \
            --log-file=valgrind-badmem.log \
            "$@"
}

die2()
{
    die "Died!"
}

foo()
{
    echo "Foo args: $*"
    die2
    echo Owww
}
declare_command foo

echo "${!cmd_devel_sh[@]}"
echo ${cmd_devel_sh[foo]}

devel.sh()
{
    echo "This script is not meant to be run directly"
}

# if_subshell; then
#     echo yes
#
#     $(basename "$0") "$@"
# fi

echo _= $_
echo 0= $0
echo BASH_SOURCE= $BASH_SOURCE

fun()
{
    echo _= $_
    echo 0= $0
    echo BASH_SOURCE= $BASH_SOURCE
    set -x
    die "Error!"
}

fun
echo Continue
