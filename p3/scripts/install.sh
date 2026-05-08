#!/bin/sh

# Simple function to check if a package is already installed or not.
check_if_package_exist(){
	if command -v $1 > /dev/null 2>&1; then
		return 0
	fi
	return 1
}

apt-get update

# This script is used to install all the necessary dependencies for the VM and configure them.
# Once its done your VM will have a ready to use k3d ecosystem with 2 namespaces, one for argocd
# and one for the application.
# Here is the list of the package we are installing:
# - curl
# - docker
# - k3d
# - kubectl
# - argocd-cli

if ! check_if_package_exist "curl --version"; then
	apt-get install curl -y
else
	echo "curl is already installed."
fi

# Docker installation check
if ! check_if_package_exist "docker -v"; then
	apt remove $(dpkg --get-selections docker.io docker-compose docker-doc podman-docker containerd runc | cut -f1)

	# Add Docker's official GPG key
	apt update -y
	apt install ca-certificates curl -y
	install -m 0755 -d /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
	chmod a+r /etc/apt/keyrings/docker.asc

	# Add the repository to Apt sources
	tee /etc/apt/sources.list.d/docker.sources <<-EOF
	Types: deb
	URIs: https://download.docker.com/linux/debian
	Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
	Components: stable
	Architectures: $(dpkg --print-architecture)
	Signed-By: /etc/apt/keyrings/docker.asc
	EOF

	apt-get update > /dev/null

	apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
else
	echo "Docker is already installed."
fi

if ! check_if_package_exist "k3d --version"; then
	curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
else
	echo "k3d is already installed."
fi

if ! check_if_package_exist "kubectl"; then
	curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
	curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
	# Here we check the signature
	echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
	install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
else
	echo "kubectl is already installed."
fi

# Cluster creation
if [ -z "$1" ]; then
	echo "First argument is missing (cluster name)."
	exit 1
else
	k3d cluster create $1 -p "80:80@loadbalancer" --servers 1 --agents 1
fi

# argocd configuration
if ! kubectl get namespace argocd > /dev/null 2>&1; then
	kubectl create namespace argocd
	kubectl config set-context --current --namespace=argocd
	kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --server-side
	kubectl wait --for=condition=Ready pods --all --timeout=300s
	kubectl config set-context --current --namespace=default
else
	echo "argocd namespace is already configured."
fi

if ! kubectl get namespace dev > /dev/null 2>&1; then
	kubectl create namespace dev
	kubectl config set-context --current --namespace=dev
	# ...
	kubectl config set-context --current --namespace=default
else
	echo "dev namespace is already configured."
fi
