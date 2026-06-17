#!/bin/sh

if ! k3d cluster get $1 > /dev/null 2>&1; then
	echo "[FATAL] The cluster $1 doesn't exist, pleas re-run the install."
	exit 1
fi

if kill $(lsof -i tcp:4852 | tail -n +2 | awk '{print $2}') > /dev/null 2>&1; then
	echo "ArgoCD server stopped."
else
	echo "no ArgoCD server process found."
fi

sleep 1
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo)

echo "port forwarding"
kubectl config set-context --current --namespace=argocd
kubectl port-forward svc/argocd-server 4852:443 &>/dev/null &
sleep 2
argocd login localhost:4852 --username admin --password $ARGOCD_PASSWORD --insecure --grpc-web

echo "Link to repo"
argocd app create my-app --repo "https://github.com/Inheert/tclaereb.git" \
	--path app/ --dest-namespace "dev" --dest-server "https://kubernetes.default.svc" \
	--sync-policy "automated" --upsert --grpc-web --self-heal --auto-prune
