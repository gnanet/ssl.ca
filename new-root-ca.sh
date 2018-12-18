#!/bin/bash
##
##  new-root-ca.sh - create the root CA
##  Copyright (c) 2000 Yeak Nai Siew, All Rights Reserved.
##

KEYBITS=2048
HASHALGO="sha256"
VALID_DAYS=3650
RANDOM_SRC=/dev/urandom

# Create the master CA key. This should be done once.
if [ ! -f ca.key ]; then
    echo "No Root CA key found. Generating one"
    openssl genrsa -aes256 -out ca.key $KEYBITS -rand ${RANDOM_SRC}
    echo ""
fi

# Check for root CA certificate
if [ ! -f ca.crt ]; then

    # Self-sign it if its missing
    CONFIG="root-ca.conf"

cat >$CONFIG <<EOT
[ req ]
default_bits            = $KEYBITS
default_keyfile            = ca.key
default_md              = $HASHALGO
distinguished_name        = req_distinguished_name
x509_extensions            = v3_ca
string_mask            = nombstr
req_extensions            = v3_req
[ req_distinguished_name ]
countryName            = Country Name (2 letter code)
countryName_default        = US
countryName_min            = 2
countryName_max            = 2
stateOrProvinceName        = State or Province Name (full name)
stateOrProvinceName_default    = Texas
localityName            = Locality Name (eg, city)
localityName_default        = Austin
0.organizationName        = Organization Name (eg, company)
0.organizationName_default    = My Personal Certificate Authority
organizationalUnitName        = Organizational Unit Name (eg, section)
organizationalUnitName_default    = Certification Services Division
commonName            = Common Name (eg, MD Root CA)
commonName_max            = 64
emailAddress            = Email Address
emailAddress_max        = 40
[ v3_ca ]
basicConstraints        = critical,CA:true
subjectKeyIdentifier        = hash
[ v3_req ]
nsCertType            = objsign,email,server
EOT

    echo "Self-sign the root CA..."
    openssl req -new -x509 -days ${VALID_DAYS} -config $CONFIG -key ca.key -out ca.crt
    rm -f $CONFIG

else
    echo "Your CA certificate is already generated. Hopefully you know the password for your signing key."
    echo ""
fi

# Create the environment
#
if [ ! -d ca.db.certs ] || [ ! -f ca.db.* ]; then
    echo "Creating CA environment, files and folders"
    echo ""
fi

# Folder for generated certificates
if [ ! -d ca.db.certs ]; then
    echo "Creating new certificate dir"
    mkdir ca.db.certs
fi
# File for holding the last serial, with initial serial
if [ ! -f ca.db.serial ]; then
    echo "Creating initial serial"
    echo '01' >ca.db.serial
fi
# Create empty index database, and the database attribute file
if [ ! -f ca.db.index ]; then
    echo "Creating certificate index database"
    cp /dev/null ca.db.index
    cp /dev/null ca.db.index.attr
fi

