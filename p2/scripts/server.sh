#!/bin/sh

# store outputs of the script in the specified file
exec > /var/log/provision.log 2>&1

apt-get update

apt-get install curl -y

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --bind-address=192.168.56.110 --node-external-ip=192.168.56.110 --flannel-iface=eth1" sh -

echo "Server script has been successfully executed."
