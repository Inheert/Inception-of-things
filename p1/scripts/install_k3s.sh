#!/bin/bash

#ufw allow 6443/tcp #apiserver
#ufw allow from 10.42.0.0/16 to any #pods
#ufw allow from 10.43.0.0/16 to any #services

if [ "$1" = "hclaudeS" ]; then
	echo "Installing K3s Server..."
	#curl -sfL https://get.k3s.io | sh -s - server \
	#	--disable-cloud-controller \
	#	--disable network-policy \
	#	--disable metrics-server

	export K3S_KUBECONFIG_MODE="644"
	export INSTALL_K3S_EXEC="server --node-external-ip=192.168.56.110 --bind-address=192.168.56.110"

	curl -sfL https://get.k3s.io | sh -
	if [ $? -ne 0 ]; then
		echo "Failed to install k3s. Exiting."
		exit 1
	fi

	# 2. On réinstalle la version "Régime sec"
	#curl -sfL https://get.k3s.io | sh -s - server \
	#	--node-ip=192.168.56.110 \
	#	--tls-san=192.168.56.110 \
	#	--write-kubeconfig-mode=644 \
	#	--disable-cloud-controller \
	#	--disable network-policy \
	#	--disable local-storage \
	#	--disable metrics-server
		#--disable traefik \
		#--disable servicelb \

	while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
		sleep 2
	done
	sudo mkdir -p /vagrant/shared
	sudo cp /var/lib/rancher/k3s/server/node-token /vagrant/shared/token
	sudo chmod 644 /vagrant/shared/token
elif [ "$1" = "hclaudeSW" ]; then
	echo "Installing K3s Worker..."
	while [ ! -f /vagrant/shared/token ]; do
		sleep 2
	done
	#TOKEN=$(cat /vagrant/shared/token)
	#curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.110:6443 K3S_TOKEN=$TOKEN sh -s - agent

	export K3S_TOKEN_FILE=/vagrant/shared/token
	export K3S_URL=https://192.168.56.110:6443
	export INSTALL_K3S_EXEC="agent"

	curl -sfL https://get.k3s.io | sh -

	#curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.110:6443 sh -s - agent \
	#	--node-ip=192.168.56.111

	if [ $? -ne 0 ]; then
		echo "Failed to install k3s. Exiting."
	exit 1
fi
else
	echo "Usage: $0 {hclaudeS|hclaudeSW}"
	exit 1
fi

# Check for Ready node, takes ~30 seconds
#sudo k3s kubectl get node