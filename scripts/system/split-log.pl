#!/usr/bin/perl
use Getopt::Long;
use Date::Parse;

use lib '.';
use Number::Bytes::Human;


my %conf;
GetOptions(\%conf, "from|f=s", "to|t=s", "in|i=s", "out|o=s");

my $in, $out, $from = 0, $to = 0;

if ($conf{from}) {
    $from = str2time($conf{from});
    die "Wrong --from date\n"
        if !$from;
}

if ($conf{to}) {
    $to = str2time($conf{to});
    die "Wrong --to date\n"
        if !$to;
}

if (!$from && !$to) {
    die "At least one of --from or --to must be specified\n";
}

if ($conf{in}) {
    open IN, '<', $conf{in}
        or die $!;
    $in = \*IN;
} else {
    $in = \*STDIN;
}

if ($conf{out}) {
    open OUT, '>', $conf{out}
        or die $!;
    $out = \*OUT;
} else {
    $out = \*STDOUT;
}

my $state = 0;

my $bytes = 0;
my $block = 0;
my $block_print = 10 * 1048576;

while (<$in>) {
    $block += length;
    $bytes += length;

    m/^(\S+)\s+(\S+)(\s+(\S+))?(\s+(\S+))?(\s+(\S+))?/;
    my $t = find_time($1, $2, $4, $6, $8);
    if ($state == 0) {
        if ($t >= $from) {
            ++$state;
        } else {
            if ($block >= $block_print) {
                print STDERR "\rProcessed: ". Number::Bytes::Human::format_bytes($bytes). "\n";
                $block = 0;
            }
            next;
        }
    }
    if ($state == 1 && $t > $to) {
        exit 0;
    }
    print $out $_;
}

sub find_time
{
    my $out;
    my $str = '';
    for (@_) {
        $str .= ' '. $_;
        my $t = str2time($str);
        if (defined $t) {
            $out = $t;
        }
    }
    return $out;
}
