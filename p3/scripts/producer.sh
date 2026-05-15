#!/bin/bash
# Output of this script is displayed inside the box in display.sh.
# Replace or extend with whatever you want to show.

echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

echo "  ArgoCD App:"
kubectl get app my-app -n argocd --no-headers 2>/dev/null \
    | awk '{printf "  %-20s %s/%s\n", $1, $7, $8}' \
    || echo "  (kubectl unavailable)"

echo ""
echo "  Pods in dev:"
kubectl get pods -n dev --no-headers 2>/dev/null \
    | awk '{printf "  %-30s %s\n", $1, $3}' \
    || echo "  (kubectl unavailable)"
