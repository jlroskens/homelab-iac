resource "proxmox_virtual_environment_download_file" "downloads" {
  for_each                = { for idx, file in var.pve_download_files : idx => file }
  content_type            = each.value.content_type
  datastore_id            = each.value.datastore_id
  node_name               = each.value.node_name
  url                     = each.value.url
  checksum                = each.value.checksum
  checksum_algorithm      = each.value.checksum_algorithm
  decompression_algorithm = each.value.decompression_algorithm
  file_name               = each.value.file_name
  overwrite               = each.value.overwrite
  overwrite_unmanaged     = each.value.overwrite_unmanaged
  upload_timeout          = each.value.upload_timeout
  verify                  = each.value.verify
}

