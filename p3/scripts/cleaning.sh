#!/bin/sh


if kubectl delete application my-app -n argocd > /dev/null 2>&1; then
    echo "Argocd application stopped."
fi

kubectl scale deployment -n dev --replicas=0 --all
# kubectl scale deployment --replicas=0 --all

if kill $(lsof -i tcp:4852 | tail -n +2 | awk '{print $2}') > /dev/null 2>&1; then
	echo "Port-forwarding stopped."
fi
k3d cluster delete $1
