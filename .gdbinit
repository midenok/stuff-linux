set listsize 30
set print elements 0
set disassembly-flavor intel
set history save on
set print pretty on
set print asm-demangle on

set detach-on-fork on
set follow-fork-mode parent

handle SIGPIPE noprint nostop pass
handle SIGSTOP print stop nopass
handle SIGUSR1 noprint nostop pass

# set inferior-tty /dev/ttya0

define parent
    set detach-on-fork on
    set follow-fork-mode parent
end

define child
    set detach-on-fork off
    set follow-fork-mode child
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
