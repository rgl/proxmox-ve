#!/bin/bash
set -eux

ip=$1
fqdn=$(hostname --fqdn)

# configure apt for non-interactive mode.
export DEBIAN_FRONTEND=noninteractive

# configure the network for NATting.
ifdown vmbr0
cat >/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet manual

auto vmbr0
iface vmbr0 inet static
    address $ip
    netmask 255.255.255.0
    bridge_ports eth1
    bridge_stp off
    bridge_fd 0
    # enable IP forwarding. needed to NAT and DNAT.
    post-up   echo 1 >/proc/sys/net/ipv4/ip_forward
    # NAT through eth0.
    post-up   iptables -t nat -A POSTROUTING -s '$ip/24' ! -d '$ip/24' -o eth0 -j MASQUERADE
    post-down iptables -t nat -D POSTROUTING -s '$ip/24' ! -d '$ip/24' -o eth0 -j MASQUERADE
EOF
sed -i -E "s,^[^ ]+( .*pve.*)\$,$ip\1," /etc/hosts
sed 's,\\,\\\\,g' >/etc/issue <<'EOF'

     _ __  _ __ _____  ___ __ ___   _____  __ __   _____
    | '_ \| '__/ _ \ \/ / '_ ` _ \ / _ \ \/ / \ \ / / _ \
    | |_) | | | (_) >  <| | | | | | (_) >  <   \ V /  __/
    | .__/|_|  \___/_/\_\_| |_| |_|\___/_/\_\   \_/ \___|
    | |
    |_|

EOF
cat >>/etc/issue <<EOF
    https://$ip:8006/
    https://$fqdn:8006/

EOF
ifup vmbr0
iptables-save # show current rules.
killall agetty # force them to re-display the issue file.

# disable the "You do not have a valid subscription for this server. Please visit www.proxmox.com to get a list of available options."
# message that appears each time you logon the web-ui.
# NB this file is restored when you (re)install the pve-manager package.
echo 'PVE.Utils.checked_command = function(o) { o(); };' >>/usr/share/pve-manager/js/pvemanagerlib.js

# install vim.
apt-get install -y --no-install-recommends vim
cat >/etc/vim/vimrc.local <<'EOF'
syntax on
set background=dark
set esckeys
set ruler
set laststatus=2
set nobackup
EOF

# configure the shell.
cat >/etc/profile.d/login.sh <<'EOF'
[[ "$-" != *i* ]] && return
export EDITOR=vim
export PAGER=less
alias l='ls -lF --color'
alias ll='l -a'
alias h='history 25'
alias j='jobs -l'
EOF

cat >/etc/inputrc <<'EOF'
set input-meta on
set output-meta on
set show-all-if-ambiguous on
set completion-ignore-case on
"\e[A": history-search-backward
"\e[B": history-search-forward
"\eOD": backward-word
"\eOC": forward-word
EOF

# configure the motd.
# NB this was generated at http://patorjk.com/software/taag/#p=display&f=Big&t=proxmox%20ve.
#    it could also be generated with figlet.org.
cat >/etc/motd <<'EOF'

     _ __  _ __ _____  ___ __ ___   _____  __ __   _____
    | '_ \| '__/ _ \ \/ / '_ ` _ \ / _ \ \/ / \ \ / / _ \
    | |_) | | | (_) >  <| | | | | | (_) >  <   \ V /  __/
    | .__/|_|  \___/_/\_\_| |_| |_|\___/_/\_\   \_/ \___|
    | |
    |_|

EOF

# update the available container templates.
# NB this downloads the https://www.turnkeylinux.org catalog.
pveam update
pveam available # show templates.

# create and start two alpine-linux containers.
pve_template=alpine-3.4-default_20161206_amd64.tar.xz
pveam download local $pve_template
for pve_id in 100 101; do
    pve_ip=$(echo $ip | sed -E "s,\.[0-9]+\$,.$pve_id,")
    pve_disk_size=128M
    pvesm alloc local-lvm $pve_id vm-$pve_id-disk-1 $pve_disk_size
    pvesm status # show status.
    mkfs.ext4 $(pvesm path local-lvm:vm-$pve_id-disk-1)
    pct create $pve_id \
        /var/lib/vz/template/cache/$pve_template \
        -onboot 1 \
        -ostype alpine \
        -hostname alpine-$pve_id \
        -cores 1 \
        -memory 128 \
        -swap 0 \
        -rootfs local-lvm:vm-$pve_id-disk-1,size=$pve_disk_size \
        -net0 name=eth0,bridge=vmbr0,gw=$ip,ip=$pve_ip/24
    pct config $pve_id # show config.
    pct start $pve_id
    pct exec $pve_id sh <<EOF
set -eu
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
    pct exec $pve_id -- route -n
    pct exec $pve_id -- ping $ip -c 2
    pct status $pve_id
done
pct list

# show versions.
uname -a
lvm version
kvm --version
lxc-ls --version
cat /etc/os-release
pveversion -v

# show the proxmox web address.
cat <<EOF
access the proxmox web interface at:
    https://$ip:8006/
    https://$fqdn:8006/
EOF
