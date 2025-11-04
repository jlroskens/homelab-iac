pve_endpoint="https://pve-host-01.local.example.com:8006"

# Vendor cloud-init files for use with cloud-init enabled images.
pve_files = [
  {
    content_type = "snippets"
    datastore_id = "local"
    node_name    = "pve-host-01"
    source_file = {
      path = "cloud_init/vendor-ubuntu-noble-cloud.yml"
    }
  },
  {
    content_type = "snippets"
    datastore_id = "local"
    node_name    = "pve-host-01"
    source_file = {
      path = "cloud_init/vendor-ubuntu-noble-cloud-docker.yml"
    }
  },
  {
    content_type = "snippets"
    datastore_id = "local"
    node_name    = "pve-host-01"
    source_file = {
      path = "cloud_init/vendor-debian-trixie-genericloud.yml"
    }
  },
  {
    content_type = "snippets"
    datastore_id = "local"
    node_name    = "pve-host-01"
    source_file = {
      path = "cloud_init/vendor-debian-trixie-genericloud-docker.yml"
    }
  },
  {
    content_type = "snippets"
    datastore_id = "local"
    node_name    = "pve-host-01"
    sensitive    = true
    source_file = {
      path = "cloud_init/vendor-ubuntu-noble-cloud-dev.yml"
    }
  }
]

# User-data cloud init files.
# Update "ssh_authorized_keys" and "password" prior to using.
pve_raw_files = [
  # Manages a "user-data-ubuntu.yml" file in the snippets directory.
  # Replaces the default "ubuntu" account with "vmadmin".
  # Requires a password change on login, and password for sudo
  # Initial user:password = vmadmin:vmadmin
  {
    content_type = "snippets"
    datastore_id = "local"
    node_name    = "pve-host-01"
    sensitive    = true
    source_raw = {
    data = <<-EOF
        #cloud-config
        users:
        - name: vmadmin
          lock_passwd: false
          gecos: Virtual Machine Administrator
          groups: adm, cdrom, dip, lxd, sudo
          sudo: "ALL=(ALL) ALL"
          shell: /bin/bash
          ssh_authorized_keys:
            - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIbXMv/92ieAfyzB5rCOtHKv2umHCyEAZD4zne+XVVE2 VM_Administrator

        chpasswd:
          expire: true
          users:
          - {name: vmadmin, password: $6$rounds=500000$5iQGvCQrNLs3ZfO8$u411Cj5Zu9mDN56kuIhp7DCZEvqNPIM3G4i7QL9ak0pwcnpR7h2LwKXZOtIPpoiRKKSYoV7wudkuLQJg8dtAq0}
      EOF

      file_name = "user-data-ubuntu.yml"
    }
  },
  # Manages a "user-data-ubuntu-docker.yml" file in the snippets directory.
  # Same as "user-data-ubuntu.yml" but includes addition of a docker group.
  # Initial user:password = vmadmin:vmadmin
  {
    content_type = "snippets"
    datastore_id = "local"
    node_name    = "pve-host-01"
    sensitive    = true
    source_raw = {
    data = <<-EOF
        #cloud-config
        users:
        - name: vmadmin
          lock_passwd: false
          gecos: Virtual Machine Administrator
          groups: adm, cdrom, dip, lxd, sudo, docker
          sudo: "ALL=(ALL) ALL"
          shell: /bin/bash
          ssh_authorized_keys:
            - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIbXMv/92ieAfyzB5rCOtHKv2umHCyEAZD4zne+XVVE2 VM_Administrator

        chpasswd:
          expire: true
          users:
          - {name: vmadmin, password: $6$rounds=500000$5iQGvCQrNLs3ZfO8$u411Cj5Zu9mDN56kuIhp7DCZEvqNPIM3G4i7QL9ak0pwcnpR7h2LwKXZOtIPpoiRKKSYoV7wudkuLQJg8dtAq0}
      EOF

      file_name = "user-data-ubuntu-docker.yml"
    }
  },
  # Manages a "user-data-ubuntu-docker-developer.yml" file in the snippets directory.
  # Configuration for a developer account with no password required for sudo, ssh
  {
    content_type = "snippets"
    datastore_id = "local"
    node_name    = "pve-host-01"
    source_raw = {
    data = <<-EOF
        #cloud-config
        users:
        - name: dev
          lock_passwd: true
          gecos: Developer Account
          groups: adm, cdrom, dip, lxd, sudo, docker
          sudo: "ALL=(ALL) NOPASSWD:ALL"
          shell: /bin/bash
          ssh_authorized_keys:
            - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIbXMv/92ieAfyzB5rCOtHKv2umHCyEAZD4zne+XVVE2 VM_Administrator
      EOF

      file_name = "user-data-ubuntu-docker-developer.yml"
    }
  },
  # Manages a "user-data-debian.yml" file in the snippets directory.
  # Replaces the default "debian" account with "vmadmin". 
  # Requires a password change on login, and password for sudo.
  {
    content_type = "snippets"
    datastore_id = "local"
    node_name    = "pve-host-01"
    sensitive    = true
    source_raw = {
    data = <<-EOF
        #cloud-config
        users:
        - name: vmadmin
          lock_passwd: false
          gecos: Virtual Machine Administrator
          groups: adm, audio, cdrom, dialout, dip, floppy, netdev, plugdev, sudo, video
          sudo: "ALL=(ALL) ALL"
          shell: /bin/bash
          ssh_authorized_keys:
            - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIbXMv/92ieAfyzB5rCOtHKv2umHCyEAZD4zne+XVVE2 VM_Administrator

        chpasswd:
          expire: true
          users:
          - {name: vmadmin, password: $6$rounds=500000$5iQGvCQrNLs3ZfO8$u411Cj5Zu9mDN56kuIhp7DCZEvqNPIM3G4i7QL9ak0pwcnpR7h2LwKXZOtIPpoiRKKSYoV7wudkuLQJg8dtAq0}
      EOF

      file_name = "user-data-debian.yml"
    }
  }
]

# Downloads ubunut and debian images as imports. Downloads talos image as an iso.
pve_download_files = [
  {
    content_type       = "import"
    datastore_id       = "local-lvm"
    node_name          = "pve-host-01"
    url                = "https://cloud-images.ubuntu.com/minimal/releases/noble/release/ubuntu-24.04-minimal-cloudimg-amd64.img"
    checksum           = "c9d17b2554832605cdb377ace2117822fb02694e8fb56d82f900ce045c7aae57"
    checksum_algorithm = "sha256"
    file_name          = "ubuntu-24.04-minimal-cloudimg-amd64.qcow2"
  },
  {
    content_type       = "import"
    datastore_id       = "local"
    node_name          = "pve-host-01"
    url                = "https://cloud.debian.org/images/cloud/trixie/20251006-2257/debian-13-genericcloud-amd64-20251006-2257.qcow2"
    checksum           = "aa1963a7356a7fab202e5eebc0c1954c4cbd4906e3d8e9bf993beb22e0a90cd7fe644bd5e0fb5ec4b9fbea16744c464fda34ef1be5c3532897787d16c7211f86"
    checksum_algorithm = "sha512"
  },
  {
    content_type       = "import"
    datastore_id       = "local"
    node_name          = "pve-host-01"
    url                = "https://cdimage.debian.org/images/cloud/bookworm/20251006-2257/debian-12-generic-amd64-20251006-2257.qcow2"
    checksum           = "be06e506319a7f0e3ee5ec2328595bc4c2205b91b4354ccbb2e6d88b047cf7288137bfa17a143ea611cb588adb9417847c0a5aec0addbbf2835f9f31e2e76547"
    checksum_algorithm = "sha512"
  },
  {
    content_type       = "iso"
    datastore_id       = "local"
    node_name          = "pve-host-01"
    url                = "https://factory.talos.dev/image/9c1d1b442d73f96dcd04e81463eb20000ab014062d22e1b083e1773336bc1dd5/v1.11.3/nocloud-amd64-secureboot.iso"
  }
]