set listsize 30
set print elements 0
set disassembly-flavor intel
set history save on
set print pretty on
set print asm-demangle on
set confirm off
set pagination off
set verbose on
set logging file ~/gdb.log
set logging overwrite
set history remove-duplicates unlimited
set verbose off

# for red hat:
# set build-id-verbose 0

handle SIGPIPE noprint nostop pass
handle SIGSTOP print stop nopass
handle SIGUSR1 noprint nostop pass
# handle SIGINT print nostop pass

# set inferior-tty /dev/ttya0

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
    if $argc == 1
        set logging $arg0
    else
        set logging $arg0 $arg1
    end
    show logging
end

define a
    attach $arg0
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

define bd
    disable breakpoint $arg0
end

define be
    enable breakpoint $arg0
end

define bc
    delete breakpoint $arg0
end

define bl
    info breakpoints
end

define sb
    if $argc == 0
        save breakpoints ~/breaks.gdb
    else
        save breakpoints $arg0
    end
end

define lb
    if $argc == 0
        source ~/breaks.gdb
    else
        source $arg0
    end
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
        bt
        c
    end
end

define blog
    b $arg0
    commands
        bt
        c
    end
end

define bbt
    b $arg0
    commands
        bt
    end
end

# step macros

define nn
    fin
    s
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

