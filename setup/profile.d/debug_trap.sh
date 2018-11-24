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

debug_trap_skip()
{
    [[ -n "$COMP_LINE" ]] && return 0  # do nothing if completing
    [[ "$BASH_COMMAND" = "$PROMPT_COMMAND" ]] && return 0
    local cmd_type=$(type -t "$1")

    # Empty cmd_type is for inexistent command or variable definition, exclude them
    # and shell builtins except echo, set and env:
    [[ -z "$cmd_type" || "$cmd_type" = builtin && "$1" != echo && "$1" != set && "$1" != env ]]  &&
        return 0

    # These commands also won't be processed by trap:
    case "$1" in
        screen)
            return 0;;
    esac

    # Check if executable is X11 program and detach from terminal:
    if [[ $cmd_type = file || $cmd_type = alias ]]; then
        local exe="`which $1`"
        if [ "$exe" ] && ldd "$exe"| grep -q libX11
        then
            setsid "$@"
            dont_execute=1
            return 0
        fi
    fi

    return 1
}
export -f debug_trap_skip

debug_trap()
{
    local cmd=$BASH_COMMAND
    local saved_set=$-
    set +x
    [[ "$trace_trap" && $trace_trap != 0 && $trace_trap != no ]] &&
        set -x
    trap DEBUG
    local dont_execute=0
    if debug_trap_skip $cmd; then
        [[ "$saved_set" == *x* ]] && set -x
        return $dont_execute
    fi

    if [[ -n "$STY" && -n "$SSH_AUTH_SOCK" && ! -S "$SSH_AUTH_SOCK" ]]
    then
        screen -X exec .! echo '$SSH_AUTH_SOCK' && read -s SSH_AUTH_SOCK
    fi
    [[ "$saved_set" == *x* ]] && set -x
    return $dont_execute
}
export -f debug_trap

if [ "$STY" ]
then
    # skip setup for screen shells
    return
fi

grep -q 'trap\s.*\sDEBUG' ~/.bashrc || cat << 'EOF' >>~/.bashrc

### Added by /etc/profile.d/debug_trap.sh:
if [[ "$(type -t debug_trap)" != function ]]; then
    source /etc/profile.d/debug_trap.sh
fi
shopt -s extdebug
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }trap debug_trap DEBUG"
trap debug_trap DEBUG
EOF
