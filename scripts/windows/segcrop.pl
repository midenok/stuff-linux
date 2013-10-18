#!/usr/bin/perl
package Config;
push our @ISA, 'Class';

use Getopt::Long qw(:config bundling);
use Pod::Usage;
use Data::Dumper;
use strict;

sub new
{
    return Class::new($_[0], {
        start_addr => 0,
        seg_size => 0,
        proc_prefix => 'sub_',
        all_proc => 1
    });
}

sub ensure
{
    return ref($_[0]) eq 'Config' ?
        $_[0] :
        Config->new();
}

sub get_options
{
    __PACKAGE__->construct(\@_);

    my $c = shift;

    GetOptions ($c, qw(
        list|ls
        start_addr|starting-address|sa=i
        seg_size|segment-size|seg-size|ss=s
        mode=s
        name=s
        segment|seg=s
        result_seg|result-segment|result-seg|rs=s
        start
        procedure|proc=s
        asm_file|asm-file|asm=s
        map_file|map-file|map=s
        map_segment|map-segment|ms=s
        proc_prefix|proc-prefix|procedure-prefix|pp=s
        dump|D+
        help|h
    )) or exit 1;

    if ($c->{help}) {
        pod2usage(-verbose => 99, -sections => 'SYNOPSIS|COMMANDS|OPTIONS');
    }
    
    if ($c->{segment}) {
        $c->{mode} = 'segment';
        $c->{name} = $c->{segment};
    } elsif ($c->{procedure}) {
        $c->{mode} = 'proc';
        $c->{name} = $c->{procedure};
    }    
    
    if (!$c->{asm_file} && !$c->{map_file}) {
        my $file = shift @ARGV
            or die "Please, specify file!\n";
       
        if ($file =~ m/\.map$/i) {
            $c->{map_file} = $file;
        } else {
            $c->{asm_file} = $file;
        }
    }
    
    if ($c->{asm_file} && $c->{map_file}) {
        die "--asm and --map are exclusive!\n"
    }
    
    $c->{file} = $c->{asm_file} || $c->{map_file};

    -f $c->{file}
            or die $c->{file}." is not a file!\n";

    
    if ($c->{map_file}) {
        $c->{mode} eq 'segment'
            or die "MAP command requires --segment!\n";
    } else {
        $c->{mode}
            or die "ASM command requires --mode!\n";
    }
    
    if ($c->{seg_size} && $c->{seg_size} =~ m/\D/) {
        $c->{seg_size} = hex($c->{seg_size});
    }

    return $c;
}

sub require_options
{
    my $c = shift;
    my @missed = grep {
        not defined $c->{$_}
    } @_;
    if (@missed) {
        die "Required options missed: ", join(", ", map("--$_", @missed)), "\n";
    }
}

sub dump
{
    my $c = shift;
    if ($c->{dump}) {
        $c->{dump}--;
        for (@_) {
            print Dumper($_);
        }
        if (!$c->{dump}) {
            exit 0;
        }
    }
}

1;

package Error;
use strict;

use constant {
    EOF => 1,
    PARSE_ERROR => 2
};

1;

package File;
push our @ISA, 'Class';

use strict;
use overload
    "<>" => \&get_line;
    
sub new
{
    return Class::new($_[0], {
        file => $_[1],
        filter => undef,
        filter_on => 0
    });
}

sub open
{
    __PACKAGE__->construct(\@_);

    my ($self, $file) = (shift, shift);

    open my $fh, '<', $file
        or die "${file}: $!\n";
        
    $self->{fh} = $fh;
    return $self;
}

sub DESTROY
{
    my $self = shift;
    close $self->{file};
}

sub filter
{
    my $self = shift;
    return $self->{filter_on} && ref($self->{filter}) ?
        $self->{filter}  : undef;
}

sub get_line
{
    my $self = shift;
    my $fh = $self->{fh};
    my $filter = $self->filter();

    do {
        $_ = defined $filter ? <$filter> : <$fh>;

        defined $_
            or return undef;
    
        $/ = "\r\n";
        if (0 == chomp) {
            $/ = "\n";
            chomp;
        }
    } while (m/^\s*$/);
    
    return $_;
}

1;


package Filter;
push our @ISA, 'Class';

use strict;
use overload
    "<>" => \&get_line;

Exception::import();
sub try (&$);
sub catch (&);
sub throw (@);

our %DIR_SIZES = (
    db => 1,
    byte => 1,
    dw => 2,
    word => 2,
    dd => 4,
    dword => 4,
    df => 6,
    fword => 6,
    dq => 8,
    qword => 8,
    dt => 10,
    tbyte => 10
);

sub new
{
    return Class::new($_[0], {
        fh => $_[1],
        dx_match => qr/d[bwdfqt]|byte|word|dword|fword|qword|tbyte/i,
        data_size => 0,
        start_addr => $_[2]->{start_addr},
        aligned => 0,
        max_align => 16
    });
}

sub get_line
{
    my $self = shift;
    my $fh = $self->{fh};
    my $dx_match = $self->{dx_match};

    if (exists $self->{save}) {
        $_ = $self->{save};
        delete $self->{save};
    } else {
        $_ = <$fh>;
    }
    
    if (m/^\s*;?\s*org\s+(([0-9a-f]+)h|(\d+))\s*(;.*)?$/i) {
        $self->{start_addr} = $3 || hex($2);
    } elsif (m/^\s*\S*\s*($dx_match)\s+(\S.*)$/) {
        my $dx = lc($1);
        my $data = parse_data($2);
        my $x_size = $DIR_SIZES{$dx};
        my $line_size = 0;
        my $save = $_;
        
        if ($data =~ m/\?|[0-9a-f]+h|\d+/) {
            my $count = 0;
            for (; m/^\s*${dx}\s+${data}\s*(;.*)?$/; ++$count) {
                $_ = <$fh>;
            }
            if ($count) {
                $self->{save} = $_;
                $self->{data_size} += $x_size * $count;
                return $count > 1 ? "${dx} ${count} dup(${data})" : $save;
            }
            $line_size = $x_size;
        } else {
            for (split(',', $data)) {
                if (m/^\s*(['"])(.+)\1\s*$/) {
                    my $q = $1;
                    my $s = $2;
                    $s =~ s/$q$q/$q/g;
                    $s =~ m/$q/ &&
                        throw Error::PARSE_ERROR();
                    $line_size += length($s);
                } else {
                    $line_size += $x_size;
                }
            }
        }
        $self->{data_size} += $line_size;
    } elsif (m/^\s*align\s+(([0-9a-f]+)h|(\d+))\s*(;.*)?$/i) {
        my $align = $3 || hex($2);
        my $off = $self->{start_addr} + $self->{data_size};
        my $rest = $off % $align;
        if ($rest) {
            my $add = $align - $rest;
            $self->{data_size} += $add;
            $self->{aligned} += $add;
        }
        if ($align > $self->{max_align}) {
            return $rest ? "db ${rest} dup(?)" : "";
        }
    }

    return $_;
}

sub parse_data
{
    my $line = shift;
    my $i = 0;
    while ($_ = substr($line, $i++)) {
        m/^('|")/ && parse_string($_, $1);
    }
}


sub parse_string
{
    my $string = shift;
    my $delim = shift;
    my $i = index ($string, $delim, 1);
    if ($i == -1) {
        throw Error::PARSE_ERROR();
    }
    my $rest = substr ($string, $i + 1);
    $rest =~ m/^\s+(\S.*)$/
        and $rest = $1;
    
}


1;


package ParserBase;
use strict;
push our @ISA, 'Class';
our %asminfo = (
    proc => 'endp',
    segment => 'ends'
);

sub new
{
    my $c = Config::ensure($_[1]);
    return Class::new($_[0], {
        conf => $c,
        file => File->open($c->{file})
    });
}


1;


package AsmCropper;
use strict;
push our @ISA, 'ParserBase';

Exception::import();
sub try (&$);
sub catch (&);
sub throw (@);

use constant {
    SEG_NOT_FOUND => 1,
    END_NOT_FOUND => 2
};

our %SEGALIGN = (
   byte => 1,
   word => 2,
   dword => 4,
   para => 16,
   page => 256
);

sub process
{
    my $self = shift;
    my $c = $self->{conf};
    my $fh = $self->{file};

    my $filter = Filter->new($fh->{fh}, $c);
    $fh->{filter} = $filter;

    my $mode = $c->{mode};
    my $mode_end = $ParserBase::asminfo{$mode}
        or die "Unknown mode: ${mode}\n";
    my $name = $c->{name}
        or die "Please, specify ${mode} name!\n";
    
    
    # To evade 'variable will not stay shared' error
    # anonymous subs must be used. Hope, this will be
    # fixed in V6...
    my $find = sub(&)
    {
        my $match = shift;
        my $res;
        while (<$fh>) {
            if ($res = &$match) {
                return $res;
            }
        }
        throw SEG_NOT_FOUND;
    };


    my $copy_until = sub(&)
    {
        my $match = shift;
        my $res;
        do {
            print $_, "\n";
            $_ = <$fh>;
            defined $_
                or throw END_NOT_FOUND;
        } while (!&$match);
        print $_, "\n";
    };

    try {
        my $rest;
        &$find (sub{
            m/^\s*\Q${name}\E\s+${mode}\b(.*)$/i and
                $rest = $1, 1;
        });

        # pack 'db ?;' strings together, handle alignment
        if ($mode eq 'segment') {
            $fh->{filter_on} = 1;
            if ($rest =~ m/^\s+(readonly\s+)?(\w+)\b(.*)$/i) {
                my $align_kw = lc($2);
                $rest = $3;
                if ($align_kw eq 'align' && $rest =~ m/^\s*\((\d+)\)/) {
                    $filter->{max_align} = $1;
                } elsif (exists $SEGALIGN{$align_kw}) {
                    $filter->{max_align} = $SEGALIGN{$align_kw};
                }
            }
        }

        &$copy_until(sub{
            m/^\s*\Q${name}\E\s+${mode_end}\b/i
        });
        
        if ($fh->{filter_on}) {
            my $s = $filter->{data_size};
            print "; found ${s} (". sprintf("0x%X %gk", $s, $s / 1024). ") bytes of data\n";
            print "; aligned ". $filter->{aligned}. " bytes\n";
        }
    }
    catch {
        my $err = $_;
        if ($err == SEG_NOT_FOUND) {
            die "${name} not found!\n";
        } elsif ($err == END_NOT_FOUND) {
            die "End of ${name} not found!\n";
        } else {
            die $err;
        }
    };

    return $self;
}

1;


package MapParser;
use strict;
push our @ISA, 'ParserBase';

Exception::import();
sub try (&$);
sub catch (&);
sub throw (@);

sub dup_nop($)
{
    return sprintf("db 0%Xh dup(90h)\n", $_[0]);
}

sub process
{
    my $self = shift;
    my $c = $self->{conf};
    my $fh = $self->{file};
    my $result_seg = $c->{result_seg} || 'CODE'. $c->{segment};
    
    my $find = sub(&)
    {
        my $match = shift;
        my $res;
        while (<$fh>) {
            if ($res = &$match) {
                return $res;
            }
        }
        throw Error::EOF();
    };
    
    my $seg = sprintf("%04d", $c->{segment});
    
    try {
        &$find (sub{
            m/^\s*Address\s+/
        });
        
        my $prev_addr = 0;
        my $addr;
        
        print "${result_seg} segment para public 'CODE' use32\n";
        
        if ($c->{start}) {
            print "start:\n";
        }
        
        while (<$fh>) {
            m/^\s*${seg}:([0-9A-F]{8})\s+(\S+)\s*$/ && do {
                $addr = hex $1;
                my $name = $2;
                my $delta = $addr - $prev_addr;
                $prev_addr = $addr;
                if ($delta > 0) {
                    print dup_nop $delta;
                }
                if ($c->{all_proc} || $name =~ m/^$c->{proc_prefix}/) {
                    print "${name} proc far\n${name} endp\n"
                } else {
                    print "${name}:\n";
                }
            };
        }

        if ($c->{seg_size}) {
            print dup_nop($c->{seg_size} - $addr);
        }

        print "${result_seg} ends\n";
    } catch {
        
    };
}

1;


package SegLister;

use strict;
push our @ISA, 'ParserBase';

Exception::import();
sub try (&$);
sub catch (&);
sub throw(@);


use constant {
    EOF => 1
};

sub process
{
    my $self = shift;
    my $fh = shift;
    
    my $c = $self->{conf};

    my $find = sub(&)
    {
        my $match = shift;
        my $res;
        while (<$fh>) {
            if ($res = &$match) {
                $_ = <$fh>;
                defined $_ or throw EOF;
                return $res;
            }
        }
        return undef;
    };
    
    try {
        while (1) {
            my $name;
            return unless &$find (sub{
                m/^\s*(\S+)\s+segment\b/i
                    and $name = $1, 1;
            });
        };
    } catch {
        
    }
}

1;


package main;
use strict;

my $c = Config::get_options();
$c->dump($c);

my $p = $c->{map_file} ? MapParser->new($c) : AsmCropper->new($c);
$p->process();

1;


package Class;

BEGIN
{
    our @ISA = 'Exporter';
}

sub new
{
    my $class = ref $_[0] || $_[0];
    return bless $_[1] || {} => $class;
}

sub construct(*)
{
    my $package = shift;
    my $args = $_[0];
    if (ref($args->[0]) eq $package) {
        return;
    }

    if (exists $args->[0] && $args->[0] eq $package) {
        shift @$args;
    }
    
    my $self = $package->new(@$args);
    unshift @$args, $self;
}

1;


package Exception;
use strict;
use overload
    '""' => sub { return $_[0]->[0]; },
    '==' => sub { return $_[0]->[0] == $_[1]},
    '!=' => sub { return $_[0]->[0] != $_[1]};

sub try (&$) {
   my($try, $catch) = @_;
   eval {&$try};
   if ($@) {
      local $_ = $@;
      chomp;
      return &$catch;
   }
}

sub catch (&) { $_[0] }

sub throw (@)
{
    my $data = shift;
    my $class = __PACKAGE__;
    if (ref($data) eq $class || $data eq $class) {
        $data = shift;
    }
    my $self = bless [$data] => $class;
    die $self;
}

sub import
{
    my $caller = caller;
    for my $fn (qw(try catch throw)) {
        my $proto = prototype($fn);
        eval "sub ${caller}::${fn}(${proto});".
             "*${caller}::${fn} = \\&". __PACKAGE__. "::${fn};";
    }
}

1;
