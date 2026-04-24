#!/bin/sh

exec > /var/log/provision.log 2>&1

apt-get update

apt-get install curl -y

# Install k3s and set the VM as worker using K3S_URL, K3S_TOKEN should be equal to the token in the control
# server at /var/lib/rancher/k3s/server/node-token.
curl -sfL https://get.k3s.io | K3S_URL="https://192.168.56.110:6443" K3S_TOKEN=$(cat /vagrant/node-token.tmp) sh -

echo "Agent script has been successfully executed."
