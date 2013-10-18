#!/bin/sh
[ -z "$1" ] && {
    echo "Must specify username!"
    exit 1
}

# setup priveleges

for g in adm admin sambashare disk dialout fax cdrom floppy fuse lpadmin sudo audio dip video plugdev power staff games users scanner vboxusers
do
    usermod --groups $g --append $1
done

# setup me
eval homedir=~$1
id=$(id $1|sed -e 's/^uid=\([[:digit:]]\+\)(.*$/\1/') # '
gid=$(id $1|sed -e 's/.*gid=\([[:digit:]]\+\)(.*$/\1/') # '
useradd --home $homedir --gid $gid --uid $id -M --no-user-group --non-unique me
