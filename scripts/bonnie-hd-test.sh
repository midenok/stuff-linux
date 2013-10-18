#!/bin/sh

bonnie()
{
    bonnie++ \
        -d $1 \
        -s 1g \
        -n 0 \
        -r 0 \
        -m $2

    bonnie++ \
        -d $1 \
        -s 1g \
        -n 0 \
        -r 0 \
        -m $2-nobuf \
        -b

    bonnie++ \
        -d $1 \
        -s 1g \
        -n 0 \
        -r 0 \
        -m $2-direct \
        -D
}

bonnie /tmp barracuda |tee ~/hd-barracuda.txt
bonnie /mnt raptor |tee ~/hd-raptor.txt
