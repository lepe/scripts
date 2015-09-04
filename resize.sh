#!/bin/bash
if [[ "$3" == "" ]];then
    echo "Usage: $0 PREFIX 320x240 *.png"
    exit;
fi
PREFIX=$1; shift;
RESIZE="-resize $1"; shift;
for I in "$@"; do
    echo "Resizing: $I to: $PREFIX$I"
    convert $RESIZE $I $PREFIX$I;
done
