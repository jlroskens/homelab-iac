# Talos Kubernetes Cluster on Proxmox

This Terraform configuration creates a highly available Talos Kubernetes cluster on Proxmox VE, consisting of control plane and worker nodes with dual network interfaces for optimal performance and security.

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
├── main.tf          # VM creation and configuration
├── cluster.tf       # Talos cluster configuration and bootstrap
├── variables.tf     # Variable definitions
├── outputs.tf       # Output values including client configuration
├── provider.tf      # Provider configurations
└── .env/
    └── example.tfvars  # Example configuration
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

## Variables Structure

### Provider Configuration

- [`pve_endpoint`](proxmox/talos_cluster/variables.tf:2): Proxmox VE API endpoint URL
- [`terraform_state_path`](proxmox/talos_cluster/variables.tf:7): Local path for Terraform state file

### ISO Configuration

- [`iso_node_name`](proxmox/talos_cluster/variables.tf:14): Proxmox node containing the Talos ISO
- [`iso_datastore_id`](proxmox/talos_cluster/variables.tf:20): Datastore ID for ISO storage
- [`iso_file_name`](proxmox/talos_cluster/variables.tf:32): Talos ISO filename
- [`talos_version`](proxmox/talos_cluster/variables.tf:38): Talos version for configuration generation

### Cluster Configuration ([`talos_cluster`](proxmox/talos_cluster/variables.tf:44))

The main cluster configuration object includes:

- **cluster_name**: Name of the Kubernetes cluster
- **cluster_endpoint**: Kubernetes API endpoint URL
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

### VM Configuration

#### Control Plane VMs ([`control_plane_vms`](proxmox/talos_cluster/variables.tf:85))

List of control plane VM objects with:
- **vm_name**: Name of the VM
- **vm_id**: Unique VM ID number
- **node_name**: Proxmox host where VM will be created
- **description**: VM description (optional)
- **cloud_init_ip_config**: Network configuration for both interfaces

#### Worker VMs ([`worker_vms`](proxmox/talos_cluster/variables.tf:108))

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

### 1. Prepare Configuration

Copy the example configuration and customize it:

```bash
cp .env/example.tfvars .env/your-cluster.tfvars
```

Edit the configuration file with your specific:
- Proxmox endpoint and credentials
- Network settings (IP addresses, gateways)
- VM names and IDs
- Cluster name and endpoint

### 2. Initialize and Apply

```bash
terraform init
terraform apply -var-file=.env/your-cluster.tfvars
```

### 3. Configure Talos Client

After successful deployment, configure your Talos client:

```bash
# Create talos config directory
mkdir -p ~/.talos

# Extract the client configuration
terraform output -raw talos_client_config > ~/.talos/config

# Set environment variable
export TALOSCONFIG=~/.talos/config

# Generate kubeconfig
talosctl kubeconfig --nodes <bootstrap_endpoint>
```

Or use the provided one-liner from the output:

```bash
mkdir -p ~/.talos && terraform output -raw talos_client_config > ~/.talos/config && export TALOSCONFIG=~/.talos/config && talosctl kubeconfig --nodes <bootstrap_endpoint>
```

## Outputs

The module provides several outputs:

- [`talos_client_config`](proxmox/talos_cluster/outputs.tf:7): Complete Talos client configuration
- [`control_plane_config`](proxmox/talos_cluster/outputs.tf:12): Applied control plane configuration
- [`worker_config`](proxmox/talos_cluster/outputs.tf:16): Applied worker configuration
- [`client_configuration`](proxmox/talos_cluster/outputs.tf:21): Client configuration details
- [`talos_config_instructions`](proxmox/talos_cluster/outputs.tf:41): Step-by-step instructions for setting up access

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

### Worker Node Management

For adding workers to an existing cluster:

```hcl
joined_worker_ids = [111, 112]  # VM IDs of already joined workers
```

This allows the module to properly manage workers that have already joined the cluster.

## Requirements

- Terraform ~> 1.6
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
```