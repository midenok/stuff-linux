#!/bin/sh
mkdir -p downloaded

while read url file tmp
do
    echo "Downloading $file..."
    curl --progress-bar -o "downloaded/$file" "$url"
done
