#!/bin/bash
set -eux

ip=$1
domain=$(hostname --fqdn)
dn=$(hostname)

mkdir -p /vagrant/shared
pushd /vagrant/shared

# create a self-signed certificate.
if [ ! -f $domain-crt.pem ]; then
    openssl genrsa \
        -out $domain-key.pem \
        2048 \
        2>/dev/null
    chmod 400 $domain-key.pem
    openssl req -new \
        -sha256 \
        -subj "/CN=$domain" \
        -key $domain-key.pem \
        -out $domain-csr.pem
    openssl x509 -req -sha256 \
        -signkey $domain-key.pem \
        -extensions a \
        -extfile <(echo "[a]
            subjectAltName=DNS:$domain,IP:$ip
            extendedKeyUsage=critical,serverAuth
            ") \
        -days 365 \
        -in  $domain-csr.pem \
        -out $domain-crt.pem
    openssl x509 \
        -in $domain-crt.pem \
        -outform der \
        -out $domain-crt.der
    # dump the certificate contents (for logging purposes).
    #openssl x509 -noout -text -in $domain-crt.pem
fi

# install the certificate.
# see https://pve.proxmox.com/wiki/HTTPS_Certificate_Configuration_(Version_4.x_and_newer)
cp $domain-key.pem "/etc/pve/nodes/$dn/pveproxy-ssl.key"
cp $domain-crt.pem "/etc/pve/nodes/$dn/pveproxy-ssl.pem"
systemctl restart pveproxy
# dump the TLS connection details and certificate validation result.
(printf 'GET /404 HTTP/1.0\r\n\r\n'; sleep .1) | openssl s_client -CAfile $domain-crt.pem -connect $domain:8006 -servername $domain
