#!/bin/bash
valgrind \
    --log-file=valgrind-leaks.log \
    --num-callers=30 \
    --leak-check=full \
    --track-origins=no \
    "$@"
