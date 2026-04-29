#!/bin/sh

exec > /var/log/provision.log 2>&1

apt update
apt install -y curl gpg wget lsb-release build-essential dkms linux-headers-$(uname -r) -y

# Vagrant (Hashicorp apt repo)
wget -O /tmp/hashicorp.gpg https://apt.releases.hashicorp.com/gpg
gpg --batch --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg /tmp/hashicorp.gpg
rm /tmp/hashicorp.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list

# VirtualBox (Oracle apt repo)
wget -O /tmp/virtualbox.asc https://www.virtualbox.org/download/oracle_vbox_2016.asc
gpg --batch --yes --dearmor -o /usr/share/keyrings/virtualbox.gpg /tmp/virtualbox.asc
rm /tmp/virtualbox.asc
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/virtualbox.gpg] https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" | tee /etc/apt/sources.list.d/virtualbox.list

apt update
apt install -y vagrant virtualbox-7.1 -y

/sbin/vboxconfig
