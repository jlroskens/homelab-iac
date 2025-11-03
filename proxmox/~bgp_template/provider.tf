terraform {
  required_version = "~> 1.6"
  # Use NFS mounted /mnt/iac-state/.terraform/ directory for state files
  # Requires NFS mount be configured ahead of time
  backend "local" {
    # Uncomment and update name if you're using a mount for keeping state files
    # path = "/mnt/iac-state/.terraform/change_this_or_risk_losing_state_with_next_manifest.tfstate"
  }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.86"
    }
  }
}

provider "proxmox" {
  # Set endpoint with a var since environment templates often target specific PVE Hosts.
  endpoint = var.pve_endpoint
  # Use Environment variables to configure auth.
  # Environment Variable              Description                   Required
  # PROXMOX_VE_USERNAME	              Username with realm	          Yes*
  # PROXMOX_VE_PASSWORD	              User password	                Yes*
  # PROXMOX_VE_API_TOKEN	            API token	                    Yes*
  # PROXMOX_VE_AUTH_TICKET	          Auth ticket	                  Yes*
  # PROXMOX_VE_CSRF_PREVENTION_TOKEN	CSRF prevention token	        Yes*
  # PROXMOX_VE_INSECURE	              Skip TLS verification	        No
  # PROXMOX_VE_SSH_USERNAME	          SSH username	                No
  # PROXMOX_VE_SSH_PASSWORD	          SSH password	                No
  # PROXMOX_VE_SSH_PRIVATE_KEY	      SSH private key	              No
  # PROXMOX_VE_TMPDIR	                Custom temporary directory	  No
  # *One of these authentication methods is required
  # Source: https://search.opentofu.org/provider/bpg/proxmox/latest#environment-variables-summary

  # Sometimes SSH required depending on the resource
  # ssh {
  #   agent       = false
  #   username    = "root"
  #   private_key = file("~/.ssh/pveroot")
  # }
}