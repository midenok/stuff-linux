set listsize 30
set disassembly-flavor intel
set history save on
set print pretty on
set print asm-demangle on
set confirm off

handle SIGPIPE noprint nostop pass
handle SIGSTOP print stop nopass

# set inferior-tty /dev/ttya0

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

