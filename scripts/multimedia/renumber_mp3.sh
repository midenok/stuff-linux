#!/bin/sh
i=1;find -type f -name *.mp3|sort|while read;do id3v2 -T $i "$REPLY";i=$((i+1));done
