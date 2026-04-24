#!/bin/sh

exec > /var/log/provision.log 2>&1

apt-get update

apt-get install curl -y

# Install k3s and set the VM as worker using K3S_URL, K3S_TOKEN should be equal to the token in the control
# server at /var/lib/rancher/k3s/server/node-token.
curl -sfL https://get.k3s.io | K3S_URL="https://192.168.56.110:6443" K3S_TOKEN=$(cat /vagrant/node-token.tmp) sh -

rm -f /vagrant/node-token.tmp

# Simple condition to check a ping's response to the control server. The execution of the script and vagrant stay the same
# regardless the response of the request.
response=$(curl -sSk https://192.168.56.110:6443/ping 2>&1)
if [ $? -eq 0 ]; then
	echo "[INFO] Control server is up (ping success: $response)."
else
	echo "[ERROR] Control server is not reachable (ping failure: $response)"
fi

echo "Agent script has been successfully executed."
