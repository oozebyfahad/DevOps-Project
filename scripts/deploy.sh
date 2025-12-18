#!/bin/bash
set -euo pipefail

# Always run relative to repo root (so paths work in Jenkins)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
K8S_DIR="$ROOT_DIR/k8s"

echo "Repo root: $ROOT_DIR"
echo "K8s dir:   $K8S_DIR"

# Apply namespace first
kubectl apply -f "$K8S_DIR/namespace.yaml"

# Auto-detect namespace name from namespace.yaml (fallback if needed)
NAMESPACE=$(grep -E "name:" -m1 "$K8S_DIR/namespace.yaml" | awk '{print $2}' || true)
NAMESPACE=${NAMESPACE:-default}

echo "Using namespace: $NAMESPACE"

# Apply DB resources
kubectl apply -n "$NAMESPACE" -f "$K8S_DIR/db-pvc.yaml"
kubectl apply -n "$NAMESPACE" -f "$K8S_DIR/db-deployment.yaml"
kubectl apply -n "$NAMESPACE" -f "$K8S_DIR/db-service.yaml"

# Apply Web resources
kubectl apply -n "$NAMESPACE" -f "$K8S_DIR/web-deployment.yaml"
kubectl apply -n "$NAMESPACE" -f "$K8S_DIR/web-service.yaml"

# Optional: wait for readiness (update deployment names if yours differ)
echo "Waiting for deployments..."
kubectl rollout status -n "$NAMESPACE" deployment/db --timeout=120s || true
kubectl rollout status -n "$NAMESPACE" deployment/web --timeout=120s || true

echo "Pods:"
kubectl get pods -n "$NAMESPACE" -o wide

echo "Services:"
kubectl get svc -n "$NAMESPACE" -o wide

echo "✅ Deployment completed successfully."