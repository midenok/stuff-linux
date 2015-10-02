#!/usr/bin/perl

package Config;

use Getopt::Long qw(:config bundling);
use Pod::Usage;
use Data::Dumper;
use strict;

our %DEFAULTS = (
    windows => {
        pokerstars_home => "$ENV{LOCALAPPDATA}/PokerStars"
    },
    unix => {
        pokerstars_home =>  "$ENV{HOME}/.wine/drive_c/Program Files/PokerStars"
    }
);


sub new
{
    my $class = shift;
    $class = (ref $class || $class);

    my $play_money = Currency->new();

    my $self = bless {
        verbose => 0,
        from_date => 0,
        till_date => Date->new(Date::date()),
        currencies => [ $play_money ], # by default only Play Money will be shown
        table => 0, # filter by size. 0 means any table size.
        total_currency => $play_money,
        parse_fatal => 1
    } => $class;

    $self->get_options();
    return $self;
}

sub dump
{
    my $c = shift;
    $c->{dump} or return $c;

    my @dump;
    my %save;
    while ($_ = shift) {
        if (! ref $_ && s/^-//) {
            $save{$_} = ${$Data::Dumper::{$_}};
            ${$Data::Dumper::{$_}} = shift;
            next;
        }
        push @dump, $_;
    }

    $c->{dump}--;
    for (@dump) {
        print Dumper($_);
    }
    if (!$c->{dump}) {
        exit 0;
    }

    for (keys %save) {
        ${$Data::Dumper::{$_}} = $save{$_};
    }

    return $c;
}

sub get_options
{
    my $c = shift;

    GetOptions ($c, qw(
        dir=s
        user=s
        today
        day=s
        from_date_str|from-date|from=s
        till_date_str|till-date|till=s
        week:i
        weeks=i
        last|days=i
        table|t=i
        tablo
        currency|c=s
        parse_fatal|parse-fatal|fatal:i
        dump|D+
        verbose|v+
        help|h
    )) or exit 1;

    if ($c->{help}) {
        tie *OUT, __PACKAGE__;
        my $fh = \*OUT;
        pod2usage(-output => $fh, -verbose => 99, -sections => 'SYNOPSIS|COMMANDS|OPTIONS');
    }

    $c->process_options();
    if (!$c->{from_date}) {
        $c->{today} = 1;
        $c->process_options();
    }

    $c->dump($c);

    return $c;
}

sub process_options
{
    my $c = shift;
    my $range_arg;

    for my $arg (qw[from_date_str till_date_str]) {
        if ($c->{$arg}) {
            $arg =~ m/^(.*)_str$/;
            $range_arg = $1;
            $c->{$range_arg} = Date->new($c->{$arg});
        }
    }

    if (exists $c->{day}) {
        if ($range_arg) {
            die "--day cannot be used with --${range_arg}!\n";
        }
        $c->{from_date} = Date->new($c->{day});
        $c->{till_date} = $c->{from_date};
        $range_arg = 'day';
    }

    if ($c->{today}) {
        if ($range_arg) {
            die "--today cannot be used with --${range_arg}!\n";
        }
        $c->{from_date} = $c->{till_date};
    }

    if (defined $c->{week} && !$c->{week}) {
        $c->{week} = 1;
    }

    if ($c->{week}) {
        $c->{weeks} = 1;
        if ($c->{week} > 1) {
            $c->{till_date} -= $c->{till_date}->weekday() + ($c->{week} - 2) * 7;
        }
    }

    if ($c->{weeks} > 0) {
        $c->{last} = $c->{till_date}->weekday();
        $c->{last} += ($c->{weeks} - 1) * 7;
    }

    if ($c->{last}) {
        if ($range_arg) {
            die "--last cannot be used with --${range_arg}!\n";
        }
        $c->{from_date} = Date->new($c->{till_date});
        $c->{from_date} -= $c->{last} - 1;
    }

    if ($c->{currency}) {
        $c->{currencies} = Currency::parse($c->{currency});
        $c->{total_currency} = $c->{currencies}->[0];
    }

    if (!$c->{user}) {
        $c->{user} = $ENV{POKERSTARS_USER} || $ENV{USER};
    }

    if (!$c->{dir}) {
        my $os = ($ENV{OS} =~ m/windows/i) ? 'windows' : 'unix';
        my $pokerstars_home = $ENV{POKERSTARS_HOME} || $DEFAULTS{$os}->{pokerstars_home};
        $c->{dir} = "${pokerstars_home}/TournSummary/$c->{user}";
    }
}

1;

package Date;
use strict;

use Date::Parse;
use Date::Format;
use Time::localtime 'localtime';

use overload
    "<=" => \&operator_le,
    "<" => \&operator_lt,
    "++" => \&operator_pp,
    '""' => \&operator_stringify,
    "=" => \&operator_assign,
    "-=" => \&operator_subassign;

my $now = time;
my $now_tm = localtime($now);


sub new
{
    my $class = shift;
    $class = (ref $class || $class);
    my $date = shift;

    my $self = bless
        (ref($date) eq 'Date' ? { %$date } : {})
    => $class;

    if (ref(\$date) eq 'SCALAR' && defined $date) {
        $self->parse_date($date);
    }
    return $self;
}

sub date
{
    my $time = shift || $now;
    return time2str("%Y%m%d", $time) + 0;
}

sub formatted
{
    my $self = shift;
    return time2str("%a %d-%b-%Y", $self->{time});
}

sub weekday
{
    my $self = shift;
    my $weekday = localtime($self->{time})->[6];
    return $weekday ? $weekday : 7;
}

sub assign_date()
{
    my $self = shift;
    my $date = shift;
    $self->{date} = $date;
    $self->{time} = str2time($date);
    return $self;
}

sub assign_time()
{
    my $self = shift;
    my $time = shift;
    $self->{time} = $time;
    $self->{date} = date($time);
    return $self;
}

sub parse_date()
{
    my $self = shift;
    local $_ = shift;
    my $date = $_;
    if (m/^\d\d?$/) {
        if ($date == 0) {
            return $self->assign_time($now);
        }
        $date += ($now_tm->year + 1900) * 10000 + ($now_tm->mon + 1) * 100;
        return $self->assign_date($date);
    } elsif (m/^\d{4}$/) {
        $date += ($now_tm->year + 1900) * 10000;
        return $self->assign_date($date);
    } elsif (m/^\d{6}$/) {
        $date += 1900 * 10000;
        return $self->assign_date($date);
    } elsif (m/^yesterday$/) {
        return $self->assign_time($now - 24 * 3600);
    } elsif (m/^-(\d+)$/) {
        return $self->assign_time($now - $1 * 24 * 3600);
    }
    return $self->assign_time(str2time($date)
        or die "Wrong date format: ${_}\n");
}

sub operator_le
{
    my $self = shift;
    my $arg = shift;
    my $swap = shift;
    return $self->{date} <= $arg->{date};
}

sub operator_lt
{
    my $self = shift;
    my $arg = shift;
    my $swap = shift;
    return $self->{date} < $arg->{date};
}

sub operator_pp
{
    my $self = shift;
    $self->assign_time($self->{time} + 24 * 3600);
    return $self;
}

sub operator_stringify
{
    my $self = shift;
    return $self->{date};
}

sub operator_assign
{
    my $self = shift;
    return Date->new($self);
}

sub operator_subassign
{
    my $self = shift;
    my $arg = shift;
    $self->assign_time($self->{time} - $arg * 24 * 3600);
    return $self;
}

1;


package Util;
use strict;

sub chop_slash
{
    my $file = shift;
    !$file && return undef;
    $file =~ s/\/+$//;
    $file eq "" and $file = "/";
    return $file;
}

1;


package PokerStars::Tournament;
use strict;

use Date::Format;

sub new
{
    my $class = shift;
    $class = (ref $class || $class);
    my $self = bless {
    } => $class;
    return $self;
}

sub format_sum
{
    my $b = shift;
    my $prefix = shift || '';
    my $t = $b < 0 ? 0 - $b : $b;
    if ($t >= 1000) {
        $t = $t / 1000 . "k";
    }
    $t = ${prefix} . ${t};
    return $b < 0 ? "-${t}" : $t;
}

sub buyin
{
    my $self = shift;
    return format_sum($self->{buyin}, $self->{buyin_currency}->{prefix});
}

sub prize
{
    my $self = shift;
    return format_sum($self->{prize}, $self->{prize_currency}->{prefix});
}

sub time
{
    my $self = shift;
    return time2str("%R", $self->{time});
}

sub winloss
{
    my $self = shift;
    return $self->{win} ? 'W' : 'L';
}

sub winlossXO
{
    my $self = shift;
    return $self->{win} ? 'X' : 'O';
}

sub line
{
    my $self = shift;
    return $self->time(), "  ", $self->buyin(), "  ", $self->winloss(), "  ", $self->{opponent};
}

1;

package PokerStars::TournStats;
use strict;

use overload
    '+=' => sub {
        my $type = ref($_[1]);
        $type eq 'ARRAY' && do {
            map {
                $_[0] += $_;
            } @{$_[1]};
            return $_[0];
        };
        $type eq 'PokerStars::Tournament' &&
            return $_[0]->add_tournament($_[1]);
        $type eq 'PokerStars::TournStats' &&
            return $_[0]->add_tournstats($_[1]);
        die "Wrong argument: ${type}";
    };

sub new
{
    my $class = shift;
    $class = (ref $class || $class);
    my $self = bless {
        wins => 0,
        min_buyin => 0,
        max_buyin => 0,
        profit => 0,
        tourns_n => 0,
        play_time => 0,
        currency => shift
    } => $class;

    return $self;
}

sub add_tournament
{
    my $self = shift;
    my $t = shift;
    die "Wrong argument" if ref($t) ne 'PokerStars::Tournament';

    ++$self->{tourns_n};
    $self->{play_time} += $t->{duration};
    $self->{wins} += $t->{win};

    $self->{currency} = $t->{buyin_currency}
        unless defined $self->{currency};

    if ($self->{currency} == $t->{buyin_currency}) {
        if ($t->{buyin_currency} != $t->{prize_currency}) {
            print STDERR "Won't convert prize $t->{prize_currency} to buyin $t->{buyin_currency}: tournament $t->{id} is skipped!";
            return $self;
        }

        if (!$self->{min_buyin} || $self->{min_buyin} > $t->{buyin}) {
            $self->{min_buyin} = $t->{buyin};
        }
        if ($t->{buyin} > $self->{max_buyin}) {
            $self->{max_buyin} = $t->{buyin};
        }
        $self->{profit} -= $t->{buyin};
        if ($t->{win}) {
            $self->{profit} += $t->{prize};
        }
    }
    return $self;
}

sub add_tournstats
{
    my $self = shift;
    my $s = shift;
    die "Wrong argument" if ref($s) ne 'PokerStars::TournStats';

    $self->{tourns_n} += $s->{tourns_n};
    $self->{wins} += $s->{wins};
    $self->{play_time} += $s->{play_time};

    $self->{currency} = $s->{currency}
        unless defined $self->{currency};

    if ($self->{currency} == $s->{currency}) {
        $self->{profit} += $s->{profit};

        if (!$self->{min_buyin} || $self->{min_buyin} > $s->{min_buyin}) {
            $self->{min_buyin} = $s->{min_buyin};
        }

        if ($s->{max_buyin} > $self->{max_buyin}) {
            $self->{max_buyin} = $s->{max_buyin};
        }
    }
    return $self;
}

sub score
{
    my $self = shift;
    my $score = $self->{wins} * 2 - $self->{tourns_n};
    if ($score > 0) {
        $score = "+${score}";
    }
    return $score;
}

sub score_detail
{
    my $self = shift;
    return $self->score(). ' ('. $self->{wins}. ':'. $self->losses(). ')';
}

sub losses
{
    my $self = shift;
    return $self->{tourns_n} - $self->{wins};
}

sub buyin_range
{
    my $self = shift;
    return PokerStars::Tournament::format_sum($self->{min_buyin}, $self->{currency}->{prefix}) .
        ($self->{min_buyin} != $self->{max_buyin} ? '-' .
            PokerStars::Tournament::format_sum($self->{max_buyin}, $self->{currency}->{prefix}) : '');
}

sub profit_loss
{
    my $self = shift;
    return ($self->{profit} > 0 ? 'profit ' : 'loss ').
        PokerStars::Tournament::format_sum($self->{profit}, $self->{currency}->{prefix});
}

sub profit_detail
{
    my $self = shift;
    return "(" .
        $self->buyin_range(). '; '.
        $self->profit_loss(). ')';
}

our @time_units = (qw(d h m s));

sub play_time
{
    my $self = shift;
    my @play_time = (gmtime $self->{play_time})[7, 2, 1, 0];
    my $rs = '';
    my $out = '';
    for (my $i = 0; $i < @time_units; ++$i) {
        $out .= $rs. $play_time[$i]. $time_units[$i], $rs = ' '
            if $play_time[$i];
    }
    return $out;
}

1;

package Currency;
use strict;

use overload
    '""' => \&operator_stringify,
    '==' => \&operator_eq,
    '!=' => sub { !operator_eq(@_) };

our %names = (
    '' => 'Play Money',
    '$' => 'USD'
);

sub new
{
    my $class = shift;
    my $prefix = shift || '';

    $class = (ref $class || $class);
    my $self = bless {
        prefix => $prefix,
        name => $names{$prefix}
    } => $class;

    die "Unknown currency: $prefix\n"
        unless defined $self->{name};

    return $self;
}

sub operator_stringify
{
    my $self = shift;
    return $self->{name};
}

sub operator_eq
{
    my $a = shift;
    my $b = shift;
    return $a->{prefix} eq $b->{prefix};
}

sub parse
{
    my $param = shift;
    my @prefices;

    if ($param eq 'all') {
        @prefices = keys %names;
    } else {
        @prefices = split(',', $param);
    }

    my @currencies;
    for my $prefix (@prefices) {
        push @currencies, __PACKAGE__->new($prefix);
    }
    return \@currencies;
}


1;


# parse TournSummary files

package PokerStars::TournSummary;
use strict;

use Date::Format;
use Date::Parse;
use Data::Dumper;

sub new
{
    my $class = shift;
    my $conf = shift;
    $class = (ref $class || $class);
    my $self = bless {
      conf => $conf,
      dir => Util::chop_slash($conf->{dir}),
      total_sum => PokerStars::TournStats->new($conf->{total_currency}),
      found_files => 0,
      parsed_days => 0
    } => $class;

    return $self;
}

sub parse_range
{
    my $self = shift;
    my $from = shift;
    my $till = shift;

    for (my $day = $from; $day <= $till; ++$day) {
        $self->parse_day($day);
    }
    if ($self->{found_files} == 0) {
        print STDERR "Warning: no matching files found in $self->{dir}!\n";
    } elsif ($self->{parsed_days} == 0) {
        print STDERR "Warning: no matching tournaments found!\n";
    }
    return $self;
}

sub parse_day
{
    my $self = shift;
    my $dir = $self->{dir};

    my $date = shift;
    opendir (my $dh, $dir) || die "${dir}: $!\n";
    map {
        $self->{found_files}++;
        $self->parse_file($_);
    } grep {
        m/^TS${date}.+\.txt$/
    } readdir $dh;

     my $d = $self->{data};
     if (exists $d->{byday}->{$date}) {
        $d->{byday}->{$date} = [
            sort {
                $a->{time} <=> $b->{time}
            } @{$d->{byday}->{$date}}
        ];
        $self->{parsed_days}++;
        return 1;
    }
    return 0;
}

sub try (&$) {
   my($try, $catch) = @_;
   eval {&$try};
   if ($@) {
      local $_ = $@;
      chomp;
      s/ at $0 line .*$//;
      &$catch;
   }
}

sub catch (&) { $_[0] }

sub match(&$)
{
    my ($match, $line) = @_;
    local $_ = $line;
    &$match or
        die $line;
}

sub verbose_file
{
    my $self = shift;
    my $file = shift;
    my $c = $self->{conf};

    if ($c->{verbose} > 0) {
        $file = $self->{dir}. "/". $file;
    }

    return $file;
}

sub parse_file
{
    my $self = shift;
    my $c = $self->{conf};
    my $file = shift;
    my $dir = $self->{dir};
    my $full_file = $dir. "/". $file;

    if (ref($self->{data}) ne 'HASH') {
        $self->{data} = {};
    }

    my $d = $self->{data};

    my $turnament;

    open F, "<", $full_file or die $self->verbose_file($file). ": $!\n";
    my @l = map { chomp; s/\r$//; $_ } <F>;
    my $mtime = (stat(F))[9];
    close F;

    try {
        my $t = PokerStars::Tournament->new();

        match {
            m/^PokerStars Tournament #(\d+)\D/ and do {
                $t->{id} = $1;
                $d->{byid}->{$1} = $t;
                1;
            };
        } $l[0];

        if ($l[1] !~ m/^Buy-In: / && $l[2] =~ m/^Buy-In: /) {
            $t->{tournament_type} = $l[1];
            delete $l[1];
        }

        match {
            m|^Buy-In: ([\$])?(\d[.0-9]*)/([\$])?(\d[.0-9]*)(\s+(USD))?$| and do {
                $t->{buyin_currency} = Currency->new($1, $6);
                $t->{rake} = $4;
                $t->{buyin} = $2 + $t->{rake};
                1;
            };
        } $l[1];

        match {
            m|^(\d+) players$|
                and $t->{players} = $1, 1
        } $l[2];

        if ($c->{table} > 0 && $t->{players} != $c->{table}) {
            if ($c->{verbose}) {
                print STDERR "(${file}) ". $t->{players}. "-player tournament skipped!\n";
            }
            return;
        }

        match {
            m|Total Prize Pool: ([\$])?(\d[.0-9]*)(\s+(USD))?| and do {
                $t->{prize_currency} = Currency->new($1, $4);
                $t->{prize} = $2;
                1;
            };
        } $l[3];

        match {
            m|^Tournament started (.+) \[(.+)\]$|
                and $t->{time} = str2time($1)
        } $l[4];

        match {
            m|^You finished in (\d+)\D|
                and $t->{win} = $1 == 1 ? 1 : 0, 1;
        } $l[7 + $t->{players}];

        match {
            m|^  \d: (.+)\s\([^(]+\)[^()]*$|
                and $t->{opponent} = $1;
        } $l[$t->{win} ? 7 : 6];

        $t->{duration} = $mtime - $t->{time};

        push @{$d->{byday}->{Date::date($t->{time})}}, $t;
        # $t->{localtime} = [localtime($t->{date})];
    }

    catch {
        if ($self->{conf}->{verbose} > 1) {
            print join("\n", @l), "\n";
        }

        print STDERR "Parsing failed: ". $self->verbose_file($file). "\n       at line: $_\n";
        if ($c->{parse_fatal}) {
            die "\n";
        }
    };
}

sub byday
{
    my $self = shift;
    my $date = shift;
    my $d = $self->{data};

    return $d->{byday}->{$date} || [];
}

sub list_day
{
    my $self = shift;
    my $date = Util::date(shift);

    for my $t (@{$self->byday($date)}) {
        print $t->line(), "\n";
    }
}

sub tablo
{
    my $self = shift;
    my $date = shift;
    my $currency = shift;

    my @tourns = grep {
        $_->{buyin_currency} == $currency
    } @{$self->byday($date)};
    my $tourns_n = @tourns;

    my $sum = PokerStars::TournStats->new();
    $sum += \@tourns;
    $self->{total_sum} += $sum;

    print $date->formatted(), " (", $currency, "); play time: ", $sum->play_time(), "\n";

    my $x = 0;
    for (my $y = 0; $y < 20 || $x < $tourns_n; $y += 10) {
        for ($x = $y; $x < $y + 10; ++$x) {
            if ($x < $tourns_n) {
                my $tourn = $tourns[$x];
                print $tourn->winlossXO();
            } else {
                print ".";
            }
        }
        if ($y == 0) {
            print ' '. $sum->score_detail();
        } elsif ($y == 10) {
            print ' '. $sum->profit_detail();
        }
        print "\n";
    }
}

sub dump
{
    my $self = shift;
    print Dumper($self->{data});
}

1;

package main;
use strict;

my $c = Config->new();

my $dir = $ARGV[0] || $c->{dir} || '.';
$c->{dir} = $dir;
my $p = PokerStars::TournSummary->new($c);

$p->parse_range($c->{from_date}, $c->{till_date});
$c->dump($p->{data});

my $tablos = 0;

for (my $d = $c->{from_date}; $d <= $c->{till_date}; ++$d) {
    if (@{$p->byday($d)} == 0) {
        next;
    }

    for my $currency (@{$c->{currencies}}) {
        $p->tablo($d, $currency);
        print "\n";
        ++$tablos;
    }
}

if ($tablos > 1) {
    my $sum = $p->{total_sum};
    print "Total for $p->{parsed_days} days: ",
        $sum->score_detail(), ' ',
        $sum->profit_detail(), "; play time: ", $sum->play_time(), "\n";
}

1;
