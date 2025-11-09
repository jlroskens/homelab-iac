#! /bin/bash
### Note: The .env/talos-ccm-manifest.yml manifest is already included in this repository. This only needs to be ran if
###       you wish to make changes to the manifest.

# Templates the charts/talos-cloud-controller-manager helm chart using the 'talos-ccm-values.yaml' values file in this 
# directory, saving the output values to an env/manifests/talos-ccm-manifest.yml.
# If you plan on installing cilium CNI, make sure to set 'talos_cluster.talos_ccm_enabled=true' 
# in your .env/{your_environment}.tfvars file after templating the charts.
set -e

minify='false'
for arg in "$@"; do
  if [[ "${arg,,}" == "minify" ]]; then
    minify='true'
  fi
done

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TEMPLATE_VALUES="${SCRIPT_DIR}/talos-ccm-values.yaml"
OUTPUT_MANIFEST="${SCRIPT_DIR}/../.env/manifests/talos-ccm-manifest.yml"

echo "### Creating Talos Cloud Controller Manager (CCM) Manifest ###"
helm template talos-cloud-controller-manager \
    oci://ghcr.io/siderolabs/charts/talos-cloud-controller-manager \
    --namespace kube-system -f "${TEMPLATE_VALUES}" \
    > "${OUTPUT_MANIFEST}"

manifest=$(helm template talos-cloud-controller-manager \
    oci://ghcr.io/siderolabs/charts/talos-cloud-controller-manager \
    --namespace kube-system -f "${TEMPLATE_VALUES}")

if [[ "$minify" == 'true' ]]; then
    echo " **Minifying output manifest with yq**"
    yq '... comments=""' <<< "$manifest" > "$OUTPUT_MANIFEST" 
else
    echo "$manifest" > "$OUTPUT_MANIFEST" 
fi

echo ""
echo "### Templating Complete ###"
echo "Manifest file saved to: $(realpath "${OUTPUT_MANIFEST}")."
echo "Make sure to enable the 'talos_cluster.talos_ccm_enabled' setting in your tfvars file to enable the installation of Talos CCM."