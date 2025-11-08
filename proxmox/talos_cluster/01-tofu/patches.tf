###  Config Patches for Control Plane  ###
locals {
  # Control Plane Patches
  cilium_pre_patch = var.talos_cluster.cilium_enabled == false ? [] : [yamlencode({
    cluster = {
      network = {
        cni = { name = "none" }
      }
      proxy = { disabled = true }
    }
  })]
  # Inline cilium deployment patch
  cilium_patch = var.talos_cluster.cilium_enabled == false ? [] : [
    <<EOT
cluster:
  inlineManifests:
    - name: cilium
      contents: |
        ${indent(8, file(var.talos_cluster.cilium_manifest_file))}
    EOT
  ]

  # Patch for Talos CCM
  talos_ccm_patch = var.talos_cluster.talos_ccm_enabled == false ? [] : [
    <<EOT
machine:
  kubelet:
    extraArgs:
      rotate-server-certificates: true
      # cloud-provider: external
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
  # Load Custom patches from file, if any were provided
  custom_control_plane_patches = [ for f in var.talos_cluster.control_plane_patches : file(f) ]

  # Merge control pane patches into a single list.
  control_plane_patches = concat(local.talos_ccm_patch, local.cilium_pre_patch, local.cilium_patch, local.custom_control_plane_patches)
}