#!/bin/sh

# store outputs of the script in the specified file
exec > /var/log/provision.log 2>&1

apt-get update

apt-get install curl -y

# Install k3s in server mode, INSTALL_K3S_EXEC="server" is optional, if K3S_URL is not set then the VM is considered
# as a control server.
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -

# Used to share the control server's token to the worker, dont forget to delete the file once everything is set.
cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token.tmp

echo "Server script has been successfully executed."
