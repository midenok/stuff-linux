screen()
{
    if [ "$SSH_AUTH_SOCK" ]
    then
        for arg in "$@"
        do
            case $arg in
            -*r*|-*R*)
                $(which screen) "$@" -X setenv SSH_AUTH_SOCK $SSH_AUTH_SOCK ||
                    return $?
                ;;
            esac
        done
    fi

    $(which screen) "$@"
}
export -f screen

if [ ! "$STY" ]
then
    # skip setup for non-screen shells
    return
fi

debug_trap_pass()
{
    local cmd_type=$(type -t "$1")
    # empty cmd_type is for inexistent command or variable definition
    [ -z "$cmd_type" -o "$cmd_type" = builtin -a "$1" != echo -a "$1" != set -a "$1" != env ] &&
        return 1

    case "$1" in
        screen)
            return 1;;
    esac
    return 0
}
export -f debug_trap_pass

debug_trap()
{
    [ -n "$COMP_LINE" ] && return  # do nothing if completing
    [ "$BASH_COMMAND" = "$PROMPT_COMMAND" ] && return
    debug_trap_pass $BASH_COMMAND || return

    if [ -n "$SSH_AUTH_SOCK" -a '!' -S "$SSH_AUTH_SOCK" ]
    then
        screen -X exec .! echo '$SSH_AUTH_SOCK' && read -s SSH_AUTH_SOCK
    fi
}
export -f debug_trap

grep -q 'trap\s.*\sDEBUG' ~/.bashrc ||
    echo $'\n'"[ \"\$STY\" ] && trap 'debug_trap' DEBUG"$'\n' >> ~/.bashrc
