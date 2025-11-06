data "local_file" "env_files" {
  for_each = { for key, file in local.pve_files : key => file if !file.sensitive }

  filename = "${path.module}/${each.value.source_file.path}"
}
data "local_sensitive_file" "env_files" {
  for_each = { for key, file in local.pve_files : key => file if file.sensitive }

  filename = "${path.module}/${each.value.source_file.path}"
}

locals {
  # Convert list of pve_files to a map
  pve_files      = { for file in var.pve_files : file.source_file.path => file }
  env_files_data = merge(data.local_file.env_files, data.local_sensitive_file.env_files)

  raw_files           = { for file in var.pve_raw_files : file.source_raw.file_name => file if !file.sensitive }
  raw_files_sensitive = { for file in var.pve_raw_files : file.source_raw.file_name => file if file.sensitive }
}

resource "proxmox_virtual_environment_file" "env_files" {
  for_each       = local.pve_files
  content_type   = each.value.content_type
  datastore_id   = each.value.datastore_id
  node_name      = each.value.node_name
  overwrite      = each.value.overwrite
  timeout_upload = each.value.timeout_upload

  dynamic "source_file" {
    for_each = each.value.source_file != null ? [each.value.source_file] : []
    content {
      path      = local.env_files_data[each.key].filename
      checksum  = local.env_files_data[each.key].content_sha256
      file_name = source_file.value.file_name
      insecure  = source_file.value.insecure
      min_tls   = source_file.value.min_tls
    }
  }

  file_mode = each.value.file_mode
}

resource "proxmox_virtual_environment_file" "env_files_raw" {
  for_each       = local.raw_files
  content_type   = each.value.content_type
  datastore_id   = each.value.datastore_id
  node_name      = each.value.node_name
  overwrite      = each.value.overwrite
  timeout_upload = each.value.timeout_upload

  dynamic "source_raw" {
    for_each = each.value.source_raw != null ? [each.value.source_raw] : []
    content {
      data      = source_raw.value.data
      file_name = source_raw.value.file_name
      resize    = source_raw.value.resize
    }
  }

  file_mode = each.value.file_mode
}

resource "proxmox_virtual_environment_file" "env_files_raw_sensitive" {
  for_each       = local.raw_files_sensitive
  content_type   = each.value.content_type
  datastore_id   = each.value.datastore_id
  node_name      = each.value.node_name
  overwrite      = each.value.overwrite
  timeout_upload = each.value.timeout_upload

  dynamic "source_raw" {
    for_each = each.value.source_raw != null ? [each.value.source_raw] : []
    content {
      data      = sensitive(source_raw.value.data)
      file_name = source_raw.value.file_name
      resize    = source_raw.value.resize
    }
  }

  file_mode = each.value.file_mode
}

output "env_files" {
  value = [for key, file in proxmox_virtual_environment_file.env_files : file.id]
}

output "raw_env_file_ids" {
  value = concat([for key, file in proxmox_virtual_environment_file.env_files_raw : file.id],
  [for key, file in proxmox_virtual_environment_file.env_files_raw_sensitive : file.id])
}