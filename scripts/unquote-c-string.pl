#!/usr/bin/perl

while (<>) {
    if (m/^(\s*)"(.*)"\s*$/) {
        print "${1}${2}\n";
    } else {
        print;
    }
}
