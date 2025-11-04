# variable "pve_endpoint" {
#   type        = string
#   description = "Endpoint of the Proxmox host. Example: https://10.0.0.2:8006/"
# }

variable "state_file" {
  type        = string
  description = "Path to the terraform state file."
  default     = ".terraform/terraform.tfstate"
}

variable "pve_endpoint" {
  type        = string
  description = "Endpoint of the Proxmox host. Example: https://10.0.0.2:8006/"
}

variable "pve_files" {
  description = "List of local files to upload to Proxmox VE storage."
  type = list(object({
    content_type   = optional(string, "snippets")
    datastore_id   = string
    file_mode      = optional(string)
    node_name      = string
    overwrite      = optional(bool, true)
    timeout_upload = optional(number, 1800)
    sensitive      = optional(bool, false)

    source_file = optional(object({
      checksum  = optional(string)
      file_name = optional(string)
      insecure  = optional(bool, false)
      min_tls   = optional(string, "1.3")
      path      = string
    }), null)
  }))

  validation {
    condition = alltrue([
      for file in var.pve_files : contains([
        "backup", "iso", "snippets", "import", "vztmpl"
      ], file.content_type)
    ])
    error_message = "Content type must be one of: backup, iso, snippets, import, vztmpl."
  }


  validation {
    condition = alltrue([
      for file in var.pve_files : file.source_file != null ? file.source_file.path != null : true
    ])
    error_message = "source_file.path is required when source_file is specified."
  }


  validation {
    condition = alltrue([
      for file in var.pve_files : file.source_file != null && file.source_file.min_tls != null ? contains([
        "1.0", "1.1", "1.2", "1.3"
      ], file.source_file.min_tls) : true
    ])
    error_message = "source_file.min_tls must be one of: 1.0, 1.1, 1.2, 1.3."
  }

  validation {
    condition = alltrue([
      for file in var.pve_files : file.file_mode != null ? can(regex("^[0-7]{3,4}$", file.file_mode)) : true
    ])
    error_message = "file_mode must be in octal format (e.g., 0700 or 600)."
  }

  validation {
    condition = alltrue([
      for file in var.pve_files : file.timeout_upload != null ? file.timeout_upload > 0 : true
    ])
    error_message = "timeout_upload must be a positive number."
  }
}

variable "pve_raw_files" {
  description = "List of raw files to upload to Proxmox VE storage"
  type = list(object({
    content_type   = optional(string, "snippets")
    datastore_id   = string
    file_mode      = optional(string)
    node_name      = string
    overwrite      = optional(bool, true)
    timeout_upload = optional(number, 1800)
    sensitive      = optional(bool, false)

    source_raw = optional(object({
      data      = string
      file_name = string
      resize    = optional(number)
    }), null)
  }))

  validation {
    condition = alltrue([
      for file in var.pve_raw_files : contains([
        "backup", "iso", "snippets", "import", "vztmpl"
      ], file.content_type)
    ])
    error_message = "Content type must be one of: backup, iso, snippets, import, vztmpl."
  }

  validation {
    condition = alltrue([
      for file in var.pve_raw_files : file.source_raw != null ? file.source_raw.data != null && file.source_raw.file_name != null : true
    ])
    error_message = "source_raw.data and source_raw.file_name are required when source_raw is specified."
  }

  validation {
    condition = alltrue([
      for file in var.pve_raw_files : file.file_mode != null ? can(regex("^[0-7]{3,4}$", file.file_mode)) : true
    ])
    error_message = "file_mode must be in octal format (e.g., 0700 or 600)."
  }

  validation {
    condition = alltrue([
      for file in var.pve_raw_files : file.timeout_upload != null ? file.timeout_upload > 0 : true
    ])
    error_message = "timeout_upload must be a positive number."
  }
}

variable "pve_download_files" {
  description = "List of Proxmox VE files to download"
  type = list(object({
    content_type = string
    datastore_id = string
    node_name    = string
    url          = string

    checksum                = optional(string)
    checksum_algorithm      = optional(string)
    decompression_algorithm = optional(string)
    file_name               = optional(string)
    overwrite               = optional(bool, true)
    overwrite_unmanaged     = optional(bool)
    upload_timeout          = optional(number, 600)
    verify                  = optional(bool, true)
  }))

  validation {
    condition = alltrue([
      for file in var.pve_download_files : contains([
        "iso", "import", "vztmpl"
      ], file.content_type)
    ])
    error_message = "Content type must be one of: iso, import, vztmpl."
  }

  validation {
    condition = alltrue([
      for file in var.pve_download_files : can(regex("^https?://.*", file.url))
    ])
    error_message = "URL must start with http:// or https://."
  }

  validation {
    condition = alltrue([
      for file in var.pve_download_files : file.checksum_algorithm != null ? contains([
        "md5", "sha1", "sha224", "sha256", "sha384", "sha512"
      ], file.checksum_algorithm) : true
    ])
    error_message = "Checksum algorithm must be one of: md5, sha1, sha224, sha256, sha384, sha512."
  }

  validation {
    condition = alltrue([
      for file in var.pve_download_files : file.decompression_algorithm != null ? contains([
        "gz", "lzo", "zst", "bz2"
      ], file.decompression_algorithm) : true
    ])
    error_message = "Decompression algorithm must be one of: gz, lzo, zst, bz2."
  }

  validation {
    condition = alltrue([
      for file in var.pve_download_files : file.upload_timeout != null ? file.upload_timeout > 0 : true
    ])
    error_message = "Upload timeout must be a positive number."
  }
}

# variable "sensitive_file_data" {
#   type = list(object({
#     env_file_name = ""
#   }))
# }