#!/bin/sh

kubectl delete application my-app -n argocd
kubectl scale deployment -n dev --replicas=0 --all
k3d cluster delete $1