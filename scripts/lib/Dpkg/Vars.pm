#!/usr/bin/perl
package Dpkg::Vars;
use Dpkg;

our %cputable, %cputable_re, %cputable_rev;
read_cputable();

sub read_cputable
{
    local $_;
    local $/ = "\n";

    open CPUTABLE, "$pkgdatadir/cputable"
    or syserr(_g("unable to open cputable"));
    while (<CPUTABLE>) {
        if (m/^(?!\#)(\S+)\s+(\S+)\s+(\S+)/) {
            $cputable{$1} = $2;
            $cputable_re{$1} = $3;
            $cputable_rev{$2} = $1;
            push @cpu, $1;
        }
    }
    close CPUTABLE;
}
    