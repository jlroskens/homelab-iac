terraform {
  required_version = "~> 1.6"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.86"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.7"
    }
  }
}