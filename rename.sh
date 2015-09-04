#!/bin/bash
X=0; 
if [[ $2 == "" ]]; then
    echo "Usage: $0 PREFIX *.jpg";
    exit;
fi
PREFIX=$1; shift;
for I in "$@"; do ((X+=1)); 
    echo "$I -> $PREFIX-$X."${I##*.};
    mv $I "$PREFIX-$X."${I##*.}; 
done
