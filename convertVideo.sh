#!/bin/bash
if [[ "$1" == "" ]];then
    echo "Usage: $0 somevideo.avi"
    exit
fi
BASE=${1%%.*}
TARGET="video-out"
if [[ "$2" != "resize" ]]; then
    ffmpeg -n -i $1 -c:v libx264 -profile:v baseline -an -movflags faststart ${TARGET}.mp4
    ffmpeg -n -i $1 -vcodec libtheora -b:v 1310720 -an ${TARGET}.ogg
    ffmpeg -n -i $1 -c:v libvpx -crf 10 -an -b:v 1M ${TARGET}.webm 
    ffmpeg -n -i $1 -an -b:v 700k -qmin 3 -qmax 5 -maxrate 1000k -codec:v mpeg4 ${TARGET}.mov
    ffmpeg -n -i $1 -b:v 1M -an -codec:v mpeg2video ${TARGET}.mpg
    ffmpeg -n -i $1 -b:v 1M -an -codec:v mjpeg ${TARGET}.avi
    #ffmpeg -n -i $1 -c:v libx264 -crf 19 -an ${TARGET}.flv
    ffmpeg -n -i $1 -b:v 1M -an ${TARGET}.swf
fi
#--------- RESIZE -------------
for SIZE in m s x; do
    if [[ "$SIZE" == "m" ]]; then
        SCALE="1000:200";
    elif [[ "$SIZE" == "s" ]]; then
        SCALE="500:100";
    else
        SCALE="250:50";
    fi
    if [[ ! -f ${TARGET}-${SIZE}.mp4 ]];then
        ffmpeg -n -i ${TARGET}.mp4 -vf scale=${SCALE} ${TARGET}-${SIZE}.mp4
    fi
    if [[ ! -f ${TARGET}-${SIZE}.ogg ]];then
        ffmpeg -n -i ${TARGET}.ogg -vf scale=${SCALE} ${TARGET}-${SIZE}.ogg
    fi
    if [[ ! -f ${TARGET}-${SIZE}.webm ]];then
        ffmpeg -n -i ${TARGET}.webm -vf scale=${SCALE} ${TARGET}-${SIZE}.webm
    fi
    if [[ ! -f ${TARGET}-${SIZE}.mov ]];then
        ffmpeg -n -i ${TARGET}.mov -vf scale=${SCALE} -codec:v mpeg4 ${TARGET}-${SIZE}.mov
    fi
    if [[ ! -f ${TARGET}-${SIZE}.mpg ]];then
        ffmpeg -n -i ${TARGET}.mpg -vf scale=${SCALE} ${TARGET}-${SIZE}.mpg
    fi
    if [[ ! -f ${TARGET}-${SIZE}.avi ]];then
        ffmpeg -n -i ${TARGET}.avi -vf scale=${SCALE} ${TARGET}-${SIZE}.avi
    fi
    if [[ ! -f ${TARGET}-${SIZE}.swf ]];then
        ffmpeg -n -i ${TARGET}.swf -vf scale=${SCALE} ${TARGET}-${SIZE}.swf
    fi
done

for SIZE in l m s x; do
    #----------------- GIF ---------------------
    if [[ ! -f ${TARGET}-${SIZE}.gif ]];then
        ffmpeg -n -i ${TARGET}.mp4 -vf fps=fps=5 out%04d.gif
        gifsicle --delay=20 out*.gif > ${TARGET}-${SIZE}.gif
        rm out*.gif;
    fi
    #----------------- APNG ---------------------
    if [[ ! -f ${TARGET}-${SIZE}.png ]];then
        ffmpeg -n -i ${TARGET}.mp4 -vf fps=fps=5 out%04d.png
        apngasm ${TARGET}-${SIZE}.png out*.png 1 5
        if [[ ! -f ${TARGET}-${SIZE}.webp ]];then
            PARAMS="";
            for FILE in out*.png; do
                PARAMS="$PARAMS -frame ${FILE%%.*}.webp +0+0+20"
                cwebp $FILE -o ${FILE%%.*}.webp
            done
        fi
        rm out*.png;
    fi
    #----------------- WEBP ---------------------
    if [[ -f out0001.webp ]]; then
        webpmux $PARAMS -loop 1 -o ${TARGET}-${SIZE}.webp
        rm out*.webp
    fi
    if [[ "$SIZE" == "l" ]]; then
        ln -s ${TARGET}-${SIZE}.gif ${TARGET}.gif
        ln -s ${TARGET}-${SIZE}.png ${TARGET}.png
        ln -s ${TARGET}-${SIZE}.webp ${TARGET}.webp
    fi
done
