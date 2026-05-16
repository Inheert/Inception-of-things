echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

echo "  Cluster:"
k3d cluster list \
    | awk '{printf "  %s         %s         %s\n", $1, $2, $3}'
echo ""

# ARGOCD_APP=$(kubectl get app my-app -n argocd 2>&1)
echo "  ArgoCD App:"
# if [ $? -eq 0 ]; then
#     kubectl get app my-app -n argocd \
#         | awk '{printf "  %s     %s     %s\n", $1, $2, $3}'
# else
#     echo "  App not found"
# fi
output=$(kubectl get app my-app -n argocd 2>/dev/null) \
        && echo "$output" | awk '{printf "  %s     %s     %s\n", $1, $2, $3}' \
        || echo "  (no app available)"

echo ""
echo "  Pods in dev:"
output=$(kubectl get pods -n dev --no-headers) \
        && echo "  $output" | awk '{printf "  %s\n", $2}' \
        || echo "  (kubectl unavailable)"

echo ""

kubectl get application my-app -n argocd -o jsonpath='{.status.operationState.finishedAt}' \
    | awk '{printf "  Last time sync: %s", $1}'