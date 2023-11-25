#!/bin/bash
set -euxo pipefail

# configure apt for non-interactive mode.
export DEBIAN_FRONTEND=noninteractive

# switch to the non-enterprise repository.
# see https://pve.proxmox.com/wiki/Package_Repositories
dpkg-divert --divert /etc/apt/sources.list.d/pve-enterprise.list.distrib.disabled --rename --add /etc/apt/sources.list.d/pve-enterprise.list
dpkg-divert --divert /etc/apt/sources.list.d/ceph.list.distrib.disabled --rename --add /etc/apt/sources.list.d/ceph.list
echo "deb http://download.proxmox.com/debian/pve $(. /etc/os-release && echo "$VERSION_CODENAME") pve-no-subscription" >/etc/apt/sources.list.d/pve.list
echo "deb http://download.proxmox.com/debian/ceph-reef $(. /etc/os-release && echo "$VERSION_CODENAME") no-subscription" >/etc/apt/sources.list.d/ceph.list

# switch the apt mirror from us to nl.
sed -i -E 's,ftp\.us\.debian,ftp.nl.debian,' /etc/apt/sources.list

# upgrade.
apt-get update
apt-get dist-upgrade -y
