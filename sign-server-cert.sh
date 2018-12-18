#!/bin/bash
##
##  sign-server-cert.sh - sign using our root CA the server cert
##  Copyright (c) 2000 Yeak Nai Siew, All Rights Reserved. 
##

HASHALGO="sha256"
VALID_DAYS=730
RANDOM_SRC=/dev/urandom

CN=$1
if [ $# -ne 1 ]; then
    echo "Usage: $0 <www.domain.com>"
    exit 1
fi
if [ ! -f $CN.csr ]; then
    echo "No $CN.csr found. You must create that first."
    exit 1
fi
# Check for root CA key
if [ ! -f ca.key -o ! -f ca.crt ]; then
    echo "You must have root CA key generated first."
    exit 1
fi
#   make sure environment exists
if [ ! -d ca.db.certs -o ! -f ca.db.serial -o ! -f ca.db.index ]; then
    echo "You must have the CA environment created first with ./new-root-ca.sh."
    exit 1
fi

# Sign the request it with our CA key #

#  create the CA requirement to sign the cert
cat >ca.config <<EOT
[ ca ]
default_ca              = default_CA
[ default_CA ]
dir                     = .
certs                   = \$dir
new_certs_dir           = \$dir/ca.db.certs
database                = \$dir/ca.db.index
serial                  = \$dir/ca.db.serial
RANDFILE                = ${RANDOM_SRC}
certificate             = \$dir/ca.crt
private_key             = \$dir/ca.key
default_days            = ${VALID_DAYS}
default_crl_days        = 30
default_md              = $HASHALGO
preserve                = no
x509_extensions        = server_cert
policy                  = policy_anything
[ policy_anything ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional
[ server_cert ]
#subjectKeyIdentifier    = hash
authorityKeyIdentifier    = keyid:always
extendedKeyUsage    = serverAuth,clientAuth,msSGC,nsSGC
basicConstraints    = critical,CA:false
[req]
default_md              = $HASHALGO
req_extensions          = v3_req
[ v3_req ]
extendedKeyUsage        = serverAuth, clientAuth
EOT

# Test for Subject Alternate Names
subjaltnames="`openssl req -text -noout -in $CN.csr | sed -e 's/^ *//' | grep -A1 'X509v3 Subject Alternative Name:' | tail -1 | sed -e 's/IP Address:/IP:/g'`"
if [ "$subjaltnames" != "" ]; then
    echo "Found subject alternate names: $subjaltnames"
    echo ""
    echo "subjectAltName          = $subjaltnames" >> ca.config
fi

#  revoke an existing old certificate
if [ -f $CN.crt ]; then
    echo "Revoking current certificate: $CN.crt"
    openssl ca -revoke $CN.crt -config ca.config
fi

#  sign the certificate
echo "CA signing: $CN.csr -> $CN.crt:"
openssl ca -config ca.config -extensions v3_req -notext -out $CN.crt -infiles $CN.csr
echo ""
if [ -f $CN.crt ]; then
    echo "Creating separate human-readable certificate info -> $CN.info.txt"
    openssl x509 -noout -text -in $CN.crt > $CN.info.txt
    echo ""
    echo "CA verifying: $CN.crt <-> CA cert"
    openssl verify -CAfile ca.crt $CN.crt
    echo ""
else
    echo "CA signing failed, missing the resulting $CN.crt."
    echo "Inspect ca.config, and the *.old files"
    exit 1
fi


#  cleanup after success
rm -f ca.config
rm -f ca.db.serial.old
rm -f ca.db.index.old
rm -f ca.db.index.attr.old
