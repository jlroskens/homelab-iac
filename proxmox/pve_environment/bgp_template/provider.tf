terraform {
  required_version = "~> 1.6"
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "~> 0.86"
    }
  }
}

provider "proxmox" {
# Environment variables are used from CI/CD runner.

# Environment Variable              Description                   Required
# PROXMOX_VE_ENDPOINT	              API endpoint URL	            Yes
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
}

# Options for manually configuring a provider

# provider "proxmox" {
#   endpoint  = var.proxmox_endpoint
#   api_token = "terraform@pve!provider=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
# }

# provider "proxmox" {
#   endpoint = "https://10.0.0.2:8006/"
#   insecure = true
#   username = "username@realm"
#   password = "a-strong-password"
# }