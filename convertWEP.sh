#!/bin/bash
if [[ "$1" == "" ]];then
    echo "Usage: $0 somevideo.avi"
    exit
fi
BASE=${1%%.*}
TARGET="video-out"
#----------------- APNG ---------------------
if [[ ! -f out0001.png ]]; then
    ffmpeg -n -i $1 -vf fps=fps=20 out%04d.png
    PARAMS="";
    for FILE in out*.png; do
        PARAMS="$PARAMS -frame ${FILE%%.*}.webp +0+0+3"
        cwebp $FILE -o ${FILE%%.*}.webp
    done
    rm out*.png;
fi
#----------------- WEBP ---------------------
if [[ -f out0001.webp ]]; then
    webpmux $PARAMS -loop 1 -o ${TARGET}-s.webp
    rm out*.webp
fi
