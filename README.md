This builds an up-to-date [Proxmox VE](https://www.proxmox.com/en/proxmox-ve) Vagrant Base Box.

Currently this targets Proxmox VE 6.4.

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

Start the example vagrant environment with:

```bash
cd example
vagrant up --provider=libvirt # or --provider=virtualbox
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
$networkAdapter = Get-NetAdapter $adapterName
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

Start the example vagrant environment with:

```bash
cd example
vagrant up --provider=hyperv
```

# Packer boot_command

As Proxmox does not have any way to be pre-seeded, this environment has to answer all the
installer questions through the packer `boot_command` interface. This is quite fragile, so
be aware when you change anything. The following table describes the current steps and
corresponding answers.

| step                              | boot_command                                          |
|----------------------------------:|-------------------------------------------------------|
| select "Intall Proxmox VE"        | `<enter>`                                             |
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
