#!/bin/bash
##
##  sign-user-cert.sh - sign using our root CA the user cert
##  Copyright (c) 2000 Yeak Nai Siew, All Rights Reserved. 
##

HASHALGO="sha256"
VALID_DAYS=730
RANDOM_SRC=/dev/urandom

CERT=$1
if [ $# -ne 1 ]; then
        echo "Usage: $0 user@email.address.com"
        exit 1
fi
if [ ! -f $CERT.csr ]; then
        echo "No $CERT.csr found. You must create that first."
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
preserve                = yes
x509_extensions        = user_cert
policy                  = policy_anything
[ policy_anything ]
commonName              = supplied
emailAddress            = supplied
[ user_cert ]
#SXNetID        = 3:yeak
subjectAltName        = email:copy
basicConstraints    = critical,CA:false
authorityKeyIdentifier    = keyid:always
extendedKeyUsage    = clientAuth,emailProtection
EOT

#  revoke an existing old certificate
if [ -f $CERT.crt ]; then
    openssl ca -revoke $CERT.crt -config ca.config
fi

#  sign the certificate
echo "CA signing: $CERT.csr -> $CERT.crt:"
openssl ca -config ca.config -notext -out $CERT.crt -infiles $CERT.csr

if [ -f $CERT.crt ]; then
    echo "Creating separate human-readable certificate info -> $CERT.info.txt"
    openssl x509 -noout -text -in $CERT.crt > $CERT.info.txt
    echo ""
    echo "CA verifying: $CERT.crt <-> CA cert"
    openssl verify -CAfile ca.crt $CERT.crt
    echo ""
else
    echo "CA signing failed, missing the resulting $CERT.crt."
    echo "Inspect ca.config, and the *.old files"
    exit 1

fi


#  cleanup after success
rm -f ca.config
rm -f ca.db.serial.old
rm -f ca.db.index.old
rm -f ca.db.index.attr.old

