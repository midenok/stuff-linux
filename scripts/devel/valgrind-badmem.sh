#!/bin/sh
valgrind \
	--leak-check=no \
	--track-origins=yes \
    --log-file=valgrind-badmem.log \
	"$@"
