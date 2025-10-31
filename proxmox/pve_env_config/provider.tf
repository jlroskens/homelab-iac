terraform {
  required_version = "~> 1.6"
  # Use NFS mounted /mnt/iac-state/.terraform/ directory for state files
  # Requires NFS mount be configured ahead of time
  backend "local" {
    path = "/mnt/iac-state/.terraform/pve_environment.tfstate"
  }

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

provider "proxmox" {
  endpoint = var.pve_endpoint
  insecure = true
  # ssh {
  #   agent       = false
  #   username    = "root"
  #   private_key = file("~/.ssh/pveroot")
  # }
}