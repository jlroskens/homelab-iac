#! /bin/bash
# Generates a ArgoCD Manifest by kustomizing the argocd resource in the argocd/kustomization.yaml 
# file, saving the output values to an .env/manifests/argocd-manifest.yml file.
# If you plan on installing ArgoCD while your cluster is bootstrapped, make sure to set 
# 'talos_cluster.argocd_enabled=true' in your .env/{your_environment}.tfvars file after generating
# the manifest.
set -e

minify='false'
for arg in "$@"; do
  if [[ "${arg,,}" == "minify" ]]; then
    minify='true'
  fi
done

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}"
KUSTOMIZE_DIR="${SCRIPT_DIR}/argocd"
OUTPUT_MANIFEST="${SCRIPT_DIR}/../.env/manifests/argocd-manifest.yml"

echo "### Kustomizing ArgoCD Manifest ###"
if [[ "$minify" == 'true' ]]; then
    echo " **Minifying output manifest with yq**"
    kubectl kustomize "$KUSTOMIZE_DIR" |  yq '... comments=""' > "$OUTPUT_MANIFEST" 
else
    kubectl kustomize "$KUSTOMIZE_DIR" -o "$OUTPUT_MANIFEST" 
fi
echo ""
echo "### Kustomizing Complete ###"
echo "Manifest file saved to: $(realpath "${OUTPUT_MANIFEST}")."
echo "Make sure to enable the 'talos_cluster.argocd_enabled' setting in your tfvars file to enable installation of this manifest."