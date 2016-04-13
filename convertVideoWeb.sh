#!/bin/bash
if [[ "$1" == "" ]];then
    echo "Usage: $0 somevideo.avi"
    exit
fi
BASE=${1%%.*}
TARGET="$BASE-web"
VIDINFO=$(ffprobe -v error -of flat=s=_ -select_streams v:0 -show_entries stream=height,width $1);
WIDTH=$(echo "$VIDINFO" | grep "width" | awk -F "=" '{print $2}')
HEIGHT=$(echo "$VIDINFO" | grep "height" | awk -F "=" '{print $2}')
ffmpeg -n -i $1 -c:v libx264 -profile:v baseline -an -movflags faststart ${TARGET}.mp4
ffmpeg -n -i $1 -vcodec libtheora -b:v 1310720 -an ${TARGET}.ogg
ffmpeg -n -i $1 -c:v libvpx -crf 10 -an -b:v 1M ${TARGET}.webm 
echo "######################### HTML ##########################"
echo "<video width='$WIDTH' height='$HEIGHT' controls>
  <source src='${TARGET}.mp4' type='video/mp4'>
  <source src='${TARGET}.ogg' type='video/ogg'>
  <source src='${TARGET}.webm' type='video/webm'>
  Your browser does not support the video tag.
</video>"
