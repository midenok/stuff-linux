#!/usr/bin/perl
use Date::Format;
use Date::Parse;
use Time::Zone;
use Data::Dumper;
print tz_offset('MSK') / 3600, "\n";
print str2time(`date`) - 3600, "\n";
print time, "\n";
print Dumper([localtime(time)]);
print Dumper([gmtime(time)]);
print ctime(str2time('20121310'));