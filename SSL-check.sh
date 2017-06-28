#!/bin/bash
if [[ $1 == "" ]]; then
	echo "Usage: $0 file";
	echo "Where file can be *.crt, *.csr"
	exit
fi
EXT="${1##*.}"
if [[ $EXT == "crt" ]]; then
	openssl x509 -noout -text -in $1
elif [[ $EXT == "csr" ]]; then
	openssl req -text -noout -verify -in $1
else
	echo "Extension should be 'crt' or 'csr'";
fi
