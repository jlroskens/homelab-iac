#! /bin/bash
## Creates an ubuntu VM cloned from the ubuntu-noble-docker-32G foundation template
## Prereqs:
## - A proxmox cluster or single host
## - Ability to execute this script via ssh against a proxmox host
## - A VM template that can be cloned from the PVE host
## - Optionally, a pool configured. Comment out if not needed
## To execute over SSH: 
## $ ssh pve-host-02.local.example.com 'bash -s' < pve-dev-vm.sh

set -e

TEMPLATE_ID=10020
VM_ID=211
VM_NAME='dev01'
TARGET_NODE='pve-host-02'
STORAGE='local-cluster-zfs'
POOL='automation'

# Optional configuration. Can be commented out if template configuration is desired / ok
MEMORY=2048           # in MB, 2048 = 2G
CPU_CORES=1
IP_CONFIG_DEVICE=0    # The [n] in the --ipconfig[n] argument. The network device #.
IP_CONFIG='ip=dhcp'   # Use DHCP
#IP_CONFIG='ip=10.0.10.123/24,gw=10.0.10.1'  # Or use a Static IP

# Add arguments to an array
clone_args=()
clone_args+=(--name $VM_NAME)
clone_args+=(--description 'VM for Development')
if [[ -n $POOL ]]; then clone_args+=(--pool $POOL); fi
clone_args+=(--full)
clone_args+=(--storage $STORAGE)
clone_args+=(--target $TARGET_NODE)

# Clone the VM
echo "## Cloning VM $TEMPLATE_ID to $VM_ID ($VM_NAME) ##"
echo qm command: qm clone $TEMPLATE_ID $VM_ID "${clone_args[@]}"
qm clone $TEMPLATE_ID $VM_ID "${clone_args[@]}"

# Wait for the VM to exit the locked state
echo "## Waiting for VM clone to complete... ##"
sleep 5
until [ "$(qm status $VM_ID)" == "status: stopped" ]; do
    sleep 0.1;
done;

# Configure ram, cores and networking (if set)
set_args=()
if (( $CPU_CORES > 0 )); then
    set_args+=(--cores $CPU_CORES)
fi
if (( $MEMORY > 0 )); then
    set_args+=(--memory $MEMORY)
fi
if [[ -n "$IP_CONFIG" ]] && [[ -n $IP_CONFIG_DEVICE ]]; then
    set_args+=(--ipconfig$IP_CONFIG_DEVICE "$IP_CONFIG")
fi
if (( ${#set_args[@]} > 0 )); then
    echo "## Configuring RAM and CPU Cores ##"
    echo qm command: qm set "${set_args[@]}"
    qm set $VM_ID "${set_args[@]}"
else
    echo "Using template configuration for CPU Cores, Memory and IP Configuration" 
fi

echo "## Starting $VM_ID ($VM_NAME) ##"
qm start $VM_ID