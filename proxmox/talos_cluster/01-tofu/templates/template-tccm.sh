#! /bin/bash
### Note: The .env/talos-ccm-manifest.yml manifest is already included in this repository. This only needs to be ran if
###       you wish to make changes to the manifest.

# Templates the charts/talos-cloud-controller-manager helm chart using the 'talos-ccm-values.yaml' values file in this 
# directory, saving the output values to an .env/talos-ccm-manifest.yml.
# If you plan on installing cilium CNI, make sure to set 'talos_cluster.talos_ccm_enabled=true' 
# in your .env/{your_environment}.tfvars file after templating the charts.
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TEMPLATE_VALUES="${SCRIPT_DIR}/talos-ccm-values.yaml"
OUPUT_MANIFEST="${SCRIPT_DIR}/../.env/talos-ccm-manifest.yml"

echo "### Creating Talos Cloud Controller Manager (CCM) Manifest ###"
helm template talos-cloud-controller-manager \
    oci://ghcr.io/siderolabs/charts/talos-cloud-controller-manager \
    --namespace kube-system -f "${TEMPLATE_VALUES}" \
    > "${OUPUT_MANIFEST}"
echo ""
echo "### Templating Complete ###"
echo "Manifest file saved to: $(realpath "${OUPUT_MANIFEST}")."
echo "Make sure to enable the 'talos_cluster.talos_ccm_enabled' setting in your tfvars file to enable the installation of Talos CCM."