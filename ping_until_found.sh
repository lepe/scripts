#!/bin/bash
if [[ $1 == "" ]]; then
    echo "Usage: $0 DOMAIN [echo]";
    echo "if 'echo' is specified, will ping the error message : 'unknown host ...' until its found"
    exit;
fi
DOMAIN=$1;
if [[ $2 == "echo" ]]; then
    while true; do sleep 1; ping -c1 $DOMAIN > /dev/null && break; done
else
    while ! ping -c1 $DOMAIN &>/dev/null; do : sleep 1 ; done
fi
