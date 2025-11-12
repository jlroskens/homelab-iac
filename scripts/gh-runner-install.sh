#! /bin/bash
# Expects 2 arguments, 
# - Relative path of the repository {org|user}/{repo} (or org only for org runners)
# - Token from https://github.com/${repo_path}/settings/actions/runners/new
# - NonInteractive.
# SSH Example:
# ssh githubrunner1.local.example.com 'bash -s' -- < ./gh-runner-install.sh "rNimbus-com/homelab-foundation" "efsdfsdf213412dw" "self-hosted,homelab-ubuntu"

set -e

if [[ -z "$1" ]]; then
    echo "A relative path to the repository or organization is require."
    echo "  usage: ./gh-runner-install.sh {your-org-or-username}/{repo-name} {token} {labels}"
    exit 1
fi
repo_path=$1

if [[ -z "$2" ]]; then
    echo "An token is required."
    echo "  usage: ./gh-runner-install.sh {your-org-or-username}/{repo-name} {token} {labels}"
    echo "Tokens are generated when creating a new runner on GitHub."
    echo "https://github.com/${repo_path}/settings/actions/runners/new"
    exit 1
fi
token="$2"

if [[ -z "$3" ]]; then
    echo "At least one label is required. Additional labels can be added by separating labels with a comma."
    echo "  usage: ./gh-runner-install.sh {your-org-or-username}/{repo-name} {token} {labels}"
    echo "  example: ./gh-runner-install.sh {your-org-or-username}/{repo-name} {token} 'example-runner,self-hosted'"
    exit 1
fi
labels="$3"

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update \
    && sudo apt-get install -y \
        jq \
        wget \
        python3 python3-pip \
        unzip \
        nodejs npm

echo "Downloading actions-runner install"
# Create a folder
mkdir -p actions-runner && cd actions-runner
# Download the latest runner package
curl -o actions-runner-linux-x64-2.329.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.329.0/actions-runner-linux-x64-2.329.0.tar.gz
# Optional: Validate the hash
echo "194f1e1e4bd02f80b7e9633fc546084d8d4e19f3928a324d512ea53430102e1d  actions-runner-linux-x64-2.329.0.tar.gz" | shasum -a 256 -c
# Extract the installer
tar xzf ./actions-runner-linux-x64-2.329.0.tar.gz

echo "Running Configuration script."
./config.sh --unattended --url https://github.com/${repo_path} --token $token --no-default-labels  --labels "$labels"

echo "Installing runner as a service"
sudo ./svc.sh install

echo "Starting runner service"
sudo ./svc.sh start