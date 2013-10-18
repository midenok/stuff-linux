#!/usr/bin/perl
use strict;
use Date::Parse;
use Date::Format;
use Time::Local;

use Data::Dumper;

my $t;
my @data;

my $t1 = str2time("2012/01/01 00:00:00");
my $t2 = str2time("2012/01/01 00:00:00 MSK");

print $t2 - $t1, "\n";
my @t = localtime($t);
print Dumper(\@t);
my $t2 = str2time("2012/04/17 15:10:18 MSK");
my @t2 = localtime($t2);
print Dumper(\@t2);
exit;

while (<>) {
    if (m|^PokerStars Tournament|) {
        $t = {};
    } elsif (m|^Buy-In:\s*(\d+)/|) {
        $t->{buyin} = $1;
    } elsif (m|^(\d+) players$|) {
        if ($1 == 2) {
            push @data, $t;
        }
    } elsif (m|^Tournament started ([^[]+[^[\s])|) {
        $t->{time} = str2time($1);
        my @time = localtime($t->{time});
        $t->{timecheck} = timelocal(@time);
        $t->{hour} = $time[2];
        $t->{dst} = $time[8];
        @time[0..2] = (0, 0, 0);
        my $midnight = timelocal(@time);
        $t->{date} = $midnight;
        $t->{timestr} = time2str("%e %b %Y %T %Z", $t->{time}, "MSK");
        $t->{datestr} = time2str("%e %b %Y %T %Z", $midnight, "MSK");
    } elsif (m|^Tournament finished ([^[]+)|) {
        $t->{duration} = str2time($1) - $t->{time};
    } elsif (m|^You finished in (\d+)\D*place.$|) {
        $t->{place} = $1;
    }
}

print Dumper(\@data);
