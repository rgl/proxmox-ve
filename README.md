This builds an up-to-date [Proxmox VE](https://www.proxmox.com/en/proxmox-ve) Vagrant Base Box.

Currently this targets Proxmox VE 7.

# Usage

Create the base box as described in the section corresponding to your provider.

If you want to troubleshoot the packer execution see the `.log` file that is created in the current directory.

After the example vagrant enviroment is started, you can access the [Proxmox Web Interface](https://10.10.10.2:8006/) with the default `root` user and password `vagrant`.

For a cluster example see [rgl/proxmox-ve-cluster-vagrant](https://github.com/rgl/proxmox-ve-cluster-vagrant).

## libvirt/VirtualBox

Create the base box:

```bash
make build-libvirt # or build-virtualbox
```

Add the base box as suggested in make output:

```bash
vagrant box add -f proxmox-ve-amd64 proxmox-ve-amd64-libvirt.box # or proxmox-ve-amd64-virtualbox.box
```

Start the example vagrant environment with:

```bash
cd example
vagrant up --no-destroy-on-error --provider=libvirt # or --provider=virtualbox
```

## Hyper-V

Follow the [rgl/debian-vagrant Hyper-V Usage section](https://github.com/rgl/debian-vagrant#hyper-v-usage).

Create a vSwitch for proxmox:

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
Take a look at `proxmox-ve.json`, object `variables`, to get an idea which values can be
overridden. Do not override `iso_url` and `iso_checksum` as the `boot_command`s might be
tied to a specific Proxmox VE version. Also take care when you decide to override `country`.

Create the base box:

```bash
make build-libvirt VAR_FILE=example.vars.json  # or build-virtualbox or build-hyperv
```

The following content of `example.vars.json`:

* sets the initial disk size to 128 GB
* sets the initial memory to 4 GB
* sets the Packer output base directory to /dev/shm
* sets the country to Germany (timezone is updated by Proxmox VE installer) and changes
  the keyboard layout back to "U.S. English" as this is needed for the subsequent
  `boot_command` statements
* sets the hostname to pve-test.example.local

  ```json
  {
      "disk_size": "131072",
      "memory": "4096",
      "output_base_dir": "/dev/shm",
      "step_country": "Ger<wait>m<wait>a<wait>n<wait><enter>",
      "step_hostname": "pve-test.example.local",
      "step_keyboard_layout": "<end><up><wait>"
  }
  ```

# Packer boot_command

As Proxmox does not have any way to be pre-seeded, this environment has to answer all the
installer questions through the packer `boot_command` interface. This is quite fragile, so
be aware when you change anything. The following table describes the current steps and
corresponding answers.

| step                              | boot_command                                          |
|----------------------------------:|-------------------------------------------------------|
| select "Install Proxmox VE"       | `<enter>`                                             |
| wait for boot                     | `<wait1m>`                                            |
| agree license                     | `<enter><wait>`                                       |
| target disk                       | `<enter><wait>`                                       |
| type country                      | `United States<wait><enter><wait><tab><wait>`         |
| timezone                          | `<tab><wait>`                                         |
| keyboard layout                   | `<tab><wait>`                                         |
| advance to the next button        | `<tab><wait>`                                         |
| advance to the next page          | `<enter><wait5>`                                      |
| password                          | `vagrant<tab><wait>`                                  |
| confirm password                  | `vagrant<tab><wait>`                                  |
| email                             | `pve@example.com<tab><wait>`                          |
| advance to the next button        | `<tab><wait>`                                         |
| advance to the next page          | `<enter><wait5>`                                      |
| hostname                          | `pve.example.com<tab><wait>`                          |
| ip address                        | `<tab><wait>`                                         |
| netmask                           | `<tab><wait>`                                         |
| gateway                           | `<tab><wait>`                                         |
| DNS server                        | `<tab><wait>`                                         |
| advance to the next button        | `<tab><wait>`                                         |
| advance to the next page          | `<enter><wait5>`                                      |
| install                           | `<enter><wait5>`                                      |

**NB** Do not change the keyboard layout. If you do, the email address will fail to be typed.
