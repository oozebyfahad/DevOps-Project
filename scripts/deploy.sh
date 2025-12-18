#!/bin/bash
set -euo pipefail

# Always run relative to repo root (so paths work in Jenkins)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
K8S_DIR="$ROOT_DIR/k8s"

echo "Repo root: $ROOT_DIR"
echo "K8s dir:   $K8S_DIR"

# Extract namespace name from namespace.yaml (STRICT)
NAMESPACE="$(awk '/^metadata:/ {m=1} m && $1=="name:" {print $2; exit}' "$K8S_DIR/namespace.yaml")"

if [[ -z "${NAMESPACE:-}" ]]; then
  echo "❌ Could not read namespace name from $K8S_DIR/namespace.yaml"
  exit 1
fi

echo "Using namespace: $NAMESPACE"

# Apply namespace first (namespace objects are cluster-scoped)
kubectl apply -f "$K8S_DIR/namespace.yaml"

# Helper: apply a manifest into namespace, while removing any hardcoded metadata.namespace
apply_ns() {
  local file="$1"
  echo "Applying: $file (namespace=$NAMESPACE)"

  # Remove "namespace:" lines if present to avoid mismatch errors
  # (kubectl -n will set the target namespace)
  sed -E '/^[[:space:]]*namespace:[[:space:]]*.*$/d' "$file" | kubectl apply -n "$NAMESPACE" -f -
}

# Apply DB resources (PVC -> Deployment -> Service)
apply_ns "$K8S_DIR/db-pvc.yaml"
apply_ns "$K8S_DIR/db-deployment.yaml"
apply_ns "$K8S_DIR/db-service.yaml"

# Apply Web resources (Deployment -> Service)
apply_ns "$K8S_DIR/web-deployment.yaml"
apply_ns "$K8S_DIR/web-service.yaml"

# Optional: wait for readiness (use correct deployment names)
echo "Waiting for deployments (if they exist)..."
kubectl rollout status -n "$NAMESPACE" deployment/web-app --timeout=180s || true
kubectl rollout status -n "$NAMESPACE" deployment/db --timeout=180s || true
kubectl rollout status -n "$NAMESPACE" deployment/db-service --timeout=180s || true

echo "Pods:"
kubectl get pods -n "$NAMESPACE" -o wide || true

echo "Services:"
kubectl get svc -n "$NAMESPACE" -o wide || true

echo "✅ Deployment completed successfully."
