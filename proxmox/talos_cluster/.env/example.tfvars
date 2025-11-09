# Proxmox provider configuration
pve_endpoint="https://pve-host-01.proxmox.local.example.com:8006"
terraform_state_path=".terraform/talos_virtual_machines_cluster_example.tfstate"

# Proxmox ISO file configuration
iso_node_name    = "pve-host-01"
iso_datastore_id = "shared-vz"
iso_content_type = "iso"
iso_file_name    = "talos-v1.11.3-nocloud-amd64-secureboot.iso"

talos_version = "1.11.3"

# Talos cluster configuration
talos_cluster = {
  cluster_name = "example"
  cluster_endpoint = "https://cluster.local.example.com:6443"
  control_plane_vm_id = 101
  dns_domain_suffix = ".cluster.local.example.com"
  machine_install_image = "factory.talos.dev/nocloud-installer-secureboot/aeec243e3a4c2a14f9ba74b1a8c7662f03eea658a7ea5f1c26fdd491280c88f8:v1.11.3"
  install_disk = "/dev/vda"
  kubelet_subnet_ip_configs = [1]
  etcd_subnet_ip_configs = [1]
  kubelet_subnets = []
  etcd_subnets = []
  machine_cert_sans = ["cluster.local.example.com"]
  api_cert_sans = ["cluster.local.example.com"]
  cilium_enabled = true
  talos_ccm_enabled = true
  control_plane_patches = [".env/example.ipam-announce-patch.yml"]
  cilium_ip_pool = {
    start_ip = "192.168.12.130"
    end_ip = "192.168.12.149"
  }
  cilium_tlsroute_enabled = true
  argocd_enabled = true
}

joined_worker_ids = []

# Control plane VM configurations
control_plane_vms = [
  {
    vm_name   = "talos-ctrlp-1"
    vm_id     = 101
    node_name = "pve-host-01"
    description = "Talos control plane 1"
    cloud_init_ip_config = [
      {
        ipv4 = {
          address = "192.168.0.101/24"
          gateway = "192.168.0.1"
        }
      },
      {
        ipv4 = {
          address = "172.16.0.101/24"
        }
      }
    ]
  },
  {
    vm_name   = "talos-ctrlp-2"
    vm_id     = 102
    node_name = "pve-host-02"
    description = "Talos control plane 2"
    cloud_init_ip_config = [
      {
        ipv4 = {
          address = "192.168.0.102/24"
          gateway = "192.168.0.1"
        }
      },
      {
        ipv4 = {
          address = "172.16.0.102/24"
        }
      }
    ]
  },
  {
    vm_name   = "talos-ctrlp-3"
    vm_id     = 102
    node_name = "pve-host-03"
    description = "Talos control plane 3"
    cloud_init_ip_config = [
      {
        ipv4 = {
          address = "192.168.0.103/24"
          gateway = "192.168.0.1"
        }
      },
      {
        ipv4 = {
          address = "172.16.0.103/24"
        }
      }
    ]
  }
]

# Worker VM configurations
worker_vms = [
  {
    vm_name   = "talos-worker-1"
    vm_id     = 111
    node_name = "pve-host-01"
    description = "Talos worker 1"
    cloud_init_ip_config = [
      {
        ipv4 = {
          address = "192.168.0.111/24"
          gateway = "192.168.0.1"
        }
      },
      {
        ipv4 = {
          address = "172.16.0.111/24"
        }
      }
    ]
  },
  {
    vm_name   = "talos-worker-2"
    vm_id     = 112
    node_name = "pve-host-02"
    description = "Talos worker 2"
    cloud_init_ip_config = [
      {
        ipv4 = {
          address = "192.168.0.112/24"
          gateway = "192.168.0.1"
        }
      },
      {
        ipv4 = {
          address = "172.16.0.112/24"
        }
      }
    ]
  },
  {
    vm_name   = "talos-worker-3"
    vm_id     = 113
    node_name = "pve-host-03"
    description = "Talos worker 3"
    cloud_init_ip_config = [
      {
        ipv4 = {
          address = "192.168.0.113/24"
          gateway = "192.168.0.1"
        }
      },
      {
        ipv4 = {
          address = "172.16.0.113/24"
        }
      }
    ]
  }
]