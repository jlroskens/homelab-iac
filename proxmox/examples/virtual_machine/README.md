# Proxmox Virtual Machine Cloud Basic Example

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
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_example_vm"></a> [example\_vm](#module\_example\_vm) | github.com/jlroskens/homelab-iac/proxmox/modules/proxmox_virtual_machine | v1 |

## Resources

| Name | Type |
|------|------|
| [proxmox_virtual_environment_download_file.ubuntu_noble](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_download_file) | resource |
| [random_password.default_account](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [tls_private_key.default_account](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_default_account_password"></a> [default\_account\_password](#output\_default\_account\_password) | n/a |
| <a name="output_default_account_private_key"></a> [default\_account\_private\_key](#output\_default\_account\_private\_key) | n/a |
| <a name="output_default_account_public_key"></a> [default\_account\_public\_key](#output\_default\_account\_public\_key) | n/a |
<!-- END_TF_DOCS -->