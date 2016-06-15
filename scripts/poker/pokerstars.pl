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

    my $usd = Currency->new('$');

    my $self = bless {
        verbose => 0,
        from_date => 0,
        till_date => Date->new(Date::date()),
        command => 'tablo',
        currencies => [ $usd ], # by default only USD games will be shown
        players => 0, # filter by players on table. 0 means any table size.
        buyin => 0, # filter by buyin. 0 means any buyin
        total_currency => $usd,
        parse_fatal => 1
    } => $class;

    $self->get_options();
    return $self;
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
        players|p=i
        buyin|b=f
        command|cmd=s
        tablo
        list
        summary|all|a
        tournament_id|tournament-id=i
        currency|c=s
        parse_fatal|parse-fatal|fatal:i
        dump|D+
        dump_files|dump-files|Df
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

    for my $arg (qw[tablo list summary]) {
        if ($c->{$arg}) {
            $c->{command} = $arg;
        }
        delete $c->{$arg};
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
    "--" => \&operator_mm,
    "+" => \&operator_plus,
    "-" => \&operator_minus,
    '""' => \&operator_stringify,
    "=" => \&operator_assign,
    "-=" => \&operator_subassign,
    "==" => \&operator_equal;

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
        if ($date eq 'time') {
            $self->assign_time(shift);
        } else {
            $self->parse_date($date);
        }
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

our %TZALIAS = (
    ET => 'EST',
    CUST => 'GMT+7'
);

sub parse
{
    my $date = shift;
    for my $a (keys %TZALIAS) {
        $date =~ s/(\s)$a\s*$/$1$TZALIAS{$a}/
            and last;
    }
    my $t = str2time($date, @_)
        or die("Can't parse date: ", $date, "\n");
    return $t;
}

sub assign_date()
{
    my $self = shift;
    my $date = shift;
    $self->{date} = $date;
    $self->{time} = parse($date);
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
    return $self->assign_time(parse($date)
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

sub operator_mm
{
    my $self = shift;
    $self->assign_time($self->{time} - 24 * 3600);
    return $self;
}

sub operator_plus
{
    my $self = Date->new(shift);
    my $days = shift;
    $self->assign_time($self->{time} + 24 * 3600 * $days);
    return $self;
}

sub operator_minus
{
    my $self = Date->new(shift);
    my $days = shift;
    $self->assign_time($self->{time} - 24 * 3600 * $days);
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

sub operator_equal
{
    my $left = shift;
    my $right = shift;
    my $res = 0;
    if (ref($right) ne 'Date') {
        $right = Date->new(time => $right);
    }
    if ($left->{date} == $right->{date}) {
        $res++;
        if ($left->{time} == $right->{time}) {
            $res++;
        }
    }
    return $res;
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

sub play_time
{
    my $self = shift;
    return Util::play_time_short($self->{duration});
}

sub line
{
    my $self = shift;
    format line =
@<<<<
$self->time()
.
    return $self->time(), "  ", $self->play_time(), " ", $self->buyin(), "  ", $self->winlossXO(), "  ", $self->{opponent}, "#$self->{id}";
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
        $self->{profit} += $t->{prize} - $t->{buyin};
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

sub score_profit_detail
{
    my $self = shift;
    return $self->score(). ' ('.
        $self->{wins}. ':'. $self->losses(). '; '.
        $self->buyin_range(). '; '.
        $self->profit_loss(). ')';
}

sub play_time
{
    my $self = shift;
    return Util::play_time($self->{play_time});
}

1;

package Util;

our @time_units = (qw(d h m s));
our @capacity = (24 * 60 * 60, 60 * 60, 60, 1);

sub play_time
{
    my $time = shift;
    my @play_time = (gmtime $time)[7, 2, 1, 0];
    my $rs = '';
    my $out = '';
    for (my $i = 0; $i < @time_units; ++$i) {
        $out .= $rs. $play_time[$i]. $time_units[$i], $rs = ' '
            if $play_time[$i];
    }
    return $out;
}

sub play_time_short
{
    my $time = shift;
    my @play_time = (gmtime $time)[7, 2, 1, 0];
    for (my $i = 0; $i < @time_units; ++$i) {
        if ($play_time[$i]) {
            my $fraction;
            if ($i < @time_units - 1) {
                my $rest;
                for (my $j = $i + 1; $j < @time_units; ++$j) {
                    $rest += $play_time[$j] * $capacity[$j];
                }
                $fraction = $rest / $capacity[$i];
            }
            return (sprintf("%.1f", $play_time[$i] + $fraction) + 0). $time_units[$i];
        }
    }
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
    'F' => 'Freeroll',
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
use Carp;

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
      parsed_days => 0,
      dir_list => undef
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

    $self->{conf}->dump($self->{data});
    return $self;
}

sub read_dir
{
    my $self = shift;
    return $self->{dir_list} if $self->{dir_list};
    my $dir = $self->{dir};
    opendir (my $dh, $dir) || die "${dir}: $!\n";
    $self->{dir_list} = [map {
            {
                file => $_,
                full_file => undef,
                mtime => 0
            }
        } readdir $dh];
    closedir $dh;
    return $self->{dir_list};
}

sub parse_day
{
    my $self = shift;
    my $date = shift;
    # date in filename is always in ET, which may be different from current timezone
    my $date0 = $date - 1;
    my $date1 = $date + 1;

    map {
        $self->{found_files}++;
        $self->parse_file($_);
    } grep {
        $_->{full_file} = $self->{dir}. "/". $_->{file};
        if (not $_->{mtime}) {
            $_->{mtime} = (stat $_->{full_file})[9];
        }
        $date == $_->{mtime};
    } grep {
        $_->{file} =~ m/^TS(${date0}|${date}|${date1}).+\.txt$/
    } @{$self->read_dir};

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

sub parse_all
{
    my $self = shift;

    map {
        $self->{found_files}++;
        $_->{full_file} = $self->{dir}. "/". $_->{file};
        $_->{mtime} = (stat $_->{full_file})[9];
        $self->parse_file($_);
    } grep {
        $_->{file} =~ m/^TS.+\.txt$/
    } @{$self->read_dir};

    $self->{conf}->dump($self->{data});
    return $self;
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

sub match(&$$)
{
    my ($code, $re, $line) = @_;
    if ($line =~ $re) {
        local $_ = $line;
        &$code;
    } else {
        die $line;
    }
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

our $money_re = qr'([\$])?(\d[.0-9]*)?';
our $money_full_re = qr"${money_re}(\s+(USD))?";

sub parse_file
{
    my $self = shift;
    my $c = $self->{conf};
    my $f = shift;
    my $dir = $self->{dir};
    my $file = $f->{file};
    my $full_file = $f->{full_file};
    my $mtime = $f->{mtime};

    if (exists $self->{parsed}->{$file}) {
        confess "File was already parsed: $file";
    }

    if (ref($self->{data}) ne 'HASH') {
        $self->{data} = {};
    }

    my $d = $self->{data};
    my $turnament;

    open F, "<", $full_file or die $self->verbose_file($file). ": $!\n";
    my @l = map { chomp; s/\r$//; $_ } <F>;
    close F;

    try {
        my $t = PokerStars::Tournament->new();

        match {
            $t->{id} = $1;
        } qr'^PokerStars Tournament #(\d+)\D' => $l[0];

        if ($c->{tournament_id} && $c->{tournament_id} != $t->{id}) {
            return;
        }

        if ($l[1] !~ m/^Buy-In: / && $l[2] =~ m/^Buy-In: /) {
            $t->{tournament_type} = $l[1];
            delete $l[1];
        }

        if ($l[1] =~ m/^Freeroll/) {
            $t->{buyin_currency} = Currency->new('F');
            $t->{rake} = 0;
            $t->{buyin} = 0;
        } else {
            match {
                $t->{buyin_currency} = Currency->new($1, $6);
                $t->{rake} = $4;
                $t->{buyin} = $2 + $t->{rake};
            } qr"^Buy-In: ${money_re}/${money_full_re}$" => $l[1];
        }
        
        if ($c->{buyin} > 0 && $t->{buyin} != $c->{buyin}) {
            if ($c->{verbose}) {
                print STDERR "(${file}) ". $t->{buyin_currency}. $t->{buyin}. " buyin tournament skipped!\n";
            }
            return;
        }

        match {
            $t->{players} = $1
        } qr'^(\d+) players$', $l[2];

        if ($c->{players} > 0 && $t->{players} != $c->{players}) {
            if ($c->{verbose}) {
                print STDERR "(${file}) ". $t->{players}. "-player tournament skipped!\n";
            }
            return;
        }

        match {
            $t->{prize_currency} = Currency->new($1, $4);
            $t->{total_prize} = $2;
        } qr"Total Prize Pool: ${money_full_re}" => $l[3];

        match {
            $t->{time} = Date::parse($1);
        } qr'^Tournament started ([^[]+)(\[(.+)\])?$' => $l[4];

        for (my $i = 6; $i < 6 + $t->{players}; ++$i) {
            match {
                my $player = $1;
                my $country = $2;
                my $prize = $5;
                my $percentage = $6;
                if ($player eq $c->{user}) {
                    $t->{prize} = $prize || 0;
                    $t->{prize_percentage} = $percentage || 0;
                } else {
                    push @{$t->{opponents}}, {
                        nickname => $player,
                        country => $country,
                        prize => $prize,
                        prize_percentage => $percentage
                    };
                }
            } qr"^  \d: ([^(].+) \(([^)]+)\),( ${money_re} \((\d[.0-9]*)%\))?" => $l[$i];
        }

        match {
            $t->{place} = $1;
            $t->{win} = $1 == 1 ? 1 : 0, 1;
        } qr'^You finished in (\d+)\D' => $l[7 + $t->{players}];

        $t->{duration} = $mtime - $t->{time};

        push @{$d->{byday}->{Date::date($t->{time})}}, $t;
        $d->{byid}->{$t->{id}} = $t;
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

    if ($c->{dump_files}) {
        print $file, "\n";
    }
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
    my $date = shift;

    my $tourns = $self->byday($date);
    my $sum = PokerStars::TournStats->new();
    $sum += $tourns;
    $self->{total_sum} += $sum;

    print $date->formatted(). ": ". @$tourns. " games; ". $sum->score_profit_detail(). "; ". $sum->play_time(). "\n";

    for my $t (@{$self->byday($date)}) {
        print $t->line(), "\n";
    }
}

sub list
{
    my $self = shift;

    for my $t (@{$self->{data}->{all}}) {
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

sub summary
{
    my $self = shift;
    my @tourns = values %{$self->{data}->{byid}};
    my $sum = PokerStars::TournStats->new();
    $sum += \@tourns;
    $self->{total_sum} += $sum;
}

sub dump
{
    my $self = shift;
    print Dumper($self->{data});
}

1;

package main;
use strict;

our $c = Config->new();

my $dir = $ARGV[0] || $c->{dir} || '.';
$c->{dir} = $dir;
our $p = PokerStars::TournSummary->new($c);

&{\&{$c->{command}}};

sub tablo
{
    $p->parse_range($c->{from_date}, $c->{till_date});

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
}

sub list
{
    $p->parse_range($c->{from_date}, $c->{till_date});

    for (my $d = $c->{from_date}; $d <= $c->{till_date}; ++$d) {
        if (@{$p->byday($d)} == 0) {
            next;
        }

        $p->list_day($d);
    }
}

sub summary
{
    $p->parse_all();
    $p->summary();
    my $sum = $p->{total_sum};
    print "Total for ". $sum->{tourns_n}. " games: ",
        $sum->score_detail(), ' ',
        $sum->profit_detail(), "; play time: ", $sum->play_time(), "\n";
    print "Processed ". $p->{found_files}. " files.\n";
}

1;
