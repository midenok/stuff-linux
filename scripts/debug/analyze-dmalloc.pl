#!/usr/bin/perl
use strict;

use Date::Format;

my $line = 0;
my $records = 0;
my $since_mark;
my $mark_since_mark;
my $first_mark;
my $prev_notfree_mark;
my $display_step = 10000;
my $display_next = $display_step;
my %result;
my %track; # allocations track

$| = 1;

while (<STDIN>) {
    ++$line;
    chomp;

    s/^(\d+):\s*(\d+):\s*//;
    my $timestamp = $1;
    my $mark = $2;

    if (m/Pointers Changed Since Mark (\d+):/) {
        $since_mark = $1;
        if (defined $prev_notfree_mark && $since_mark != $prev_notfree_mark) {
            print "\rGap in marks ${prev_notfree_mark} -> ${since_mark} corrected.\n";
            $since_mark = $prev_notfree_mark;
        }
        $mark_since_mark = $mark;
        $result{$mark}->{prev} = $since_mark;
        $result{$mark}->{timestamp} = $timestamp;
        $result{$since_mark}->{'next'} = $mark;
    } elsif (s/^(not )?freed:\s*//) {
        my $event = $1 ? 'allocated' : 'freed';
        m/^'([[:alnum:]]+)\|s(\d+)'\s*\((\d+) bytes\) from '([^']+)'/
            or die "Unknown format at line ${line}: $_\n";
        $mark_since_mark == $mark
            or die "Unknown format at line ${line}: no 'Since Mark' prepended\n";
        $first_mark = $mark
            unless defined $first_mark;
        $prev_notfree_mark = $mark;
        my $address = $1;
        my $seen = $2;
        my $size = $3;
        my $source = $4;
        $result{$mark}->{$event}->{$address} = {
            size => $size,
            seen => $seen,
            source => $source
        };
        if ($event eq 'allocated') {
            if (exists $track{$address}) {
                $result{$mark}->{freed}->{$address} = {
                    size => $track{$address}
                };
            }
            $track{$address} = $size;
        } elsif ($event eq 'freed') {
            if (exists $track{$address}) {
                $result{$mark}->{freed}->{$address}->{size} = $track{$address};
            }
            delete $track{$address};
        } else {
            die "Unknown event ${event}";
        }
        ++$records;
        if ($records == $display_next) {
            my $r = $records / 1000;
            print "\rProcessed ${r}k records...";
            $display_next += $display_step;
        }
    }
}

print "\rProcessed ${records} records.\n";

my $allocated_total = 0;
my $freed_total = 0;
my $new_total = 0;

no strict 'refs';

for (my $mark = $first_mark; $mark = $result{$mark}->{'next'}; exists $result{$mark}->{'next'}) {
    my %a = (allocated => 0, freed => 0, new => 0);
    for my $event ('allocated', 'freed') {
        for (keys %{$result{$mark}->{$event}}) {
            my $r = $result{$mark}->{$event}->{$_};
            $a{$event} += $r->{size};
            if ($event eq 'allocated' && $r->{seen} == 1) {
                $a{new} += $r->{size};
            }
        }
    }
    $allocated_total += $a{allocated};
    $freed_total += $a{freed};
    $new_total += $a{new};

    print time2str("%b %d %T", $result{$mark}->{timestamp}) . " ${mark}: new: " .
        int($a{new}/1024) . "k; allocated: " .
        int($a{allocated}/1024) . "k; freed: " .
        int($a{freed}/1024) . "k; increase: " .
        int(($a{allocated}-$a{freed})/1024) . "k\n";
}

print "Total: new: " .
    int($new_total/1024) . "k; allocated: " .
    int($allocated_total/1024) . "k; freed: " .
    int($freed_total/1024) . "k; increase: " .
    int(($allocated_total-$freed_total)/1024) . "k\n";
