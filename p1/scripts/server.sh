#!/bin/sh

exec > /var/log/provision.log 2>&1
# set -x

apt-get update

apt-get install curl -y

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -

cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token.tmp

echo "Server script has been successfully executed."
