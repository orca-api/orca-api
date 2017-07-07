#!/bin/bash

rm -f newcert.pem newkey.pem newreq.pem client.crt client.key client.p12 server.crt server.key
mkdir -p ca/{certs,crl,newcerts,private}
touch ca/index.txt

# ca
openssl req \
        -config "$(pwd)/openssl.cnf" \
        -new \
        -nodes \
        -keyout ca/private/cakey.pem \
        -out ca/careq.pem \
        -subj '/O=ORCA-API'
openssl ca \
        -config "$(pwd)/openssl.cnf" \
	    -create_serial \
        -out ca/cacert.pem \
        -days 1095 \
        -batch \
		-keyfile ca/private/cakey.pem \
        -selfsign \
		-extensions v3_ca \
		-infiles ca/careq.pem

# server cert
openssl req \
        -config "$(pwd)/openssl.cnf" \
        -new \
        -keyout newkey.pem \
        -out newreq.pem \
        -days 365 \
        -subj '/CN=localhost' \
        -passout pass:server
openssl ca \
        -config "$(pwd)/openssl.cnf" \
        -policy policy_anything \
        -updatedb \
        -batch \
        -out newcert.pem \
        -infiles newreq.pem
openssl x509 \
        -in newcert.pem \
        -out server.crt
openssl rsa \
        -in newkey.pem \
        -out server.key \
        -passin pass:server
rm newcert.pem newkey.pem newreq.pem

# client cert
openssl req \
        -config "$(pwd)/openssl.cnf" \
        -new \
        -keyout newkey.pem \
        -out newreq.pem \
        -days 365 \
        -subj '/O=ORCA-API Client' \
        -passout pass:client
openssl ca \
        -config "$(pwd)/openssl.cnf" \
        -policy policy_anything \
        -updatedb \
        -batch \
        -out newcert.pem \
        -infiles newreq.pem
openssl x509 \
        -in newcert.pem \
        -out client.crt
openssl rsa \
        -in newkey.pem \
        -out client.key \
        -passin pass:client
openssl pkcs12 \
        -export \
        -in client.crt \
        -inkey client.key \
        -out client.p12 \
        -passout pass:client
rm newcert.pem newkey.pem newreq.pem

if [[ ! -f dhparam.pem ]]; then
  openssl dhparam 2048 -out dhparam.pem
fi

sudo mkdir -p /etc/nginx/ssl
sudo cp ca/cacert.pem server.crt server.key dhparam.pem /etc/nginx/ssl
sudo cp proxy.conf /etc/nginx/sites-available/
sudo rm -f /etc/nginx/sites-enabled/proxy
sudo ln -s /etc/nginx/sites-available/proxy /etc/nginx/sites-enabled/proxy
sudo service nginx restart
