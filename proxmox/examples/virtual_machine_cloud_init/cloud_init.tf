
# Vendor and User Data configurations that are used to configure the VM on boot.
# Note: Creating/Updateing snippets files requries the provider be configured for SSH access.
#  See the provider docs for options.
# Note: Like images, it is probably better to manage these from a central location unless the
#  cloud init configs are specifically for this VM.
# Note: These files need to be deployed to the same proxmox host the VM is being created on
#  unless you have shared storage configured.

# Installs apt packages
# Enables the qme-agent and restarts ssh
resource "proxmox_virtual_environment_file" "vendor" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve-host-01"

  source_raw {
    data = <<-EOF
        #cloud-config
        package_update: true
        package_upgrade: true
        packages:
        - apt-transport-https
        - ca-certificates
        - gnupg-agent
        - gnupg
        - software-properties-common
        - openssh-server
        - git
        - jq
        - wget
        - curl
        - qemu-guest-agent

        allow_public_ssh_keys: true
        ssh_deletekeys: true
        ssh_pwauth: false
        
        runcmd:
        - systemctl enable --now qemu-guest-agent
        - systemctl reload ssh || systemctl restart ssh
    EOF

    file_name = "vendor-ubuntu-noble-cloud.yml"
  }
}

# Replaces the default 'ubuntu' user with a new user that requires a preset password to perform sudo actions.
# User:password = vmadmin:vmadmin
# Requires changing password on first login.
resource "proxmox_virtual_environment_file" "user_data" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve-host-01"

  source_raw {
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
}