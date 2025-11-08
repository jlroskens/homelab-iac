terraform {
  required_version = "~> 1.6"
  backend "local" {
    path = var.terraform_state_path
  }
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.86"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.9"
    }
    # kubernetes = {
    #   source  = "hashicorp/kubernetes"
    #   version = "~> 2.28"
    # }
    corefunc = {
      source  = "northwood-labs/corefunc"
      version = "~> 2.1"
    }
  }
}

provider "proxmox" {
  endpoint = var.pve_endpoint
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

provider "talos" {}
provider "corefunc" {}