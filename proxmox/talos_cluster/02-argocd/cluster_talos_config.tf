terraform {
  required_version = "~> 1.6"
}

data "terraform_remote_state" "cluster" {
  backend = "local"

  config = {
    path = var.terraform_state_path
  }
}
output "talosconfig" {
  value = data.terraform_remote_state.cluster.outputs.talos_client_config
  sensitive = true
}
output "cluster_hostname" {
  value = data.terraform_remote_state.cluster.outputs.cluster_hostname
  sensitive = true
}

variable "terraform_state_path" {
  type = string
  default = "../01-tofu/.terraform/terraform.tfstate"
}