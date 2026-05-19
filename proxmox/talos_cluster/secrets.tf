data "proxmox_virtual_environment_role" "k8sCCM" {
  role_id = "k8sCCM"
}
data "proxmox_virtual_environment_role" "k8sCSI" {
  role_id = "k8sCSI"
}

# Create Users needed by Proxmox CCM and CSI
resource "proxmox_virtual_environment_user" "kubernetes_ccm" {
  comment = "Proxmox Cloud Controller Manager - Managed by OpenTofu"
  email   = "kubernetes_ccm@pve"
  enabled = true
  user_id = "kubernetes_ccm@pve"
  acl {
    path      = "/"
    propagate = true
    role_id   = data.proxmox_virtual_environment_role.k8sCCM.id
  }
}

resource "proxmox_virtual_environment_user" "kubernetes_csi" {
  comment = "Proxmox CSI Plugin token - Managed by OpenTofu"
  email   = "kubernetes_csi@pve"
  enabled = true
  user_id = "kubernetes_csi@pve"
  acl {
    path      = "/"
    propagate = true
    role_id   = data.proxmox_virtual_environment_role.k8sCSI.id
  }
}

resource "proxmox_virtual_environment_user_token" "ccm" {
  comment               = "Proxmox Cloud Controller Manager - Managed by OpenTofu"
  token_name            = "ccm"
  user_id               = proxmox_virtual_environment_user.kubernetes_ccm.user_id
  privileges_separation = false
}

resource "proxmox_virtual_environment_user_token" "csi" {
  comment               = "Proxmox CSI Plugin token - Managed by OpenTofu"
  token_name            = "csi"
  user_id               = proxmox_virtual_environment_user.kubernetes_csi.user_id
  privileges_separation = false
}
