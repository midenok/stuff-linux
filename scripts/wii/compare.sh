#!/bin/bash

declare -A old

while read label title
do
    [ -n "$label" ] || continue
    old[$label]="$title"
done < old.txt

while read label title
do
    [ -n "$label" ] || continue
    [ -z "${old[$label]}" ] && echo $label
done < new.txt