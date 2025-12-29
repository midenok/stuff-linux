#!/bin/bash

# Download and unpack specific chroot image set by $release and $mirror

get_last_version()
{
    local package=$1
    local distrib=${2:+~${2}.*}
    local code='s/^.*>\('${package}'_.*'$distrib'\.deb\)<.*$/\1/; t print; d; :print p'
    sed -n "$code"|sort -V|tail -1
}

chmkdir()
{
    mkdir -p "$1"
    cd "$1"
}

release=hardy
mirror='http://old-releases.ubuntu.com/ubuntu/'
repo_url=${mirror%/}'/pool/main/d/debootstrap/'

update_debootstrap()
{
    echo -n "Getting packages list..."
    local package=$(wget -qO - "$repo_url"|get_last_version debootstrap $release)
    [ -n "$package" ] && echo " got it"

    local archives=var/cache/apt/archives
    (
        set -e
        chmkdir "$release"
        pushd .
        chmkdir "$archives"
        echo -n Downloading $package...
        wget -nc -q "${repo_url%/}/$package"
        echo " ok"
        popd
        dpkg -x "$archives/$package" .
    )
}

debootstrap=$release/usr/sbin/debootstrap

[ -x "$debootstrap" ] ||
    update_debootstrap

export DEBOOTSTRAP_DIR=$release/usr/share/debootstrap
fakeroot $debootstrap "$@" $release $release/ "$mirror"
