#!/bin/sh

exec > /var/log/provision.log 2>&1

apt-get update
apt-get install curl -y

 curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --tls-san 192.168.56.110" sh -

until [ -f /var/lib/rancher/k3s/server/node-token ]; do
    sleep 5
done
cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token.tmp

