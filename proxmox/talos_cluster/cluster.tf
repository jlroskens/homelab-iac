# Data sources for Talos configuration files
data "talos_machine_configuration" "control_plane" {
  cluster_name     = var.talos_cluster.cluster_name
  cluster_endpoint = var.talos_cluster.cluster_endpoint
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.talos_cluster.cluster_name
  cluster_endpoint = var.talos_cluster.cluster_endpoint
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
}

# Generate machine secrets for the cluster
resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

# Get the control plane VM to reference for IP configuration
locals {
  # Concat control plane VMs and Worker VMs into a single list
  all_vms = concat(var.control_plane_vms, var.worker_vms)
  # Create a map of all VMs using the vm_id as a key
  all_vms_map = { for vm in local.all_vms : vm.vm_id => vm }
  # Create another map of control_plane_vms
  control_plane_vms_map = { for vm in var.control_plane_vms : vm.vm_id => vm }
  # Get a map of all the cloud_init_ip_config lists for all VMs
  all_vm_ip_configs = {
    for vm_id, vm in local.all_vms_map : vm_id => vm.cloud_init_ip_config
    if vm.cloud_init_ip_config != null && length(vm.cloud_init_ip_config) > 0
  }
  # Search through each VM's cloud_init_ip_config list and extract ipv4 addresses that aren't set to dhcp
  static_ip4_cidrs = {
    for vm_id, ipconfigs in local.all_vm_ip_configs : vm_id => flatten([
      for ipconfig in ipconfigs : [
        ipconfig.ipv4.address
      ]
      if ipconfig.ipv4 != null && ipconfig.ipv4 != "dhcp"
    ])
  }
  # Remove the static IP part of the ip cidr creating a list of subnets
  cidr_subnets = {
    for vm_id, ip_list in local.static_ip4_cidrs : vm_id => [
      for ip_with_cidr in ip_list :
      "${cidrhost(ip_with_cidr, 0)}${substr(ip_with_cidr, index(split("", ip_with_cidr), "/"), 3)}"
    ]
  }

  # cidrhost("172.20.12.101/23", 0)
  # This creates a new map with the same VM IDs but with CIDR notation stripped
  static_ip4s = {
    for vm_id, ip_list in local.static_ip4_cidrs : vm_id => [
      for ip_with_cidr in ip_list :
      substr(ip_with_cidr, 0, index(split("", ip_with_cidr), "/"))
    ]
  }

  # Create a map containing each node's hostname indexed by each node's VM ID
  # Hostname is built using each VM's 'vm_name' and combining it with the 'var.talos_cluster.dns_domain_suffix'
  # If dns_domain_suffix is not set, then try and use the static ip for the vm/node
  # Finally, if no static IP can be found then default to the VM's 'vm_name'
  nodes_address = { for vm in local.all_vms : vm.vm_id =>
    can(coalesce(var.talos_cluster.dns_domain_suffix, null)) ? "${vm.vm_name}${var.talos_cluster.dns_domain_suffix}"
    : contains(keys(local.static_ip4s), tostring(vm.vm_id)) ? local.static_ip4s[vm.vm_id][0] : vm.vm_name
  }
  # Create a map containing each node's host/primary IP used to apply configurations indexed by each node's VM ID
  # Logic is similar to the above, but a static_ip is attempted first before using a hostname
  nodes_host_ip = { for vm in local.all_vms : vm.vm_id =>
    contains(keys(local.static_ip4s), tostring(vm.vm_id)) ? local.static_ip4s[vm.vm_id][0]
    : can(coalesce(var.talos_cluster.dns_domain_suffix, null)) ? "${vm.vm_name}${var.talos_cluster.dns_domain_suffix}" : vm.vm_name
  }

  # Find the control plane VM to use as a template for setting cluster subnet configuration values
  ip_configs_vm  = can(coalesce(var.talos_cluster.control_plane_vm_id, null)) ? local.all_vms_map[var.talos_cluster.control_plane_vm_id] : var.control_plane_vms[0]
  template_vm_id = local.ip_configs_vm.vm_id
  # The ip_configs_vm will be used to bootstrap the cluster
  bootstrap_endpoint = local.nodes_address[local.ip_configs_vm.vm_id]
  # The node endpoint and endpoints listed in the talos config only expect the hostname.
  cluster_node_endpoint = provider::corefunc::url_parse(var.talos_cluster.cluster_endpoint).hostname

  # YAML Patches
  # The below is used to build the controlplane and worker YAML patches for the nodes.

  # Extract ip4 address subnets from the template VM's cloud_init_ip_config list with the index values listed 
  # in the var.talos_cluster.kubelet_subnet_ip_configs variable.
  # If no values are specified in the kubelet_subnet_ip_configs list, then use the first ipv4 subnet
  # that was found for the VM.
  # If none of the above can be accomplish, default to an empty list.
  ipconfig_kubelet_nodeip_ips = length(var.talos_cluster.kubelet_subnet_ip_configs) > 0 ? [
    for idx in var.talos_cluster.kubelet_subnet_ip_configs :
    local.ip_configs_vm.cloud_init_ip_config[idx].ipv4.address
  ] : contains(keys(local.static_ip4s), local.template_vm_id) ? local.static_ip4s[local.template_vm_id] : []
  # Convert the ip4 cidr blocks to cidr subnets
  ipconfig_kubelet_nodeip_subnets = [
    for ip_with_cidr in local.ipconfig_kubelet_nodeip_ips :
    "${cidrhost(ip_with_cidr, 0)}${substr(ip_with_cidr, index(split("", ip_with_cidr), "/"), 3)}"
  ]
  # Concat the found ipconfig subnets from above, if any, with user specified subnets. Remove any duplicates.
  # YAML: machine.kubelet.nodeIP.validSubnets
  kubelet_nodeip_subnets = distinct(concat(local.ipconfig_kubelet_nodeip_subnets, var.talos_cluster.kubelet_subnets))

  # The next two variables are set the same as the kubelet variables above, except the etcd_subnet vars are used.
  ipconfig_etcd_ips = length(var.talos_cluster.etcd_subnet_ip_configs) > 0 ? [
    for idx in var.talos_cluster.etcd_subnet_ip_configs :
    local.ip_configs_vm.cloud_init_ip_config[idx].ipv4.address
  ] : contains(keys(local.static_ip4s), local.template_vm_id) ? local.static_ip4s[local.template_vm_id] : []
  # Convert the ip4 cidr blocks to cidr subnets
  ipconfig_etcd_subnets = [
    for ip_with_cidr in local.ipconfig_etcd_ips :
    "${cidrhost(ip_with_cidr, 0)}${substr(ip_with_cidr, index(split("", ip_with_cidr), "/"), 3)}"
  ]
  # Concat the found ipconfig subnets from above, if any, with user specified subnets. Remove any duplicates
  # YAML: cluster.etcd.advertisedSubnets
  etcd_subnets = distinct(concat(local.ipconfig_etcd_subnets, var.talos_cluster.etcd_subnets))

  # Create certificate SANs lists for the machine and apiserver sections.
  # Create a list of machine SANs. Talos generates one certificate for all machines.
  # The IPs and hostnames in this list will be added as alternate names to that certificate
  # so those machines can be accessed without certificate errors.
  # YAML: machine.certSANs
  machine_cert_sans = distinct(concat(
    flatten([for k, ips in local.static_ip4s : [for ip in ips : ip]]),
    [for k, address in local.nodes_address : address],
    var.talos_cluster.machine_cert_sans
  ))
  # Similar to the above, but for the certificate used by the kubernetes API.
  # The major difference is only control plane address/ips need to be added here.
  # YAML: cluster.apiServer.certSANs
  api_cert_sans = distinct(concat(
    flatten([for k, ips in local.static_ip4s : [for ip in ips : ip] if contains(keys(local.control_plane_vms_map), k)]),
    [for k, address in local.nodes_address : address if contains(keys(local.control_plane_vms_map), k)],
    var.talos_cluster.api_cert_sans
  ))
}

# Talos Machine Configuration Apply Resources for Control Plane Nodes
resource "talos_machine_configuration_apply" "control_plane" {
  for_each = local.control_plane_vms_map

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.control_plane.machine_configuration
  node                        = local.nodes_host_ip[each.key]
  config_patches = concat(
      [yamlencode({
        machine = {
          install = {
            disk  = var.talos_cluster.install_disk
            image = var.talos_cluster.machine_install_image
          }
          kubelet = {
            nodeIP = {
              validSubnets = local.kubelet_nodeip_subnets
            }
          }
          certSANs = local.machine_cert_sans
        }
        cluster = {
          apiServer = {
            certSANs = local.api_cert_sans
          }
          etcd = {
            advertisedSubnets = local.etcd_subnets
          }
        }
      })
    ],
    local.control_plane_patches
  )
  depends_on = [
    module.control_plane_vms
  ]
}

resource "talos_machine_bootstrap" "this" {
  node                 = local.bootstrap_endpoint
  client_configuration = talos_machine_secrets.this.client_configuration
  depends_on           = [talos_machine_configuration_apply.control_plane]
}

# Talos Machine Configuration Apply Resources for Worker Nodes
resource "talos_machine_configuration_apply" "worker" {
  for_each = { for vm in var.worker_vms : vm.vm_id => vm }

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  # Use a control_plane endpoint for configuring already joined workers, otherwise use the worker's IP address for initial configuration.
  # Otherwise terraform / tofu will timeout, as the endpoint on the worker is no longer available after it joins the cluster
  endpoint = contains(var.joined_worker_ids, tonumber(each.key)) ? local.cluster_node_endpoint : local.nodes_host_ip[each.key]
  node     = local.nodes_host_ip[each.key]
  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk  = var.talos_cluster.install_disk
          image = var.talos_cluster.machine_install_image
        }
        kubelet = {
          nodeIP = {
            validSubnets = local.kubelet_nodeip_subnets
          }
          # For https://github.com/siderolabs/talos-cloud-controller-manager
          extraArgs = var.talos_cluster.talos_ccm_enabled == false ? {} : {
            rotate-server-certificates = true
            # cloud-provider = "external"
          }
        }
        certSANs = local.machine_cert_sans
      }
    })
  ]
  depends_on = [
    module.worker_vms, talos_machine_configuration_apply.control_plane, talos_machine_bootstrap.this
  ]
}