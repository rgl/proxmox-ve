#!/bin/bash
set -euxo pipefail

# configure apt for non-interactive mode.
export DEBIAN_FRONTEND=noninteractive

# use traditional interface names like eth0 instead of enp0s3
# by disabling the predictable network interface names.
sed -i -E 's,^(GRUB_CMDLINE_LINUX=).+,\1"net.ifnames=0",' /etc/default/grub
update-grub

# NB isc-dhcp-client is deprecated but is still needed by ifupdown2 to configure
#    the interface using dhcp.
# NB in upstream debian, ifupdown is used instead, which works fine with dhcpcd
#    instead of dhclient, but in proxmox, ifupdown2 is used instead of ifupdown.
# see https://packages.debian.org/trixie/isc-dhcp-client
# see https://packages.debian.org/trixie/dhcpcd
# see https://packages.debian.org/trixie/ifupdown
# see https://packages.debian.org/trixie/ifupdown2
apt-get install -y isc-dhcp-client

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
