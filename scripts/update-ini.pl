#!/usr/bin/perl
use strict;
use Config::IniFiles;
use Getopt::Long qw(:config bundling);
use Pod::Usage;
use File::Basename;
use Data::Dumper;

Getopt::Long::Configure(qw(
    permute
    pass_through));

my %o = (
    verbose => 0
);

GetOptions (\%o, qw(
    verbose|v+
    help|h
));

if (@ARGV != 2 || !-d $ARGV[0] || !-d $ARGV[1]) {
    $o{help} = 1;
}

if ($o{help}) {
    pod2usage(-verbose => 1)
}

$o{src_dir} = $ARGV[0];
$o{dst_dir} = $ARGV[1];

my @files = map {chomp; $_} `find $o{src_dir} -type f`;

for my $f (@files) {
    $f =~ m|^$o{src_dir}/(.+)$|
        or die "find was wrong: ${f}\n";
    my $f_base = $1;
    my $f_dst = "$o{dst_dir}/${f_base}";

    print_verbose("Processing ${f_base}\n");

    my %ini_src;
    tie %ini_src, 'Config::IniFiles', ( -file => $f );

    if (not defined %ini_src) {
        print STDERR "Skipping non-ini ${f}\n";
        next;
    }

    if (!-f $f_dst) {
        0 == system(mkdir => '-p', dirname($f_dst))
            or die "Mkdir failed\n";
        0 == system(cp => '-p', ($o{verbose} ? '-v' : ()), $f, $f_dst)
            or die "Copy failed\n";
        next;
    }

    my %ini_dst;
    tie %ini_dst, 'Config::IniFiles', ( -file => $f_dst );

    if (not defined %ini_dst) {
        die "Non-ini destination ${f_dst}\n";
    }

    for my $section (keys %ini_src) {
        for my $key (keys %{$ini_src{$section}}) {
            print_verbosen(2, "Overriding '${section}::${key}' with '". cut_string($ini_src{$section}{$key}). "'\n");
            $ini_dst{$section}{$key} = $ini_src{$section}{$key};
        }
    }

    tied(%ini_dst)->RewriteConfig()
        or die "Failed to write ${f_dst}\n";
}

sub print_verbosen
{
    my $level = shift;
    print @_
        if $o{verbose} >= $level;
}

sub print_verbose
{
    print_verbosen(1, @_);
}

sub cut_string
{
    my $str = shift;
    my $cut = 50;
    if (length($str) > $cut) {
        return substr($str, 0, $cut). ' ...';
    }
    return $str;
}


=head1 SYNOPSIS

update-ini.pl [OPTION]... SOURCE DEST

=head1 OPTIONS

=over 4

item B<--help>
Print this help

=back

=cut
