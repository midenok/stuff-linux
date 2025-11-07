set listsize 30
set confirm off
set disassembly-flavor intel
set history save on
set history remove-duplicates unlimited
set history file ~/.gdbhistory
set print elements 0
set print pretty on
set print asm-demangle on
set print thread-events off
set print repeats 0
set print static-members off
set style address intensity bold
set style address foreground magenta
set pagination off
set logging file ~/gdb.log
set logging overwrite
set verbose off
set width 0
set debuginfod enabled off
#set target-async on
#set non-stop on
set index-cache enabled on

# for red hat:
# set build-id-verbose 0

handle SIGPIPE noprint nostop pass
handle SIGSTOP print stop nopass
handle SIGUSR1 noprint nostop pass
# handle SIGINT print nostop pass

# set inferior-tty /dev/ttya0

define reconf
    source ~/.gdbinit
end

define hex
    set output-radix 16
end

define dec
    set output-radix 10
end

define parent
    set detach-on-fork on
    set follow-fork-mode parent
end

define child
    set detach-on-fork off
    set follow-fork-mode child
end

define pagination
    if $argc == 1
        set pagination $arg0
    end
    show pagination
end

define verbose
    if $argc == 1
        set verbose $arg0
    end
    show verbose
end

define confirm
    if $argc == 1
        set confirm $arg0
    end
    show confirm
end

define log
    if $argc == 0
        set logging enabled off
        set style enabled off
        set logging overwrite on
        set logging enabled on
    else
        if $argc == 1
            if !$_streq("$arg0", "status")
                if $_streq("$arg0", "off")
                    set logging enabled off
                    set style enabled on
                end
                if $_streq("$arg0", "on")
                    set logging enabled off
                    set style enabled off
                    set logging overwrite on
                    set logging enabled on
                end
            end
        else
            set logging $arg0 $arg1
        end
    end
    show logging file
    show logging enabled
end

define colors
    if $argc == 0
        set style enabled on
    else
        set style enabled $arg0
    end
    show style enabled
end

define a
    attach $arg0
end

define btc
    set width 0
    echo ```c++\n
    if $argc == 0
        backtrace
    else
        backtrace $arg0
    end
    echo ```\n
end

define recycle
    b __GI___assert_fail
    commands
        r
    end
end

# thread macros

define t
    thread $arg0
    set width 0
    bt
end

define tl
    set width 0
    info threads
end

define tt
    set width 0
    thread apply all bt
end

define ttlog
    log
    tt
    log off
end

# breakpoint macros

define bx
    break $arg0
    echo Continuing.\n
    continue
end

define bd
    disable breakpoint $arg0
end

define bdx
    disable breakpoint $arg0
    echo Continuing.\n
    continue
end

define be
    enable breakpoint $arg0
end

define bex
    enable breakpoint $arg0
    echo Continuing.\n
    continue
end

define bc
    delete breakpoint $arg0
end

define bcx
    delete breakpoint $arg0
    echo Continuing.\n
    continue
end

define bl
    info breakpoints
end

define sb
    if $argc == 0
        save breakpoints ~/breaks.gdb
    else
        save breakpoints ~/$arg0.gdb
    end
end

define lb
    if $argc == 0
        source ~/breaks.gdb
    else
        source ~/$arg0.gdb
    end
    info breakpoints
end

define eb
    if $argc == 0
        set $arg = "~/breaks.gdb"
    else
        set $arg = "~/$arg0.gdb"
    end
    eval "save breakpoints %s", $arg
    eval "shell mcedit %s", $arg
    delete
    eval "source %s", $arg
end

define ign
    if $argc == 1
        ignore $bpnum $arg0
    else
        if $argc > 1
            ignore $arg0 $arg1
        else
            ignore
        end
    end
end

define statb
    if $argc > 0
        set $b = $arg0
    else
        set $b = $bpnum
    end
    commands $b
        c
    end
end

define btb
    if $argc > 0
        set $b = $arg0
    else
        set $b = $bpnum
    end
    commands $b
        bt
    end
end

define logb
    if $argc > 0
        set $b = $arg0
    else
        set $b = $bpnum
    end
    commands $b
        btc
        c
    end
end

define blog
    break $arg0
    commands
        btc
        c
    end
end

define b
    break $arg0
    commands
        btc
    end
end

define btt
    break $arg0
    commands
        tt
    end
end


define coff
    define c
    end
    echo Ignoring 'c'.\n
end

define con
    define c
        continue
    end
    echo Not ignoring 'c'.\n
end

define wl
    watch -l $arg0
end

define wv
    watchvar $arg0
end

define uv
    unwatchvar $arg0
end

# step macros

define nn
    fin
    s
end

define basan
    b __asan::ReportGenericError
end

define rf
    reverse-finish
end

define r
    if $_thread != 0
        echo Inferior is already running. Use "run" to restart.\n
    else
        run
    end
end

# MariaDB macros

define rassert
    b __GI___assert_fail
    commands
        btc
        r
    end
end

define pitem
    p dbug_print_item($arg0)
end

define pselect
    p dbug_print_select($arg0)
end

define punit
    p dbug_print_unit($arg0)
end

# dumping macros

define dump_array
    set $p = $arg0
    set $i = 0
    while *$p != 0
        printf "%d: %s\n", $i, *$p
        set $p = $p + 1
        set $i = $i + 1
    end
end

define xx
    dump binary memory /tmp/dump.bin $arg0 $arg0+$arg1
    shell xxd /tmp/dump.bin
end

define wh
    winheight cmd -8
end

define dmp
    !source ~/tmp/dmp
end

define pts
    eval "!date -d @%d", $arg0
end

# perl

define perl_eval
    call (void*)Perl_eval_pv((void*)Perl_get_context(), $arg0, 0)
end

define perl_stop
    perl_eval "Enbugger->stop"
    continue
end

define perl_init
    python import os
    python gdb.execute("set $tty=\"" + os.ttyname(0) + "\"")
    call open($tty, 0)
    set $tty_in=$
    call open($tty, 1)
    set $tty_out=$
    call (int) 'dup@plt'(0)
    set $old_stdin=$
    call (int) 'dup@plt'(1)
    set $old_stdout=$
    call (int) 'dup@plt'(2)
    set $old_stderr=$
    call (int) 'dup2@plt'($tty_in, 0)
    call (int) 'dup2@plt'($tty_out, 1)
    call (int) 'dup2@plt'($tty_out, 2)
    eval "perl_eval \"$ENV{PERLDB_OPTS}='TTY=%s'\"", $tty
    perl_eval "require Enbugger"
end

define attach_perl
    attach $arg0
    perl_init
    perl_stop
end

define curdir
    print (char *) get_current_dir_name()
end

python
import os

def source_if_exists(filename):
    filename = os.path.expanduser(filename)
    if os.path.isfile(filename):
        gdb.execute(f"source {filename}")

source_if_exists("~/.gdbinit.py")
source_if_exists("~/startup.gdb")
# source_if_exists("/home/midenok/src/gdbWatchVariableWindow/watchVariable.py"
end
