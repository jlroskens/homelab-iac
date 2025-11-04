# PVE File Repository

This Tofu manifest manages files in Proxmox VE (Virtual Environment) storage. It provides functionality to:

1. **Upload local files** to Proxmox VE storage with support for both regular and sensitive files
2. **Create raw files** directly in Proxmox VE storage from inline content
3. **Download files** from remote URLs directly to Proxmox VE storage

The manifest supports different content types including:
- `backup` - Backup files
- `iso` - ISO images
- `snippets` - Configuration snippets and scripts
- `import` - Import files
- `vztmpl` - Container templates

Files can be uploaded to specific datastores and nodes within your Proxmox cluster, with options for file permissions, overwrite behavior, and upload timeouts. The tofu also provides validation to ensure proper configuration and supports checksum verification for downloaded files.

## Usage

To use this tofu, first copy and modify the example configuration file:

```bash
cp .env/example.tfvars .env/your-config.tfvars
# Edit .env/your-config.tfvars with your specific values
```

Then execute the following Terraform commands:

```bash
# Initialize Terraform/OpenTofu
tofu init

# Plan the changes
tofu plan -var-file=.env/your-config.tfvars

# Apply the changes
tofu apply -var-file=.env/your-config.tfvars
```

Note: Before applying, make sure to update sensitive values like SSH keys and passwords in the configuration file.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.6 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.4 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | ~> 0.86 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_local"></a> [local](#provider\_local) | 2.5.3 |
| <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) | 0.86.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [proxmox_virtual_environment_download_file.downloads](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_download_file) | resource |
| [proxmox_virtual_environment_file.env_files](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file) | resource |
| [proxmox_virtual_environment_file.env_files_raw](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file) | resource |
| [proxmox_virtual_environment_file.env_files_raw_sensitive](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file) | resource |
| [local_file.env_files](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) | data source |
| [local_sensitive_file.env_files](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/sensitive_file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_pve_download_files"></a> [pve\_download\_files](#input\_pve\_download\_files) | List of Proxmox VE files to download | <pre>list(object({<br/>    content_type = string<br/>    datastore_id = string<br/>    node_name    = string<br/>    url          = string<br/><br/>    checksum                = optional(string)<br/>    checksum_algorithm      = optional(string)<br/>    decompression_algorithm = optional(string)<br/>    file_name               = optional(string)<br/>    overwrite               = optional(bool, true)<br/>    overwrite_unmanaged     = optional(bool)<br/>    upload_timeout          = optional(number, 600)<br/>    verify                  = optional(bool, true)<br/>  }))</pre> | n/a | yes |
| <a name="input_pve_endpoint"></a> [pve\_endpoint](#input\_pve\_endpoint) | Endpoint of the Proxmox host. Example: https://10.0.0.2:8006/ | `string` | n/a | yes |
| <a name="input_pve_files"></a> [pve\_files](#input\_pve\_files) | List of local files to upload to Proxmox VE storage. | <pre>list(object({<br/>    content_type   = optional(string, "snippets")<br/>    datastore_id   = string<br/>    file_mode      = optional(string)<br/>    node_name      = string<br/>    overwrite      = optional(bool, true)<br/>    timeout_upload = optional(number, 1800)<br/>    sensitive      = optional(bool, false)<br/><br/>    source_file = optional(object({<br/>      checksum  = optional(string)<br/>      file_name = optional(string)<br/>      insecure  = optional(bool, false)<br/>      min_tls   = optional(string, "1.3")<br/>      path      = string<br/>    }), null)<br/>  }))</pre> | n/a | yes |
| <a name="input_pve_raw_files"></a> [pve\_raw\_files](#input\_pve\_raw\_files) | List of raw files to upload to Proxmox VE storage | <pre>list(object({<br/>    content_type   = optional(string, "snippets")<br/>    datastore_id   = string<br/>    file_mode      = optional(string)<br/>    node_name      = string<br/>    overwrite      = optional(bool, true)<br/>    timeout_upload = optional(number, 1800)<br/>    sensitive      = optional(bool, false)<br/><br/>    source_raw = optional(object({<br/>      data      = string<br/>      file_name = string<br/>      resize    = optional(number)<br/>    }), null)<br/>  }))</pre> | n/a | yes |
| <a name="input_state_file"></a> [state\_file](#input\_state\_file) | Path to the terraform state file. | `string` | `".terraform/terraform.tfstate"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_env_files"></a> [env\_files](#output\_env\_files) | n/a |
| <a name="output_raw_env_files"></a> [raw\_env\_files](#output\_raw\_env\_files) | n/a |
| <a name="output_raw_env_files_sensitive"></a> [raw\_env\_files\_sensitive](#output\_raw\_env\_files\_sensitive) | n/a |
<!-- END_TF_DOCS -->