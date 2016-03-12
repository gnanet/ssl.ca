# SSL/TLS Certificate Authority Package

This package is a set of scripts designed to handle the tasks of an SSL
certificate authority. While you could do this using only the OpenSSL command
line utility, this package encapsulates the operational knowledge of doing this
and provides a repeatable process that is suitable for the PKI foundation of a
small organization.

This package was originally developed Yeak Nai Siew (v0.1).
> Copyright (c) 2000 Yeak Nai Siew, All Rights Reserved.

It was updated by Mike Rhyner (v0.2) in 2004 to add handling for certificate
renewals.

Release v0.3 is the result of several years of changes by Eric Dey in order to
improve error handling, update the encryption strength, and add handling for
Subject Alternate Names and wildcard certificates.


## Getting Started

While this package is only tested and used on Linux, it was originally
developed for Solaris and will likely work on generic Unix systems. You must
have the OpenSSL command line utility installed and in your PATH. For
Debian/Ubuntu and RHEL/CentOS derived systems, this is included in the
`openssl` package.

The steps to get started are:

1. Create a root certificate
2. Create a server certificate
3. Sign the server certificate

After the root certificate has been created, only steps #2 and #3 are performed
for normal operations. 

The root certificate is created with a 10 year expiration date and does not
need to be remade unless its private key is compromised. Server and user
certificates are created with 2 year expiration dates.



## Examples


### Create a new Root CA certificate

This creates the self-signed root certificate for your new CA. This certificate
will be used to sign all other certificates and must be trusted by the clients
of those servers.

```
$ ./new-root-ca.sh
No Root CA key found. Generating one
Generating RSA private key, 2048 bit long modulus
......+++
.....+++
e is 65537 (0x10001)
Enter pass phrase for ca.key:
Verifying - Enter pass phrase for ca.key:

Self-sign the root CA...
Enter pass phrase for ca.key:
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [US]:
State or Province Name (full name) [Texas]:
Locality Name (eg, city) [Austin]:
Organization Name (eg, company) [My Personal Certificate Authority]:
Organizational Unit Name (eg, section) [Certification Services Division]:
Common Name (eg, MD Root CA) []:My Root CA
Email Address []:pki@my.root.ca.com
```

This process creates these two files:
* ca.crt -- _distribute to clients and add to trusted CA databases_
* ca.key -- _keep private and never disclose this file_



### Create and sign a new server certificate

This example creates a server certificate with two Subject Alternate
Names. This web server would presumably respond to these DNS host names:

* www.example.com
* example.com
* staging.example.com

```
$ ./new-server-cert.sh www.example.com example.com staging.example.com
No www.example.com.key found. Generating one
Generating RSA private key, 2048 bit long modulus
.......................................+++
...................................................................+++
e is 65537 (0x10001)

Fill in certificate data
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [US]:
State or Province Name (full name) [Texas]:
Locality Name (eg, city) [Austin]:
Organization Name (eg, company) [My Personal Organization]:
Organizational Unit Name (eg, section) [Secure Server]:
Common Name (eg, www.domain.com) [www.example.com]:
Email Address []:

You may now run ./sign-server-cert.sh to get it signed
```

This process creates these two files:
* www.example.com.csr -- _certificate signing request for the CA_
* www.example.com.key -- _private encryption key only the web server knows_


The CSR is the file that carries the information that the CA needs in order to
create the certificate (CRT) file that is delivered to the server's clients.

```
$ ./sign-server-cert.sh www.example.com
Found subject alternate names: DNS:www.example.com, DNS:example.com,
DNS:staging.example.com

CA signing: www.example.com.csr -> www.example.com.crt:
Using configuration from ca.config
Enter pass phrase for ./ca.key:
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
countryName           :PRINTABLE:'US'
stateOrProvinceName   :PRINTABLE:'Texas'
localityName          :PRINTABLE:'Austin'
organizationName      :PRINTABLE:'My Personal Organization'
organizationalUnitName:PRINTABLE:'Secure Server'
commonName            :PRINTABLE:'www.example.com'
Certificate is to be certified until Mar  9 19:45:30 2018 GMT (730 days)
Sign the certificate? [y/n]:y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Data Base Updated

CA verifying: www.example.com.crt <-> CA cert
www.example.com.crt: OK
```

This process creates one new file:
* www.example.com.crt -- _signed certificate given to clients by the server_



### Create a wildcard certificate

This example creates a wildcard certificate with a SAN that matches the base
domain name. These are the DNS names that will match the final certificate:

* *.example.com
* example.com

Note that, unlike DNS resolution, SSL/TLS clients will only use one level of
matching for wildcard names. For example, an SSL certificate for
`*.example.com` will validate `dev.example.com` and `staging.example.com` but
will reject `alpha.dev.example.com`. This is by design of the SSL validation
and there is no _fix_ for it.

```
$ ./new-server-cert.sh example.com '*.example.com'
No example.com.key found. Generating one
Generating RSA private key, 2048 bit long modulus
..................+++
.............................................................+++
e is 65537 (0x10001)

Fill in certificate data
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [US]:
State or Province Name (full name) [Texas]:
Locality Name (eg, city) [Austin]:
Organization Name (eg, company) [My Personal Organization]:
Organizational Unit Name (eg, section) [Secure Server]:
Common Name (eg, www.domain.com) [example.com]:
Email Address []:

You may now run ./sign-server-cert.sh to get it signed
```

If you do not wish to include the base domain name as a Subject Alternate Name
and you only want the CN to be the wildcard name, run the create command as
shown and, when prompted for the CN, enter `*.example.com` as shown:

```
$ ./new-server-cert.sh wildcard.example.com
...
Common Name (eg, www.domain.com) [wildcard.example.com]:*.example.com
...
```


## Installing Certificates

While there are more complete guides on the Internet for installing SSL
certificates, these my are my notes on a few common services. Please note that,
while I have not included any guidance for configuring the cipher suites and
protocols, these are crucial items that you must understand when configuring
any secure service on the Internet.

Some of these these examples assume that you have put the server certificate
and private key files into the standard locations for Debian/Ubuntu.


### Debian/Ubuntu Certificate Storage

On Debian/Ubuntu, the trusted root CAs are installed into the `/etc/ssl/certs`
directory. Copy your `ca.crt` file into this directory and give it a better
name and `pem` extension. For example: `My_Personal_Root_CA.pem`

After doing this, run the OpenSSL command `c_rehash` in order to recreate all
of the symbolic links in that directory.  Then, run the
`update-ca-certificates` command to remake the `ca-certificates.crt` single
bundle file.

Private keys are normally installed into the `/etc/ssl/private`
directory. Since your CA key will not be used by system services, you do not
need to copy it there. However, it will be convenient to copy your server keys
there, especially if multiple services share a key.


### nginx Web Server

Create the server's private key and certificate and include them in the web
server configuration as follows:

```nginx
ssl_certificate /etc/ssl/certs/www.example.com.crt;
ssl_certificate_key /etc/ssl/private/www.example.com.key;
```


### Pound Proxy

The pound proxy requires that the server's key and certificate plus the CA's
certificate be combined together into one PEM file. These commands will give
you the correct ordering within the file:

```
$ cat www.example.com.key > www.example.com.pem
$ openssl x509 -in www.example.com.crt >> www.example.com.pem
$ cat ca.crt >> www.example.com.pem
```

The combined PEM file is now referenced from `pound.cfg` as follows:

```
ListenHTTPS
    Address 0.0.0.0
    Port    443
    Cert    "/etc/pound/www.example.com.pem"
```


### Postfix MTA

```
smtp_tls_CApath= /etc/ssl/certs
smtp_tls_cert_file = /etc/ssl/certs/mail.example.com.crt
smtp_tls_key_file = /etc/ssl/private/mail.example.com.key
#
smtpd_tls_CApath= /etc/ssl/certs
smtpd_tls_cert_file = /etc/ssl/certs/mail.example.com.crt
smtpd_tls_key_file = /etc/ssl/private/mail.example.com.key
```


### Dovecot IMAP

```
ssl_ca = /etc/ssl/certs/My_Personal_Root_CA.pem
ssl_cert = </etc/ssl/certs/mail.example.com.crt
ssl_key = </etc/ssl/private/mail.example.com.key
```



## Validation with OpenSSL

These commands show how to view and validate an SSL certificate from a client's
point of view. These assume that that your operating system's trusted root CAs
are in the `/etc/ssl/certs` directory. See the previous instructions for the
steps to rehash and manage this directory on Debian/Ubuntu systems.

*HTTPS web server:*
```
openssl s_client -CApath /etc/ssl/certs -connect www.example.com:443 \
   </dev/null | openssl x509 -text -noout
```

*SMTP mail server w/TLS:*
```
openssl s_client -CApath /etc/ssl/certs -connect mail.example.com:25 \
   -starttls smtp  </dev/null | openssl x509 -text -noout
```

*IMAP server w/TLS:*
```
openssl s_client -CApath /etc/ssl/certs -connect mail.example.com:143 \
   -starttls imap  </dev/null | openssl x509 -text -noout
```



## Customizing Your CA

These are instructions for modifying this package in order to customize it for
your particular deployment.


### Root Certificate

The root certificate is created with the `new-root-ca.sh` script. The
certificate it creates is then used to sign all of your server and client
certificates. These are the typical customizations that you will want to make
within that script.

Operating parameters:

```
KEYBITS=2048
HASHALGO="sha256"
VALID_DAYS=3650
RANDOM_SRC=/dev/urandom
```

Defaults for the certificate contents:

```
[ req_distinguished_name ]
countryName_default             = US
stateOrProvinceName_default     = Texas
localityName_default            = Austin
0.organizationName_default      = My Personal Certificate Authority
organizationalUnitName_default  = Certification Services Division
```


### Server Certificates

The server certificates are created with the `new-server-cert.sh` and signed
with the `sign-server-cert.sh` script. These are the typical customizations
that you will want to make within those scripts.


#### Creating

These changes are made in the `new-server-cert.sh` script.

Operating parameters:

```
KEYBITS=2048
HASHALGO="sha256"
```

Defaults for the certificate contents:

```
[ req_distinguished_name ]
countryName_default             = US
stateOrProvinceName_default     = Texas
localityName_default            = Austin
0.organizationName_default      = My Personal Organization
organizationalUnitName_default  = Secure Server
```


#### Signing

These changes are made in the `sign-server-cert.sh` script.

Operating parameters:

```
HASHALGO="sha256"
VALID_DAYS=730
RANDOM_SRC=/dev/urandom
```


### User Certificates

The user certificates are created with the `new-user-cert.sh` and signed with
the `sign-user-cert.sh` script. These are the typical customizations that you
will want to make within those scripts.


#### Creating

These changes are made in the `new-user-cert.sh` script.

Operating parameters:

```
KEYBITS=2048
HASHALGO="sha256"
```


#### Signing

These changes are made in the `sign-user-cert.sh` script.

Operating parameters:

```
HASHALGO="sha256"
VALID_DAYS=730
RANDOM_SRC=/dev/urandom
```



### Entropy Source

The default choice of entropy (randomness) is the `/dev/urandom` device and
this is probably okay for most sites. However, for the most security with
regard to entropy, you may consider using `/dev/random` for public certificate
authorities.

The disadvantage to using `/dev/random` is that it may take your system a long
time to generate enough kernel entropy to complete the request. This can be
especially true on virtual machines. The `/dev/urandom` device will continue to
give decent entropy without blocking even after the kernel's entropy pool is
depleted.

Earlier versions of this package (v0.1 and v0.2) used a static `random-bits`
file as the source of entropy. If this file was updated with fresh entropy
before every signing operation, this would be okay. However, it is more likely
that the same entropy will be used more than once and this is not a secure
situation.
