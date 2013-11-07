#!/usr/bin/perl
use strict;
use Data::Dumper;

my $action;
my $stack = [];
my %allocated;
my $skip_to_next_frame = 0;
my $allocations = 0;
my $frees = 0;
my $alloced = 0;

while (<STDIN>) {
    chomp;

    if (m/<signal handler called>/) {
        $skip_to_next_frame = 1;
        next;
    }
    m/^#(\d+)\s+(0x[0-9a-f]+ in )?([^\(]+) \(([^\)]*)\)/
        or next;

    my $frame = $1;
    my $procedure = $3;
    my $arguments = $4;

    if ($frame == 0) {
        if ($procedure eq '_dmalloc_chunk_malloc') {
            $action = 'alloc';
            ++$allocations;
        } elsif ($procedure eq '_dmalloc_chunk_free') {
            $action = 'free';
            ++$frees;
        } else {
            #print "Skipping $_\n";
            $skip_to_next_frame = 1;
            next;
        }
        $stack = [];
        $skip_to_next_frame = 0;
    } elsif ($skip_to_next_frame) {
        push @$stack, $_;
        next;
    } elsif ($procedure =~ m/^allocator_(alloc|free)/) {
        die "Wrong ${procedure} in: $_\n"
            unless $1 eq $action;
        $arguments =~ m/^allocator=(0x[0-9a-f]+),/
            or die "Wrong $arguments in $_\n";
        my $allocator = $1;
        if ($action eq 'alloc') {
            $allocated{$allocator}->{counter}++;
            push @{$allocated{$allocator}->{stacks}}, $stack;
            $alloced++;
        } else {
            if (!exists $allocated{$allocator} || $allocated{$allocator}->{counter} == 0) {
                $skip_to_next_frame = 1;
                next;
            }
            $allocated{$allocator}->{counter}--;
            $alloced--;
            if ($allocated{$allocator}->{counter} == 0) {
                delete $allocated{$allocator};
            }
        }
        $skip_to_next_frame = 1;
    }
    push @$stack, $_;
}

print "allocations: $allocations; frees: $frees; difference: ".($allocations-$frees)."\n";
print "found alloced: $alloced\n";

my %depths;

for my $k (keys %allocated) {
    if ($allocated{$k}->{counter} != 1) {
        print "Counter for $k: ".$allocated{$k}->{counter}, "\n";
    }
    for my $stack (@{$allocated{$k}->{stacks}}) {
        my $depth = @$stack;
        ++$depths{$depth};
    }
}

print Dumper(\%depths);