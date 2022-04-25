#!/bin/bash
set -eux

ip=$1
fqdn=$(hostname --fqdn)

# configure apt for non-interactive mode.
export DEBIAN_FRONTEND=noninteractive

# show running containers.
pct list

# show running VMs.
qm list

# show versions.
uname -a
lvm version
kvm --version
lxc-ls --version
cat /etc/os-release
pveversion -v

# show block devices.
lsblk -x KNAME -o KNAME,SIZE,TRAN,SUBSYSTEMS,FSTYPE,UUID,LABEL,MODEL,SERIAL

# show disk partitions.
sfdisk -l

# show the free space.
df -h /

# show the proxmox web address.
cat <<EOF
access the proxmox web interface at:
    https://$ip:8006/
    https://$fqdn:8006/
EOF
