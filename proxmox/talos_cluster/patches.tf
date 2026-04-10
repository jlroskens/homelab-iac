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
  # Create patch from the cilium chart manifest file and gateway CRDs
  cilium_patch = var.talos_cluster.cilium_enabled == false ? [] : [
    <<-EOT
      cluster:
        extraManifests:
          - https://github.com/kubernetes-sigs/gateway-api/releases/download/${var.talos_cluster.cilium_version}/standard-install.yaml
          ${var.talos_cluster.cilium_tlsroute_enabled ? "- https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${var.talos_cluster.cilium_version}/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml" : ""}
        inlineManifests:
          - name: cilium
            contents: |
              ${indent(8, file(var.talos_cluster.cilium_manifest_file))}
    EOT
  ]

  cilium_ip_annoucement = var.talos_cluster.cilium_ip_pool == null ? [] : [
    <<-EOT
      cluster:
        inlineManifests:
          - name: default-ipam-l2-announce
            contents: |
              apiVersion: cilium.io/v2alpha1
              kind: CiliumL2AnnouncementPolicy
              metadata:
                name: default-announcment-policy
                namespace: kube-system
              spec:
                externalIPs: true
                loadBalancerIPs: true
              ---
              apiVersion: cilium.io/v2alpha1
              kind: CiliumLoadBalancerIPPool
              metadata:
                name: default-pool
              spec:
                blocks:
                  - start: ${var.talos_cluster.cilium_ip_pool.start_ip}
                    stop: ${var.talos_cluster.cilium_ip_pool.end_ip}
                    cidr: ${var.talos_cluster.cilium_ip_pool.cidr_block}
    EOT
  ]

  # Patches for Proxmox CCM
  proxmox_providerid_patches = var.talos_cluster.talos_ccm_enabled == false ? {} : {
    for id, vm in local.all_vms_map : id =>
    <<-EOT
      machine:
        kubelet:
          extraArgs:
            provider-id: proxmox://${var.talos_cluster.region}/${id}
      EOT
  }
  proxmox_ccm_secrets_patch = var.talos_cluster.proxmox_ccm_enabled == false ? [] : [
    <<-EOT
      cluster:
        inlineManifests:
          - name: proxmox-ccm-user-token
            contents: |
              ${indent(8, local.proxmox_ccm_secret)}
    EOT
  ]
  proxmox_ccm_patch = var.talos_cluster.proxmox_ccm_enabled == false ? [] : [
    <<-EOT
      cluster:
        inlineManifests:
          - name: proxmox-cloud-controller-manager
            contents: |
              ${indent(8, file(var.talos_cluster.proxmox_ccm_manifest))}
    EOT
  ]
  # Patches for Talos CCM
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
      cluster:
        inlineManifests:
          - name: talos-cloud-controller-manager
            contents: |
              ${indent(8, file(var.talos_cluster.talos_ccm_manifest))}
    EOT
  ]
  # Patches for Proxmox CSI Plugin
  proxmox_csi_secrets_patch = var.talos_cluster.proxmox_csi_enabled == false ? [] : [
    <<-EOT
      cluster:
        inlineManifests:
          - name: proxmox-csi-user-token
            contents: |
              ${indent(8, local.proxmox_csi_secret)}
    EOT
  ]

  proxmox_csi_patch = var.talos_cluster.proxmox_csi_enabled == false ? [] : [
    <<-EOT
      cluster:
        inlineManifests:
          - name: proxmox-csi-plugin
            contents: |
              ${indent(8, file(var.talos_cluster.proxmox_csi_manifest))}
    EOT
  ]

  # ArgoCD Patch
  argocd_patch = var.talos_cluster.argocd_enabled == false ? [] : [
    <<-EOT
      cluster:
        inlineManifests:
          - name: argocd
            contents: |
              ${indent(8, file(var.talos_cluster.argocd_manifest_file))}
    EOT
  ]
  # Load Custom patches from file, if any were provided
  custom_control_plane_patches = [for f in var.talos_cluster.control_plane_patches : file(f)]

  # Load custom patches that get applied to all nodes
  node_patches = [for f in var.talos_cluster.node_patches : file(f)]

  # Merge control pane patches into a single list.
  control_plane_patches = concat(
    local.proxmox_ccm_secrets_patch,
    local.proxmox_ccm_patch,
    local.talos_ccm_all_patch,
    local.talos_ccm_cp_patch,
    local.cilium_pre_patch,
    local.cilium_patch,
    local.cilium_ip_annoucement,
    local.proxmox_csi_secrets_patch,
    local.proxmox_csi_patch,
    local.argocd_patch,
    local.custom_control_plane_patches,
    local.node_patches
  )
  worker_patches = concat(
    local.talos_ccm_all_patch,
    local.node_patches
  )
}