#!/bin/bash
rsync -aP --delete ~/.kde3/ ~/.kde3.prev/
echo
echo "Now change KDE settings you wish to extrude. Press any key when done..."
read -n1
diff -Nuard ~/.kde3.prev ~/.kde3
echo
echo "Now store these changes in settings override..."
