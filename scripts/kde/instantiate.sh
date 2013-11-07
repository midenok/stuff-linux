#!/bin/sh
chmod +x admin/am_edit admin/cvs.sh
admin/cvs.sh configure.files
admin/cvs.sh subdirs
admin/cvs.sh configure.in
admin/cvs.sh Makefile.am
admin/cvs.sh acinclude.m4
