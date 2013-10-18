#!/usr/bin/perl
my $test = {};

for (my $cont = 0; <>; $cont = m/\\\s*$/)
{
    if ($cont) {
        next;
    }
    $cont = m/\\\s*$/;
    my @rec = split(',');
    if (@rec < 4) {
        next;
    }
    exists $test->{$rec[0]}->{$rec[1]}->{$rec[2]} &&
        print join(' ', @rec);
   $test->{$rec[0]}->{$rec[1]}->{$rec[2]} = $rec[3];
}
