#!/bin/bash
echo "authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${1%.*}" > v3.ext
openssl x509 -req -days 7200 -CA ca.crt -CAkey ca.key -CAcreateserial -in $1 -out ${1%.*}.crt -extfile v3.ext
rm v3.ext
