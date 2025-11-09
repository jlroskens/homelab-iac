#! /bin/bash
# Installs ArgoCD to the talos cluster. Uses 01-tofu's state file to retrieve the talosconfig, creates a temporary kubeconfig
# and installs ArgoCD.
set -e


ARGOCD_NAMESPACE='argocd'
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}"

declare -a tofu_vars=()
if [[ -n "$1" ]]; then
    tofu_vars=(-var terraform_state_path="$1")
fi

tmp_config_dir=$(mktemp -d "talos.XXXXXXXXXXXXXXXX" -p .)
trap 'rm -rf "$tmp_config_dir"' EXIT

echo "### Creating temporary talosconfig and kubeconfig ###"
tofu apply -auto-approve "${tofu_vars[@]}"
tofu output -raw "${tofu_vars[@]}" talosconfig > "${tmp_config_dir}/.talosconfig"
cluster_hostname=$(tofu output -raw "${tofu_vars[@]}" cluster_hostname)
talosctl kubeconfig "${tmp_config_dir}/.kubeconfig" --nodes "$cluster_hostname" --talosconfig "${tmp_config_dir}/.talosconfig"
export KUBECONFIG="$(realpath "${tmp_config_dir}/.kubeconfig")"
echo " Successfully created temporary ${tmp_config_dir}/.kubeconfig."

echo ""
echo "### Installing ArgoCD ###"
kubectl create namespace $ARGOCD_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
kubectl kustomize kustomize-argocd | kubectl apply -n $ARGOCD_NAMESPACE -f -
echo " Waiting for argocd-server deployment (timeout 180s)..."
kubectl wait deployment/argocd-server --for condition=available --timeout=180s -n $ARGOCD_NAMESPACE

# For testing. We'll rely on port-forwarding to Argo to install the cert-mananger and gateway.
# echo ""
# echo "### Configuring Gateway HTTPRoute ###"
# # kubectl apply -f argocd-ingress.yaml
# kubectl apply -f argocd-gateway.yaml
# echo ""

echo "### ArgoCD Installation Complete ###"
echo ""
echo "### Bootstrapping Apps ###"
# Extract the initial password from the secret
export ARGO_PASSWORD="$(kubectl -n $ARGOCD_NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"

# Setup port forwarding and a trap to kill it when we exit
kubectl -n argocd port-forward svc/argocd-server 8080:80 &
_port_forward_pid=$!
trap "kill $_port_forward_pid" SIGINT SIGTERM EXIT
# Login on the local port we just forwarded to
argocd login --skip-test-tls --plaintext --username admin --skip-test-tls --password "$ARGO_PASSWORD" localhost:8080

# Create our App of Apps
argocd app create apps \
    --dest-namespace argocd \
    --dest-server https://kubernetes.default.svc \
    --repo https://github.com/jlroskens/homelab-iac.git \
    --revision feature/talos-bootstrapping \
    --path proxmox/talos_cluster/02-argocd/bootstrap-apps
argocd app sync apps

echo "### Connection Instructions ###"
echo "-------------------------------"

if [[ "${SHOW_ARGOCD_PASSWORD^^}" == "TRUE" ]]; then
    password=$(kubectl -n $ARGOCD_NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    echo "Initial Admin Password: ${password}"
else
    echo "Execute to retrieve initial admin password:"
    echo "$ kubectl -n $ARGOCD_NAMESPACE get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d && echo"
fi
echo ""
echo "Run command to connect local port to argocd service:"
echo "$ kubectl port-forward service/argocd-server -n $ARGOCD_NAMESPACE :80"