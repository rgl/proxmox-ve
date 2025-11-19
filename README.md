This builds an up-to-date [Proxmox VE](https://www.proxmox.com/en/proxmox-ve) Vagrant Base Box.

Currently this targets Proxmox VE 8.

# Usage

Create the base box as described in the section corresponding to your provider.

If you want to troubleshoot the packer execution see the `.log` file that is created in the current directory.

After the example vagrant environment is started, you can access the [Proxmox Web Interface](https://10.10.10.2:8006/) with the default `root` user and password `password`.

For a cluster example see [rgl/proxmox-ve-cluster-vagrant](https://github.com/rgl/proxmox-ve-cluster-vagrant).

## libvirt

Create the base box:

```bash
make build-libvirt
```

Add the base box as suggested in make output:

```bash
vagrant box add -f proxmox-ve-amd64 proxmox-ve-amd64-libvirt.box
```

Start the example vagrant environment with:

```bash
cd example
vagrant up --no-destroy-on-error --provider=libvirt
```

## Proxmox

Set the Proxmox VE details:

```bash
cat >secrets-proxmox.sh <<EOF
export PROXMOX_URL='https://192.168.1.21:8006/api2/json'
export PROXMOX_USERNAME='root@pam'
export PROXMOX_PASSWORD='password'
export PROXMOX_NODE='pve'
EOF
source secrets-proxmox.sh
```

Create the template:

```bash
make build-proxmox
```

**NB** There is no way to use the created template with vagrant (the [vagrant-proxmox plugin](https://github.com/telcat/vagrant-proxmox) is no longer compatible with recent vagrant versions). Instead, use packer or terraform.

## Hyper-V

Follow the [rgl/windows-vagrant Hyper-V Usage section](https://github.com/rgl/windows-vagrant#hyper-v-usage) to create the `Vagrant` vSwitch for use by the packer template and the example vagrant environment.

Create the `proxmox` vSwitch for use in the example vagrant environment second
network interface:

```bash
PowerShell -NoLogo -NoProfile -ExecutionPolicy Bypass <<'EOF'
$switchName = 'proxmox'
$networkAdapterName = "vEthernet ($switchName)"
$networkAdapterIpAddress = '10.10.10.1'
$networkAdapterIpPrefixLength = 24

# create the vSwitch.
New-VMSwitch -Name $switchName -SwitchType Internal | Out-Null

# assign it an host IP address.
$networkAdapter = Get-NetAdapter $networkAdapterName
$networkAdapter | New-NetIPAddress `
    -IPAddress $networkAdapterIpAddress `
    -PrefixLength $networkAdapterIpPrefixLength `
    | Out-Null

# remove all virtual switches from the windows firewall.
Set-NetFirewallProfile `
    -DisabledInterfaceAliases (
            Get-NetAdapter -name "vEthernet*" | Where-Object {$_.ifIndex}
        ).InterfaceAlias
EOF
```

Set the Hyper-V details:

```bash
cat >secrets-hyperv.sh <<'EOF'
# set this value when you need to set the VM Switch Name.
export HYPERV_SWITCH_NAME='Vagrant'

# set this value when you need to set the VM VLAN ID.
unset HYPERV_VLAN_ID
#export HYPERV_VLAN_ID=''

# set the credentials that the guest will use
# to connect to this host smb share.
# NB you should create a new local user named _vagrant_share
#    and use that one here instead of your user credentials.
# NB it would be nice for this user to have its credentials
#    automatically rotated, if you implement that feature,
#    let me known!
export VAGRANT_SMB_USERNAME='_vagrant_share'
export VAGRANT_SMB_PASSWORD=''

# remove the virtual switch from the windows firewall.
# NB execute if the VM fails to obtain an IP address from DHCP.
PowerShell -Command 'Set-NetFirewallProfile -DisabledInterfaceAliases (Get-NetAdapter -name "vEthernet*" | Where-Object {$_.ifIndex}).InterfaceAlias'
EOF
source secrets-hyperv.sh
```

Create the base box:

```bash
make build-hyperv
```

Add the base box as suggested in make output:

```bash
vagrant box add -f proxmox-ve-amd64 proxmox-ve-amd64-hyperv.box
```

Start the example vagrant environment with:

```bash
cd example
vagrant up --provider=hyperv
```

## VMware vSphere usage

Download [govc](https://github.com/vmware/govmomi/releases/latest) and place it inside your `/usr/local/bin` directory.

Set your VMware vSphere details and test the connection:

```bash
sudo apt-get install build-essential patch ruby-dev zlib1g-dev liblzma-dev
vagrant plugin install vagrant-vsphere
cat >secrets-vsphere.sh <<'EOF'
export GOVC_INSECURE='1'
export GOVC_HOST='vsphere.local'
export GOVC_URL="https://$GOVC_HOST/sdk"
export GOVC_USERNAME='administrator@vsphere.local'
export GOVC_PASSWORD='password'
export GOVC_DATACENTER='Datacenter'
export GOVC_CLUSTER='Cluster'
export GOVC_DATASTORE='Datastore'
export VSPHERE_OS_ISO="[$GOVC_DATASTORE] iso/proxmox-ve_9.1-1.iso"
export VSPHERE_ESXI_HOST='esxi.local'
export VSPHERE_TEMPLATE_FOLDER='test/templates'
# NB the VSPHERE_TEMPLATE_NAME last segment MUST match the
#    builders.vm_name property inside the packer template.
export VSPHERE_TEMPLATE_NAME="$VSPHERE_TEMPLATE_FOLDER/proxmox-ve-amd64"
export VSPHERE_VM_FOLDER='test'
export VSPHERE_VM_NAME='proxmox-ve-example'
# NB for the nested VMs to access the network, this VLAN port group security
#    policy MUST be configured to Accept:
#      Promiscuous mode
#      Forged transmits
export VSPHERE_VLAN='packer'
export VSPHERE_IP_WAIT_ADDRESS='0.0.0.0/0'
# set the credentials that the guest will use
# to connect to this host smb share.
# NB you should create a new local user named _vagrant_share
#    and use that one here instead of your user credentials.
# NB it would be nice for this user to have its credentials
#    automatically rotated, if you implement that feature,
#    let me known!
export VAGRANT_SMB_USERNAME='_vagrant_share'
export VAGRANT_SMB_PASSWORD=''
EOF
source secrets-vsphere.sh
# see https://github.com/vmware/govmomi/blob/master/govc/USAGE.md
govc version
govc about
govc datacenter.info # list datacenters
govc find # find all managed objects
```

Download the Proxmox ISO (you can find the full iso URL in the [proxmox-ve.json](proxmox-ve.json) file) and place it inside the datastore as defined by the `iso_paths` property that is inside the [packer template](proxmox-ve-vsphere.json) file.

See the [example Vagrantfile](example/Vagrantfile) to see how you could use a cloud-init configuration to configure the VM.

Type `make build-vsphere` and follow the instructions.

Try the example guest:

```bash
source secrets-vsphere.sh
cd example
vagrant up --provider=vsphere --no-destroy-on-error --no-tty
vagrant ssh
exit
vagrant destroy -f
```

## Packer build performance options

To improve the build performance you can use the following options.

### Accelerate build time with Apt Caching Proxy

To speed up package downloads, you can specify an apt caching proxy 
(e.g. [apt-cacher-ng](https://www.unix-ag.uni-kl.de/~bloch/acng/))
by defining the environment variables `APT_CACHE_HOST` (default: undefined)
and `APT_CACHE_PORT` (default: 3124).

Example:

```bash
APT_CACHE_HOST=10.10.10.100 make build-libvirt
```

### Decrease disk wear by using temporary memory file-system

To decrease disk wear (and potentially reduce io times),
you can use `/dev/shm` (temporary memory file-system) as `output_directory` for Packer builders.
Your system must have enough available memory to store the created virtual machine.

Example:

```bash
PACKER_OUTPUT_BASE_DIR=/dev/shm make build-libvirt
```

Remember to also define `PACKER_OUTPUT_BASE_DIR` when you run `make clean` afterwards.

## Variables override

Some properties of the virtual machine and the Proxmox VE installation can be overridden.
Take a look at `proxmox-ve.pkr.hcl`, `variable` blocks, to get an idea which values can be
overridden. Do not override `iso_url` and `iso_checksum` as the `boot_command`s might be
tied to a specific Proxmox VE version.

Create the base box:

```bash
make build-libvirt VAR_FILE=example.pkrvars.hcl
```

The following content of `example.pkrvars.hcl`:

* sets the initial disk size to 128 GB
* sets the initial memory to 4 GB
* sets the Packer output base directory to /dev/shm
* uses all default shell provisioners (see [`./provisioners`](./provisioners)) and a
  custom one for german localisation

```hcl
disk_size = 128 * 1024
memory = 4 * 1024
output_base_dir = "/dev/shm"
shell_provisioner_scripts = [
  "provisioners/apt_proxy.sh",
  "provisioners/upgrade.sh",
  "provisioners/network.sh",
  "provisioners/localisation-de.sh",
  "provisioners/reboot.sh",
  "provisioners/provision.sh",
]
```

# Packer boot_command

The Proxmox installation is [automatically configured](https://pve.proxmox.com/wiki/Automated_Installation) using the [`answer.toml` file](answer.toml), but to trigger the automatic installation, this environment has to nudge the default Proxmox installation ISO to use the [`answer.toml` file](answer.toml) through the packer `boot_command` interface. This is quite fragile, so be aware when you change anything. The following table describes the current steps and corresponding answers.

| step                                    | boot_command                                                                               |
|----------------------------------------:|--------------------------------------------------------------------------------------------|
| select "Advanced Options"               | `<end><enter>`                                                                             |
| select "Install Proxmox VE (Automated)" | `<down><down><down><enter>`                                                                |
| wait for the shell prompt               | `<wait1m>`                                                                                 |
| do the installation                     | `proxmox-fetch-answer partition >/run/automatic-installer-answers<enter><wait>exit<enter>` |
