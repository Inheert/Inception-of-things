#!/bin/sh

apt-get update

check_if_package_exist(){
	if command -v $1 > /dev/null 2>&1; then
		return 0
	fi
	return 1
}

if ! check_if_package_exist "helm version"; then
	curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
	chmod 700 get_helm.sh
	./get_helm.sh
	rm  get_helm.sh
else
	echo $(helm version --template='Helm {{.Version}}') "is already installed."
fi

if ! kubectl get namespace gitlab > /dev/null 2>&1; then
	kubectl create namespace gitlab
else
	echo "(gitlab) Namespace is already configured."
fi

helm repo add gitlab https://charts.gitlab.io/
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
# helm search repo gitlab
helm install redis bitnami/redis -n gitlab --set auth.enabled=false
helm install postgresql bitnami/postgresql -n gitlab
helm install gitlab gitlab/gitlab -n gitlab --skip-crds -f ./confs/gitlab-values.yaml
