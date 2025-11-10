data "talos_client_configuration" "this" {
  cluster_name         = var.talos_cluster.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [local.cluster_node_endpoint]
}

output "control_plane_config" {
  value     = [for key, cfg in talos_machine_configuration_apply.control_plane : cfg.machine_configuration][0]
  sensitive = true
}
output "worker_config" {
  value     = length(talos_machine_configuration_apply.worker) > 0 ? [for key, cfg in talos_machine_configuration_apply.worker : cfg.machine_configuration][0] : ""
  sensitive = true
}

# output "talos_config" {
#   value = replace(yamlencode({
#     context = var.talos_cluster.cluster_name
#     contexts = {
#       "${var.talos_cluster.cluster_name}" = {
#         endpoints = local.api_cert_sans
#         ca = local.client_config.ca_certificate
#         crt = local.client_config.client_certificate
#         key = local.client_config.client_key
#       }
#     }
#   }), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
#   sensitive = true
# }

output "cluster_endpoint" {
  value       = var.talos_cluster.cluster_endpoint
  description = "Endpoint of the cluster in the format of https://cluster.local.example.com:6443"
}
output "cluster_hostname" {
  value       = local.cluster_node_endpoint
  description = "The hostname of the cluster. Example: cluster.local.example.com."
}

output "controlplane_node_hostnames" {
  value = [for vm_id, hostname in local.nodes_address : {
    vm_id    = vm_id
    hostname = hostname
    }
    if contains(keys(local.control_plane_vms_map), vm_id)
  ]
  description = "Hostnames of the control plane nodes."
}

output "controlplane_node_ips" {
  value = [for vm_id, ip in local.nodes_host_ip : {
    vm_id        = vm_id
    ipv4_address = ip
    }
    if contains(keys(local.control_plane_vms_map), vm_id)
  ]
  description = "IP Addresses of the control plane nodes."
}

output "talos_client_config" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.cluster_node_endpoint
}

output "talos_cluster_kubeconfig" {
  value     = talos_cluster_kubeconfig.this
  sensitive = true
}
output "kubeconfig" {
  value     = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

output "kubeconfig_client_certificate" {
  value     = talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate
}
output "kubeconfig_client_key" {
  value     = talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key
  sensitive = true
}
output "kubeconfig_ca_certificate" {
  value     = talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate
}

output "talos_config_instructions" {
  value = <<-EOT
              To configure your talos config and kubeconfig files:
              
              # Extract talos_client_config output to ~/.talos/config
              mkdir -p ~/.talos
              tofu output -raw -var pve_endpoint=${var.pve_endpoint} -var terraform_state_path="${var.terraform_state_path}" talos_client_config > ~/.talos/config

              # Export config file location to the TALOSCONFIG variable talosctl expects
              export TALOSCONFIG=~/.talos/config
              
              # Merge the config for this cluster with your default kubeconfig
              talosctl kubeconfig --nodes ${local.bootstrap_endpoint}

              # One liner:
              mkdir -p ~/.talos && tofu output -raw -var pve_endpoint=${var.pve_endpoint} -var terraform_state_path="${var.terraform_state_path}" talos_client_config > ~/.talos/config && export TALOSCONFIG=~/.talos/config && talosctl kubeconfig --nodes ${local.bootstrap_endpoint}
             EOT
}