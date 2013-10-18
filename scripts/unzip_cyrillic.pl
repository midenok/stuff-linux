#!/usr/bin/perl

use strict;
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use Encode qw(from_to);
use File::Copy;
use Data::Dumper;

my $movedir = 'zip';

-d $movedir or mkdir $movedir
    or die "$movedir: $!";

for my $zipfile (@ARGV) {
    my $zip = Archive::Zip->new();
    unless ($zip->read($zipfile) == AZ_OK) {
        print STDERR "Error reading $zipfile: $!";
        next;
    }
    
    my @members = $zip->members();
    my $dir;

    if (@members > 1) {
        $dir = $zipfile;
        $dir =~ s/\.zip$//;
        mkdir $dir
            or die "$dir: $!";
    }

    for my $member (@members) {
        my $filename = $member->fileName();
        $filename = $dir . '/' . $filename
            if defined $dir;
        from_to($filename, "cp866", "utf8");
        print $filename, "\n";
        $zip->extractMember($member, $filename);
    }
    
    if (defined $movedir) {
        move($zipfile, $movedir . '/' . $zipfile)
            or die "move $zipfile $movedir: $!";
    }
}
