#!/bin/bash

if [ "$1" == "" ];then
    echo "Usage: $0 file.sql file.csv [MYSQL EXTRA COMMANDS]"
    exit
fi

FILE=$1
FNAME=$2
MCOMM=$3


echo "MySQL password:"
stty -echo
read PASS
stty echo

mysql -uroot -p$PASS pcnew $MCOMM -B < ${FILE} | sed "s/'/\'/;s/\t/\",\"/g;s/^/\"/;s/$/\"/;s/\n//g" > $FNAME
