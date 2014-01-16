#!/usr/bin/perl

package Parser;

use strict;
use HTML::Parser ();

my %by_group;
my $c;

sub parse
{
    $c = shift;
    my $p = HTML::Parser->new(
                            api_version => 3,
                            handlers => {
                                start => [\&start, "tagname"],
                                end => [\&end, "tagname"],
                                text => [\&text,   "text,length"]
                            },
                            unbroken_text => 0);

    if (! $p->parse_file($c->{input_file})) {
        die "$c->{input_file}: $!\n";
    }

    my $data = {
        conf => $c,
        groups => \%by_group
    };

    return $data;
}

my $tag;
my $prev_tag;
my $prev;
my $group;
my $browser;
my @out;

sub start
{
    $prev = 0;
    if ($_[0] eq 'img') {
        return;
    }

    $tag = $_[0];

    if (defined $group && defined $browser && $tag eq 'a') {
        return;
    }

    if (defined $group && $tag eq 'h4') {
        undef $browser;
        return;
    }

    if ($tag eq 'h3') {
        undef $group;
        undef $browser;
    }

    if ($tag eq 'script') {
        undef $group;
        undef $browser;
    }
}

sub end
{
    $prev = 0;
    undef $tag;
}

sub text
{
    my $text = $_[0];

    if ($prev == 2) {
        return;
    }

    if ($tag eq 'h3') {
        if ($prev) {
            $group .= $text;
        } else {
            $group = $text;
        }
    } elsif ($tag eq 'h4') {
        if ($prev) {
            $browser .= $text;
        } else {
            $browser = $text;
        }
    } elsif (defined $group && defined $browser && $tag eq 'a') {
        if ($prev) {
            $out[-1]->[2] .= $text;
        } else {
            if ($text =~ m/^More\s+/) {
                $prev = 2;
                return;
            }
            if ($c->{valid_browsers}) {
                for my $vb (@{$c->{valid_browsers}->{data}}) {
                    if ($text =~ m/$vb/) {
                        goto matched;
                    }
                }

                $prev = 2;
                return;

                matched:
            }
            push @out, [$group, $browser, $text];
            push @{$by_group{$group}}, \$out[-1]->[2];
        }
    }

    $prev = 1;
}

1;


package Processor;
use strict;

my %group_subst = (
    'Internet Explorer' => 'MSIE',
    'theWorld Browser' => 'TheWorld',
    'Tencent Traveler' => 'TencentTraveler',
    'surf' => 'Surf',
    'Rekonq' => 'rekonq'
);

my @group_drop = (
    'WorldWideWeb'
);

my %alternatives = (
    'LeechCraft' => 'Leechcraft',
    'Conkeror' => 'conkeror',
    'Maxthon' => 'MAXTHON',
    'SeaMonkey' => 'Seamonkey',
    'Epiphany' => ['epiphany-browser', 'epiphany-webkit'],
    'Firefox' => 'firefox',
    'uzbl' => 'Uzbl',
    'KKman' => 'KKMAN',
    'Elinks' => 'ELinks',
    'Iceweasel' => ['IceWeasel', 'iceweasel'],
    'Prism' => 'prism',
    'NCSA_Mosaic' => 'NCSA Mosaic',
    'Midori' => 'midori',
    'Sunrise' => 'SunriseBrowser',
    'Navscape' => 'NavscapeNavigator'
);

my @architectures = (qw'
    i386
    i686
    Mach-O
    x86_64
    arm
    i86pc
    sun4u
    sun4m
    x86pc
');

my @os_strings = (
    'Windows NT',
    'Intel Mac OS X',
    'Mac OSX',
    'Mac OS X',
    'Windows CE',
    'Windows XP',
    'Windows ME', qw'
    Windows
    WinNT
    Win98
    Win95
    Darwin
    Macintosh
    Mac_PowerPC
    SunOS
    Debian
    Ubuntu
    Fedora
    Syllable
    Linux
    FreeBSD
    NetBSD
    OpenBSD
    DragonFly
    IRIX64
    IRIX
    AIX
    HP-UX
    OpenSolaris
    Wii
    AmigaOS
    CP/M86
    BeOS
    QNX',
    'Star-Blade OS', qw'
    PalmOS
    webOS
    Symbian
    Mac_68K'
);

my %ignore_deps = (
    'Firefox' => 'Mozilla'
);

my @groups_without_os = (qw(
    retawq
    Oregano
    Surf
    Dooble
    Charon
    HotJava
    Lynx
    Dillo
    Vimprobable),
    'Enigma Browser',
    'IBM WebExplorer'
);

my %versions_fallback => (
    'Iceweasel' => 'Firefox',
    'Sundance' => 'Version'
);

my @groups_without_versions = (qw(
    TenFourFox
    Maxthon
    Lunascape
));


sub new
{
    my $class = shift;
    my $data = shift;

    $class = (ref $class || $class);
    bless my $self = {
        %$data,
        oses => \@os_strings,
        alternatives => \%alternatives,
        without_os => { map { $_ => 1 } @groups_without_os },
        without_versions => { map { $_ => 1 } @groups_without_versions }
    }, $class;
    return $self;
}

sub check_group_is_in_text
{
    my $self = shift;
    my $groups = $self->{groups};

    my %problematic_groups;

    GROUP:
    for my $g (keys %$groups) {
        for my $t (@{$groups->{$g}}) {
            if ($$t !~ m/$g/) {
                $problematic_groups{$g} = 1;
                next GROUP;
            }
        }
    }

    GROUP:
    for my $g (keys %problematic_groups) {
        for my $t (@{$groups->{$g}}) {
            if ($$t =~ m/$g/) {
                $problematic_groups{$g} = 0;
                next GROUP;
            }
        }
    }

    return \%problematic_groups;
}

sub check_versions
{
    my $self = shift;
    my $groups = $self->{groups};
    my $c = $self->{conf};
    my $delims = $c->{version_delimiters};
    my $stops = $c->{version_stoppers};

    my %problematic_delimiters;
    my %no_delimiters;
    my %starts_not_digit;
    my %problematic_end;

    GROUP:
    for my $g (keys %$groups) {
        for my $t (@{$groups->{$g}}) {
            if ($$t =~ m/$g(.*)$/) {
                my $v = $1;
                my $version_found = 0;
                if ($v =~ m/^\d/) {
                    $version_found = 1;
                    $no_delimiters{$g} = $v
                        unless exists $no_delimiters{$g};
                } elsif ($v =~ m|^[${delims}](.+)$|) {
                    $version_found = 1;
                    if (!exists $starts_not_digit{$g} && $1 =~ m/^\D/) {
                        $starts_not_digit{$g} = $v;
                    }
                } elsif (!exists $problematic_delimiters{$g}) {
                    $problematic_delimiters{$g} = $v;
                }

                if ($version_found && !exists $problematic_end{$g}) {
                    if ($v =~ m/(.+?)([${stops}]|$)/) {
                        if (length($1) > 20) {
                            $problematic_end{$g} = $v;
                        }
                    } else {
                        $problematic_end{$g} = $v;
                    }
                }
            }
        }
    }

    return {
        problematic_delimiters => \%problematic_delimiters,
        no_delimiters => \%no_delimiters,
        starts_not_digit => \%starts_not_digit,
        problematic_end => \%problematic_end
    };
}

sub print_problematic_versions
{
    my $self = shift;
    my $version_check = shift;

    print "Following groups has problematic version delimiters:\n";

    my $pd = $version_check->{problematic_delimiters};
    for my $g (keys %$pd) {
        print $g, "($pd->{$g})\n";
    }
    print "\n";

    print "Following groups has no version delimiters:\n";

    my $nd = $version_check->{no_delimiters};
    for my $g (keys %$nd) {
        print $g, "($nd->{$g})\n";
    }
    print "\n";

    print "Following groups has versions that start not from digit:\n";

    my $snd = $version_check->{starts_not_digit};
    for my $g (keys %$snd) {
        print $g, "($snd->{$g})\n";
    }
    print "\n";

    print "Following groups has unknown version stopper or version length > 20 chars:\n";

    my $pe = $version_check->{problematic_end};
    for my $g (keys %$pe) {
        print $g, "($pe->{$g})\n";
    }
    print "\n";
}

sub print_problematic_groups
{
    my $self = shift;
    my $groups = $self->{groups};
    my $c = $self->{conf};

    # fix alternatives
    for my $g (keys %alternatives) {
        if (!exists $groups->{$g}) {
            next;
        }
        my $move_to;
        if (ref $alternatives{$g} eq 'ARRAY') {
            $move_to = $alternatives{$g};
        } else {
            $move_to = [$alternatives{$g}];
        }
        for my $new_g (@$move_to) {
            for (my $ti = 0; $ti < @{$groups->{$g}};) {
                my $t = $groups->{$g}->[$ti];
                if ($$t =~ m/$new_g/) {
                    push @{$groups->{$new_g}}, $t;
                    splice @{$groups->{$g}}, $ti, 1;
                } else {
                    ++$ti;
                }
            }
        }
    }

    my $problematic_groups = $self->check_group_is_in_text();
    print "Following groups has not even one entry in its UA strings:\n";

    for my $g (keys %$problematic_groups) {
        if ($problematic_groups->{$g}) {
            print $g, "\n";
        }
    }
    print "\n";

    print "Following groups has some UA strings, where they have no entry:\n";

    for my $g (keys %$problematic_groups) {
        if ($problematic_groups->{$g} == 0) {
            print $g, "\n";
        }
    }
    print "\n";

    my $version_check = $self->check_versions();
    $self->print_problematic_versions($version_check);
}

sub check_oses
{
    my $self = shift;
    my $groups = $self->{groups};
    my $c = $self->{conf};

    my %os_used = map { $_ => 0 } @os_strings;

    os:
    for my $os (@os_strings) {
        for my $g (keys %$groups) {
            for my $t (@{$groups->{$g}}) {
                if ($$t =~ m/$os/) {
                    $os_used{$os} = 1;
                    next os;
                }
            }
        }
    }

    my %have_os;
    group:
    for my $g (keys %$groups) {
        for my $t (@{$groups->{$g}}) {
            for my $os (@os_strings) {
                if ($$t =~ m/$os/) {
                    $have_os{$g} = 1;
                    next group;
                }
            }
        }
    }

    my @os_unknown;
    for my $g (keys %have_os) {
        text:
        for my $t (@{$groups->{$g}}) {
            for my $os (@os_strings) {
                if ($$t =~ m/$os/) {
                    next text;
                }
            }
            push @os_unknown, $t;
        }
    }

    my %no_delimiters;
    my %starts_not_digit;
    my %problematic_delimiters;
    my %problematic_end;

    for my $g (keys %have_os) {
        text:
        for my $t (@{$groups->{$g}}) {
            for my $os (@os_strings) {
                if ($$t =~ m/$os(.+)$/) {
                    my $v = $1;
                    my $version_found = 0;

                    if ($v =~ m/^\d/) {
                        $version_found = 1;
                        $no_delimiters{$os} = $v
                            unless exists $no_delimiters{$os};
                    } elsif ($v =~ m|^[/\- \(](.+)$|) {
                        $version_found = 1;
                        if (!exists $starts_not_digit{$os} && $1 =~ m/^\D/) {
                            $starts_not_digit{$os} = $v;
                        }
                    } elsif (!exists $problematic_delimiters{$os}) {
                        $problematic_delimiters{$os} = $v;
                    }

                    if ($version_found && !exists $problematic_end{$g}) {
                        if ($v =~ m/(.+?)([ ;\)\(\/]|$)/) {
                            if (length($1) > 20) {
                                $problematic_end{$os} = $v;
                            }
                        } else {
                            $problematic_end{$os} = $v;
                        }
                    }
                    next text;
                }
            }
        }
    }

    return {
        unused => [grep { $os_used{$_} == 0 } @os_strings],
        unknown => \@os_unknown,
        without_os => [
            map {
                my $x = '';
                if ($c->{examples}) {
                    $x = $groups->{$_}->[0];
                    $x = ref $x ? $$x : "*not found*";
                    $x = " (${x})";
                }
                $_. $x
            } grep {
                !exists $have_os{$_}
            } keys %$groups
        ],
        no_delimiters => \%no_delimiters,
        starts_not_digit => \%starts_not_digit,
        problematic_delimiters => \%problematic_delimiters,
        problematic_end => \%problematic_end
    };
}

sub print_os_check
{
    my $self = shift;
    my $c = $self->{conf};

    my $os_info = $self->check_oses();

    print "Following groups has not even one OS detected:\n",
        join("\n", @{$os_info->{without_os}}), "\n\n";

    print "Following OSes was never used:\n",
        join("\n", @{$os_info->{unused}}), "\n\n";

    print "Following strings has no OS detected:\n",
        join("\n", map {$$_} @{$os_info->{unknown}}[0..$c->{max_print} - 1]), "\n\n";

    $self->print_problematic_versions($os_info);
}

sub print_versions
{
    my $self = shift;
    my $groups = $self->{groups};
    my $c = $self->{conf};
    my $delims = $c->{version_delimiters};
    my $delims2 = $c->{version_delimiters2};
    my $stops = $c->{version_stoppers};

    my %versions;
    my %unmatched;

    for my $g (keys %$groups) {
        if ($c->{by_group} && $c->{by_group} != 1 && $c->{by_group} ne "$g") {
            next;
        }

        $versions{$g} = 0;
        for my $t (@{$groups->{$g}}) {
            if ($$t !~ m/$g(.*)$/) {
                next;
            }

            my $v = $1;
            if ($v !~ m/^((\d)|[${delims}](\d)| [${delims2}](\d))(.*?)([$stops]|$)/) {
                push @{$unmatched{$g}}, $t;
                next;
            }

            my $ver = "$2$3$4$5";
            $versions{$g} = {}
                unless $versions{$g};
            $versions{$g}->{$ver} = 1;
        }
    }

    if ($c->{unmatched}) {
        for my $g (keys %unmatched) {
            if ($versions{$g} && $c->{only_empty}) {
                next;
            }
            if (!$versions{$g} && !$c->{only_empty}) {
                next;
            }
            if ($c->{by_group} == 1) {
                print "${g}:\n";
            }
            for my $t (@{$unmatched{$g}}) {
                print "$$t\n";
            }
            if ($c->{by_group} == 1) {
                print "\n";
            }
        }
    } else {
        for my $g (keys %versions) {
            if ($versions{$g}) {
                if ($c->{only_empty}) {
                    next;
                }
                if ($c->{by_group} == 1) {
                    print "${g}: ";
                }
                for my $ver (keys %{$versions{$g}}) {
                    print "${ver}  ";
                }
                if ($c->{by_group} == 1) {
                    print "\n";
                }
            } elsif ($c->{only_empty}) {
                print "${g}\n"
            }
        }
        print "\n";
    }
}

sub fix_groups
{
    my $self = shift;
    my $groups = $self->{groups};

    for my $g (@group_drop) {
        delete $by_group{$g};
    }

    for my $g (keys %group_subst) {
        my $tmp = $groups->{$g};
        $groups->{$group_subst{$g}} = $tmp;
        delete $groups->{$g};
    }
}

sub check_group_uniqueness
{
    my $self = shift;
    my $groups = $self->{groups};

    my %non_unique;

    for my $g (keys %$groups) {
        for my $h (keys %$groups) {
            if ($g eq $h || exists $ignore_deps{$g} && $ignore_deps{$g} eq $h) {
                next;
            }
            for my $t (@{$groups->{$h}}) {
                if ($$t =~ m/$g/) {
                    push @{$non_unique{$g}->{$h}}, $t;
                }
            }
        }
    }

    return \%non_unique;
}

sub reorder_groups
{
    my $self = shift;
    my $sorted = shift;

    my $non_unique = $self->check_group_uniqueness();


    my @basket; # basket of free saplings
    my @levels; # where saplings will be planted

    # build array of saplings, put them into basket
    for my $x (keys %$non_unique) {
        my $sapling = {
            id => $x,
            parent => undef,
            hints => $non_unique->{$x}
        };
        push @basket, $sapling;
    }

    # cycle free saplings
    while (@basket) {
        my $s = pop @basket;

        # try to attach on already planted saplings
        LEVELS:
        for (my $l = $#levels; $l >= 0; --$l) {
            PLANTED:
            for my $planted (values %{$levels[$l]}) {
                if (!exists $planted->{hints}->{$s->{id}}) {
                    next PLANTED;
                }
                # hint child found, put $s onto $planted
                $s->{parent} = $planted;
                # put it into next level
                $levels[$l + 1]->{$s->{id}} = $s;
                # replant lower saplings onto it, if any
                for (my $m = 0; $m <= $l; ++$m) {
                    LOWER:
                    for my $lower (values %{$levels[$m]}) {
                        if (exists $s->{hints}->{$lower->{id}}) {
                            # check that it grows not from parent
                            for (my $p = $s; ; $p = $p->{parent}) {
                                if ($p == $lower) {
                                    print "Loop found: $p->{id} <-> $s->{id}\n";
                                    next LOWER;
                                }
                                last until defined $p->{parent};
                            }

                            # ok, we can replant $lower onto $s
                            $lower->{parent} = $s;

                            # change level
                            delete $levels[$m]->{$lower->{id}};
                            $levels[$l + 2]->{$lower->{id}} = $lower;
                        }
                    }
                } # replant
                # done job, $s is planted
                $s = undef;
                last LEVELS;
            } # $planted
        } # $l

        # if not yet planted, put it into level 0
        if (defined $s) {
            $levels[0]->{$s->{id}} = $s;
        }
    }

    # generate plain sorted array
    my %check;
    for (my $l = $#levels; $l >= 0; --$l) {
        for my $s (values %{$levels[$l]}) {
            for my $h (keys %{$s->{hints}}) {
                push @$sorted, $h
                    if ++$check{$h} == 1;
            } # hints
            push @$sorted, $s->{id}
                if ++$check{$s->{id}} == 1;
        } # saplings
    }

    return \%check;
}

sub get_alts
{
    my $self = shift;
    my $g = shift;

    if (!exists $self->{alternatives}->{$g}) {
        return undef;
    }

    my $a = ref $self->{alternatives}->{$g} eq 'ARRAY' ?
         $self->{alternatives}->{$g} :
         [$self->{alternatives}->{$g}];

    if (@$a) {
        return $a;
    }

    return undef;
}

1;


package main;

use strict;
use Getopt::Long qw(:config bundling);
use Data::Dumper;

Getopt::Long::Configure(qw(
    permute
    pass_through
));

my %c = (
    verbose => 0,
    fix_groups => 1,
    reorder_groups => 1,
    max_print => 30,
    examples => 1,
    version_delimiters => quotemeta('-/ ('),
    version_delimiters2 => quotemeta('(/'),
    version_stoppers => quotemeta(' ;()/')
);

GetOptions (\%c, qw(
    input_file|input-file|i=s
    valid_browsers|valid-browsers|vb=s
    print_group|print-group|pg=s
    check_group|check-group|cg=s
    list_groups|list-groups|lg
    list_items|list|l
    dump_groups|dump-groups|dump
    dump_conf|dump-conf
    print_versions|print-versions|pv
    by_group|by-group|g:s
    only_empty|only-empty|e
    unmatched|u
    grep_text|grep-text|gt=s
    problematic|find-problematic|pbl
    os_check|os-check|oc
    fix_groups|fix-groups|fix!
    non_unique|find-non-unique|non-unique|nu
    reorder_groups|reorder-groups|reorder|rg!
    max_print|max-print|M=i
    examples|ex!
    export_browsers|export-browsers|eb
    export_oses|export-oses|eo
    quiet|q
    verbose|v+
    help|h
));

if (!$c{input_file}) {
    die "Required option missing: --input-file\n";
}

if ($c{by_group} eq '') {
    $c{by_group} = 1;
}

if ($c{valid_browsers}) {
    open VB, '<', $c{valid_browsers}
        or die "$c{valid_browsers}: $!\n";

    my @vb = map { chomp; $_ } <VB>;
    $c{valid_browsers} = {
        file => $c{valid_browsers},
        data => \@vb
    }
}

if ($c{dump_conf}) {
    print Dumper(\%c);
    exit 0;
}

my $d = Parser::parse(\%c);
my $groups = $d->{groups};

if ($c{dump_groups}) {
    print Dumper($d->{groups});
    exit 0;
}

my $p = Processor->new($d);

if ($c{fix_groups}) {
    $p->fix_groups();
}

if ($c{list_groups}) {
    for my $g (sort keys %$groups) {
        print "${g}\n";
    }
    exit 0;
}

if ($c{list_items}) {
    for my $g (sort keys %$groups) {
        for my $t (@{$groups->{$g}}) {
            print $$t, "\n";
        }
    }
}

if ($c{problematic}) {
    $p->print_problematic_groups();
    exit 0;
}

if ($c{os_check}) {
    $p->print_os_check();
    exit 0;
}

if ($c{print_versions}) {
    $p->print_versions();
    exit 0;
}

if ($c{print_group}) {
    for my $t (@{$d->{groups}->{$c{print_group}}}) {
        print $$t, "\n";
    }
    exit 0;
}

if ($c{check_group}) {
    for my $t (@{$d->{groups}->{$c{check_group}}}) {
        if ($$t !~ m/$c{check_group}/) {
            print $$t, "\n";
        }
    }
    exit 0;
}

if ($c{grep_text}) {
    for my $g (keys %$groups) {
        for my $t (@{$groups->{$g}}) {
            if ($$t =~ m/$c{grep_text}/) {
                print $$t, "\n";
            }
        }
    }
    exit 0;
}

if ($c{non_unique}) {
    my $non_unique = $p->check_group_uniqueness();
    $Data::Dumper::Maxdepth = 2;
    print Dumper($non_unique);
    exit 0;
}

if ($c{export_browsers}) {
    my @output;
    my %input = %$groups;

    if ($c{reorder_groups}) {
        $p->reorder_groups(\@output);
        map { delete $input{$_} } @output;
    }

    push @output, (keys %input);
    for my $g (@output) {
        my $s = "SubString(\"${g}\", ". length($g).")";

        my @flags;

        if (exists $p->{without_versions}->{$g}) {
            push @flags, "BrowserInfo::WITHOUT_VERSION";
        }

        if (exists $p->{without_os}->{$g}) {
            push @flags, "BrowserInfo::WITHOUT_OS";
        }

        if (!@flags) {
            push @flags, "0";
        }

        $s .= ", ". join('|', @flags);

        my $a = $p->get_alts($g);
        if ($a) {
            $s .= ", vl" .
                join '',
                map {
                    "(SubString(\"${_}\", ". length($_). "))"
                } @$a;
        }
        print "{$s},\n";
    }
}

if ($c{export_oses}) {
    for my $os (@{$p->{oses}}) {
        print "{SubString(\"${os}\", ". length($os). ")},\n";
    }
}

1;
