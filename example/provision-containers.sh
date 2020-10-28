#!/bin/bash
set -eux

ip=$1
fqdn=$(hostname --fqdn)

# update the available container templates.
# NB this downloads the https://www.turnkeylinux.org catalog.
pveam update
pveam available # show templates.

# create and start two alpine-linux containers.
pve_template=alpine-3.12-default_20200823_amd64.tar.xz
pveam download local $pve_template
for pve_id in 100 101; do
    pve_ip=$(echo $ip | sed -E "s,\.[0-9]+\$,.$pve_id,")
    pve_disk_size=512M
    pvesm alloc local-lvm $pve_id vm-$pve_id-disk-1 $pve_disk_size
    pvesm status # show status.
    mkfs.ext4 $(pvesm path local-lvm:vm-$pve_id-disk-1)
    pct create $pve_id \
        local:vztmpl/$pve_template \
        --unprivileged 0 \
        --onboot 1 \
        --ostype alpine \
        --hostname alpine-$pve_id \
        --cores 1 \
        --memory 128 \
        --swap 0 \
        --rootfs local-lvm:vm-$pve_id-disk-1,size=$pve_disk_size \
        --net0 name=eth0,bridge=vmbr0,gw=$ip,ip=$pve_ip/24
    pct config $pve_id # show config.
    pct start $pve_id
    pct exec $pve_id sh <<EOF
set -eu
apk update
apk add nginx
adduser -D -u 1000 -g www www
mkdir /www
cat >/etc/nginx/nginx.conf <<'EOC'
user www;
worker_processes 1;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;
events {
    worker_connections 1024;
}
http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    sendfile on;
    access_log /var/log/nginx/access.log;
    keepalive_timeout 3000;
    server {
        listen 80;
        root /www;
        index index.html;
        server_name localhost;
        client_max_body_size 4m;
        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
              root /var/lib/nginx/html;
        }
    }
}
EOC
cat >/www/index.html <<'EOC'
<!doctype html>
<html>
<head>
    <title>server $pve_id</title>
</head>
<body>
    this is server $pve_id
</body>
</html>
EOC
rc-service nginx start
rc-update add nginx default
EOF
    wget -qO- $pve_ip
    pct exec $pve_id -- cat /etc/alpine-release
    pct exec $pve_id -- passwd -d root                          # remove the root password.
    pct exec $pve_id -- sh -c "echo 'root:vagrant' | chpasswd"  # or change it to vagrant.
    pct exec $pve_id -- ip addr
    pct exec $pve_id -- route -n
    pct exec $pve_id -- ping $ip -c 2
    pct status $pve_id
done
