#!/bin/bash

set -exu

net=$1
ip=$2

echo y | pveceph install
pveceph init --network ${net}0/24

# allow ceph to run on a single node
cp /etc/ceph/ceph.conf /etc/ceph/ceph.conf.bak
awk 'NR==9{print "         osd crush chooseleaf type = 0"}1' \
  /etc/ceph/ceph.conf.bak > /etc/ceph/ceph.conf

pveceph createmon
for i in b c d;do
  pveceph createosd /dev/vd$i
done

mkdir /etc/pve/priv/ceph
cp /etc/ceph/ceph.client.admin.keyring /etc/pve/priv/ceph/rbd.keyring
cat <<EOF >>/etc/pve/storage.cfg

rbd: rbd
        monhost ${ip}
        content rootdir,images
        krbd 1
        pool rbd
        username admin
EOF
