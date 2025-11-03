# Proxmox Virtual Machine Cloud Init Example

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.6 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | ~> 0.86 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) | ~> 0.86 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_example_cloud_init_vm"></a> [example\_cloud\_init\_vm](#module\_example\_cloud\_init\_vm) | github.com/jlroskens/homelab-iac/proxmox/modules/proxmox_virtual_machine | v1 |

## Resources

| Name | Type |
|------|------|
| [proxmox_virtual_environment_download_file.ubuntu_noble](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_download_file) | resource |
| [proxmox_virtual_environment_file.user_data](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file) | resource |
| [proxmox_virtual_environment_file.vendor](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file) | resource |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->