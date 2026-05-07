#!/bin/bash
set -e

echo "Configuring k3s-agent service environment..."

sudo tee /etc/systemd/system/k3s-agent.service.env <<'EOF'
K3S_URL=https://10.0.0.55:6443
K3S_TOKEN=K102837f53a5fbd6798e0677b3cd0e67b6583acfb5722415a173c9f2fdd86ca214b::server:9382ccd40ef2009ddae5bc24d2ca6997
EOF

echo "Reloading systemd..."
sudo systemctl daemon-reload

echo "Restarting k3s-agent..."
sudo systemctl restart k3s-agent

echo "Waiting for k3s-agent to start..."
sleep 10

echo "Checking service status..."
sudo systemctl status k3s-agent --no-pager

echo "Checking k3s version..."
sudo k3s --version

echo "Done. Run 'kubectl get nodes' from your control plane to verify."
