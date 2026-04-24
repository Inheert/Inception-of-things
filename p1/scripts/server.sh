#!/bin/sh

exec > /var/log/provision.log 2>&1
# set -x

apt-get update

apt-get install curl -y

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -

cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token.tmp

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

echo "Server script has been successfully executed."
