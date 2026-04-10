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
| <a name="module_bootstrap_vm"></a> [bootstrap\_vm](#module\_bootstrap\_vm) | ../modules/proxmox_virtual_machine | n/a |

## Resources

| Name | Type |
|------|------|
| [proxmox_virtual_environment_file.image](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/data-sources/virtual_environment_file) | data source |
| [proxmox_virtual_environment_file.user_data](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/data-sources/virtual_environment_file) | data source |
| [proxmox_virtual_environment_file.vendor](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/data-sources/virtual_environment_file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloud_init_dns"></a> [cloud\_init\_dns](#input\_cloud\_init\_dns) | (Optional) DNS configuration.<br/>  - domain            (Optional) DNS search domain.<br/>  - servers           (Optional) List of DNS servers. | <pre>object({<br/>    domain  = optional(string)<br/>    servers = optional(list(string))<br/>  })</pre> | `null` | no |
| <a name="input_cloud_init_ip_config"></a> [cloud\_init\_ip\_config](#input\_cloud\_init\_ip\_config) | List of IP configurations for cloud-init network setup.<br/>- ipv4: (Optional) IPv4 configuration object.<br/>  - address: (Required) IPv4 address in CIDR notation (e.g., "192.168.1.10/24") or "dhcp" for autodiscovery.<br/>  - gateway: (Optional) IPv4 gateway address. Omit if address is set to "dhcp".<br/>- ipv6: (Optional) IPv6 configuration object.<br/>  - address: (Required) IPv6 address in CIDR notation (e.g., "2001:db8::10/64") or "dhcp" for autodiscovery.<br/>  - gateway: (Optional) IPv6 gateway address. Omit if address is set to "dhcp". | <pre>list(object({<br/>    ipv4 = optional(object({<br/>      address = string<br/>      gateway = optional(string)<br/>    }))<br/>    ipv6 = optional(object({<br/>      address = string<br/>      gateway = optional(string)<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_cpu_cores"></a> [cpu\_cores](#input\_cpu\_cores) | The amount of vCPU / cores to assign to the the control plane VM. | `number` | `2` | no |
| <a name="input_description"></a> [description](#input\_description) | Description for the virtual machine. Defaults to "Talos control plane node". | `string` | `"Talos control plane node"` | no |
| <a name="input_image_content_type"></a> [image\_content\_type](#input\_image\_content\_type) | The content type of the file | `string` | `"iso"` | no |
| <a name="input_image_datastore_id"></a> [image\_datastore\_id](#input\_image\_datastore\_id) | The datastore ID where image file is stored | `string` | `"shared-vz"` | no |
| <a name="input_image_file_name"></a> [image\_file\_name](#input\_image\_file\_name) | The name of the image file | `string` | n/a | yes |
| <a name="input_image_node_name"></a> [image\_node\_name](#input\_image\_node\_name) | The name of node where image file is located | `string` | `"pve-host-01"` | no |
| <a name="input_memory_mb"></a> [memory\_mb](#input\_memory\_mb) | The amount of memory (in MB) to assign to the the control plane VM. | `number` | `2048` | no |
| <a name="input_node_name"></a> [node\_name](#input\_node\_name) | The name of the Proxmox node to assign the virtual machine to. | `string` | n/a | yes |
| <a name="input_pve_endpoint"></a> [pve\_endpoint](#input\_pve\_endpoint) | The Proxmox VE API endpoint URL | `string` | n/a | yes |
| <a name="input_terraform_state_path"></a> [terraform\_state\_path](#input\_terraform\_state\_path) | The local path for storing Terraform state file | `string` | `".terraform/terraform.tfstate"` | no |
| <a name="input_user_data_snippet_name"></a> [user\_data\_snippet\_name](#input\_user\_data\_snippet\_name) | Name of the user data snippet uploaded to proxmox for cloud-init. | `string` | `null` | no |
| <a name="input_vendor_data_snippet_name"></a> [vendor\_data\_snippet\_name](#input\_vendor\_data\_snippet\_name) | Name of the vendor snippet uploaded to proxmox for cloud-init. | `string` | `null` | no |
| <a name="input_vm_id"></a> [vm\_id](#input\_vm\_id) | Unique ID of the Virtual Machine. Must be a value between 100 and 999,999,999 and unique across the entire Proxmox cluster. | `number` | n/a | yes |
| <a name="input_vm_name"></a> [vm\_name](#input\_vm\_name) | The name of the virtual machine. This name will be used for cluster identification and DNS resolution. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->