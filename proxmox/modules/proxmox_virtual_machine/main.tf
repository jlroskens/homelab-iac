resource "proxmox_virtual_environment_vm" "this" {
  name        = var.vm_name
  vm_id       = var.vm_id
  node_name   = var.node_name
  description = "${var.description} :- Managed by OpenTofu"
  tags        = sort(var.tags)
  # One off flags / settings
  protection      = var.protection
  pool_id         = var.pool_id
  scsi_hardware   = var.scsi_hardware
  template        = var.create_template
  keyboard_layout = var.keyboard_layout

  # QEMU Agent settings
  agent {
    enabled = var.qemu_agent_enabled
    timeout = var.qemu_agent_timeout
    trim    = var.qemu_agent_trim
    type    = var.qemu_agent_type
  }

  operating_system {
    type = var.operating_system_type
  }

  ## Startup, shutdown, creating, etc
  # Timeouts for creating, starting, rebooting, stopping, etc
  timeout_clone       = var.operation_timeouts.clone
  timeout_create      = var.operation_timeouts.create
  timeout_migrate     = var.operation_timeouts.migrate
  timeout_start_vm    = var.operation_timeouts.start
  timeout_reboot      = var.operation_timeouts.reboot
  timeout_shutdown_vm = var.operation_timeouts.shutdown
  timeout_stop_vm     = var.operation_timeouts.stop
  # When true, force stop instead of waiting for shutdown.
  stop_on_destroy = true
  # Startup order and delays 
  dynamic "startup" {
    for_each = (var.startup_order != null && var.startup_order > 0) || (var.next_vm_startup_delay != null && var.next_vm_startup_delay > 0) || (var.next_vm_shutdown_delay != null && var.next_vm_shutdown_delay > 0) ? [1] : []
    content {
      order      = var.startup_order == var.startup_order
      up_delay   = var.next_vm_startup_delay == var.next_vm_startup_delay
      down_delay = var.next_vm_shutdown_delay == var.next_vm_shutdown_delay
    }
  }
  # startup {
  #   order      = var.startup_order == null ? -1 : var.startup_order
  #   up_delay   = var.next_vm_startup_delay == null ? -1 : var.next_vm_startup_delay
  #   down_delay = var.next_vm_shutdown_delay == null ? -1 : var.next_vm_shutdown_delay
  # }
  # Boot / reboot settings
  on_boot             = var.start_on_host_boot
  reboot              = var.reboot_after_creation
  reboot_after_update = var.reboot_after_update
  # Custom args to send to the kvm
  kvm_arguments = var.kvm_args
  # Bios, CPU and Memory Configuration
  acpi    = var.acpi
  bios    = var.bios
  machine = var.machine

  cpu {
    # Requires root
    architecture = var.cpu.architecture
    sockets      = var.cpu.sockets
    cores        = var.cpu.cores
    type         = var.cpu.type
    hotplugged   = var.cpu.hotplugged_vcpus
    limit        = var.cpu.cpu_limit
    units        = var.cpu.cpu_units
    flags        = length(var.cpu.flags) > 0 ? var.cpu.flags : null
  }

  memory {
    dedicated = var.memory.dedicated_mb
    # Ballooning requries dedicated and floating memory to match, so if set use dedicated_mb value.
    floating = var.memory.ballooning_enabled ? var.memory.dedicated_mb : var.memory.floating_mb
  }

  # Disk configuration
  boot_order = var.boot_order
  
  dynamic "disk" {
    for_each = { for disk in var.disks : disk.interface => disk }
    content {
      aio               = disk.value.aio
      backup            = disk.value.backup
      cache             = disk.value.cache
      datastore_id      = disk.value.datastore_id
      path_in_datastore = disk.value.path_in_datastore
      discard           = disk.value.discard
      file_format       = disk.value.file_format
      import_from       = disk.value.import_from
      interface         = disk.value.interface
      iothread          = disk.value.iothread
      replicate         = disk.value.replicate
      serial            = disk.value.serial
      size              = disk.value.size
      ssd               = disk.value.ssd

      dynamic "speed" {
        for_each = disk.value.speed == null ? [] : [1]
        content {
          iops_read            = disk.value.speed.iops_read
          iops_read_burstable  = disk.value.speed.iops_read_burstable
          iops_write           = disk.value.speed.iops_write
          iops_write_burstable = disk.value.speed.iops_write_burstable
          read                 = disk.value.speed.read
          read_burstable       = disk.value.speed.read_burstable
          write                = disk.value.speed.write
          write_burstable      = disk.value.speed.write_burstable
        }
      }
    }
  }

  dynamic "cdrom" {
    for_each = var.cdrom == null ? [] : [1]
    content {
      file_id   = var.cdrom.file_id
      interface = var.cdrom.interface
    }
  }

  dynamic "efi_disk" {
    for_each = var.efi_disk == null ? [] : [1]
    content {
      datastore_id      = var.efi_disk.datastore_id
      file_format       = var.efi_disk.file_format
      type              = var.efi_disk.type
      pre_enrolled_keys = var.efi_disk.pre_enrolled_keys
    }
  }

  # Share between host and guest
  dynamic "virtiofs" {
    for_each = var.virtiofs == null ? [] : [1]
    content {
      mapping      = var.virtiofs.mapping
      cache        = var.virtiofs.cache
      direct_io    = var.virtiofs.direct_io
      expose_acl   = var.virtiofs.expose_acl
      expose_xattr = var.virtiofs.expose_xattr
    }
  }

  # --- Dynamic network devices ---
  dynamic "network_device" {
    for_each = { for device in var.network_devices : device.bridge => device }
    content {
      bridge       = network_device.value.bridge
      model        = network_device.value.model
      mac_address  = network_device.value.mac_address
      mtu          = network_device.value.mtu
      queues       = network_device.value.queues
      rate_limit   = network_device.value.rate_limit
      vlan_id      = network_device.value.vlan_id
      trunks       = network_device.value.trunks
      firewall     = network_device.value.firewall
      enabled      = network_device.value.enabled
      disconnected = network_device.value.disconnected
    }
  }

  # Device Configuration (Display, TPM, PCI, USB)

  dynamic "serial_device" {
    for_each = { for d in var.serial_devices : d.device => d }
    content {
      device = serial_device.value.device
    }
  }

  dynamic "vga" {
    for_each = var.vga == null ? [] : [1]
    content {
      memory = var.vga.memory_mb
      type   = var.vga.type
    }
  }

  dynamic "tpm_state" {
    for_each = var.tpm_state == null ? [] : [1]
    content {
      datastore_id = var.tpm_state.datastore_id
      version      = var.tpm_state.version
    }
  }

  dynamic "hostpci" {
    for_each = { for device in var.hostpci : device.device => device }
    content {
      device   = each.value.device
      mapping  = each.value.mapping
      mdev     = each.value.mdev
      pcie     = each.value.pcie
      rombar   = each.value.rombar
      rom_file = each.value.rom_file
      xvga     = each.value.xvga
    }
  }

  dynamic "usb" {
    for_each = { for device in var.usb : coalesce(device.host, device.mapping) => device }
    content {
      host    = each.value.host
      mapping = each.value.mapping
      usb3    = each.value.usb3
    }
  }

  # Cloud-Init
  dynamic "initialization" {
    for_each = var.cloud_init != null ? [var.cloud_init] : []
    content {
      datastore_id = initialization.value.datastore_id
      interface    = initialization.value.interface

      # --- DNS Configuration ---
      dynamic "dns" {
        for_each = initialization.value.dns != null ? [initialization.value.dns] : []
        content {
          domain  = dns.value.domain
          servers = dns.value.servers
        }
      }

      # --- IP Configuration (Multiple Blocks Supported) ---
      dynamic "ip_config" {
        for_each = initialization.value.ip_config != null ? initialization.value.ip_config : []
        content {
          dynamic "ipv4" {
            for_each = ip_config.value.ipv4 != null ? [ip_config.value.ipv4] : []
            content {
              address = ipv4.value.address
              gateway = ipv4.value.gateway
            }
          }

          dynamic "ipv6" {
            for_each = ip_config.value.ipv6 != null ? [ip_config.value.ipv6] : []
            content {
              address = ipv6.value.address
              gateway = ipv6.value.gateway
            }
          }
        }
      }

      # --- User Account Configuration ---
      dynamic "user_account" {
        for_each = initialization.value.user_account != null ? [initialization.value.user_account] : []
        content {
          username = user_account.value.username
          password = user_account.value.password
          keys     = user_account.value.keys
        }
      }

      # --- Optional Cloud-Init File IDs ---
      network_data_file_id = initialization.value.network_data_file_id
      user_data_file_id    = initialization.value.user_data_file_id
      vendor_data_file_id  = initialization.value.vendor_data_file_id
      meta_data_file_id    = initialization.value.meta_data_file_id
    }
  }



  lifecycle {
    # The AMI ID must refer to an AMI that contains an operating system
    # for the `x86_64` architecture.
    precondition {
      condition     = lower(var.bios) == "seabios" || var.efi_disk != null
      error_message = "Bios type of `ovmf` requires an efi_disk to be configured."
    }
  }
}