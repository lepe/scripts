#!/bin/bash
if [[ $2 == "" ]]; then
    echo "Usage: $0 name command";
    exit 1;
fi
name=$1
command=$2
path=".";
config="logfile ${path}/${name}.log
logfile flush 1
log on
logtstamp after 1
logtstamp string \"[ %t: %Y-%m-%d %c:%s ]\012\"
logtstamp on";
echo "$config" > /tmp/log.conf
screen -c /tmp/log.conf -dmSL '$name' $command
rm /tmp/log.conf
