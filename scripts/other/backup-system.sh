#!/bin/sh
rsync -aHP --exclude '/dev/*' \
	--exclude '/sys/*' \
	--exclude '/proc/*' \
	--exclude '/tmp/*' \
	--exclude '/var/tmp/*' \
	--exclude '/lib/init/rw/*' \
	--exclude '/var/lib/nfs/rpc_pipefs/*' \
	--exclude '/mnt/*' / /mnt/sda1/hosts/babe
