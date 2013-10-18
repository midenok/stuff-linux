#!/usr/bin/perl
package KernelConfig;

use strict;

my %C = (
    max_print => 10
);

sub diff_configs
{
    die "Required paramters missing"
        if @_ < 2;
    
    my $oldfile = shift;
    my $newfile = shift;
   
    my $old = load_config($oldfile);
    my $new = load_config($newfile);
    
    my $changed = get_changes($old, $new);
    my $changes = '';
 
    if (keys %$old > 0) {
        $changes .= show_config('deleted: ', $old);
    }
    
    if (keys %$new > 0) {
        $changes .= '; ' if $changes;
        $changes .= show_config('added: ', $new);
    }
    
    if (keys %$changed > 0) {
        $changes .= '; ' if $changes;
        $changes .= show_config('changed: ', $changed);
    }

    $changes .= '.' if $changes;
    
    return $changes ? $changes : undef;
}

sub load_config
{
	my $file = shift;
    open file, $file
            or die "$file: $!";
     
	my %config;
	while (<file>) {
		next if m/^(#|$)/;
		chomp;
		my ($key, $value) = split('=', $_);
        $key =~ s/^CONFIG_/c/;      
		$config{$key} = $value;
	}
   
    close file;   
	return \%config;
}

sub show_config
{
    my $message = shift;
	my $conf = shift;
    my @settings;

	for my $key (keys %$conf) {
        my $val = $conf->{$key};
        push @settings, $key . '(' . (ref $val eq 'ARRAY' ? join(', ', @$val) : $val) . ')';
	}
    
    if (@settings > $C{max_print}) {
        my $count = @settings - $C{max_print};
        splice @settings, $C{max_print};
        push @settings, "$count settings more";
    }
    return $message . join(', ', @settings) . @_;
}

sub get_changes
{
    my $old = shift;
    my $new = shift;
    my %changed;
    for my $key (keys %$old) {
        if (exists $new->{$key}) {
            if ($old->{$key} ne $new->{$key}) {
                $changed{$key} = [$old->{$key}, $new->{$key}];
            }
            delete $old->{$key};
            delete $new->{$key};
        }
    }
    return \%changed;
}

1;
