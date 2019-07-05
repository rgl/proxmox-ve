#!/bin/bash
set -eux

# configure apt for non-interactive mode.
export DEBIAN_FRONTEND=noninteractive

# switch to the non-enterprise repository.
# see https://pve.proxmox.com/wiki/Package_Repositories
rm -f /etc/apt/sources.list.d/pve-enterprise.list
echo 'deb http://download.proxmox.com/debian/pve buster pve-no-subscription' >/etc/apt/sources.list.d/pve.list

# switch the apt mirror from us to nl.
sed -i -E 's,ftp\.us\.debian,ftp.nl.debian,' /etc/apt/sources.list

# upgrade.
apt-get update
apt-get dist-upgrade -y

# use traditional interface names like eth0 instead of enp0s3
# by disabling the predictable network interface names.
sed -i -E 's,^(GRUB_CMDLINE_LINUX=).+,\1"net.ifnames=0",' /etc/default/grub
update-grub

# configure the network for working in a vagrant environment.
# NB proxmox has created the vmbr0 bridge and placed eth0 on the it, but
#    that will not work, vagrant expects to control eth0. so we have to
#    undo the proxmox changes.
cat >/etc/network/interfaces <<'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto vmbr0
iface vmbr0 inet manual
EOF

# add support for the pt_PT locale.
sed -i -E 's,.+(pt_PT.UTF-8 .+),\1,' /etc/locale.gen
locale-gen
locale -a

# set the keyboard layout.
apt-get install -y console-data
cat >/etc/default/keyboard <<'EOF'
# KEYBOARD CONFIGURATION FILE
# Consult the keyboard(5) manual page.
XKBMODEL="pc105"
XKBLAYOUT="pt"
XKBVARIANT=""
XKBOPTIONS=""
KEYMAP="pt-latin1"
BACKSPACE="guess"
EOF
dpkg-reconfigure keyboard-configuration

# set the timezone.
ln -fs /usr/share/zoneinfo/Europe/Lisbon /etc/localtime
dpkg-reconfigure tzdata

# reboot.
nohup bash -c "ps -eo pid,comm | awk '/sshd/{print \$1}' | xargs kill; sync; reboot"
