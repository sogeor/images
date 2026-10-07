variable "iso_url" {
  type = string
}

variable "iso_checksum" {
  type = string

  validation {
    condition     = can(regex("^sha256:[0-9a-f]{64}$", var.iso_checksum))
    error_message = "Значение iso_checksum должно быть в формате sha256:<hex>."
  }
}

variable "disk_size" {
  type    = string
  default = "10G"
}

variable "ssh_public_key" {
  type = string
}

variable "ssh_private_key_file" {
  type = string
}

variable "apt_mirror" {
  type    = string
  default = "http://archive.ubuntu.com/ubuntu"
}
