###  Config Patches for Control Plane  ###
locals {
  # Control Plane Patches
  # Disables default cni and kubeproxy. Adds a taint to prevent scheduling until cilium is installed and running
  cilium_pre_patch = var.talos_cluster.cilium_enabled == false ? [] : [yamlencode({
    machine = {
      nodeTaints = {
        "node.cilium.io/agent-not-ready" = "true:NoExecute"
      }
    }
    cluster = {
      network = {
        cni = { name = "none" }
      }
      proxy = { disabled = true }
    }
  })]
  # Patches for Talos CCM
  # Patches for Proxmox CCM (provider-id on kubelets - gated on talos_ccm_enabled for CSR approval)
  proxmox_providerid_patches = var.talos_cluster.talos_ccm_enabled == false ? {} : {
    for id, vm in local.all_vms_map : id =>
    <<-EOT
      machine:
        kubelet:
          extraArgs:
            provider-id: proxmox://${var.talos_cluster.region}/${id}
      EOT
  }

  talos_ccm_all_patch = var.talos_cluster.talos_ccm_enabled == false ? [] : [
    <<-EOT
      machine:
        kubelet:
          extraArgs:
            rotate-server-certificates: true
            cloud-provider: external
          extraConfig:
            imageGCHighThresholdPercent: 70
            imageGCLowThresholdPercent: 50
            shutdownGracePeriod: 60s
            topologyManagerPolicy: best-effort
            topologyManagerScope: container
            cpuManagerPolicy: static
            allowedUnsafeSysctls: [net.core.somaxconn]
    EOT
  ]
  talos_ccm_cp_patch = var.talos_cluster.talos_ccm_enabled == false ? [] : [
    <<-EOT
      machine:
        features:
          kubernetesTalosAPIAccess:
            enabled: true
            allowedRoles:
              - os:reader
            allowedKubernetesNamespaces:
              - kube-system
    EOT
  ]

  # Load Custom patches from file, if any were provided
  custom_control_plane_patches = [for f in var.talos_cluster.control_plane_patches : file(f)]

  # Load custom patches that get applied to all nodes
  node_patches = [for f in var.talos_cluster.node_patches : file(f)]

  # Merge control pane patches into a single list.
  control_plane_patches = concat(
    local.talos_ccm_all_patch,
    local.talos_ccm_cp_patch,
    local.cilium_pre_patch,
    local.custom_control_plane_patches,
    local.node_patches
  )
  worker_patches = concat(
    local.talos_ccm_all_patch,
    local.node_patches
  )
}