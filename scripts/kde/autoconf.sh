#!/bin/sh
set -x
aclocal-1.7 &&
autoheader2.59 &&
automake-1.7 &&
admin/am_edit &&
autoconf2.59