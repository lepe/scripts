#!/bin/bash
#
# @author A.Lepe
# @since Feb 25, 2011
# It removes files older than X days and zip all files older than 1 day. 
#
if [ "$1" = "" ]; then
    echo "Path is required";
    exit;
fi
RECURSIVE=0; #no-recursive 
EXTENSION="log";
REMOVEOLD=2; #days -1

MAXDEPTH=""
if [ $RECURSIVE = 0 ]; then
    MAXDEPTH="-maxdepth 1";
fi

find $1 $MAXDEPTH -type f -name "*.${EXTENSION}" -mtime +${REMOVEOLD} -exec rm {} \;
find $1 $MAXDEPTH -type f -name "*.${EXTENSION}.gz" -mtime +${REMOVEOLD} -exec rm {} \;
#find $1 $MAXDEPTH -type f -name "*.${EXTENSION}" -mtime +${REMOVEOLD} | xargs rm
find $1 $MAXDEPTH -type f -name "*.${EXTENSION}" -mtime +1 -exec gzip {} \; 
#find $1 $MAXDEPTH -type f -name "*.${EXTENSION}" -mtime +1 | xargs gzip
