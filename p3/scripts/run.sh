#!/bin/sh

# kubectl port-forward svc/argocd-server -n argocd 8181:443 --address $(PRIVATE_IP) &>/dev/null &
# kubectl wait --for=condition=Ready pods --all --timeout=300s


kill $(ps | grep -v 'grep' | grep 'kubectl port-forward svc/argocd-server' | cut -d ' ' -f1) 2>/dev/null

ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo)


echo "port forwarding"
kubectl port-forward svc/argocd-server -n argocd 4852:443 &>/dev/null &
kubectl config set-context --current --namespace=argocd
argocd login localhost:4852 --username admin --password $ARGOCD_PASSWORD --insecure --grpc-web

echo "Link to repo"
argocd app create my-app --repo "https://github.com/Inheert/tclaereb.git" --path app/ --dest-namespace "dev" --dest-server "https://kubernetes.default.svc" --grpc-web

echo "app describe"
kubectl describe deployments my-app-deployment | grep "Image"
