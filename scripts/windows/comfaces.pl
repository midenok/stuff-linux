#!/usr/bin/perl

=head1 SYNOPSIS

comfaces.pl [COMMAND] [OPTION]... DIR|FILE...

=head1 COMMANDS

=over 4

=item B<(default command)>

Produce IDA-compatible structures from DECLARE_INTERFACE_ directives.

=item B<--check>

Apply --parse-errors=show and do not show anything except errors.

=item B<--list-class, --lsc NAME>

Show methods by class name.

=item B<--list-classes, --ls [MASK]>

Show all classes along with method counts and file origins.

=item B<--source, -s>

Dump sources of parsed classes.

=back

=head1 OPTIONS

=over 4

=item B<--context[-lines], -C NUM>

Show NUM count of lines before the line that caused any error,
including that line. 0 turns off context printing. Default: 3 

=item B<--duplicates, --dups fail | force | skip | overwrite>

Duplicates are classes with same name.

 'fail' will fail on any duplicate class;
 'force' will handle duplicates like normal classes;
 'skip' will skip any duplicates except the first;
 'overwrite' will skip duplicates except the last.
Default: fail

=item B<--filemask MASKLIST>

MASKLIST is comma-separated list of file masks. When opening DIR use
these masks to find files. Default: *.h,*.hpp

=item B<--ignore-case, -i>

Ignore case in MASK or REGEX.

=item B<--match-classes, --match, -m MASK>

Skip classes that do not match filemask MASK.

=item B<--match-regex, --regex REGEX>

Skip classes that do not match regular expression REGEX.

=item B<--parse-errors, -e fail | show | skip>

 'fail' will show parsing error and will stop processing;
 'show' will show parsing error and will continue processing;
 'skip' will ignore any parsing errors.
Default: fail

=item B<--postfix, -o STR>

Add STR at the end of structure names in generated output.
E<10> E<8>
Default: _

=item B<--prefix, -r STR>

Add STR at the beginning of structure names in generated output. Default: (none)

=item B<--infix, -x STR>

Add STR between structure name and enum member name (used only with --produce=enum).
Default: __

=item B<--produce-mode, -p struct | enum>

Produce structures or enums. Default: struct

=item B<--nosort>

Don't sort structures alphabetically.

=back

=cut


package Config;
use Getopt::Long qw(:config bundling);
use Pod::Usage;
use Data::Dumper;
use strict;
our @ISA = "Autoconstructible";

sub new
{
    my $class = shift;
    $class = (ref $class || $class);

    my $self = bless {
        verbose => 0,
        max_context => 3,
        parse_errors => 'fail',
        duplicates => 'fail',
        filemask => '*.h,*.hpp',
        postfix => '_',
        prefix => '',
        infix => '__',
        produce => 'struct',
        sort => 1
    } => $class;

    return $self;
}

sub get_options
{
    __PACKAGE__->__construct_if_required__(\@_);

    my $c = shift;

    GetOptions ($c, qw(
        list_classes|list-classes|ls:s
        classes_wildcard|match-classes|match|m=s
        classes_regex|match-regex|regex=s
        list_class|list-class|lsc=s
        source|s:s
        ignore_case|ignore-case|i
        parse_errors|parse-errors|e:s
        check
        max_context|context-lines|context|C=i
        duplicates|dups=s
        filemask
        postfix|o=s
        prefix|r=s
        infix|x=s
        produce|produce-mode|p=s
        sort!
        number_list|number-list|n
        dump|D+
        verbose|v+
        help|h
    )) or exit 1;

    if ($c->{help}) {
        pod2usage(-verbose => 99, -sections => 'SYNOPSIS|COMMANDS|OPTIONS');
    }

    if ($c->{source}) {
        $c->{classes_wildcard} = $c->{source};
    }
    
    if (defined $c->{source}) {
        $c->{source} = 1;
    }
    
    if ($c->{list_classes}) {
        $c->{classes_wildcard} = $c->{list_classes};
    }

    if (defined $c->{list_classes}) {
        $c->{list_classes} = 1;
    }
    
    if ($c->{classes_wildcard}) {
        $c->{classes_regex} =
            Text::Glob::glob_to_regex_string($c->{classes_wildcard});
    }
    
    if ($c->{classes_regex}) {
        if ($c->{ignore_case}) {
            $c->{classes_regexp} = qr/^$c->{classes_regex}$/i;
        } else {
            $c->{classes_regexp} = qr/^$c->{classes_regex}$/;
        }
    }
    
    if ($c->{duplicates}
        && $c->{duplicates} ne 'skip'
        && $c->{duplicates} ne 'force'
        && $c->{duplicates} ne 'overwrite'
        && $c->{duplicates} ne 'fail')
    {
        die "--duplicates must be 'skip', 'overwrite', 'force' or 'fail'!\n";
    }
    
    if ($c->{check}) {
        $c->{parse_errors} = 'show';
    }

    if (defined $c->{parse_errors} && !$c->{parse_errors}) {
        $c->{parse_errors} = 'skip';
    } elsif ($c->{parse_errors}
        && $c->{parse_errors} ne 'skip'
        && $c->{parse_errors} ne 'show'
        && $c->{parse_errors} ne 'fail')
    {
        die "--parse-errors must be 'skip', 'show' or 'fail'!\n"
    }
    
    if ($c->{produce}
        && $c->{produce} ne 'struct'
        && $c->{produce} ne 'enum')
    {
        die "--produce must be 'struct' or 'enum'!\n";
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


package Method;
use strict;

use overload
    '""' => sub { return $_[0]->{name}; };

sub new
{
    my $class = shift;
    $class = (ref $class || $class);
    my $self = bless shift || {} => $class;
    $self->{name} = undef
        unless exists $self->{name};
    return $self;
}

1;


package Class;
use strict;

use overload
    '""' => sub { $_[0]->{name} },
    'cmp' => sub { $_[0]->{name} cmp $_[1]->{name} },
    '@{}' => sub { $_[0]->{methods} };

sub new
{
    my $class = shift;
    $class = (ref $class || $class);
    my $self = bless shift || {} => $class;
    $self->{methods} = []
        unless ref($self->{methods}) eq 'ARRAY';
    $self->{by_name} = {}
        unless ref($self->{by_name}) eq 'HASH';        
    $self->{orphan_comments} = []
        unless ref($self->{orphan_comments}) eq 'ARRAY';
    $self->{text} = []
        unless ref($self->{text}) eq 'ARRAY';
    return $self;
}

sub add_method
{
    my $self = shift;
    my $name = shift;
    my $arg2 = shift;
    
    my $method = Method->new({
        name => $name,
        origin => $arg2
    });
    
    my $side_comment = shift;
    if (!defined $side_comment) {
        $side_comment = $arg2;
        $method->{origin} = $self->{name};
    }

    if ($side_comment) {
        $method->{side_comment} = $side_comment;
    }

    push @{$self->{methods}}, $method;
    $self->{by_name}->{$name} = $method;

    if (@{$self->{orphan_comments}} > 0) {
        $method->{comments_top} = $self->{orphan_comments};
        $self->{orphan_comments} = [];
    }
}

sub add_comment
{
    my $self = shift;
    my $comment = shift || $_;
    push @{$self->{orphan_comments}}, $comment;
}

sub add_text
{
    my $self = shift;
    my $text = shift;
    push @{$self->{text}}, $text;
}

sub add_methods_from_macro
{
    my $self = shift;
    my $macro = shift;
    my $from = $self->{data}->{macros}->{$macro};
    if (ref($from) ne 'Class') {
        return 0;
    }

    for my $method (@$from) {
        push @{$self->{methods}}, $method;;
    }
    return 1;
}

1;


package File;
use strict;

use overload
    "<>" => \&get_line;

sub open
{
    my ($class, $c, $file) = (shift, shift, shift);
    $class = (ref $class || $class);

    if (ref($c) ne 'Config') {
        die "File::open() wrong arguments";
    }

    open my $fh, '<', $file
        or die "${file}: $!\n";
        
    my $self = bless {
        conf => $c,
        file => $file,
        fh => $fh,
        line => 0,
        text => undef,
        context => [],
        dont_preprocess => 0
    } => $class;

    return $self;
}

sub DESTROY
{
    my $self = shift;
    close $self->{file};
}

sub get_line
{
    my $self = shift;
    my $fh = $self->{fh};
    $self->{text} = "";
    do {
        do {
            ++$self->{line};
            $_ = <$fh>;
            return undef
                unless defined $_;
            
            $self->update_context();
    
            $/ = "\r\n";
            if (0 == chomp) {
                $/ = "\n";
                chomp;
            }
            if ($self->{dont_process}) {
                # return text 'as is' when in middle of macro processing
                $self->{text} = $_;
                return $_;
            }
        } while (m/^\s*$/); # skip empty lines

        # drop in-place comments
        s|^(.*\w.*)/\*.*\*/(.*)$|$1$2|;
        
        if ($self->{text}) {
            # drop leading spaces
            s|^\s*(\S.*)$| $1|;
        }
        # drop trailing spaces
        s|^(.*\S)\s*$|$1|;
        $self->{text} .= $_;

        # don't merge lines with multiline comments
        m|/\*| and $self->{no_concat} = 1;
        m|\*/| and $self->{no_concat} = 0;
    } while (!$self->{no_concat} &&
        # merge lines that don't contain comments or preprocessor directives
        # and do not end with ';' or '{'
        m/^(?!.*(\/\/|\/\*|#|\*\/)).*[^;{]\s*$/);
    return $self->{text};
}

sub update_context
{
    my $self = shift;
    my $c = $self->{conf};
    
    return undef unless $c->{max_context};
    
    if (@{$self->{context}} >= $c->{max_context}) {
        shift @{$self->{context}};
    }
    push @{$self->{context}}, sprintf("%5d: %s", $self->{line}, $_);
}

sub context
{
    return join("", @{$_[0]->{context}});
}

1;

package ClassData;
use strict;

use overload
    '@{}' => sub{ $_[0]->{sorted} || $_[0]->{array} };

use constant {
    EOF => 1,
    PARSE_ERROR => 2,
    ALREADY_EXISTS => 3,
    POSTPONE => 4
};

Exception->import('throw');

sub new
{
    my ($class, $c) = (shift, shift);
    if (ref($c) ne 'Config') {
        $c = Config->new();
    }
    $class = (ref $class || $class);
    my $self = bless {
        conf => $c,
        array => [],
        by_name => {},
        by_name_lc => {}
    } => $class;
    return $self;
}

sub get_by_name
{
    my $self = shift;
    my $name = shift;
    my $c = $self->{conf};
    if ($c->{ignore_case}) {
        return $self->{by_name_lc}->{lc($name)};
    }
    return $self->{by_name}->{$name};
}

sub add_class
{
    my $self = shift;
    my $class = shift;
    my $mode = shift;
    my $c = $self->{conf};

    if (ref($class) ne 'Class') {
        die "Expected 'Class' ref";
    }

    my $name = $class->{name};    
    if ($mode == 2) {
        $self->{macros}->{$name} = $class;
        return;
    }
    
    my $class2 = $self->{by_name}->{$name};
    if (defined $class2) {
        if (!$c->{duplicates} || $c->{duplicates} eq 'fail') {
            throw(ALREADY_EXISTS);
        }
        if ($c->{duplicates} eq 'skip') {
            return;
        } elsif ($c->{duplicates} eq 'overwrite') {
            splice @$self, $class2->{index}, 1;
        }
    }

    my $index = push(@$self, $class) - 1;
    $class->{index} = $index;
    $self->{by_name}->{$name} = $class;
    $self->{by_name_lc}->{lc($name)} = $class;
}

sub sort
{
    my $self = shift;
    $self->{sorted} = [
        sort {$a cmp $b} @{$self->{array}}
    ];
}

1;

package FileLink;
use strict;
use File::Basename;

sub new
{
    my $class = shift;
    $class = (ref $class || $class);
    my $self = bless {
        prev => undef,
        next => undef
    } => $class;
    return $self;
}

sub set
{
    my $self = shift;
    my $file = shift;
    $self->{path} = $file;
    $file = basename($file);
    $self->{name} = $file;
}

sub make_next
{
    my $self = shift;
    my $next = $self->new();
    $next->{prev} = $self;
    $self->{next} = $next;
}

sub relink_after
{
    my $self = shift;
    my $after = shift;
    if ($self->{prev}) {
        $self->{prev}->{next} = $self->{next};
    }
    $self->{next}->{prev} = $self->{prev};
    $self->{next} = $after->{next};
    $self->{prev} = $after;
    if ($after->{next}) {
        $after->{next}->{prev} = $self;
    }
    $after->{next} = $self;
}

1;


package Parser;
use strict;
use Data::Dumper;
our @ISA="Autoconstructible";

Exception->import('throw');

use constant {
    EOF => 1,
    PARSE_ERROR => 2,
    ALREADY_EXISTS => 3,
    POSTPONE => 4
};


sub new
{
    my ($class, $c) = (shift, shift);
    if (ref($c) ne 'Config') {
        $c = Config->new();
    }
    $class = (ref $class || $class);
    my $self = bless {
        conf => $c,
        data => ClassData->new($c),
        files_chain => FileLink->new(),
        files_by_name => {}
    } => $class;
    return $self;
}

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

sub parse_file
{
    __PACKAGE__->__construct_if_required__(\@_);

    my $self = shift;
    my $file = shift;
    my $c = $self->{conf};

    my $fh = File->open($c, $file->{path});

    # To evade 'variable will not stay shared' error
    # anonymous subs must be used. Hope, this will be
    # fixed in V6...
    my $find = sub(&)
    {
        my $match = shift;
        my $res;
        while (<$fh>) {
            if ($res = &$match) {
                $_ = <$fh>;
                defined $_ or throw(EOF);
                return $res;
            }
        }
        throw(EOF);
    };


    my $match = sub(&)
    {
        my $match = shift;
        my $res = &$match or
            throw(PARSE_ERROR);
        $_ = <$fh>;
        defined $_ or $res < 0 or throw(EOF);
        return $res;
    };

    my $error = 0;

    do {
        $fh->{dont_process} = 0;
        try {
            my $class;
    
            my $res0 = &$find (sub{
                m/^\s*DECLARE_INTERFACE_\s*\(\s*(\w+)\s*,\s*(\w+)\s*\)\s*{\s*$/
                    and do {
                        my ($name, $parent) = ($1, $2);
                        $c->{classes_regex}
                            and $name !~ m/$c->{classes_regexp}/
                            and return -1;
                        $class = Class->new({
                            name => $name,
                            parent => $parent,
                            file => $file,
                            data => $self->{data}
                        });
                        $class->add_text($_);
                        return 1;
                    };
                m/^\s*#define\s+(\w+)_METHODS\(\w+\)\s*\\\s*$/
                    and do {
                        $class = Class->new({
                            name => $1,
                            parent => '(MACRO)'
                        });
                        $fh->{dont_process} = 1;
                        return 2;
                    };
                m/^\s*#include\s*[<"](.*)[">]\s*$/
                    and do {
                        my $include = $self->{files_by_name}->{$1};
                        if (!defined $include or $include->{finished}) {
                            return 0;
                        }
                        $file->relink_after($include);
                        throw(POSTPONE);
                    };
            });
            
            if ($res0 <= 0) {
                return;
            }
            
            # check trailing '\' for macro directives
            my $end = $res0 == 2 ?
                sub { m/\\\s*$/ ? 1 : -1 } :
                sub { 1 };

            my $res = 1;
            do {
                my $method_name;
                
                $class->add_text($_);
                $res = &$match (sub{
                    m/^\s*STDMETHOD\s*\(\s*(\w+)\s*\)\s*(\(.*\))/
                        and $class->add_method($1, $2),
                        return &$end;
                    m/^\s*STDMETHOD_\s*\((\s*(\w+.*)\s*,)+\s*(\w+)\s*\)\s*(\(.*\))/
                        and $class->add_method($3, "(${2})${4}"),
                        return &$end;
                    m/^\s*(\w+)_METHODS\s*\(/
                        and
                        return $class->add_methods_from_macro($1) && &$end;
                    if ($res0 == 1) {
                        m/^\s*}\s*;\s*$/
                            and return -1;
                    }
                    m[^\s*(//.*|/\*.*\*/\s*)?$]
                        and do {
                            $class->add_comment($1)
                                if $1;
                            return 1;
                        };
                    m|^\s*/\*.*$|
                        and $class->add_comment(),
                        return 2;
                    return 0;
                });
                
                while ($res > 1) {
                    $class->add_text($_);
                    $res = &$match (sub{
                        $class->add_comment();
                        m|\*/\s*$|
                            and return 1;
                        return 2;
                    });
                }
            } while ($res > 0);
            
            $self->{data}->add_class($class, $res0);
            $self->print_verbose($fh->{file});
        }
        catch {
            $error = $_;
            if ($error == PARSE_ERROR) {
                if ($c->{parse_errors} eq 'skip') {
                    $error = undef;
                    return;
                }
                my $msg = "Parse error at $fh->{file} line $fh->{line}:\n".
                    $fh->context();
                if ($c->{parse_errors} eq 'show') {
                    print STDERR $msg;
                } else {
                    die $msg;
                }
            } elsif ($error == ALREADY_EXISTS) {
                die "Duplicate class at $fh->{file} line $fh->{line}:\n".
                    $fh->context();
            } elsif ($error == EOF) {
                $file->{finished} = 1;
            } elsif ($error == POSTPONE) {
                return;
            } else {
                die $error;
            }
        };
    } until ($error);

    return $self;
}

sub print_verbose
{
    my $self = shift;
    my $c = $self->{conf};
    if ($c->{verbose}) {
        print @_, "\n";
    }
}

sub number_item
{
    my $self = shift;
    my $n = shift;
    my $item = shift;
    my $c = $self->{conf};
    return $c->{number_list} ? sprintf("% 3d. %s", ++$$n, $item) : $item;
}

sub list_classes
{
    my $self = shift;
    my $c = $self->{conf};
    my $data = $self->{data};

    my $n = 0;
    for my $class (@$data) {
        print $self->number_item(\$n, $class->{name}).
            " (". @{$class->{methods}}. ") ".
            " [". $class->{file}->{name}. "]\n";
    }
}

sub source
{
    my $self = shift;
    my $c = $self->{conf};
    my $data = $self->{data};
    
    for my $class (@$data) {
        print join("\n", @{$class->{text}}), "\n";
    }
}

sub list_class
{
    my $self = shift;
    my $name = shift;
    my $data = $self->{data};
    
    my $class = $data->get_by_name($name);
    my $n = 0;
    for my $method (@$class) {
        print $self->number_item(\$n, $method), "\n";
    }
}


sub produce
{
    my $self = shift;
    my $c = $self->{conf};
    my $data = $self->{data};
    my $statement;
    my $member;

    if ($c->{produce} eq 'enum') {
        $statement = 'enum';
        $member = sub { sprintf("  $_[0]". $c->{infix}. "$_[1] = 0x%X,", $_[2]) };
    } else {
        $statement = 'struct';
        $member = sub { "  DWORD $_[1];" };
    }
    
    for my $class (@$data) {
        print $statement. " ".
            $c->{prefix}.
            $class.
            $c->{postfix}.
            "\n{\n";
        my $offset = 0;
        for my $method (@{$class->{methods}}) {
            if (ref($method->{comments_top}) eq 'ARRAY') {
                print join("\n", map {"  $_"} @{$method->{comments_top}}), "\n";
            }
            print &$member($class, $method, $offset).
                ($method->{side_comment} ? " // ". $method->{side_comment} : "").
                "\n";
            $offset += 4;
        }
        print "};\n\n"
    }
}

sub read_files
{
    my $self = shift;
    my $files = shift;
    my $link = $self->{files_chain};
    
    for my $file (@$files) {
        if ($link->{path}) {
            $link = $link->make_next();
        }
        $link->set($file);
        $self->{files_by_name}->{$link->{name}} = $link;
    }
    
    my $next;
    for ($link = $self->{files_chain}; defined $link; $link = $next)
    {
        $next = $link->{next};
        $self->parse_file($link);
    }
        
    if ($self->{conf}->{sort}) {
        $self->{data}->sort();
    }
}

1;

package Finder;
use strict;
our @ISA="Autoconstructible";

use overload
    '@{}' => sub { return $_[0]->{files}; };

sub new
{
    my ($class, $c) = (shift, shift);
    if (ref($c) ne 'Config') {
        $c = Config->new();
    }
    $class = (ref $class || $class);
    my $self = bless {
        conf => $c,
        files => []
    } => $class;
    
    $self->{rxlist} = [
        map {
            s/^\s*(\S.*)$/$1/;
            s/^(.*\S)\s*$/$1/;
            my $rx = Text::Glob::glob_to_regex_string($_);
            qr/^$rx$/i;
        }
        split(',', $c->{filemask})
    ];
    return $self;
}

sub find
{
    __PACKAGE__->__construct_if_required__(\@_);

    my $self = shift;
    my $args = shift;
    my $files = $self->{files};

    for my $arg (@$args) {
        if (-f $arg) {
            push @$files, $arg;
            next;
        }
        if (-d $arg) {
            $self->expand_dir($arg);
        } else {
            die "${arg}: is not file or directory!\n"
        }
    }

    return $self;
}

sub expand_dir
{
    my $self = shift;
    my $dir = shift;

    opendir my $dh, $dir
        or die "$dir: $!\n";

    my @files =
        map {
            "${dir}/${_}"
        } grep {
            my $match = 0;
            for my $rx (@{$self->{rxlist}}) {
                m/$rx/ and do {
                    $match = 1;
                    last;
                }
            }
            $match;
        } readdir $dh;

    closedir $dh;
    push @{$self->{files}}, @files;
}

1;


package main;
use strict;

my $c = Config::get_options();
$c->dump($c);

@ARGV or push @ARGV, '.';

my $files = Finder::find(\@ARGV);
$c->dump($files);

my $p = Parser->new($c);
$p->read_files($files);
$c->dump($p);

if ($c->{check}) {
    exit 0;
}

if ($c->{list_classes}) {
    $p->list_classes();
    exit 0;
}

if ($c->{list_class}) {
    $p->list_class($c->{list_class});
    exit 0;
}

if ($c->{source}) {
    $p->source();
    exit 0;
}

$p->produce();

1;


package Autoconstructible;

our @ISA = 'Exporter';
our @EXPORT = qw(__construct_if_required__);

sub __construct_if_required__(*)
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

use Exporter 'import';
use base 'Exporter';

BEGIN {
    our @EXPORT = qw(&throw);
    our @EXPORT_OK = qw(&throw);
}

sub throw
{
    my $data = shift;
    my $class = __PACKAGE__;
    if (ref($data) eq $class || $data eq $class) {
        $data = shift;
    }
    my $self = bless [$data] => $class;
    die $self;
}

1;



# Third-party libs
# pasted in sake of mobility

package Text::Glob;
use strict;
use vars qw/$VERSION
            $strict_leading_dot $strict_wildcard_slash/;
$VERSION = '0.08';

$strict_leading_dot    = 1;
$strict_wildcard_slash = 1;

use constant debug => 0;

sub glob_to_regex {
    my $glob = shift;
    my $regex = glob_to_regex_string($glob);
    return qr/^$regex$/;
}

sub glob_to_regex_string
{
    my $glob = shift;
    my ($regex, $in_curlies, $escaping);
    local $_;
    my $first_byte = 1;
    for ($glob =~ m/(.)/gs) {
        if ($first_byte) {
            if ($strict_leading_dot) {
                $regex .= '(?=[^\.])' unless $_ eq '.';
            }
            $first_byte = 0;
        }
        if ($_ eq '/') {
            $first_byte = 1;
        }
        if ($_ eq '.' || $_ eq '(' || $_ eq ')' || $_ eq '|' ||
            $_ eq '+' || $_ eq '^' || $_ eq '$' || $_ eq '@' || $_ eq '%' ) {
            $regex .= "\\$_";
        }
        elsif ($_ eq '*') {
            $regex .= $escaping ? "\\*" :
              $strict_wildcard_slash ? "[^/]*" : ".*";
        }
        elsif ($_ eq '?') {
            $regex .= $escaping ? "\\?" :
              $strict_wildcard_slash ? "[^/]" : ".";
        }
        elsif ($_ eq '{') {
            $regex .= $escaping ? "\\{" : "(";
            ++$in_curlies unless $escaping;
        }
        elsif ($_ eq '}' && $in_curlies) {
            $regex .= $escaping ? "}" : ")";
            --$in_curlies unless $escaping;
        }
        elsif ($_ eq ',' && $in_curlies) {
            $regex .= $escaping ? "," : "|";
        }
        elsif ($_ eq "\\") {
            if ($escaping) {
                $regex .= "\\\\";
                $escaping = 0;
            }
            else {
                $escaping = 1;
            }
            next;
        }
        else {
            $regex .= $_;
            $escaping = 0;
        }
        $escaping = 0;
    }
    print "# $glob $regex\n" if debug;

    return $regex;
}

sub match_glob {
    print "# ", join(', ', map { "'$_'" } @_), "\n" if debug;
    my $glob = shift;
    my $regex = glob_to_regex $glob;
    local $_;
    grep { $_ =~ $regex } @_;
}

1;
