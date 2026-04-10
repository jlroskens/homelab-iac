<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.6 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | ~> 0.86 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~>3.7 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) | ~> 0.86 |
| <a name="provider_random"></a> [random](#provider\_random) | ~>3.7 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [proxmox_virtual_environment_dns.first_node_dns_configuration](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_dns) | resource |
| [proxmox_virtual_environment_group.this](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_group) | resource |
| [proxmox_virtual_environment_hosts.nodes](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_hosts) | resource |
| [proxmox_virtual_environment_pool.this](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_pool) | resource |
| [proxmox_virtual_environment_role.this](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_role) | resource |
| [proxmox_virtual_environment_user.pve_users](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_user) | resource |
| [random_password.generated](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dns_search_domain"></a> [dns\_search\_domain](#input\_dns\_search\_domain) | (Required) The DNS search domain to configure for each node. | `string` | n/a | yes |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | (Required) The DNS servers to configure for each node. | `list(string)` | n/a | yes |
| <a name="input_groups"></a> [groups](#input\_groups) | (Optional) List of groups and their ACLs<br/><br/>        group\_id (string): (Required) The group identifier.<br/>    <br/>        acls (list(object)): List of Access Control List items for a user.<br/>        - path(string): The path or scope to which the role will be granted for.<br/>        - role\_id(string): The role ID to apply. Must either already exists or be set in the `roles` variable.<br/><br/>        comment (string): Optional comment. | <pre>list(object({<br/>    group_id = string<br/>    acls = optional(list(object({<br/>      path    = string,<br/>      role_id = string<br/>    })), [])<br/>    comment = optional(string, null)<br/>  }))</pre> | `[]` | no |
| <a name="input_node_host_entries"></a> [node\_host\_entries](#input\_node\_host\_entries) | (Optional). Host entries per node, indexed by host name. If set, all host entries must be provided. | <pre>map(list(object({<br/>    ip_address = string<br/>    hostnames  = list(string)<br/>  })))</pre> | `{}` | no |
| <a name="input_nodes"></a> [nodes](#input\_nodes) | Cluster node names. Only the names, not the FQDN. Example: [ "pve-host-01" ] | `list(string)` | n/a | yes |
| <a name="input_pools"></a> [pools](#input\_pools) | Used to group a set of virtual machines and datastores. | <pre>list(object({<br/>    pool_id = string,<br/>    comment = optional(string, null)<br/>  }))</pre> | `[]` | no |
| <a name="input_pve_endpoint"></a> [pve\_endpoint](#input\_pve\_endpoint) | Endpoint of the Proxmox host. Example: https://10.0.0.2:8006/ | `string` | n/a | yes |
| <a name="input_resource_comment"></a> [resource\_comment](#input\_resource\_comment) | Comment to add to resources (if available). | `string` | `"Managed by OpenTofu"` | no |
| <a name="input_roles"></a> [roles](#input\_roles) | (Optional) Custom roles and their associated privileges. | <pre>list(object({<br/>    role_id    = string<br/>    privileges = list(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_user_passwords"></a> [user\_passwords](#input\_user\_passwords) | (Optional) Map of user passwords that aligns with a user\_id in the `users[]` list. Passwords are only set when a user is first created. Changes to this value or the users password after user creation are ignored! | `map(string)` | `{}` | no |
| <a name="input_users"></a> [users](#input\_users) | (Optional) List of users and their ACLs. Will use a password set for the user in `user_passwords`, otherwise generates a random password and output's it.<br/><br/>        user\_id (string): The user name/id (without the @pve suffix)<br/>        email (string): (Optional) Email address of the user.<br/>        first\_name (string): (Optional) The user's first name.<br/>        last\_name (string): (Optional) The user's last name.<br/>    <br/>        acls (list(object)): List of Access Control List items for a user.<br/>        - path(string): The path or scope to which the role will be granted for.<br/>        - role\_id(string): The role ID to apply. Must either already exists or be set in the `roles` variable.<br/><br/>        groups (list(string)): (Optional) The user's group ids.<br/><br/>        enabled (bool): (Optional) Whether the user account is enabled.<br/>        expiration\_date (string): (Optional) The user account's expiration date (RFC 3339).<br/>        comment (string): Optional comment. | <pre>list(object({<br/>    user_id    = string<br/>    email      = optional(string, null)<br/>    first_name = optional(string, null)<br/>    last_name  = optional(string, null)<br/>    acls = optional(list(object({<br/>      path    = string,<br/>      role_id = string<br/>    })), [])<br/>    groups          = optional(list(string), [])<br/>    enabled         = optional(bool, true)<br/>    expiration_date = optional(string, null)<br/>    comment         = optional(string, null)<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_generated_passwords"></a> [generated\_passwords](#output\_generated\_passwords) | Passwords that were generate by this terraform. Passwords provided via tfvars will not be shown here. |
<!-- END_TF_DOCS -->