#!/bin/bash
set -e

# ── Docker ────────────────────────────────────────────────────────────────────
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker vagrant

# Enable QEMU emulation for amd64 images if host is arm64
if [ "$(uname -m)" = "aarch64" ]; then
  docker run --privileged --rm tonistiigi/binfmt --install amd64
fi

# ── k3d ───────────────────────────────────────────────────────────────────────
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# ── kubectl ───────────────────────────────────────────────────────────────────
ARCH=$(dpkg --print-architecture)
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# ── ArgoCD CLI ────────────────────────────────────────────────────────────────
ARGOCD_VERSION="v2.14.0"
curl -sSL -o argocd "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-${ARCH}"
sudo install -m 755 argocd /usr/local/bin/argocd
rm argocd

# ── Cluster ───────────────────────────────────────────────────────────────────
k3d cluster create --port "${ARGOCD_PORT}:443@loadbalancer" --port "8888:8888@loadbalancer" --k3s-arg "--disable=traefik@server:0"

kubectl create namespace argocd
kubectl create namespace dev

# ── ArgoCD ────────────────────────────────────────────────────────────────────
kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

# Disable GPG (fails in VM without enough entropy)
kubectl patch deployment argocd-repo-server -n argocd --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/env","value":[{"name":"ARGOCD_GPG_ENABLED","value":"false"}]}]'

# Expose ArgoCD via the load balancer
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Wait for all ArgoCD deployments to be available
kubectl wait --for=condition=available deployment --all -n argocd --timeout=600s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-application-controller -n argocd --timeout=600s

# ── App ───────────────────────────────────────────────────────────────────────
kubectl apply -f /vagrant/confs/argocd-app.yaml

echo "ArgoCD admin password:"
until kubectl -n argocd get secret argocd-initial-admin-secret &>/dev/null; do
  sleep 2
done
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
