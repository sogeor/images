packer {
  required_version = "= 1.16.1"

  required_plugins {
    proxmox = {
      version = "= 1.2.4"
      source  = "github.com/hashicorp/proxmox"
    }
    ansible = {
      version = "= 1.1.6"
      source  = "github.com/hashicorp/ansible"
    }
  }
}
