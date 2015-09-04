#!/bin/sh
echo "########################"
FILES=`ls *.mpeg`
echo $FILES

for FN in $FILES
do
    BASE=$(basename $FN)
    ffmpeg -i $FN -f yuv4mpegpipe - | yuvfps -s 10:1 -r 10:1  | ffmpeg -f yuv4mpegpipe -i - -vcodec copy -y -f avi $BASE.avi
    ffmpeg -i $BASE.avi -vcodec mpeg4 -b 10000k -f avi $BASE.new
    mv $FN __$FN
    mv $BASE.new $FN
    rm $BASE.avi
done
echo "########################"
