variable "vm_id" {
  type        = number
  description = "Unique ID of the Virtual Machine."
  validation {
    condition     = var.vm_id >= 100 && var.vm_id <= 999999999
    error_message = "VM ID must be a value between 100 and 999,999,999."
  }
}

variable "vm_name" {
  type        = string
  description = "The name of the Virtual Machine."
}

variable "node_name" {
  type        = string
  description = "The name of the node to assign the virtual machine to."
}

variable "qemu_agent_enabled" {
  type        = bool
  description = "Enables the QEMU agent."
  default     = false
}

variable "qemu_agent_timeout" {
  type        = string
  description = <<-EOT
                    The maximum amount of time to wait for data from the QEMU agent to become available. Value 
                    is a signed sequence of decimal numbers, each with optional fraction and a unit suffix, 
                    such as "300ms", "-1.5h" or "2h45m". Valid time units are "ns", "us" (or "µs"), "ms", "s", "m", "h"."
                  EOT
  default     = "15m"
}

variable "qemu_agent_trim" {
  type        = bool
  description = "Enables the FSTRIM feature in the QEMU agent."
  default     = false
}

variable "qemu_agent_type" {
  type        = string
  description = "The QEMU agent interface type, `virtio` or `isa`."
  default     = "virtio"
  validation {
    condition     = contains(["virtio", "isa"], lower(var.qemu_agent_type))
    error_message = "Invalid value for qemu_agent_type. Valid values are `virtio` or `isa`."
  }
}

variable "operating_system_type" {
  description = <<-EOT
  (Optional) The Operating System type for the VM. Defaults to "l26" (Linux Kernel 2.6 - 5.X).

  Supported types:
    - l24     : Linux Kernel 2.4
    - l26     : Linux Kernel 2.6 - 5.X
    - other   : Unspecified OS
    - solaris : OpenIndiana, OpenSolaris, or Solaris Kernel
    - w2k     : Windows 2000
    - w2k3    : Windows 2003
    - w2k8    : Windows 2008
    - win7    : Windows 7
    - win8    : Windows 8, 2012 or 2012 R2
    - win10   : Windows 10 or 2016
    - win11   : Windows 11
    - wvista  : Windows Vista
    - wxp     : Windows XP
  EOT

  type    = string
  default = "l26"

  # Validation: ensure type is one of the allowed OS types
  validation {
    condition = var.operating_system_type == null || contains([
      "l24", "l26", "other", "solaris",
      "w2k", "w2k3", "w2k8",
      "win7", "win8", "win10", "win11",
      "wvista", "wxp"
    ], lower(var.operating_system_type))
    error_message = "Invalid operating_system_type. Must be one of: l24, l26, other, solaris, w2k, w2k3, w2k8, win7, win8, win10, win11, wvista, wxp."
  }
}


variable "acpi" {
  type        = bool
  description = "Enable/disable ACPI."
  default     = true
}

variable "bios" {
  type        = string
  description = "BIOS implementation of `ovmf` OVMF (UEFI) or `seabios` SeaBIOS."
  default     = "ovmf"
  validation {
    condition     = contains(["ovmf", "seabios"], lower(var.bios))
    error_message = "Invalid value for `bios`. Valid values are `ovmf` and `seabios`."
  }
}

variable "machine" {
  description = <<-EOT
  (Optional) The VM machine type. Defaults to "q35".

  Supported types:
    - pc    : Standard PC (i440FX + PIIX, 1996)
    - q35   : Standard PC (Q35 + ICH9, 2009). Optionally, you can enable VIOMMU by adding viommu=virtio|intel
             to the value, e.g., "q35,viommu=virtio".
  EOT

  type    = string
  default = "q35"

  validation {
    condition     = can(regex("^(pc|q35)(,viommu=(virtio|intel))?$", var.machine))
    error_message = "Invalid machine type. Must be 'pc' or 'q35'. Optional VIOMMU can be set as ',viommu=virtio' or ',viommu=intel'."
  }
}


variable "cpu" {
  type = object({
    architecture     = optional(string, null)
    type             = optional(string, "x86-64-v2-AES")
    sockets          = optional(number, 1)
    cores            = optional(number, 1)
    hotplugged_vcpus = optional(number, 0)
    cpu_limit        = optional(number, 0)
    cpu_units        = optional(number, 1024)
    flags            = optional(list(string), [])
  })
  description = <<-EOT
                    CPU configuration for the Virtual Machine. All values are optional.

                    architecture - CPU architecture: "aarch64" or "x86_64". Proxmox defaults to "x86_64". 
                     Note: Requires root. Leave this set to null unless you need to change it. 
                    sockets - The number of CPU sockets. Defaults to 1.
                    cores - The number of CPU cores. Defaults to 1.
                    hotplugged_vcpus - Number of hotplugged vcpus. Defaults to 0.
                    cpu_limit - Limit of CPU usage. Defaults to 0 (no limit). NOTE: If the computer has 2 CPUs, it has total of '2' CPU time. Value '0' indicates no CPU limit.
                    cpu_units - CPU weight for a VM. Argument is used in the kernel fair scheduler. The larger the number is, the more CPU time this VM gets. Number is relative to weights of all the other running VMs. Defaults to 1024.
                    flags - List of flags (+/-) to set for the CPU. See [Proxmox cpu-models.conf](https://pve.proxmox.com/wiki/Manual:_cpu-models.conf) and the [Proxmox VE Administration Guide](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#_cpu_type).
                  EOT
  default     = {}
  validation {
    condition     = var.cpu != null
    error_message = "`null` is not a valid value for `cpu`. If cpu customization is not desired, then set it to `{}` or leave it out of your variable configuration."
  }
  validation {
    condition     = var.cpu.architecture == null || contains(["aarch64", "x86_64"], lower(var.cpu.architecture))
    error_message = "Invalid value for `cpu.architecture`. Valid values are `aarch64`, `x86_64` and null."
  }
  validation {
    condition     = var.cpu.type != null
    error_message = "`null` is not a valid value for `cpu.type`. If cpu.type customization is not desired, then leave it out of your variable configuration."
  }
  validation {
    condition     = var.cpu.sockets > 0
    error_message = "`cpu.sockets` must be a value greater than 0."
  }
  validation {
    condition     = var.cpu.cores > 0
    error_message = "`cpu.cores` must be a value greater than 0."
  }
  validation {
    condition     = var.cpu.hotplugged_vcpus >= 0
    error_message = "`cpu.hotplugged_vcpus` must be a value equal to or greater than 0."
  }
  validation {
    condition     = var.cpu.cpu_limit >= 0
    error_message = "`cpu.cpu_limit` must be a value equal to or greater than 0."
  }
  validation {
    condition     = var.cpu.cpu_units > 0
    error_message = "`cpu.cpu_units` must be a value greater than 0."
  }
  validation {
    condition     = var.cpu.flags != null
    error_message = "`null` is not a valid value for `cpu.flags`. If cpu.flags customization is not desired, then leave it out of your variable configuration."
  }
}

variable "memory" {
  type = object({
    dedicated_mb       = optional(number, 512)
    floating_mb        = optional(number, 512)
    ballooning_enabled = optional(bool, true)
  })
  description = <<-EOT
                    Memory configuration for the Virtual Machine. All values are optional.

                    dedicated_mb - The dedicated memory in megabytes. Defaults to 512.
                    
                    floating_mb - The floating memory in megabytes. Defaults to 512. Setting `ballooning=true` will override whatever value is set to match the `dedicated_mb` value.
                    
                    ballooning_enabled - Allows VMs to dynamically change their memory usage by evicting unused memory during run time. Defaults to true. Setting this value to true will cause force the `floating_mb` value to match `dedicated_mb`.
                  EOT
  default     = {}
  validation {
    condition     = var.memory != null
    error_message = "`null` is not a valid value for `memory`. If memory customization is not desired, then set it to `{}` or leave it out of your variable configuration."
  }
  validation {
    condition     = var.memory.dedicated_mb > 0
    error_message = "`cpu.dedicated_mb` must be a value greater than 0."
  }
  validation {
    condition     = var.memory.floating_mb > 0 || var.memory.ballooning == true
    error_message = "`cpu.floating_mb` must be a value greater than 0 when ballooning is disabled."
  }
}

variable "operation_timeouts" {
  type = object({
    clone    = optional(number, 1800)
    create   = optional(number, 1800)
    migrate  = optional(number, 1800)
    start    = optional(number, 1800)
    reboot   = optional(number, 1800)
    shutdown = optional(number, 1800)
    stop     = optional(number, 300)
  })
  description = <<-EOT
                    Timeouts for various VM operations.

                    clone - (Optional) Timeout for cloning a VM in seconds (defaults to 1800).
                    create - (Optional) Timeout for creating a VM in seconds (defaults to 1800).
                    migrate - (Optional) Timeout for migrating the VM (defaults to 1800).
                    start - (Optional) Timeout for rebooting a VM in seconds (defaults to 1800).
                    reboot - (Optional) Timeout for shutting down a VM in seconds ( defaults to 1800).
                    shutdown - (Optional) Timeout for starting a VM in seconds (defaults to 1800).
                    stop - (Optional) Timeout for stopping a VM in seconds (defaults to 300).
                  EOT
  default     = {}
  validation {
    condition     = var.operation_timeouts != null
    error_message = "`null` is not a valid value for operation_timeouts. If timeout customization is not desired, then set it to `{}` or leave it out of your variable configuration."
  }
}

variable "startup_order" {
  type        = number
  description = "A non-negative number defining the general startup order. Shutdown in done with reverse ordering."
  validation {
    condition     = var.startup_order > 0 || var.startup_order == null
    error_message = "Non-null values must be a value greater than 0."
  }
  default = null
}

variable "start_on_host_boot" {
  type        = bool
  description = "(Optional) Specifies whether a VM will be started during system boot. (defaults to true)."
  default     = true
}

variable "next_vm_startup_delay" {
  type        = number
  description = "Specifies a delay to wait before the next VM is started. Requires `startup_order` to be set."
  validation {
    condition     = var.next_vm_startup_delay > 0 || var.next_vm_startup_delay == null
    error_message = "Non-null values must be a value greater than 0."
  }
  validation {
    condition     = (var.startup_order == null && var.next_vm_startup_delay == null) || var.startup_order != null
    error_message = "`next_vm_startup_delay` requires `startup_order` to be set to a non-null value."
  }
  default = null
}

variable "next_vm_shutdown_delay" {
  type        = number
  description = "Specifies a delay to wait before the next VM is shutdown. Requires `startup_order` to be set."
  validation {
    condition     = var.next_vm_shutdown_delay > 0 || var.next_vm_shutdown_delay == null
    error_message = "Non-null values must be a value greater than 0."
  }
  validation {
    condition     = (var.startup_order == null && var.next_vm_shutdown_delay == null) || var.startup_order != null
    error_message = "`next_vm_shutdown_delay` requires `startup_order` to be set to a non-null value."
  }
  default = null
}

variable "reboot_after_creation" {
  type        = bool
  description = "(Optional) Reboot the VM after initial creation (defaults to false)."
  default     = false
}

variable "reboot_after_update" {
  type        = bool
  description = "(Optional) Reboot the VM after update if needed (defaults to true)."
  default     = true
}

variable "serial_devices" {
  type = list(object({
    device = string
  }))
  description = <<-EOT
                    A list of serial displays. Defaults to a single list of `{ device = "socket" }`.

                    - device: (Required) The serial device (socket or /dev/*)
                    EOT
  validation {
    condition = alltrue([
      for d in var.serial_devices : lower(d.device) == "socket" || startswith(lower(d.device), "/dev/")
    ])
    error_message = "Invalid serial device `device`. Must be one of: socket, /dev/*."
  }

  default = [{
    device = "socket"
  }]
}

variable "vga" {
  description = <<-EOT
  (Optional) The VGA configuration for the VM.

  Attributes:
    - memory_mb (Optional) VGA memory in megabytes (defaults to 16).
    - type      (Optional) VGA type (defaults to "std").

      Supported types:
        - cirrus        : Cirrus (deprecated since QEMU 2.2)
        - none          : No VGA device
        - qxl           : SPICE
        - qxl2          : SPICE Dual Monitor
        - qxl3          : SPICE Triple Monitor
        - qxl4          : SPICE Quad Monitor
        - serial0       : Serial Terminal 0
        - serial1       : Serial Terminal 1
        - serial2       : Serial Terminal 2
        - serial3       : Serial Terminal 3
        - std           : Standard VGA
        - virtio        : VirtIO-GPU
        - virtio-gl     : VirtIO-GPU with 3D acceleration (VirGL)
        - vmware        : VMware Compatible

    - clipboard (Optional) Enable VNC clipboard by setting to "vnc".
  EOT

  type = object({
    memory_mb = optional(number, 16)
    type      = optional(string, "std")
    clipboard = optional(string)
  })

  default = null

  # Validate VGA type
  validation {
    condition = (
      var.vga == null ||
      contains([
        "cirrus", "none", "qxl", "qxl2", "qxl3", "qxl4",
        "serial0", "serial1", "serial2", "serial3",
        "std", "virtio", "virtio-gl", "vmware"
      ], var.vga.type)
    )
    error_message = "Invalid VGA type. Must be one of: cirrus, none, qxl, qxl2, qxl3, qxl4, serial0, serial1, serial2, serial3, std, virtio, virtio-gl, vmware."
  }
}

variable "disks" {
  description = <<-EOT
                    A list of disk configurations for the virtual machine.

                    Each disk supports the following parameters:

                    - interface: (Required) Disk interface. Example: "virtio0", "scsi1", etc.
                    - size: Disk size in GB.
                    - aio: (Optional) Disk AIO mode. One of "io_uring", "native", or "threads".
                    - backup: (Optional) Whether the disk is included in backups. Defaults to true.
                    - cache: (Optional) Cache mode. One of "none", "directsync", "writethrough", "writeback", or "unsafe".
                    - datastore_id: (Required) Datastore identifier. Defaults to "local-lvm".
                    - path_in_datastore: (Optional) Path within the datastore. Experimental.
                    - discard: (Optional) Whether to pass discard/trim requests. One of "on" or "ignore". Defaults to "ignore".
                    - file_format: (Optional) Disk file format. One of "qcow2", "raw", or "vmdk".
                    - import_from: (Optional) File ID for importing disk images.
                    - iothread: (Optional) Whether to use IO threads. Defaults to false.
                    - replicate: (Optional) Whether to include the disk in replication. Defaults to true.
                    - serial: (Optional) Serial number (max 20 bytes).
                    - speed: (Optional) Speed limits block for IOPS and throughput.
                    - ssd: (Optional) Whether to emulate an SSD. Defaults to false.
                  EOT

  type = list(object({
    interface         = string
    size              = number
    datastore_id      = optional(string, "local-lvm")
    aio               = optional(string, "io_uring")
    backup            = optional(bool, true)
    cache             = optional(string, "none")
    path_in_datastore = optional(string)
    discard           = optional(string, "ignore")
    file_format       = optional(string)
    import_from       = optional(string)
    iothread          = optional(bool, false)
    replicate         = optional(bool, true)
    serial            = optional(string)

    speed = optional(object({
      iops_read            = optional(number)
      iops_read_burstable  = optional(number)
      iops_write           = optional(number)
      iops_write_burstable = optional(number)
      read                 = optional(number)
      read_burstable       = optional(number)
      write                = optional(number)
      write_burstable      = optional(number)
    }), null)
    ssd = optional(bool, false)
  }))
}

variable "cdrom" {
  description = <<-EOT
                  CD-ROM configuration for the virtual machine.

                    Attributes:
                    - file_id:   The file ID for an ISO image.
                                  Use "none" to leave the CD-ROM drive empty.
                    - interface: The hardware interface for the CD-ROM drive.
                                  Must be one of ideN, sataN, or scsiN, where N is the interface index.
                                  Note: q35 machine type only supports ide0 and ide2.
                  EOT

  type = object({
    file_id   = string
    interface = string
  })
  default = null
}

variable "efi_disk" {
  description = <<-EOT
                    (Optional) The EFI disk device configuration, required if BIOS is set to 'ovmf'.

                    Attributes:
                      - datastore_id       The identifier for the datastore to create the disk in.
                      - file_format        (Optional) The file format (defaults to "raw").
                      - type               (Optional) Size and type of the OVMF EFI disk. "4m" is newer and recommended, and required for Secure Boot.
                                            For backwards compatibility use "2m". Ignored for VMs with cpu.architecture="aarch64" (defaults to "4m").
                      - pre_enrolled_keys  (Optional) Use an EFI vars template with distribution-specific and Microsoft Standard keys enrolled if used with
                                            EFI type="4m". Ignored for VMs with cpu.architecture="aarch64" (defaults to false).
                  EOT

  type = object({
    datastore_id      = string
    file_format       = optional(string, "raw")
    type              = optional(string, "4m")
    pre_enrolled_keys = optional(bool, false)
  })

  default = null
}

variable "scsi_hardware" {
  description = <<-EOT
  (Optional) The SCSI hardware type for the VM (defaults to "virtio-scsi-pci").

  Supported values:
    - lsi                  : LSI Logic SAS1068E
    - lsi53c810            : LSI Logic 53C810
    - virtio-scsi-pci      : VirtIO SCSI
    - virtio-scsi-single   : VirtIO SCSI (single queue)
    - megasas              : LSI Logic MegaRAID SAS
    - pvscsi               : VMware Paravirtual SCSI
  EOT

  type    = string
  default = "virtio-scsi-pci"

  validation {
    condition = contains([
      "lsi", "lsi53c810", "virtio-scsi-pci", "virtio-scsi-single", "megasas", "pvscsi"
    ], var.scsi_hardware)

    error_message = "Invalid scsi_hardware. Must be one of: lsi, lsi53c810, virtio-scsi-pci, virtio-scsi-single, megasas, pvscsi."
  }
}

variable "virtiofs" {
  description = <<-EOT
  (Optional) Virtiofs share configuration for the VM.

  Attributes:
    - mapping      (Required) Identifier of the directory mapping.
    - cache        (Optional) Caching mode. Supported values:
                     - auto
                     - always
                     - metadata
                     - never
    - direct_io    (Optional) Whether to allow direct IO.
    - expose_acl   (Optional) Enable POSIX ACLs (implies xattr support).
    - expose_xattr (Optional) Enable support for extended attributes.
  EOT

  type = object({
    mapping      = string
    cache        = optional(string)
    direct_io    = optional(bool, false)
    expose_acl   = optional(bool, false)
    expose_xattr = optional(bool, false)
  })

  default = null

  # Validate cache mode
  validation {
    condition = (
      var.virtiofs == null ||
      var.virtiofs.cache == null ||
      contains(["auto", "always", "metadata", "never"], var.virtiofs.cache)
    )
    error_message = "Invalid virtiofs.cache value. Must be one of: auto, always, metadata, never."
  }
}

variable "network_devices" {
  description = <<-EOT
  (Optional) A network device (multiple blocks supported).

  Each object in this list represents a virtual network device.

  Attributes:
    - bridge        (Required) The name of the network bridge.
    - disconnected  (Optional) Whether to disconnect the network device from the network (defaults to false).
    - enabled       (Optional) Whether to enable the network device (defaults to true).
    - firewall      (Optional) Whether to enable firewall rules for this interface (defaults to false).
    - mac_address   (Optional) The MAC address for this interface.
    - model         (Optional) The network device model (defaults to "virtio").
                     Supported values: e1000, e1000e, rtl8139, virtio, vmxnet3.
    - mtu           (Optional) MTU value for VirtIO devices only.
                     Set to 1 to inherit the bridge MTU. Cannot exceed bridge MTU.
    - queues        (Optional) Number of queues for VirtIO devices (1–64).
    - rate_limit    (Optional) Bandwidth limit in megabytes per second.
    - vlan_id       (Optional) VLAN identifier for this interface.
    - trunks        (Optional) Semicolon-separated list of VLAN trunk IDs (e.g., "10;20;30").
                     VLAN-aware must be enabled on the Proxmox bridge to use trunks.
  EOT

  type = list(object({
    bridge       = string
    disconnected = optional(bool, false)
    enabled      = optional(bool, true)
    firewall     = optional(bool, false)
    mac_address  = optional(string)
    model        = optional(string, "virtio")
    mtu          = optional(number)
    queues       = optional(number)
    rate_limit   = optional(number)
    vlan_id      = optional(number)
    trunks       = optional(string)
  }))

  default = []

  # Validate allowed model values
  validation {
    condition = alltrue([
      for nic in var.network_devices :
      contains(["e1000", "e1000e", "rtl8139", "virtio", "vmxnet3"], nic.model)
    ])
    error_message = "Each network_device.model must be one of: e1000, e1000e, rtl8139, virtio, vmxnet3."
  }

  # Validate queues range (if defined)
  validation {
    condition = alltrue([
      for nic in var.network_devices :
      nic.queues == null || (nic.queues >= 1 && nic.queues <= 64)
    ])
    error_message = "If specified, network_device.queues must be between 1 and 64."
  }

  # Validate MTU value (must be positive if defined)
  validation {
    condition = alltrue([
      for nic in var.network_devices :
      nic.mtu == null || nic.mtu >= 1
    ])
    error_message = "If specified, network_device.mtu must be a positive integer (1 or higher)."
  }
}

variable "tpm_state" {
  description = <<-EOT
                    (Optional) The TPM state device configuration.

                    Attributes:
                      - datastore_id  (The identifier for the datastore to create the TPM state disk in.
                      - version       (Optional) TPM state device version. Can be "v1.2" or "v2.0" (defaults to "v2.0").
                  EOT

  type = object({
    datastore_id = string
    version      = optional(string, "v2.0")
  })

  default = null
}

variable "hostpci" {
  description = <<-EOT
  (Optional) A host PCI device mapping (multiple blocks supported).
  CAUTION: Experimental! User reported problems with this option.

  Attributes:
    - device   (Required) The PCI device name for Proxmox, in the form "hostpciX" where X is 0–15.
    - mapping  (Optional) The resource mapping name of the device (e.g., "gpu"). Use either this or id.
    - mdev     (Optional) The mediated device ID to use.
    - pcie     (Optional) Whether to use a PCIe port (true) or PCI port (false). PCIe is available only for q35 machine types (defaults to false).
    - rombar   (Optional) Whether to make the firmware ROM visible to the VM (defaults to true).
    - rom_file (Optional) Relative path to a ROM file under "/usr/share/kvm/".
    - xvga     (Optional) Marks the PCI(e) device as the primary GPU of the VM. When enabled, the VGA configuration argument is ignored (defaults to false).
  EOT

  type = list(object({
    device = string
    # - id       (Optional) The PCI device ID. Not compatible with api_token; requires root credentials in the Proxmox provider. Use either this or mapping.
    # id       = optional(string)
    mapping  = optional(string)
    mdev     = optional(string)
    pcie     = optional(bool, false)
    rombar   = optional(bool, true)
    rom_file = optional(string)
    xvga     = optional(bool, false)
  }))

  default = []

  validation {
    condition = alltrue([
      for pci in var.hostpci : can(regex("^hostpci([0-9]|1[0-5])$", pci.device))
    ])
    error_message = "Each 'device' must match the format 'hostpciX' where X is a number between 0 and 15."
  }

  validation {
    condition = alltrue([
      for pci in var.hostpci : (
        !(contains(keys(pci), "id") && contains(keys(pci), "mapping"))
      )
    ])
    error_message = "Each hostpci object must use either 'id' or 'mapping', but not both."
  }
}

variable "usb" {
  description = <<-EOT
  (Optional) A host USB device mapping (multiple blocks supported).

  Each object in this list represents a host USB device mapping.

  Attributes:
    - host     (Optional) The host USB device or port, or the value "spice". Use either this or mapping.
    - mapping  (Optional) The cluster-wide resource mapping name of the device (e.g., "usbdevice"). Use either this or host.
    - usb3     (Optional) Whether to make the USB device a USB3 device for the VM (defaults to false).
  EOT

  type = list(object({
    host    = optional(string)
    mapping = optional(string)
    usb3    = optional(bool, false)
  }))

  default = []

  # Ensure that each entry uses either `host` or `mapping`, but not both or neither
  validation {
    condition = alltrue([
      for usb_dev in var.usb : (
        (contains(keys(usb_dev), "host") != contains(keys(usb_dev), "mapping"))
      )
    ])
    error_message = "Each USB object must use either 'host' or 'mapping', but not both or neither."
  }

  # Ensure host value (if provided) is valid (e.g., 'spice' or 'bus:device' or 'port') 
  validation {
    condition = alltrue([
      for usb_dev in var.usb : (
        !contains(keys(usb_dev), "host") || can(regex("^(spice|[0-9]+-[0-9]+|[0-9]+)$", usb_dev.host))
      )
    ])
    error_message = "If specified, 'host' must be 'spice' or a valid USB bus/device identifier (e.g., '1-2' or '2')."
  }
}

variable "cloud_init" {
  description = <<-EOT
  (Optional) The cloud-init configuration for the VM.

  Attributes:
    - datastore_id          (Required) Datastore to create the cloud-init disk in.
    - interface             (Optional) Hardware interface for the cloud-init image. Must be one of ide0..3, sata0..5, or scsi0..30.
    - dns                   (Optional) DNS configuration.
        - domain            (Optional) DNS search domain.
        - servers           (Optional) List of DNS servers.
    - ip_config             (Optional) List of IP configurations (one per network device).
        - ipv4              (Optional) IPv4 configuration.
            - address       (Optional) IPv4 address in CIDR or "dhcp" for autodiscovery.
            - gateway       (Optional) IPv4 gateway (omit if address=dhcp).
        - ipv6              (Optional) IPv6 configuration.
            - address       (Optional) IPv6 address in CIDR or "dhcp" for autodiscovery.
            - gateway       (Optional) IPv6 gateway (omit if address=dhcp).
    - user_account          (Optional) User account configuration (conflicts with user_data_file_id).
        - keys              (Optional) SSH keys.
        - password          (Optional) SSH password.
        - username          (Optional) SSH username.
    - network_data_file_id  (Optional) File ID for custom network configuration (conflicts with ip_config).
    - user_data_file_id     (Optional) File ID for custom user data (conflicts with user_account).
    - vendor_data_file_id   (Optional) File ID for vendor data.
    - meta_data_file_id     (Optional) File ID for meta data.
  EOT

  type = object({
    datastore_id = string
    interface    = optional(string)

    dns = optional(object({
      domain  = optional(string)
      servers = optional(list(string))
    }))

    ip_config = optional(list(object({
      ipv4 = optional(object({
        address = optional(string)
        gateway = optional(string, null)
      }))
      ipv6 = optional(object({
        address = optional(string)
        gateway = optional(string, null)
      }))
    })), null)

    user_account = optional(object({
      keys     = optional(list(string))
      password = optional(string)
      username = optional(string)
    }), null)

    network_data_file_id = optional(string, null)
    user_data_file_id    = optional(string, null)
    vendor_data_file_id  = optional(string, null)
    meta_data_file_id    = optional(string, null)
  })

  default = null

  # Validate that interface follows valid naming convention
  validation {
    condition = (
      var.cloud_init.interface == null ||
      can(regex("^(ide[0-3]|sata[0-5]|scsi([0-9]|[1-2][0-9]|30))$", var.cloud_init.interface))
    )
    error_message = "The 'interface' must be one of ide0..3, sata0..5, or scsi0..30."
  }

  # Ensure user_account and user_data_file_id are not both set
  validation {
    condition = (
      var.cloud_init == null ||
      !(var.cloud_init.user_account != null && var.cloud_init.user_data_file_id != null)
    )
    error_message = "You cannot specify both 'user_account' and 'user_data_file_id' in 'cloud_init'."
  }

  # Ensure ip_config and network_data_file_id are not both set
  validation {
    condition = (
      var.cloud_init == null ||
      !(var.cloud_init.ip_config != null && var.cloud_init.network_data_file_id != null)
    )
    error_message = "You cannot specify both 'ip_config' and 'network_data_file_id' in 'cloud_init'."
  }

  # Validate that if ipv4/ipv6 address is 'dhcp', gateway must not be set
  validation {
    condition = (
      var.cloud_init == null ||
      alltrue([
        for cfg in coalesce(var.cloud_init.ip_config, []) : (
          (cfg.ipv4 == null || !(cfg.ipv4.address == "dhcp" && cfg.ipv4.gateway != null)) &&
          (cfg.ipv6 == null || !(cfg.ipv6.address == "dhcp" && cfg.ipv6.gateway != null))
        )
      ])
    )
    error_message = "If an IPv4 or IPv6 address is set to 'dhcp', the corresponding gateway must be omitted."
  }
}

variable "keyboard_layout" {
  description = <<-EOT
                (Optional) The keyboard layout for the virtual machine console. Defaults to "en-us".

                Supported layouts:
                  - da     : Danish
                  - de     : German
                  - de-ch  : Swiss German
                  - en-gb  : British English
                  - en-us  : American English
                  - es     : Spanish
                  - fi     : Finnish
                  - fr     : French
                  - fr-be  : Belgian French
                  - fr-ca  : French Canadian
                  - fr-ch  : Swiss French
                  - hu     : Hungarian
                  - is     : Icelandic
                  - it     : Italian
                  - ja     : Japanese
                  - lt     : Lithuanian
                  - mk     : Macedonian
                  - nl     : Dutch
                  - no     : Norwegian
                  - pl     : Polish
                  - pt     : Portuguese
                  - pt-br  : Brazilian Portuguese
                  - sl     : Slovenian
                    - sv     : Swedish
                    - tr     : Turkish
                  EOT

  type    = string
  default = "en-us"

  validation {
    condition = contains([
      "da", "de", "de-ch", "en-gb", "en-us", "es", "fi", "fr", "fr-be", "fr-ca", "fr-ch",
      "hu", "is", "it", "ja", "lt", "mk", "nl", "no", "pl", "pt", "pt-br", "sl", "sv", "tr"
    ], var.keyboard_layout)

    error_message = "Invalid keyboard layout. Must be one of: da, de, de-ch, en-gb, en-us, es, fi, fr, fr-be, fr-ca, fr-ch, hu, is, it, ja, lt, mk, nl, no, pl, pt, pt-br, sl, sv, tr."
  }
}

variable "create_template" {
  type        = bool
  description = "(Optional) Whether to create a template (defaults to false)."
  default     = false
}

variable "kvm_args" {
  type        = string
  description = <<-EOT
                  Arbitrary arguments passed to kvm, for example:
                    args: -no-reboot -smbios 'type=0,vendor=FOO'

                    NOTE: this option is for experts only.
                EOT
  default     = null
}

variable "pool_id" {
  type        = string
  description = "(Optional) The identifier for a pool to assign the virtual machine to."
  default     = null
}

variable "protection" {
  type        = bool
  description = "(Optional) Sets the protection flag of the VM. This will disable the remove VM and remove disk operations (defaults to false)."
  default     = false
}

variable "description" {
  type        = string
  description = "An optional description for the VM. A ` :- Managed by OpenTofu` string will be appended to the end of the description."
  default     = ""
}

variable "tags" {
  description = <<-EOT
  (Optional) A list of tags for the VM. This is only metadata and does not affect VM functionality.

  Notes:
    - Defaults to an empty list.
    - Proxmox always sorts VM tags. Tags will be sorted alphabetically to avoid the provider reporting differences caused to sorting.
  EOT

  type    = list(string)
  default = []
}