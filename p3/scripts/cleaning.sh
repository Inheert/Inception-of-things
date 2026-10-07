#!/bin/sh


if ! kubectl delete application my-app -n argocd > /dev/null 2>&1; then
	echo "(argocd) No ArgoCD application found."
else
	echo "(argocd) ArgoCD application stopped."
fi

if ! kubectl scale deployment -n dev --replicas=0 --all > /dev/null 2>&1; then
	echo "(dev) No deployment to scale to 0."
else
	kubectl scale deployment --replicas=0 --all
	echo "(dev) Deployment scaled to 0."
fi

if kill $(lsof -i tcp:4852 | tail -n +2 | awk '{print $2}') > /dev/null 2>&1; then
	echo "Port-forwarding stopped."
fi

if ! k3d cluster get $1 > /dev/null 2>&1; then
	echo "Cluster $1 already deleted."
else
	k3d cluster delete $1
	echo "Cluster $1 deleted."
fi
