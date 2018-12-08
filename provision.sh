#!/bin/bash
# abort this script when a command fails or a unset variable is used.
set -eu
# echo all the executed commands.
set -x

# configure apt for non-interactive mode.
export DEBIAN_FRONTEND=noninteractive

# remove old kernel packages.
# NB as of pve 5.2, there's a metapackage, pve-kernel-4.15, then there are the
#    real kernels at pve-kernel-*-pve (these are the ones that are removed).
pve_kernels=$(dpkg-query -f '${Package}\n' -W 'pve-kernel-*-pve')
for pve_kernel in $pve_kernels; do
    if [[ $pve_kernel != "pve-kernel-$(uname -r)" ]]; then
        apt-get remove -y --purge $pve_kernel
    fi
done

# create a group where sudo will not ask for a password.
apt-get install -q -y sudo
groupadd -r admin
echo '%admin ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/admin

# create the vagrant user. also allow access with the insecure vagrant public key.
# NB vagrant will replace it on the first run.
groupadd vagrant
useradd -g vagrant -m vagrant -s /bin/bash
gpasswd -a vagrant admin
chmod 750 /home/vagrant
install -d -m 700 /home/vagrant/.ssh
pushd /home/vagrant/.ssh
wget -q --no-check-certificate https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub -O authorized_keys
chmod 600 authorized_keys
chown -R vagrant:vagrant .
popd

# install the Guest Additions.
if [ -n "$(lspci | grep VirtualBox)" ]; then
# install the VirtualBox Guest Additions.
# this will be installed at /opt/VBoxGuestAdditions-VERSION.
# NB You can unpack the VBoxLinuxAdditions.run file contents with:
#       VBoxLinuxAdditions.run --target /tmp/VBoxLinuxAdditions.run.contents --noexec
# NB REMOVE_INSTALLATION_DIR=0 is to fix a bug in VBoxLinuxAdditions.run.
#    See http://stackoverflow.com/a/25943638.
apt-get -y -q install gcc dkms pve-headers
mkdir -p /mnt
mount /dev/sr1 /mnt
while [ ! -f /mnt/VBoxLinuxAdditions.run ]; do sleep 1; done
# NB we ignore exit code 2 (cannot find vboxguest module) because of what
#    seems to be a bug in VirtualBox 5.1.20. there isn't actually a problem
#    loading the module.
REMOVE_INSTALLATION_DIR=0 /mnt/VBoxLinuxAdditions.run --target /tmp/VBoxGuestAdditions || [ $? -eq 2 ]
rm -rf /tmp/VBoxGuestAdditions
umount /mnt
eject /dev/sr1
else
# install the qemu-kvm Guest Additions.
apt-get install -y qemu-guest-agent spice-vdagent
fi

# install rsync to support "rsync shared" folders in vagrant.
apt-get install -y rsync

# disable the DNS reverse lookup on the SSH server. this stops it from
# trying to resolve the client IP address into a DNS domain name, which
# is kinda slow and does not normally work when running inside VB.
echo UseDNS no >>/etc/ssh/sshd_config

# disable the graphical terminal. its kinda slow and useless on a VM.
sed -i -E 's,#(GRUB_TERMINAL\s*=).*,\1console,g' /etc/default/grub
update-grub

# clean packages.
apt-get -y autoremove
apt-get -y clean

# zero the free disk space -- for better compression of the box file.
# NB prefer discard/trim (safer; faster) over creating a big zero filled file
#    (somewhat unsafe as it has to fill the entire disk, which might trigger
#    a disk (near) full alarm; slower; slightly better compression).
if [ "$(lsblk -no DISC-GRAN $(findmnt -no SOURCE /) | awk '{print $1}')" != '0B' ]; then
    fstrim -v /
else
    dd if=/dev/zero of=/EMPTY bs=1M || true && sync && rm -f /EMPTY
fi
