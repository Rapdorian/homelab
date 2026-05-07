#!/bin/bash
set -e

echo "Stopping k3s-agent..."
sudo systemctl stop k3s-agent

echo "Downloading and installing k3s v1.34.6+k3s1..."
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=v1.34.6+k3s1 sh -s - agent

echo "Restarting k3s-agent..."
sudo systemctl restart k3s-agent

echo "Waiting for k3s-agent to start..."
sleep 10

echo "Checking k3s version..."
sudo k3s --version

echo "Done. Run 'kubectl get nodes' from your control plane to verify."
