packer {
  required_plugins {
    # see https://github.com/hashicorp/packer-plugin-vsphere
    vsphere = {
      version = "1.2.6"
      source  = "github.com/hashicorp/vsphere"
    }
  }
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

variable "vsphere_os_iso" {
  type    = string
  default = env("VSPHERE_OS_ISO")
}

variable "vsphere_host" {
  type    = string
  default = env("GOVC_HOST")
}

variable "vsphere_username" {
  type    = string
  default = env("GOVC_USERNAME")
}

variable "vsphere_password" {
  type    = string
  default = env("GOVC_PASSWORD")
}

variable "vsphere_esxi_host" {
  type    = string
  default = env("VSPHERE_ESXI_HOST")
}

variable "vsphere_datacenter" {
  type    = string
  default = env("GOVC_DATACENTER")
}

variable "vsphere_cluster" {
  type    = string
  default = env("GOVC_CLUSTER")
}

variable "vsphere_datastore" {
  type    = string
  default = env("GOVC_DATASTORE")
}

variable "vsphere_folder" {
  type    = string
  default = env("VSPHERE_TEMPLATE_FOLDER")
}

variable "vsphere_network" {
  type    = string
  default = env("VSPHERE_VLAN")
}

variable "vsphere_ip_wait_address" {
  type    = string
  default = env("VSPHERE_IP_WAIT_ADDRESS")
}

variable "apt_cache_host" {
  type    = string
  default = env("APT_CACHE_HOST")
}

variable "apt_cache_port" {
  type    = string
  default = env("APT_CACHE_PORT")
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

source "vsphere-iso" "proxmox-ve-amd64" {
  vm_name        = "proxmox-ve-amd64"
  http_directory = "."
  guest_os_type  = "debian12_64Guest"
  NestedHV       = true
  CPUs           = var.cpus
  RAM            = var.memory
  storage {
    disk_size             = var.disk_size
    disk_thin_provisioned = true
  }
  disk_controller_type = ["pvscsi"]
  iso_paths = [
    var.vsphere_os_iso,
  ]
  vcenter_server      = var.vsphere_host
  username            = var.vsphere_username
  password            = var.vsphere_password
  insecure_connection = true
  datacenter          = var.vsphere_datacenter
  cluster             = var.vsphere_cluster
  host                = var.vsphere_esxi_host
  folder              = var.vsphere_folder
  datastore           = var.vsphere_datastore
  network_adapters {
    network      = var.vsphere_network
    network_card = "vmxnet3"
  }
  convert_to_template = true
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
    "<wait10m>",
    "root<enter>vagrant<enter><wait5s>",
    "apt-get update<enter><wait15s>",
    "apt-get install -y open-vm-tools<enter><wait1m>",
    "exit<enter>",
  ]
  shutdown_command = "poweroff"
}

build {
  sources = [
    "source.vsphere-iso.proxmox-ve-amd64",
  ]

  provisioner "shell" {
    expect_disconnect = true
    environment_vars = [
      "apt_cache_host=${var.apt_cache_host}",
      "apt_cache_port=${var.apt_cache_port}",
    ]
    scripts = var.shell_provisioner_scripts
  }
}
