terraform {
  required_version = "~> 1.6"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.86"
    }
  }
}

provider "proxmox" {
  endpoint = "https://pve-host-01.local.example.com:8006"
  insecure = true
  # This example requires SSH configured. Either
  # uncomment the below section and configure your username 
  # and key or set the PROXMOX_VE_SSH_USERNAME and PROXMOX_VE_SSH_PRIVATE_KEY exports.
  # ssh {
  #   agent       = false
  #   username    = "root"
  #   private_key = file("~/.ssh/pveroot")
  # }
}
