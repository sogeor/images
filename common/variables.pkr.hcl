# PROXMOX_URL, PROXMOX_USERNAME, PROXMOX_TOKEN

variable "repo_root" {
  type        = string
  description = "Корень репозитория."
}

variable "build_version" {
  type        = string
  description = "Версия сборки."

  validation {
    condition     = can(regex("^[0-9A-Za-z.-]+$", var.build_version))
    error_message = "Значение build_version может содержать только латиницу, цифры, точку и дефис."
  }
}

variable "git_sha" {
  type    = string
  default = "local"
}

variable "proxmox_node" {
  type    = string
  default = "pve"
}

variable "proxmox_insecure_skip_tls_verify" {
  type    = bool
  default = false
}

variable "vm_id" {
  type    = number
  default = 0
}

variable "storage_pool" {
  type    = string
  default = "local-lvm"
}

variable "iso_storage_pool" {
  type    = string
  default = "local"
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "build_ip_cidr" {
  type        = string
  description = "192.168.100.250-254"

  validation {
    condition     = can(cidrhost(var.build_ip_cidr, 0))
    error_message = "Значение build_ip_cidr должно быть адресом в формате CIDR."
  }
}

variable "build_gateway" {
  type    = string
  default = "192.168.100.1"
}

variable "build_nameservers" {
  type    = list(string)
  default = ["1.1.1.1", "9.9.9.9"]
}

variable "ssh_username" {
  type    = string
  default = "packer"
}

variable "ssh_host" {
  type    = string
  default = ""
}

variable "ssh_port" {
  type    = number
  default = 22
}

locals {
  build_ip = split("/", var.build_ip_cidr)[0]
  ssh_host = var.ssh_host != "" ? var.ssh_host : local.build_ip
}
