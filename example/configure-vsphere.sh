#!/bin/bash
set -euxo pipefail

vm_uuid="$1"
vm_boot_disk_size_gb="$2"
vm_vlan="$3"

# set the boot disk size.
echo "Setting the boot disk size to $vm_boot_disk_size_gb GB..."
vm_boot_disk_name="$(govc device.info --vm.uuid "$vm_uuid" -json 'disk-*' | jq -r '.Devices[0].Name')"
govc vm.disk.change \
    --vm.uuid "$vm_uuid" \
    "-disk.name=$vm_boot_disk_name" \
    -size "${vm_boot_disk_size_gb}GB"

# add network interface.
vm_interfaces="$(govc device.info --vm.uuid "$vm_uuid" -json 'ethernet-*' | jq -r '[.Devices[].Backing.DeviceName]')"
vm_interfaces_count="$(echo "$vm_interfaces" | jq -r '.[]' | wc -l)"
if [ "$(echo "$vm_interfaces_count" | wc -l)" == '1' ]; then
    echo "Adding the $vm_vlan network interface..."
    govc vm.network.add \
        --vm.uuid "$vm_uuid" \
        -net "$vm_vlan" \
        -net.adapter vmxnet3
fi
