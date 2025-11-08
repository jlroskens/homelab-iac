#! /bin/bash
# Installs ArgoCD to the talos cluster. Uses 01-tofu's state file to retrieve the talosconfig, creates a temporary kubeconfig
# and installs ArgoCD.
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}"

declare -a tofu_vars=()
if [[ -n "$1" ]]; then
    tofu_vars=(-var terraform_state_path="$1")
fi

tmp_config_dir=$(mktemp -d "talos.XXXXXXXXXXXXXXXX" -p .)
trap 'rm -rf "$tmp_config_dir"' EXIT

# mkdir -p ~/.talos && tofu output -raw -var pve_endpoint=https://pve-host-01.proxmox.local.rnimbus.com:8006 -var terraform_state_path="/mnt/iac-state/.terraform/talos_virtual_machines_cluster_rnimbus.tfstate" talos_client_config > ~/.talos/config && export TALOSCONFIG=~/.talos/config && talosctl kubeconfig --nodes talos-ctrlp-1.cluster.local.rnimbus.com

echo "### Creating temporary talosconfig and kubeconfig ###"
tofu apply -auto-approve "${tofu_vars[@]}"
tofu output -raw "${tofu_vars[@]}" talosconfig > "${tmp_config_dir}/.talosconfig"
cluster_hostname=$(tofu output -raw "${tofu_vars[@]}" cluster_hostname)
talosctl kubeconfig "${tmp_config_dir}/.kubeconfig" --nodes "$cluster_hostname" --talosconfig "${tmp_config_dir}/.talosconfig"
export KUBECONFIG="${tmp_config_dir}/.kubeconfig"
echo " Successfully created temporary ${tmp_config_dir}/.kubeconfig."
echo ""
echo "### Installing ArgoCD ###"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -k kustomize-argocd
echo ""
# Ingress not working yet. Requires TLS termination. Use port-forward
echo "### Configuring Ingress ###"
kubectl apply -f argocd-ingress.yaml
echo ""
echo "### Installation Complete ###"
echo ""
echo "### Connection Instructions ###"
echo "-------------------------------"

if [[ "${SHOW_ARGOCD_PASSWORD^^}" == "TRUE" ]]; then
    password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    echo "Initial Admin Password: ${password}"
else
    echo "Execute to retrieve initial admin password:"
    echo '$ kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo'
fi
echo ""
echo "Run command to connect local port to argocd service:"
echo "$ kubectl port-forward service/argocd-server -n argocd :443"