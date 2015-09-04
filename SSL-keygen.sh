#!/bin/bash
###########################################################
# Script to create web server keys                        #
# By Alberto Lepe (www.alepe.com, www.support.ne.jp)      #
# Created: 19VIII2010                                     #
# Version: 14VII2011                                      #
###########################################################

DOMAIN=$1
LENGTH=$2
WILDCARD=$3

#---------------------  To edit --------------------
REQ_COUNTRY="XX"
REQ_CITY="City Name"
REQ_STATE="State"
REQ_ORG="Someorg LTD"
REQ_UNIT="Some Org.Unit"
#---------------------------------------------------

REQUIREPSS=0  #Turn to 1 if you need the certificate to use a PSS to be read.

if [ "$DOMAIN" = "" ]; then
    echo "To create keys:"
    echo "$0 example.com 1024 [+|ALT]"
    echo "[OPTIONAL] Where '1024' is the key length. Default is 2048"
    echo "[OPTIONAL] Where '+' is to add any subdomain into the CSR (*.domain.tld)"
	echo "           Where ALT is any alternative domain name"
    exit 1
fi

################ START ########################
echo "Checking root access..."
    if [ "$(id -u)" != "0" ]; then
       echo "This script must be run as root" 1>&2
       exit 1
    fi

##################### KEY LENGTH ##############################
    if [ "$LENGTH" = "" ]; then LENGTH=2048; fi

##################### WILD CARD ##############################
    if [ "$WILDCARD" = "+" ]; then 
        WILDCARD="*."; 
		ALTNAME="$WILDCARD$DOMAIN";
    elif [ "$WILDCARD" != "" ]; then
		ALTNAME="$WILDCARD";
    fi


##################### CREATE CONFIG FILE #####################
  echo "[ req ]" > $DOMAIN.cfg
  echo "default_bits           = $LENGTH" >> $DOMAIN.cfg
  echo "default_keyfile        = $DOMAIN.key" >> $DOMAIN.cfg
  echo "default_days           = 730" >> $DOMAIN.cfg
  echo "distinguished_name     = req_distinguished_name" >> $DOMAIN.cfg
  echo "string_mask            = nombstr"  >> $DOMAIN.cfg
  echo "prompt                 = no" >> $DOMAIN.cfg

  if [ $REQUIREPSS == 0 ]; then
  echo "encrypt_key            = no" >> $DOMAIN.cfg
  fi

  if [ "$WILDCARD" != "" ]; then
  echo "req_extensions         = v3_req # Extensions to add to certificate request" >> $DOMAIN.cfg
  echo "[ v3_req ]" >> $DOMAIN.cfg
  echo "subjectAltName         = DNS:$ALTNAME" >> $DOMAIN.cfg
  fi 

  echo "[ req_distinguished_name ]" >> $DOMAIN.cfg
  echo "C                      = $REQ_COUNTRY" >> $DOMAIN.cfg
  echo "ST                     = $REQ_CITY" >> $DOMAIN.cfg
  echo "L                      = $REQ_STATE" >> $DOMAIN.cfg
  echo "O                      = $REQ_ORG" >> $DOMAIN.cfg
  echo "OU                     = $REQ_UNIT" >> $DOMAIN.cfg
  echo "CN                     = $DOMAIN" >> $DOMAIN.cfg

  if [ $REQUIREPSS == 1 ]; then
    ##################### CREATE PASS PRASE #######################
    dd if=/dev/urandom count=1 2> /dev/null | tr -dc [:graph:] | head -c 128 > $DOMAIN.pss
    echo "Generating KEY..."
    openssl genrsa -des3 -out $DOMAIN.key -passout file:$DOMAIN.pss $LENGTH
    echo "Generating PEM..."
    openssl rsa -in $DOMAIN.key -passin file:$DOMAIN.pss -out $DOMAIN.pem 
    echo "Generating CSR..."
    openssl req -new -key $DOMAIN.key -passin file:$DOMAIN.pss -config $DOMAIN.cfg -out $DOMAIN.csr
    echo "Don't forget to backup the .pss file and delete it from here!"
    ##################### CREATE REQUEST #######################
  else
    openssl req -batch -config $DOMAIN.cfg -newkey rsa:$LENGTH -out $DOMAIN.csr
  fi

rm $DOMAIN.cfg
cat $DOMAIN.csr
chmod 400 $DOMAIN.*
