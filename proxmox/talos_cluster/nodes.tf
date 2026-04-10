data "proxmox_virtual_environment_file" "iso" {
  node_name    = var.iso_node_name
  datastore_id = var.iso_datastore_id
  content_type = var.iso_content_type
  file_name    = var.iso_file_name
}

resource "proxmox_virtual_environment_file" "nodes_metadata" {
  for_each     = local.all_vms_map
  node_name    = each.value.node_name
  content_type = "snippets"
  datastore_id = var.iso_datastore_id

  source_raw {
    data = yamlencode({
      hostname   = each.value.vm_name
      id         = each.key
      providerID = "proxmox://${var.talos_cluster.region}/${each.key}"
      type       = "${each.value.cpu_cores}VCPU-${floor(each.value.memory_mb / 1024)}GB"
      zone       = each.value.node_name
      region     = var.talos_cluster.region
    })
    file_name = "${each.key}.metadata.yaml"
  }
}

module "control_plane_vms" {
  for_each = { for vm in var.control_plane_vms : vm.vm_id => vm }
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

  smbios = {
    serial = "h=${each.value.vm_name};i=${each.value.vm_id}"
  }

  cpu = {
    type      = "host"
    cores     = each.value.cpu_cores
    cpu_units = 900
  }

  startup_order         = 1
  next_vm_startup_delay = 60

  # Boot from virtio0 disk then CD-ROM
  boot_order = ["virtio0", "ide0"]
  # boot_order = [ "virtio0" ]
  disks = [
    {
      interface    = "virtio0"
      datastore_id = "local-cluster-zfs"
      size         = 100
      datastore_id = each.value.datastore_id
      size         = each.value.disk_size
    }
  ]

  cdrom = {
    file_id   = data.proxmox_virtual_environment_file.iso.id
    interface = "ide0"
  }

  memory = {
    dedicated_mb       = each.value.memory_mb
    ballooning_enabled = true
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

  hostpci = each.value.hostpci

  cloud_init = {
    datastore_id      = "local-cluster-zfs"
    interface         = "scsi1"
    ip_config         = each.value.cloud_init_ip_config
    meta_data_file_id = proxmox_virtual_environment_file.nodes_metadata[each.value.vm_id].id
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

  smbios = {
    serial = "h=${each.value.vm_name};i=${each.value.vm_id}"
  }

  cpu = {
    type      = "host"
    cores     = each.value.cpu_cores
    cpu_units = 800
  }

  # Boot from virtio0 disk then CD-ROM
  boot_order = ["virtio0", "ide0"]
  # boot_order = [ "virtio0" ]
  disks = [
    {
      interface    = "virtio0"
      datastore_id = each.value.datastore_id
      size         = each.value.disk_size
    }
  ]

  hostpci = each.value.hostpci

  cdrom = {
    file_id   = data.proxmox_virtual_environment_file.iso.id
    interface = "ide0"
  }

  memory = {
    dedicated_mb       = each.value.memory_mb
    ballooning_enabled = true
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
    datastore_id      = "local-cluster-zfs"
    interface         = "scsi1"
    ip_config         = each.value.cloud_init_ip_config
    meta_data_file_id = proxmox_virtual_environment_file.nodes_metadata[each.value.vm_id].id
  }
}