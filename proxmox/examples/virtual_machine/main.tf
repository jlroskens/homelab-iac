# Example VM provisoning
# - Downloads a ubuntu-24.04-minimal-cloudimg-amd64.img image to a pve node.
# - Generates a random password for the default ubuntu account
# - Generates a private key and enables the public key for SSH for the ubuntu account
# - Creates outputs in state for the password and ssh keys.
# - Creates a VM using the downloaded ubuntu cloud image

# Download the ubuntu-24.04-minimal-cloudimg-amd64.img image to a pve node and rename it for importing.
# Note: Unless this image is only going to be used for this VM, it is better to have it in it's own manifest
# so it is not tied to any particular VM terraform / tofu.
resource "proxmox_virtual_environment_download_file" "ubuntu_noble" {
  content_type       = "import"
  datastore_id       = "local"
  node_name          = "pve-host-01"
  url                = "https://cloud-images.ubuntu.com/minimal/releases/noble/release/ubuntu-24.04-minimal-cloudimg-amd64.img"
  checksum           = "c9d17b2554832605cdb377ace2117822fb02694e8fb56d82f900ce045c7aae57"
  checksum_algorithm = "sha256"
  file_name          = "ubuntu-24.04-minimal-cloudimg-amd64.qcow2"
}

# Generate a password for the default "ubuntu" account
resource "random_password" "default_account" {
  length           = 16
  override_special = "!#$%&*()-_=+[]{}<>:?"
  special          = true
}

# Generate an ssh key for the default "ubuntu" account
resource "tls_private_key" "default_account" {
  algorithm = "ED25519"
}

# Create the VM on the 
module "example_vm" {
  source      = "github.com/jlroskens/homelab-iac/proxmox/modules/proxmox_virtual_machine?ref=v0"
  vm_name     = "vm-example-ubuntu-nobel"
  vm_id       = 1001
  node_name   = "pve-host-01"
  description = "Example Ubuntu Noble VM with generated password and ssh key."

  # Needs to be false unless the image has the qemu agent installed and enabled (it doesn't)
  # Otherwise, this will timeout on creation.
  qemu_agent_enabled = true
  # Boot / reboot settings
  start_on_host_boot    = true
  reboot_after_creation = false
  reboot_after_update   = true

  disks = [
    {
      interface    = "virtio0"
      datastore_id = "local-lvm"
      size         = 32
      import_from  = proxmox_virtual_environment_download_file.ubuntu_noble.id
    }
  ]

  memory = {
    dedicated_mb      = 2048
    balooning_enabled = true
  }

  efi_disk = {
    datastore_id = "local-lvm"
  }

  network_devices = [
    {
      bridge = "vmbr0"
    }
  ]
  cloud_init = {
    datastore_id = "local-lvm"
    interface    = "scsi1"
    ip_config = [{
      ipv4 = {
        address = "dhcp"
      }
    }]
    user_account = {
      keys     = [trimspace(tls_private_key.default_account.public_key_openssh)]
      password = random_password.default_account.result
      username = "ubuntu"
    }
  }
}

output "default_account_password" {
  value     = random_password.default_account.result
  sensitive = true
}

output "default_account_private_key" {
  value     = tls_private_key.default_account.private_key_openssh
  sensitive = true
}

output "default_account_public_key" {
  value = tls_private_key.default_account.public_key_openssh
}