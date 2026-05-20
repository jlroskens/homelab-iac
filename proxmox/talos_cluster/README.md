# Talos Kubernetes Cluster on Proxmox

This tofu configuration creates a highly available Talos Kubernetes cluster on Proxmox VE, consisting of control plane and worker nodes with dual network interfaces for optimal performance and security.

## Overview

This module automates the deployment of a Talos-based Kubernetes cluster with the following key features:

- **High Availability Control Plane**: Deploys multiple control plane nodes for fault tolerance
- **Worker Nodes**: Deploys worker nodes for running container workloads
- **Dual Network Configuration**: Each VM has two network interfaces - one for external access and one for internal cluster traffic
- **Automated Bootstrap**: Handles the complete cluster initialization process
- **Certificate Management**: Automatically configures certificates with proper SANs for secure communication

## Architecture

### High Availability Design

The cluster achieves high availability through:

1. **Multiple Control Plane Nodes**: Typically 3 control plane nodes are deployed to maintain quorum
2. **Distributed Worker Nodes**: Worker nodes can be distributed across multiple Proxmox hosts
3. **Dual Network Interfaces**:
   - **Primary Interface (vmbr0)**: External network access with gateway configuration
   - **Secondary Interface (vmbr1)**: Internal cluster communication without gateway

### Network Configuration

Each VM in the cluster is configured with two network interfaces:

```hcl
network_devices = [
  {
    bridge = "vmbr0"  # External network - accessible from your network
  },
  {
    bridge = "vmbr1"  # Internal cluster network - for cluster traffic
  }
]
```

#### Example Network Setup

From the example.tfvars, each VM has:

- **External IPs** (192.168.0.x/24): Accessible from your main network with gateway (192.168.0.1)
- **Internal IPs** (172.16.0.x/24): Used for cluster-internal communication

This separation provides:
- Better security by isolating cluster traffic
- Improved performance for cluster communication
- Clear network traffic separation

## File Structure

```
proxmox/talos_cluster/
├── nodes.tf                   # VM creation and configuration
├── cluster.tf                 # Talos cluster configuration and bootstrap
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output values including client configuration
├── provider.tf                # Provider configurations
├── patches.tf                 # Patches for Talos configuration
├── secrets.tf                 # Proxmox API user/token resources for CCM/CSI
├── .env/
│   ├── example.tfvars         # Example configuration
│   └── manifests/             # Generated manifests (git-ignored, no longer used)
└── README.md                  # This documentation
```

## Key Components

### VM Configuration ([`nodes.tf`](proxmox/talos_cluster/nodes.tf))

The module creates two types of VMs:

#### Control Plane VMs
- **CPU**: 2 cores (default) with 900 CPU units
- **Memory**: 2GB dedicated (default) with ballooning enabled
- **Storage**: 100GB virtio disk (default) on `local-cluster-zfs` datastore (default)
- **Boot**: From disk then CD-ROM (for initial Talos installation)

#### Worker VMs
- **CPU**: 2 cores (default) with 800 CPU units
- **Memory**: 2GB dedicated (default) with ballooning enabled
- **Storage**: 100GB virtio disk (default) on `local-cluster-zfs` datastore (default)
- **Boot**: From disk then CD-ROM (for initial Talos installation)

### Cluster Configuration ([`cluster.tf`](proxmox/talos_cluster/cluster.tf))

The cluster configuration handles:

1. **Machine Secrets Generation**: Creates unique secrets for the cluster
2. **Configuration Application**: Applies Talos configurations to all nodes
3. **Bootstrap Process**: Initializes the first control plane node
4. **Network Configuration**: Sets up proper subnet configurations for kubelet and etcd

### Certificate Management

The module automatically configures certificates with:

- **Machine Certificates**: Include all node IPs and hostnames as SANs
- **API Server Certificates**: Include control plane IPs and hostnames as SANs
- **Custom SANs**: Supports additional IPs and hostnames via variables

### CNI / Cilium Bootstrap

When `cilium_enabled = true`, this module applies a pre-patch that:

1. **Disables the default CNI** — sets `cluster.network.cni.name = "none"`
2. **Disables kube-proxy** — sets `cluster.proxy.disabled = true`
3. **Adds a NoExecute taint** — `node.cilium.io/agent-not-ready=true:NoExecute` on all nodes

> ⚠️ **Important**: When `cilium_enabled = true`, the cluster **will not function** until Cilium is installed. Pods cannot get IP addresses and the taint prevents scheduling. Cilium must be installed manually via helm before the cluster will work properly. See the [New Cluster Bootstrap](#new-cluster-bootstrap) section below.

Once Cilium is running and removes the taint, the cluster is functional and ready for ArgoCD installation. From that point on, Cilium is managed as an ArgoCD application via `core-deployments/00-base`.

### Proxmox API Tokens

The module creates Proxmox VE API tokens for the Proxmox CCM and CSI plugins:

- **CCM Token**: Used by the Proxmox Cloud Controller Manager for node lifecycle management
- **CSI Token**: Used by the Proxmox CSI Plugin for storage provisioning

These tokens are exported as outputs (`proxmox_ccm_token_id`, `proxmox_ccm_token_secret`, `proxmox_csi_token_id`, `proxmox_csi_token_secret`) and consumed by `core-deployments/00-base` via tofu remote state.

## Variables Structure

### Provider Configuration

- [`pve_endpoint`](proxmox/talos_cluster/variables.tf): Proxmox VE API endpoint URL (single node)
- [`pve_cluster_endpoint`](proxmox/talos_cluster/variables.tf): Proxmox VE cluster API endpoint URL
- [`terraform_state_path`](proxmox/talos_cluster/variables.tf): Local path for tofu state file

### ISO Configuration

- [`iso_node_name`](proxmox/talos_cluster/variables.tf): Proxmox node containing the Talos ISO
- [`iso_datastore_id`](proxmox/talos_cluster/variables.tf): Datastore ID for ISO storage
- [`iso_file_name`](proxmox/talos_cluster/variables.tf): Talos ISO filename
- [`talos_version`](proxmox/talos_cluster/variables.tf): Talos version for configuration generation

### Cluster Configuration ([`talos_cluster`](proxmox/talos_cluster/variables.tf))

The main cluster configuration object includes:

- **cluster_name**: Name of the Kubernetes cluster
- **cluster_endpoint**: Kubernetes API endpoint URL
- **region**: Region designator for the cluster
- **control_plane_vm_id**: Reference VM ID for IP configuration (optional)
- **dns_domain_suffix**: Domain suffix for hostnames (optional)
- **machine_install_image**: Custom Talos installation image (optional)
- **install_disk**: Target disk for Talos installation (default: /dev/sda)
- **kubelet_subnet_ip_configs**: Network interface indexes for kubelet subnets
- **etcd_subnet_ip_configs**: Network interface indexes for etcd subnets
- **kubelet_subnets**: Additional kubelet subnets
- **etcd_subnets**: Additional etcd subnets
- **machine_cert_sans**: Additional certificate SANs for machines
- **api_cert_sans**: Additional certificate SANs for API server
- **control_plane_patches**: List of custom patch filenames to apply to control plane nodes
- **node_patches**: List of custom patch filenames to apply to all cluster nodes
- **cilium_enabled**: Disables default CNI/kube-proxy and adds Cilium taint (see [CNI / Cilium Bootstrap](#cni--cilium-bootstrap))
- **talos_ccm_enabled**: Enables Talos CCM patches (kubelet cert rotation, cloud-provider: external)

### VM Configuration

#### Control Plane VMs ([`control_plane_vms`](proxmox/talos_cluster/variables.tf))

List of control plane VM objects with:
- **vm_name**: Name of the VM
- **vm_id**: Unique VM ID number
- **node_name**: Proxmox host where VM will be created
- **cpu_cores**: Number of vCPU cores (optional, default: 2)
- **memory_mb**: Memory in MB (optional, default: 2048)
- **datastore_id**: Datastore ID for the primary disk (optional, default: `local-cluster-zfs`)
- **disk_size**: Disk size in GB (optional, default: 100)
- **description**: VM description (optional)
- **cloud_init_ip_config**: Network configuration for both interfaces
- **hostpci**: List of host PCI device configurations for hardware passthrough (optional)

#### Worker VMs ([`worker_vms`](proxmox/talos_cluster/variables.tf))

List of worker VM objects with the same structure as control plane VMs.

#### Network Configuration Details

Each VM's `cloud_init_ip_config` is a list of network interface configurations:

```hcl
cloud_init_ip_config = [
  {
    ipv4 = {
      address = "192.168.0.101/24"  # External IP with CIDR
      gateway = "192.168.0.1"        # Gateway for external network
    }
  },
  {
    ipv4 = {
      address = "172.16.0.101/24"    # Internal IP (no gateway)
    }
  }
]
```

## Usage

### New Cluster Bootstrap

This is the complete workflow for bootstrapping a new cluster from scratch.

#### 1. Prepare Configuration

Copy the example configuration and customize it:

```bash
cp .env/example.tfvars .env/your-cluster.tfvars
```

#### 2. Apply Talos Cluster

```bash
tofu init
tofu apply -var-file=.env/your-cluster.tfvars
```

After this step, the cluster is bootstrapped but **CNI is disabled** and nodes are tainted. The cluster is not functional yet.

#### 3. Install Cilium (Manual)

Cilium must be installed manually before the cluster will function. Use the same values that ArgoCD will manage later:

```bash
# Get kubeconfig from talos_cluster tofu output
tofu output -raw kubeconfig > ~/.kube/config

# Install Cilium via helm with production values
helm repo add cilium https://helm.cilium.io
helm install cilium cilium/cilium --version 1.19.2 --namespace kube-system \
  -f /path/to/core-deployments/00-base/value_files/cilium.yaml

# Wait for Cilium to be ready (removes the NoExecute taint)
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cilium -n kube-system --timeout=300s
```

#### 4. Configure Talos Client

```bash
mkdir -p ~/.talos
tofu output -raw talos_client_config > ~/.talos/config
export TALOSCONFIG=~/.talos/config
```

#### 5. Install ArgoCD

Follow the first-time install instructions in `core-deployments/00-base/README.md`:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.2.0/manifests/ha/install.yaml
kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge -p '{"data":{"server.insecure":"true"}}'
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd
```

#### 6. Deploy 00-base

Deploy the base infrastructure via ArgoCD. This adopts Cilium, installs Gateway API CRDs, Talos CCM, Proxmox CCM, and Proxmox CSI:

```bash
cd core-deployments/00-base
tofu init -var-file=.env/prod.rnimbus.tfvars
tofu apply -var-file=.env/prod.rnimbus.tfvars -var githubapp_private_key="$(cat ~/secrets/rnimbus-argocd.pem)"
```

### Adding Workers to an Existing Cluster

For adding workers to an existing cluster:

```hcl
joined_worker_ids = [111, 112]  # VM IDs of already joined workers
```

This allows the module to properly manage workers that have already joined the cluster.

## Advanced Configuration

### Custom Network Subnets

For more complex network setups, you can specify custom subnets:

```hcl
talos_cluster = {
  # ... other configuration
  kubelet_subnet_ip_configs = [1]  # Use second interface for kubelet
  etcd_subnet_ip_configs = [1]     # Use second interface for etcd
  kubelet_subnets = ["172.16.0.0/24"]  # Additional kubelet subnets
  etcd_subnets = ["172.16.0.0/24"]     # Additional etcd subnets
}
```

### Certificate SANs

Add additional certificate SANs for external access:

```hcl
talos_cluster = {
  # ... other configuration
  machine_cert_sans = [
    "cluster.local.example.com",
    "192.168.0.100",
    "10.0.0.100"
  ]
  api_cert_sans = [
    "k8s-api.local.example.com",
    "192.168.0.100"
  ]
}
```

## Outputs

The module provides several outputs:

- [`kubeconfig`](proxmox/talos_cluster/outputs.tf): Raw kubeconfig for cluster access
- [`talos_cluster_kubeconfig`](proxmox/talos_cluster/outputs.tf): Full kubeconfig resource object
- [`kubeconfig_ca_certificate`](proxmox/talos_cluster/outputs.tf): kubeconfig CA certificate
- [`kubeconfig_client_certificate`](proxmox/talos_cluster/outputs.tf): kubeconfig client certificate
- [`kubeconfig_client_key`](proxmox/talos_cluster/outputs.tf): kubeconfig client key
- [`talos_client_config`](proxmox/talos_cluster/outputs.tf): Complete Talos client configuration
- [`control_plane_config`](proxmox/talos_cluster/outputs.tf): Applied control plane configuration
- [`worker_config`](proxmox/talos_cluster/outputs.tf): Applied worker configuration
- [`cluster_endpoint`](proxmox/talos_cluster/outputs.tf): Cluster API endpoint URL
- [`cluster_hostname`](proxmox/talos_cluster/outputs.tf): Cluster hostname
- [`controlplane_node_hostnames`](proxmox/talos_cluster/outputs.tf): Hostnames of control plane nodes
- [`controlplane_node_ips`](proxmox/talos_cluster/outputs.tf): IP addresses of control plane nodes
- [`proxmox_ccm_token_id`](proxmox/talos_cluster/outputs.tf): Proxmox CCM API token ID (used by 00-base)
- [`proxmox_ccm_token_secret`](proxmox/talos_cluster/outputs.tf): Proxmox CCM API token secret (used by 00-base)
- [`proxmox_csi_token_id`](proxmox/talos_cluster/outputs.tf): Proxmox CSI API token ID (used by 00-base)
- [`proxmox_csi_token_secret`](proxmox/talos_cluster/outputs.tf): Proxmox CSI API token secret (used by 00-base)
- [`talos_config_instructions`](proxmox/talos_cluster/outputs.tf): Step-by-step instructions for setting up access

## Requirements

- tofu ~> 1.6
- Proxmox VE with API access
- Talos ISO uploaded to Proxmox datastore
- Proper network bridges configured (vmbr0, vmbr1)
- Sufficient resources on Proxmox hosts

## Providers

- **bpg/proxmox** ~> 0.86: For Proxmox VE resource management
- **siderolabs/talos** ~> 0.9: For Talos cluster configuration
- **northwood-labs/corefunc** ~> 2.1: For utility functions

## Security Considerations

1. **Network Isolation**: The dual network setup provides isolation between external and cluster traffic
2. **Certificate Management**: All certificates are automatically generated with proper SANs
3. **Secure Boot**: Supports secure boot Talos images
4. **API Access**: Configure proper firewall rules for the Kubernetes API endpoint

## Troubleshooting

### Common Issues

1. **VM Boot Issues**: Ensure the Talos ISO is properly uploaded and accessible
2. **Network Configuration**: Verify bridge configurations and IP address assignments
3. **Bootstrap Failures**: Check that the control plane VM has proper network connectivity
4. **Certificate Errors**: Verify all required SANs are included in the configuration
5. **Pods Not Starting**: If `cilium_enabled = true`, ensure Cilium has been installed manually (see [New Cluster Bootstrap](#new-cluster-bootstrap))

### Debug Commands

```bash
# Check VM status
talosctl version --nodes <node_ip>

# View cluster status
talosctl cluster --nodes <node_ip>

# Check service status
talosctl service --nodes <node_ip>

# View logs
talosctl logs --nodes <node_ip> <service_name>
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.6 |
| <a name="requirement_corefunc"></a> [corefunc](#requirement\_corefunc) | ~> 2.1 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | ~> 0.86 |
| <a name="requirement_talos"></a> [talos](#requirement\_talos) | ~> 0.9.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) | ~> 0.86 |
| <a name="provider_talos"></a> [talos](#provider\_talos) | ~> 0.9.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_control_plane_vms"></a> [control\_plane\_vms](#module\_control\_plane\_vms) | github.com/rNimbus-com/homelab-iac/proxmox/modules/proxmox_virtual_machine | v0 |
| <a name="module_worker_vms"></a> [worker\_vms](#module\_worker\_vms) | github.com/rNimbus-com/homelab-iac/proxmox/modules/proxmox_virtual_machine | v0 |

## Resources

| Name | Type |
|------|------|
| [proxmox_virtual_environment_file.nodes_metadata](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file) | resource |
| [proxmox_virtual_environment_user.kubernetes_ccm](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_user) | resource |
| [proxmox_virtual_environment_user.kubernetes_csi](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_user) | resource |
| [proxmox_virtual_environment_user_token.ccm](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_user_token) | resource |
| [proxmox_virtual_environment_user_token.csi](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_user_token) | resource |
| [talos_cluster_kubeconfig.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/cluster_kubeconfig) | resource |
| [talos_machine_bootstrap.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_bootstrap) | resource |
| [talos_machine_configuration_apply.control_plane](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_configuration_apply.worker](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_secrets.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_secrets) | resource |
| [proxmox_virtual_environment_file.iso](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/data-sources/virtual_environment_file) | data source |
| [proxmox_virtual_environment_role.k8sCCM](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/data-sources/virtual_environment_role) | data source |
| [proxmox_virtual_environment_role.k8sCSI](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/data-sources/virtual_environment_role) | data source |
| [talos_client_configuration.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/client_configuration) | data source |
| [talos_machine_configuration.control_plane](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/machine_configuration) | data source |
| [talos_machine_configuration.worker](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/machine_configuration) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_control_plane_vms"></a> [control\_plane\_vms](#input\_control\_plane\_vms) | List of control plane VM configurations for the Talos Kubernetes cluster.<br/><br/>Each control plane VM object supports the following parameters:<br/><br/>- vm\_name: (Required) The name of the virtual machine. This name will be used for cluster identification and DNS resolution.<br/>- vm\_id: (Required) Unique ID of the Virtual Machine. Must be a value between 100 and 999,999,999 and unique across the entire Proxmox cluster.<br/>- node\_name: (Required) The name of the Proxmox node to assign the virtual machine to.<br/>- cpu\_cores: (Optional) The amount of vCPU / cores to assign to the the control plane VM.<br/>- memory\_mb: (Optional) The amount of memory (in MB) to assign to the the control plane VM.<br/>- datastore\_id: (Optional) The ID of the datastore used for the primary disk.<br/>- disk\_size: (Optional) Size of the worker VM's primary disk in GB.<br/>- description: (Optional) Description for the virtual machine. Defaults to "Talos control plane node".<br/>- cloud\_init\_ip\_config: (Required) List of IP configurations for cloud-init network setup.<br/>  - ipv4: (Optional) IPv4 configuration object.<br/>    - address: (Required) IPv4 address in CIDR notation (e.g., "192.168.1.10/24") or "dhcp" for autodiscovery.<br/>    - gateway: (Optional) IPv4 gateway address. Omit if address is set to "dhcp".<br/>  - ipv6: (Optional) IPv6 configuration object.<br/>    - address: (Required) IPv6 address in CIDR notation (e.g., "2001:db8::10/64") or "dhcp" for autodiscovery.<br/>    - gateway: (Optional) IPv6 gateway address. Omit if address is set to "dhcp".<br/>- hostpci: (Optional) List of host PCI device configurations for hardware passthrough.<br/>  - device: (Required) The device identifier (e.g., "hostpci0").<br/>  - id: (Required) The PCI device ID (e.g., "0000:65:00.0").<br/>  - pcie: (Optional) Whether to use PCIe mode. Defaults to false.<br/>  - rombar: (Optional) Whether to expose the ROM bar. Defaults to true.<br/>  - xvga: (Optional) Whether to use XVGA. Defaults to false.<br/><br/>Note: At least one control plane VM is required for a functional cluster. For high availability, configure 3 or more control plane VMs. | <pre>list(object({<br/>    vm_name      = string<br/>    vm_id        = number<br/>    node_name    = string<br/>    cpu_cores    = optional(number, 2)<br/>    memory_mb    = optional(number, 2048)<br/>    datastore_id = optional(string, "local-cluster-zfs")<br/>    disk_size    = optional(number, 100)<br/>    description  = optional(string, "Talos control plane node")<br/><br/>    cloud_init_ip_config = list(object({<br/>      ipv4 = optional(object({<br/>        address = string<br/>        gateway = optional(string)<br/>      }))<br/>      ipv6 = optional(object({<br/>        address = string<br/>        gateway = optional(string)<br/>      }))<br/>    }))<br/><br/>    hostpci = optional(list(object({<br/>      device = string<br/>      id     = string<br/>      pcie   = optional(bool, false)<br/>      rombar = optional(bool, true)<br/>      xvga   = optional(bool, false)<br/>    })), [])<br/><br/>  }))</pre> | n/a | yes |
| <a name="input_iso_content_type"></a> [iso\_content\_type](#input\_iso\_content\_type) | The content type of the file | `string` | `"iso"` | no |
| <a name="input_iso_datastore_id"></a> [iso\_datastore\_id](#input\_iso\_datastore\_id) | The datastore ID where ISO file is stored | `string` | `"shared-vz"` | no |
| <a name="input_iso_file_name"></a> [iso\_file\_name](#input\_iso\_file\_name) | The name of the ISO file | `string` | `"talos-v1.12.6-nocloud-amd64-secureboot.iso"` | no |
| <a name="input_iso_node_name"></a> [iso\_node\_name](#input\_iso\_node\_name) | The name of node where ISO file is located | `string` | `"pve-host-01"` | no |
| <a name="input_joined_worker_ids"></a> [joined\_worker\_ids](#input\_joined\_worker\_ids) | List of worker VM\_IDs that have already joined the cluster. This is needed because workers initially need to be configured using their VM's DNS / IP endpoint but once joined need to be managed through a control plane endpoint. | `list(number)` | `[]` | no |
| <a name="input_pve_cluster_endpoint"></a> [pve\_cluster\_endpoint](#input\_pve\_cluster\_endpoint) | The Cluster Proxmox VE API endpoint URL. | `string` | n/a | yes |
| <a name="input_pve_endpoint"></a> [pve\_endpoint](#input\_pve\_endpoint) | The Proxmox VE API endpoint URL. Usually a single node. | `string` | n/a | yes |
| <a name="input_talos_cluster"></a> [talos\_cluster](#input\_talos\_cluster) | Talos cluster configuration settings.<br/><br/>- cluster\_name: The name of the Kubernetes cluster<br/>- cluster\_endpoint: The kubernetes API endpoint of the cluster. For multiple control plane VMs, this is the DNS A record assigned for each VM, or the load balancer if you have one. Example: `https://cluster.local.example.com:6443`<br/>- region: Region designator for the cluster. Added as metadata to the VM and used to create labels for Nodes.<br/>- control\_plane\_vm\_id: The control plane Virtual Machine's vm\_id to reference for ip configuration. If not set, uses the first control plane VM.<br/>- dns\_domain\_suffix: The domain suffix to append to the Virtual Machine names prior to adding them to the certSANS lists. Starts with a '.'. If not set, then the VM names are added as is. (Example: `.local.example.com`).<br/>- machine\_install\_image: The Talos machine installation image to use. Uses the default configure image if not set. Needed for secureboot.<br/>- install\_disk: The disk the talos os will be installed to ('/dev/sda' by default).<br/>- kubelet\_subnet\_ip\_configs: The indexes of ip4 address cloud-init configuration for virtual machine that should be listed as valid subnets for kublet Node IPs.<br/>- etcd\_subnet\_ip\_configs: The indexes of ip4 address cloud-init configuration for virtual machine that should be listed as valid subnets for etcd advertisedSubnets.<br/>- kubelet\_subnets: List of ip4 subnets for kubelet Node IPs. At least kubelet\_subnets or kubelet\_subnet\_ip\_configs must be provided. If both are provided, results are merged.<br/>- etcd\_subnets: List of ip4 subnets for etcd advertisedSubnets. Same rules apply for this and etcd\_subnet\_ip\_configs.<br/>- machine\_cert\_sans: List of IP addresses and hostnames to add as alternate subjects to the generated certificate(s) for each machine / VM.<br/>- api\_cert\_sans: List of IP addresses and hostnames to add as alternate subjects to the generated certificate(s) for the kubernetes API.<br/>- control\_plane\_patches: List of custom patch filenames to apply to control plane nodes.<br/>- node\_patches: List of custom patch filenames to apply to all cluster nodes.<br/>- talos\_ccm\_enabled: Enables installation of the node-csr-approval controller from the [Talos Cloud Controller Manager](https://github.com/siderolabs/talos-cloud-controller-manager/blob/main/README.md). Enables certificate renewal for your nodes. Required for metrics server. <br/>- cilium\_enabled: Disables the default CNI (flannel) and kube-proxy, and adds a `node.cilium.io/agent-not-ready=true:NoExecute` taint to all nodes. **Cilium must be installed manually via helm before the cluster will function properly.** See the bootstrap instructions in the README. Once ArgoCD is installed, Cilium is managed by `core-deployments/00-base`. | <pre>object({<br/>    cluster_name              = string<br/>    cluster_endpoint          = string<br/>    region                    = string<br/>    control_plane_vm_id       = optional(number, null)<br/>    dns_domain_suffix         = optional(string, null)<br/>    machine_install_image     = optional(string, null)<br/>    install_disk              = optional(string, null)<br/>    kubelet_subnet_ip_configs = optional(list(number), [])<br/>    etcd_subnet_ip_configs    = optional(list(number), [])<br/>    kubelet_subnets           = optional(list(string), [])<br/>    etcd_subnets              = optional(list(string), [])<br/>    machine_cert_sans         = optional(list(string), [])<br/>    api_cert_sans             = optional(list(string), [])<br/>    control_plane_patches     = optional(list(string), [])<br/>    node_patches              = optional(list(string), [])<br/>    talos_ccm_enabled         = optional(bool, true)<br/>    cilium_enabled            = optional(bool, false)<br/>  })</pre> | n/a | yes |
| <a name="input_talos_version"></a> [talos\_version](#input\_talos\_version) | The version of talos features to use in generated machine configuration. | `string` | n/a | yes |
| <a name="input_terraform_state_path"></a> [terraform\_state\_path](#input\_terraform\_state\_path) | The local path for storing Terraform state file | `string` | `".terraform/terraform.tfstate"` | no |
| <a name="input_worker_vms"></a> [worker\_vms](#input\_worker\_vms) | List of worker VM configurations for the Talos Kubernetes cluster.<br/><br/>Each worker VM object supports the following parameters:<br/><br/>- vm\_name: (Required) The name of the virtual machine. This name will be used for cluster identification and DNS resolution.<br/>- vm\_id: (Required) Unique ID of the Virtual Machine. Must be a value between 100 and 999,999,999 and unique across the entire Proxmox cluster.<br/>- node\_name: (Required) The name of the Proxmox node to assign the virtual machine to.<br/>- cpu\_cores: (Optional) The amount of vCPU / cores to assign to the the worker VM.<br/>- memory\_mb: (Optional) The amount of memory (in MB) to assign to the the worker VM.<br/>- datastore\_id: (Optional) The ID of the datastore used for the primary disk.<br/>- disk\_size: (Optional) Size of the worker VM's primary disk in GB.<br/>- description: (Optional) Description for the virtual machine. Defaults to "Talos worker".<br/>- cloud\_init\_ip\_config: (Required) List of IP configurations for cloud-init network setup.<br/>  - ipv4: (Optional) IPv4 configuration object.<br/>    - address: (Required) IPv4 address in CIDR notation (e.g., "192.168.1.20/24") or "dhcp" for autodiscovery.<br/>    - gateway: (Optional) IPv4 gateway address. Omit if address is set to "dhcp".<br/>  - ipv6: (Optional) IPv6 configuration object.<br/>    - address: (Required) IPv6 address in CIDR notation (e.g., "2001:db8::20/64") or "dhcp" for autodiscovery.<br/>    - gateway: (Optional) IPv6 gateway address. Omit if address is set to "dhcp".<br/>- hostpci: (Optional) List of host PCI device configurations for hardware passthrough.<br/>  - device: (Required) The device identifier (e.g., "hostpci0").<br/>  - id: (Required) The PCI device ID (e.g., "0000:65:00.0").<br/>  - pcie: (Optional) Whether to use PCIe mode. Defaults to false.<br/>  - rombar: (Optional) Whether to expose the ROM bar. Defaults to true.<br/>  - xvga: (Optional) Whether to use XVGA. Defaults to false.<br/><br/>Note: Worker VMs are optional but recommended for running container workloads. They can be scaled horizontally to handle increased workload demands. | <pre>list(object({<br/>    vm_name      = string<br/>    vm_id        = number<br/>    node_name    = string<br/>    cpu_cores    = optional(number, 2)<br/>    memory_mb    = optional(number, 2048)<br/>    datastore_id = optional(string, "local-cluster-zfs")<br/>    disk_size    = optional(number, 100)<br/>    description  = optional(string, "Talos worker")<br/><br/>    cloud_init_ip_config = list(object({<br/>      ipv4 = optional(object({<br/>        address = string<br/>        gateway = optional(string)<br/>      }))<br/>      ipv6 = optional(object({<br/>        address = string<br/>        gateway = optional(string)<br/>      }))<br/>    }))<br/><br/>    hostpci = optional(list(object({<br/>      device = string<br/>      id     = string<br/>      pcie   = optional(bool, false)<br/>      rombar = optional(bool, true)<br/>      xvga   = optional(bool, false)<br/>    })), [])<br/><br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Endpoint of the cluster in the format of https://cluster.local.example.com:6443 |
| <a name="output_cluster_hostname"></a> [cluster\_hostname](#output\_cluster\_hostname) | The hostname of the cluster. Example: cluster.local.example.com. |
| <a name="output_control_plane_config"></a> [control\_plane\_config](#output\_control\_plane\_config) | n/a |
| <a name="output_controlplane_node_hostnames"></a> [controlplane\_node\_hostnames](#output\_controlplane\_node\_hostnames) | Hostnames of the control plane nodes. |
| <a name="output_controlplane_node_ips"></a> [controlplane\_node\_ips](#output\_controlplane\_node\_ips) | IP Addresses of the control plane nodes. |
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | n/a |
| <a name="output_kubeconfig_ca_certificate"></a> [kubeconfig\_ca\_certificate](#output\_kubeconfig\_ca\_certificate) | n/a |
| <a name="output_kubeconfig_client_certificate"></a> [kubeconfig\_client\_certificate](#output\_kubeconfig\_client\_certificate) | n/a |
| <a name="output_kubeconfig_client_key"></a> [kubeconfig\_client\_key](#output\_kubeconfig\_client\_key) | n/a |
| <a name="output_proxmox_ccm_token_id"></a> [proxmox\_ccm\_token\_id](#output\_proxmox\_ccm\_token\_id) | Proxmox API tokens - exported for use by core-deployments/00-base |
| <a name="output_proxmox_ccm_token_secret"></a> [proxmox\_ccm\_token\_secret](#output\_proxmox\_ccm\_token\_secret) | n/a |
| <a name="output_proxmox_csi_token_id"></a> [proxmox\_csi\_token\_id](#output\_proxmox\_csi\_token\_id) | n/a |
| <a name="output_proxmox_csi_token_secret"></a> [proxmox\_csi\_token\_secret](#output\_proxmox\_csi\_token\_secret) | n/a |
| <a name="output_talos_client_config"></a> [talos\_client\_config](#output\_talos\_client\_config) | n/a |
| <a name="output_talos_cluster_kubeconfig"></a> [talos\_cluster\_kubeconfig](#output\_talos\_cluster\_kubeconfig) | n/a |
| <a name="output_talos_config_instructions"></a> [talos\_config\_instructions](#output\_talos\_config\_instructions) | n/a |
| <a name="output_worker_config"></a> [worker\_config](#output\_worker\_config) | n/a |
<!-- END_TF_DOCS -->