#!/bin/bash
perlwhere()
{
    perl -M$1 -e 'print $INC{"'${1/::/\/}'.pm"}, "\n";'
}
