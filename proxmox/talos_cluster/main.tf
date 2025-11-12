data "proxmox_virtual_environment_file" "iso" {
  node_name    = var.iso_node_name
  datastore_id = var.iso_datastore_id
  content_type = var.iso_content_type
  file_name    = var.iso_file_name
}

module "control_plane_vms" {
  for_each    = { for vm in var.control_plane_vms : vm.vm_id => vm }
  source      = "github.com/rNimbus-com/homelab-iac/proxmox/modules/proxmox_virtual_machine?ref=v0"
  vm_name     = each.value.vm_name
  vm_id       = each.value.vm_id
  node_name   = each.value.node_name
  description = each.value.description

  # QEMU Agent can be set to true because the vendor config will install and start it.
  qemu_agent_enabled = true
  # Boot / reboot settings
  start_on_host_boot    = true
  reboot_after_creation = false
  reboot_after_update   = false

  cpu = {
    type      = "host"
    cores     = var.cpu_cores
    cpu_units = 900
  }

  # Boot from virtio0 disk then CD-ROM
  boot_order = ["virtio0", "ide0"]
  # boot_order = [ "virtio0" ]
  disks = [
    {
      interface    = "virtio0"
      datastore_id = "local-cluster-zfs"
      size         = 100
    }
  ]

  cdrom = {
    file_id   = data.proxmox_virtual_environment_file.iso.id
    interface = "ide0"
  }

  memory = {
    dedicated_mb      = var.memory_mb
    balooning_enabled = true
  }

  efi_disk = {
    datastore_id = "local-cluster-zfs"
  }

  network_devices = [
    {
      bridge = "vmbr0"
    },
    {
      bridge = "vmbr1"
    }
  ]
  cloud_init = {
    datastore_id = "local-cluster-zfs"
    interface    = "scsi1"
    ip_config    = each.value.cloud_init_ip_config
  }
}

module "worker_vms" {
  for_each = { for vm in var.worker_vms : vm.vm_id => vm }
  source   = "github.com/rNimbus-com/homelab-iac/proxmox/modules/proxmox_virtual_machine?ref=v0"
  # source      = "../../proxmox/modules/proxmox_virtual_machine"
  vm_name     = each.value.vm_name
  vm_id       = each.value.vm_id
  node_name   = each.value.node_name
  description = each.value.description

  # QEMU Agent can be set to true because the vendor config will install and start it.
  qemu_agent_enabled = true
  # Boot / reboot settings
  start_on_host_boot    = true
  reboot_after_creation = false
  reboot_after_update   = false

  cpu = {
    type      = "host"
    cores     = var.cpu_cores
    cpu_units = 800
  }

  # Boot from virtio0 disk then CD-ROM
  boot_order = ["virtio0", "ide0"]
  # boot_order = [ "virtio0" ]
  disks = [
    {
      interface    = "virtio0"
      datastore_id = "local-cluster-zfs"
      size         = 100
    }
  ]

  cdrom = {
    file_id   = data.proxmox_virtual_environment_file.iso.id
    interface = "ide0"
  }

  memory = {
    dedicated_mb      = var.memory_mb
    balooning_enabled = true
  }

  efi_disk = {
    datastore_id = "local-cluster-zfs"
  }

  network_devices = [
    {
      bridge = "vmbr0"
    },
    {
      bridge = "vmbr1"
    }
  ]
  cloud_init = {
    datastore_id = "local-cluster-zfs"
    interface    = "scsi1"
    ip_config    = each.value.cloud_init_ip_config
  }
}