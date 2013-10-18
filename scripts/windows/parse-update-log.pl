#!/usr/bin/perl
my $count = 0;

while (<>)
{
    m/DnldMgr.*Downloading from\s+(\S+)\s+/ ||
        next;
    my $url = $1;
    $url =~ m|^.*/([^/]+)(_[a-fA-F0-9]{40})\.exe$|;
    "$1" or die "Parsing error";
    my $file = "${1}.exe";
    my $file2 = sprintf "%04d_${file}", $count++;
    print $url, " ", $file2, "\n";
}
