echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

output=$(sudo k3d cluster list -o json | jq length 2> /dev/null)
if [ $output -eq 0 ]; then
	echo "  No existing cluster found."
else
	echo "  Cluster:"
	k3d cluster list \
		| awk '{printf "  %s         %s         %s\n", $1, $2, $3}'
fi

echo
output=$(kubectl get app my-app -n argocd 2>/dev/null)
if [ $? -ne 0 ]; then
	echo "  ArgoCD do not have any application available."
else
	echo "  ArgoCD app:"
	echo "  $output" | awk '{printf "  %s     %s     %s\n", $1, $2, $3}'
fi

echo
output=$(kubectl get pods -n dev --no-headers 2>/dev/null)
if [ $? -ne 0 ]; then
	echo "  No pods available."
else
	echo "  Pods in dev namespace:"
	echo "  $output" | awk '{printf "  %s\n", $2}'
fi

echo
output=$(kubectl get application my-app -n argocd -o jsonpath='{.status.operationState.finishedAt}' 2>/dev/null)
if [ $? -eq 0 ]; then
	echo " $output"  | awk '{printf "  Last time sync: %s", $1}'
fi

echo
