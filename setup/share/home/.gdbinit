set listsize 30
set disassembly-flavor intel
set history save on
set print elements 0
set print pretty on
set print asm-demangle on
set print thread-events off
set confirm off
set pagination off
set verbose on
set logging file ~/gdb.log
set logging overwrite
set history remove-duplicates unlimited
set history file ~/.gdbhistory
set verbose off

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

define logging
    if $argc == 0
        set logging off
        set logging on
        show logging
    else
        if $argc == 1
            set logging $arg0
        else
            set logging $arg0 $arg1
        end
    end
end

define a
    attach $arg0
end

define btc
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
    bt
end

define tl
    info threads
end

define tt
    thread apply all bt
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

# step macros

define nn
    fin
    s
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

define wh
    winheight src +8
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
    python gdb.execute("set $tty=\"" + os.ttyname(0) + "\"")
    call open($tty, 0)
    set $tty_in=$
    call open($tty, 1)
    set $tty_out=$
    call dup(0)
    set $old_stdin=$
    call dup(1)
    set $old_stdout=$
    call dup(2)
    set $old_stderr=$
    call dup2($tty_in, 0)
    call dup2($tty_out, 1)
    call dup2($tty_err, 2)
    eval "perl_eval \"$ENV{PERLDB_OPTS}='TTY=%s'\"", $tty
    perl_eval "require Enbugger"
end

define attach_perl
    attach $arg0
    perl_init
    perl_stop
end

source ~/.gdbinit.py
