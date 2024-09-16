packer {
  required_plugins {
    # see https://github.com/hashicorp/packer-plugin-qemu
    qemu = {
      version = "1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
    # see https://github.com/hashicorp/packer-plugin-proxmox
    proxmox = {
      version = "1.1.8"
      source  = "github.com/hashicorp/proxmox"
    }
    # see https://github.com/hashicorp/packer-plugin-hyperv
    hyperv = {
      version = "1.1.3"
      source  = "github.com/hashicorp/hyperv"
    }
    # see https://github.com/hashicorp/packer-plugin-vagrant
    vagrant = {
      version = "1.1.5"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

variable "vagrant_box" {
  type = string
}

variable "cpus" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  default = 2 * 1024
}

variable "disk_size" {
  type    = number
  default = 20 * 1024
}

variable "iso_url" {
  type    = string
  default = "http://download.proxmox.com/iso/proxmox-ve_8.2-2.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:c96ad84eacbbcef299ab8f407f9602f832abb5ceb08a9aa288c1e1164df2da97"
}

variable "proxmox_node" {
  type    = string
  default = env("PROXMOX_NODE")
}

variable "hyperv_switch_name" {
  type    = string
  default = env("HYPERV_SWITCH_NAME")
}

variable "hyperv_vlan_id" {
  type    = string
  default = env("HYPERV_VLAN_ID")
}

variable "apt_cache_host" {
  type    = string
  default = env("APT_CACHE_HOST")
}

variable "apt_cache_port" {
  type    = string
  default = env("APT_CACHE_PORT")
}

variable "output_base_dir" {
  type    = string
  default = env("PACKER_OUTPUT_BASE_DIR")
}

variable "step_country" {
  type    = string
  default = "United S<wait>t<wait>a<wait>t<wait>e<wait>s<wait><enter><wait>"
}

variable "step_email" {
  type    = string
  default = "pve@example.com"
}

variable "step_hostname" {
  type    = string
  default = "pve.example.com"
}

variable "step_keyboard_layout" {
  type    = string
  default = ""
}

variable "step_timezone" {
  type    = string
  default = ""
}

variable "shell_provisioner_scripts" {
  type = list(string)
  default = [
    "provisioners/apt_proxy.sh",
    "provisioners/upgrade.sh",
    "provisioners/network.sh",
    "provisioners/localisation-pt.sh",
    "provisioners/reboot.sh",
    "provisioners/provision.sh",
  ]
}

source "qemu" "proxmox-ve-amd64" {
  accelerator  = "kvm"
  machine_type = "q35"
  cpus         = var.cpus
  memory       = var.memory
  qemuargs = [
    ["-cpu", "host"],
  ]
  headless            = true
  use_default_display = false
  net_device          = "virtio-net"
  http_directory      = "."
  format              = "qcow2"
  disk_size           = var.disk_size
  disk_interface      = "virtio-scsi"
  disk_cache          = "unsafe"
  disk_discard        = "unmap"
  iso_url             = var.iso_url
  iso_checksum        = var.iso_checksum
  output_directory    = "${var.output_base_dir}/output-{{build_name}}"
  ssh_username        = "root"
  ssh_password        = "vagrant"
  ssh_timeout         = "60m"
  boot_wait           = "5s"
  boot_command = [
    "<enter>",
    "<wait5m>",
    "<enter><wait>",
    "<enter><wait>",
    "${var.step_country}<tab><wait>",
    "${var.step_timezone}<tab><wait>",
    "${var.step_keyboard_layout}<tab><wait>",
    "<tab><wait>",
    "<enter><wait5>",
    "vagrant<tab><wait>",
    "vagrant<tab><wait>",
    "${var.step_email}<tab><wait>",
    "<tab><wait>",
    "<enter><wait5>",
    "${var.step_hostname}<tab><wait>",
    "<tab><wait>",
    "<tab><wait>",
    "<tab><wait>",
    "<tab><wait>",
    "<tab><wait>",
    "<enter><wait5>",
    "<enter><wait5>",
  ]
  shutdown_command = "poweroff"
}

source "qemu" "proxmox-ve-uefi-amd64" {
  accelerator  = "kvm"
  machine_type = "q35"
  efi_boot     = true
  cpus         = var.cpus
  memory       = var.memory
  qemuargs = [
    ["-cpu", "host"],
  ]
  headless            = true
  use_default_display = false
  net_device          = "virtio-net"
  http_directory      = "."
  format              = "qcow2"
  disk_size           = var.disk_size
  disk_interface      = "virtio-scsi"
  disk_cache          = "unsafe"
  disk_discard        = "unmap"
  iso_url             = var.iso_url
  iso_checksum        = var.iso_checksum
  ssh_username        = "root"
  ssh_password        = "vagrant"
  ssh_timeout         = "60m"
  boot_wait           = "10s"
  boot_command = [
    "<enter>",
    "<wait5m>",
    "<enter><wait>",
    "<enter><wait>",
    "${var.step_country}<tab><wait>",
    "${var.step_timezone}<tab><wait>",
    "${var.step_keyboard_layout}<tab><wait>",
    "<tab><wait>",
    "<enter><wait5>",
    "vagrant<tab><wait>",
    "vagrant<tab><wait>",
    "${var.step_email}<tab><wait>",
    "<tab><wait>",
    "<enter><wait5>",
    "${var.step_hostname}<tab><wait>",
    "<tab><wait>",
    "<tab><wait>",
    "<tab><wait>",
    "<tab><wait>",
    "<tab><wait>",
    "<enter><wait5>",
    "<enter><wait5>",
  ]
  shutdown_command = "poweroff"
}

source "proxmox-iso" "proxmox-ve-amd64" {
  template_name            = "template-proxmox-ve"
  template_description     = "See https://github.com/rgl/proxmox-ve"
  tags                     = "proxmox-ve;template"
  insecure_skip_tls_verify = true
  node                     = var.proxmox_node
  machine                  = "q35"
  bios                     = "seabios"
  cpu_type                 = "host"
  cores                    = var.cpus
  memory                   = var.memory
  vga {
    type   = "qxl"
    memory = 16
  }
  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }
  scsi_controller = "virtio-scsi-single"
  disks {
    type         = "scsi"
    io_thread    = true
    ssd          = true
    discard      = true
    disk_size    = "${var.disk_size}M"
    storage_pool = "local-lvm"
  }
  iso_storage_pool = "local"
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  unmount_iso      = true
  os               = "l26"
  ssh_username     = "root"
  ssh_password     = "vagrant"
  ssh_timeout      = "60m"
  http_directory   = "."
  boot_wait        = "30s"
  boot_command = [
    "<enter>",
    "<wait5m>",
    "<enter><wait>",
    "<enter><wait>",
    "${var.step_country}<tab><wait>",
    "${var.step_timezone}<tab><wait>",
    "${var.step_keyboard_layout}<tab><wait>",
    "<tab><wait>",
    "<enter><wait5>",
    "vagrant<tab><wait>",
    "vagrant<tab><wait>",
    "${var.step_email}<tab><wait>",
    "<tab><wait>",
    "<enter><wait5>",
    "${var.step_hostname}<tab><wait>",
    "<tab><wait>",
    "<tab><wait>",
    "<tab><wait>",
    "<tab><wait>",
    "<tab><wait>",
    "<enter><wait5>",
    "<enter><wait5>",
    "<wait4m>",
    "root<enter>",
    "<wait5>",
    "vagrant<enter>",
    "<wait5>",
    "rm -f /etc/apt/sources.list.d/{pve-enterprise,ceph}.list<enter>",
    "apt-get update<enter><wait1m>",
    "apt-get install -y qemu-guest-agent<enter><wait30s>",
    "systemctl start qemu-guest-agent<enter><wait>",
  ]
}

source "proxmox-iso" "proxmox-ve-uefi-amd64" {
  template_name            = "template-proxmox-ve-uefi"
  template_description     = "See https://github.com/rgl/proxmox-ve"
  tags                     = "proxmox-ve-uefi;template"
  insecure_skip_tls_verify = true
  node                     = var.proxmox_node
  machine                  = "q35"
  bios                     = "ovmf"
  efi_config {
    efi_storage_pool = "local-lvm"
  }
  cpu_type = "host"
  cores    = var.cpus
  memory   = var.memory
  vga {
    type   = "qxl"
    memory = 16
  }
  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }
  scsi_controller = "virtio-scsi-single"
  disks {
    type         = "scsi"
    io_thread    = true
    ssd          = true
    discard      = true
    disk_size    = "${var.disk_size}M"
    storage_pool = "local-lvm"
  }
  iso_storage_pool = "local"
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  unmount_iso      = true
  os               = "l26"
  ssh_username     = "root"
  ssh_password     = "vagrant"
  ssh_timeout      = "60m"
  http_directory   = "."
  boot_wait        = "30s"
  boot_command = [
    "<enter>",
    "<wait5m>",
    "<enter><wait>",
    "<enter><wait>",
    "${var.step_country}<tab><wait>",
    "${var.step_timezone}<tab><wait>",
    "${var.step_keyboard_layout}<tab><wait>",
    "<tab><wait>",
    "<enter><wait5>",
    "vagrant<tab><wait>",
    "vagrant<tab><wait>",
    "${var.step_email}<tab><wait>",
    "<tab><wait>",
    "<enter><wait5>",
    "${var.step_hostname}<tab><wait>",
    "<tab><wait>",
    "<tab><wait>",
    "<tab><wait>",
    "<tab><wait>",
    "<tab><wait>",
    "<enter><wait5>",
    "<enter><wait5>",
    "<wait4m>",
    "root<enter>",
    "<wait5>",
    "vagrant<enter>",
    "<wait5>",
    "rm -f /etc/apt/sources.list.d/{pve-enterprise,ceph}.list<enter>",
    "apt-get update<enter><wait1m>",
    "apt-get install -y qemu-guest-agent<enter><wait30s>",
    "systemctl start qemu-guest-agent<enter><wait>",
  ]
}

source "hyperv-iso" "proxmox-ve-amd64" {
  temp_path                        = "tmp"
  headless                         = true
  http_directory                   = "."
  generation                       = 2
  enable_virtualization_extensions = true
  enable_mac_spoofing              = true
  cpus                             = var.cpus
  memory                           = var.memory
  switch_name                      = var.hyperv_switch_name
  vlan_id                          = var.hyperv_vlan_id
  disk_size                        = var.disk_size
  iso_url                          = var.iso_url
  iso_checksum                     = var.iso_checksum
  output_directory                 = "${var.output_base_dir}/output-{{build_name}}"
  ssh_username                     = "root"
  ssh_password                     = "vagrant"
  ssh_timeout                      = "60m"
  first_boot_device                = "DVD"
  boot_order                       = ["SCSI:0:0"]
  boot_wait                        = "5s"
  boot_command = [
    "<enter>",
    "<wait5m>",
    "<enter><wait>",
    "<enter><wait>",
    "${var.step_country}<tab><wait>",
    "${var.step_timezone}<tab><wait>",
    "${var.step_keyboard_layout}<tab><wait>",
    "<tab><wait>",
    "<enter><wait5>",
    "vagrant<tab><wait>",
    "vagrant<tab><wait>",
    "${var.step_email}<tab><wait>",
    "<tab><wait>",
    "<enter><wait5>",
    "${var.step_hostname}<tab><wait>",
    "<tab><wait>",
    "<tab><wait>",
    "<tab><wait>",
    "<tab><wait>",
    "<tab><wait>",
    "<enter><wait5>",
    "<enter><wait5>",
    "<wait4m>",
    "root<enter>",
    "<wait5>",
    "vagrant<enter>",
    "<wait5>",
    "rm -f /etc/apt/sources.list.d/pve-enterprise.list<enter>",
    "apt-get update<enter>",
    "<wait1m>",
    "apt-get install -y hyperv-daemons<enter>",
  ]
  shutdown_command = "poweroff"
}

build {
  sources = [
    "source.qemu.proxmox-ve-amd64",
    "source.qemu.proxmox-ve-uefi-amd64",
    "source.proxmox-iso.proxmox-ve-amd64",
    "source.proxmox-iso.proxmox-ve-uefi-amd64",
    "source.hyperv-iso.proxmox-ve-amd64",
  ]

  provisioner "shell" {
    expect_disconnect = true
    environment_vars = [
      "apt_cache_host=${var.apt_cache_host}",
      "apt_cache_port=${var.apt_cache_port}",
    ]
    scripts = var.shell_provisioner_scripts
  }

  post-processor "vagrant" {
    only = [
      "qemu.proxmox-ve-amd64",
      "hyperv-iso.proxmox-ve-amd64",
    ]
    output               = var.vagrant_box
    vagrantfile_template = "Vagrantfile.template"
  }

  post-processor "vagrant" {
    only = [
      "qemu.proxmox-ve-uefi-amd64",
    ]
    output               = var.vagrant_box
    vagrantfile_template = "Vagrantfile-uefi.template"
  }
}
