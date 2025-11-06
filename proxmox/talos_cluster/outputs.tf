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

output "talos_client_config" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
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