#!/bin/sh

exec > /var/log/provision.log 2>&1

apt-get update
apt-get install curl -y

until [ -f /vagrant/node-token.tmp ]; do
    sleep 5                                                 
done

curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.110:6443 K3S_TOKEN=$(cat /vagrant/node-token.tmp) sh -