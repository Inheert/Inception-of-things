#!/bin/sh

exec > /var/log/provision.log 2>&1

apt-get update

apt-get install curl -y

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --bind-address=$1 --node-external-ip=$1 --flannel-iface=eth1" sh -

# From here we are using all the yaml files we have in the confs folder to create our applications.
# Here i create a config map storing my html file. A config map is primary used to decouple configuration from the container image,
# without that if i want to change the HTML file i'll have  to rebuild the image.
# Config map should only be used to store non sensitive data, never store secrets keys or even passwords in it.
kubectl create configmap app1-resource --from-file="/vagrant/confs/app1/index.html"

# The deployment.yaml file is used to create our pods (applications), in it we define the image we are going to use for
# our container, mount our volumes, etc.
kubectl apply -f /vagrant/confs/app1/deployment.yaml

# Service prodives a stable DNS name and a stable IP that points to a set of pods, we select our pods using the 'label' key.
# It also does load balancing, if i have 3 replicas the service distributes requests across the pods.
kubectl apply -f /vagrant/confs/app1/service.yaml

kubectl create configmap app2-resource --from-file="/vagrant/confs/app2/index.html"
kubectl apply -f /vagrant/confs/app2/deployment.yaml
kubectl apply -f /vagrant/confs/app2/service.yaml

kubectl create configmap app3-resource --from-file="/vagrant/confs/app3/index.html"
kubectl apply -f /vagrant/confs/app3/deployment.yaml
kubectl apply -f /vagrant/confs/app3/service.yaml

# After we created all our pods and services we init the Ingress, it allow inbound connections to reach endpoints defined
# in the backend.
kubectl apply -f /vagrant/confs/ingress.yaml

echo "Server script has been successfully executed."
