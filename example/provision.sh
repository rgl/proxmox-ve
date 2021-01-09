#!/bin/bash
set -eux

ip=$1
fqdn=$(hostname --fqdn)

# configure apt for non-interactive mode.
export DEBIAN_FRONTEND=noninteractive

# make sure the local apt cache is up to date.
while true; do
    apt-get update && break || sleep 5
done

# extend the main partition to the end of the disk
# and extend the pve/data logical volume to use all
# the free space.
apt-get install -y cloud-guest-utils
if growpart /dev/[vs]da 3; then
    pvresize /dev/[vs]da3
    lvextend --extents +100%FREE /dev/pve/data
fi

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
killall agetty | true # force them to re-display the issue file.

# disable the "You do not have a valid subscription for this server. Please visit www.proxmox.com to get a list of available options."
# message that appears each time you logon the web-ui.
# NB this file is restored when you (re)install the pve-manager package.
echo 'Proxmox.Utils.checked_command = function(o) { o(); };' >>/usr/share/pve-manager/js/pvemanagerlib.js

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

# show versions.
uname -a
lvm version
kvm --version
lxc-ls --version
cat /etc/os-release
cat /etc/debian_version
cat /etc/machine-id
pveversion -v
lsblk -x KNAME -o KNAME,SIZE,TRAN,SUBSYSTEMS,FSTYPE,UUID,LABEL,MODEL,SERIAL

# show the proxmox web address.
cat <<EOF
access the proxmox web interface at:
    https://$ip:8006/
    https://$fqdn:8006/
EOF
