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
├── main.tf                    # VM creation and configuration
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

### VM Configuration ([`main.tf`](proxmox/talos_cluster/main.tf))

The module creates two types of VMs:

#### Control Plane VMs
- **CPU**: 1 core with 900 CPU units
- **Memory**: 2GB dedicated with ballooning enabled
- **Storage**: 100GB virtio disk
- **Boot**: From disk then CD-ROM (for initial Talos installation)

#### Worker VMs
- **CPU**: 2 cores with 800 CPU units
- **Memory**: 8GB dedicated with ballooning enabled
- **Storage**: 100GB virtio disk
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

When `cilium_enabled = true` (the default), this module applies a pre-patch that:

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
- **cilium_enabled**: Disables default CNI/kube-proxy and adds Cilium taint (see [CNI / Cilium Bootstrap](#cni--cilium-bootstrap))
- **talos_ccm_enabled**: Enables Talos CCM patches (kubelet cert rotation, cloud-provider: external)

### VM Configuration

#### Control Plane VMs ([`control_plane_vms`](proxmox/talos_cluster/variables.tf))

List of control plane VM objects with:
- **vm_name**: Name of the VM
- **vm_id**: Unique VM ID number
- **node_name**: Proxmox host where VM will be created
- **description**: VM description (optional)
- **cloud_init_ip_config**: Network configuration for both interfaces

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