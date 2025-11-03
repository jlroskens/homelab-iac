resource "proxmox_virtual_environment_download_file" "ubuntu_noble" {
  content_type       = "import"
  datastore_id       = "shared-vz"
  node_name          = "pve-host-01"
  url                = "https://cloud-images.ubuntu.com/minimal/releases/noble/release/ubuntu-24.04-minimal-cloudimg-amd64.img"
  checksum           = "c9d17b2554832605cdb377ace2117822fb02694e8fb56d82f900ce045c7aae57"
  checksum_algorithm = "sha256"
  file_name          = "ubuntu-24.04-minimal-cloudimg-amd64.qcow2"
}

module "example_cloud_init_vm" {
  source      = "github.com/jlroskens/homelab-iac/proxmox/modules/proxmox_virtual_machine?ref=v1"
  vm_name     = "vm-example-ubuntu-noble-cloudinit"
  vm_id       = 1002
  node_name   = "pve-host-01"
  description = "Example Ubuntu Noble VM provisioned with cloud-init vendor and user data files."

  # QEMU Agent can be set to true because the vendor config will install and start it.
  qemu_agent_enabled = true
  # Boot / reboot settings
  start_on_host_boot    = true
  reboot_after_creation = false
  reboot_after_update   = true

  disks = [
    {
      interface    = "virtio0"
      datastore_id = "local-lvm"
      size         = 32 # 32 GB
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
    vendor_data_file_id = proxmox_virtual_environment_file.vendor.id
    user_data_file_id   = proxmox_virtual_environment_file.user_data.id
  }
}