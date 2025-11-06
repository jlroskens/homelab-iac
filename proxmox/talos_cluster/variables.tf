# Variables for Proxmox provider configuration
variable "pve_endpoint" {
  type        = string
  description = "The Proxmox VE API endpoint URL"
}

variable "terraform_state_path" {
  type        = string
  description = "The local path for storing Terraform state file"
  default     = ".terraform/terraform.tfstate"
}

# Variables for Proxmox ISO file
variable "iso_node_name" {
  type        = string
  description = "The name of node where ISO file is located"
  default     = "pve-host-01"
}

variable "iso_datastore_id" {
  type        = string
  description = "The datastore ID where ISO file is stored"
  default     = "shared-vz"
}

variable "iso_content_type" {
  type        = string
  description = "The content type of the file"
  default     = "iso"
}

variable "iso_file_name" {
  type        = string
  description = "The name of the ISO file"
  default     = "talos-v1.11.3-nocloud-amd64-secureboot.iso"
}

variable "talos_version" {
  type        = string
  description = "The version of talos features to use in generated machine configuration."
}

# Variables for cluster configuration
variable "talos_cluster" {
  type = object({
    cluster_name              = string
    cluster_endpoint          = string
    control_plane_vm_id       = optional(number, null)
    dns_domain_suffix         = optional(string, null)
    machine_install_image     = optional(string, null)
    install_disk              = optional(string, null)
    kubelet_subnet_ip_configs = optional(list(number), [])
    etcd_subnet_ip_configs    = optional(list(number), [])
    kubelet_subnets           = optional(list(string), [])
    etcd_subnets              = optional(list(string), [])
    machine_cert_sans         = optional(list(string), [])
    api_cert_sans             = optional(list(string), [])
  })
  description = <<-EOT
Talos cluster configuration settings.

- cluster_name: The name of the Kubernetes cluster
- cluster_endpoint: The kubernetes API endpoint of the cluster. For multiple control plane VMs, this is the DNS A record assigned for each VM, or the load balancer if you have one. Example: `https://cluster.local.example.com:6443`
- control_plane_vm_id: The control plane Virtual Machine's vm_id to reference for ip configuration. If not set, uses the first control plane VM.
- dns_domain_suffix: The domain suffix to append to the Virtual Machine names prior to adding them to the certSANS lists. Starts with a '.'. If not set, then the VM names are added as is. (Example: `.local.example.com`).
- machine_install_image: The Talos machine installation image to use. Uses the default configure image if not set. Needed for secureboot.
- install_disk: The disk the talos os will be installed to ('/dev/sda' by default).
- kubelet_subnet_ip_configs: The indexes of ip4 address cloud-init configuration for virtual machine that should be listed as valid subnets for kublet Node IPs.
- etcd_subnet_ip_configs: The indexes of ip4 address cloud-init configuration for virtual machine that should be listed as valid subnets for etcd advertisedSubnets.
- kubelet_subnets: List of ip4 subnets for kubelet Node IPs. At least kubelet_subnets or kubelet_subnet_ip_configs must be provided. If both are provided, results are merged.
- etcd_subnets: List of ip4 subnets for etcd advertisedSubnets. Same rules apply for this and etcd_subnet_ip_configs.
- machine_cert_sans: List of IP addresses and hostnames to add as alternate subjects to the generated certificate(s) for each machine / VM.
- api_cert_sans: List of IP addresses and hostnames to add as alternate subjects to the generated certificate(s) for the kubernetes API.

EOT
}

variable "joined_worker_ids" {
  type        = list(number)
  description = "List of worker VM_IDs that have already joined the cluster. This is needed because workers initially need to be configured using their VM's DNS / IP endpoint but once joined need to be managed through a control plane endpoint."
  default     = []
}

# Variables for control plane VM configuration
variable "control_plane_vms" {
  type = list(object({
    vm_name     = string
    vm_id       = number
    node_name   = string
    description = optional(string, "Talos control plane node")

    cloud_init_ip_config = list(object({
      ipv4 = optional(object({
        address = string
        gateway = optional(string)
      }))
      ipv6 = optional(object({
        address = string
        gateway = optional(string)
      }))
    }))

  }))
  description = <<-EOT
List of control plane VM configurations for the Talos Kubernetes cluster.

Each control plane VM object supports the following parameters:

- vm_name: (Required) The name of the virtual machine. This name will be used for cluster identification and DNS resolution.
- vm_id: (Required) Unique ID of the Virtual Machine. Must be a value between 100 and 999,999,999 and unique across the entire Proxmox cluster.
- node_name: (Required) The name of the Proxmox node to assign the virtual machine to.
- description: (Optional) Description for the virtual machine. Defaults to "Talos control plane node".
- cloud_init_ip_config: (Required) List of IP configurations for cloud-init network setup.
  - ipv4: (Optional) IPv4 configuration object.
    - address: (Required) IPv4 address in CIDR notation (e.g., "192.168.1.10/24") or "dhcp" for autodiscovery.
    - gateway: (Optional) IPv4 gateway address. Omit if address is set to "dhcp".
  - ipv6: (Optional) IPv6 configuration object.
    - address: (Required) IPv6 address in CIDR notation (e.g., "2001:db8::10/64") or "dhcp" for autodiscovery.
    - gateway: (Optional) IPv6 gateway address. Omit if address is set to "dhcp".

Note: At least one control plane VM is required for a functional cluster. For high availability, configure 3 or more control plane VMs.
EOT
}

# Variables for worker VM configuration
variable "worker_vms" {
  type = list(object({
    vm_name     = string
    vm_id       = number
    node_name   = string
    description = optional(string, "Talos worker")

    cloud_init_ip_config = list(object({
      ipv4 = optional(object({
        address = string
        gateway = optional(string)
      }))
      ipv6 = optional(object({
        address = string
        gateway = optional(string)
      }))
    }))

  }))
  description = <<-EOT
List of worker VM configurations for the Talos Kubernetes cluster.

Each worker VM object supports the following parameters:

- vm_name: (Required) The name of the virtual machine. This name will be used for cluster identification and DNS resolution.
- vm_id: (Required) Unique ID of the Virtual Machine. Must be a value between 100 and 999,999,999 and unique across the entire Proxmox cluster.
- node_name: (Required) The name of the Proxmox node to assign the virtual machine to.
- description: (Optional) Description for the virtual machine. Defaults to "Talos worker".
- cloud_init_ip_config: (Required) List of IP configurations for cloud-init network setup.
  - ipv4: (Optional) IPv4 configuration object.
    - address: (Required) IPv4 address in CIDR notation (e.g., "192.168.1.20/24") or "dhcp" for autodiscovery.
    - gateway: (Optional) IPv4 gateway address. Omit if address is set to "dhcp".
  - ipv6: (Optional) IPv6 configuration object.
    - address: (Required) IPv6 address in CIDR notation (e.g., "2001:db8::20/64") or "dhcp" for autodiscovery.
    - gateway: (Optional) IPv6 gateway address. Omit if address is set to "dhcp".

Note: Worker VMs are optional but recommended for running container workloads. They can be scaled horizontally to handle increased workload demands.
EOT
  default     = []
}
