#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_NAME="signoz"

echo "========================================="
echo "  SigNoz on Kind - Optimized Setup"
echo "========================================="
echo ""

# Step 1: Check prerequisites
echo "[1/7] Checking prerequisites..."
for cmd in kind kubectl helm docker; do
  command -v $cmd &> /dev/null || { echo "Error: $cmd not found"; exit 1; }
done
echo "OK"
echo ""

# Step 2: Create Kind cluster
echo "[2/7] Creating Kind cluster..."
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo "Cluster exists, recreating..."
  kind delete cluster --name ${CLUSTER_NAME}
fi
kind create cluster --config "${SCRIPT_DIR}/kind-config.yaml" --wait 1m
echo "OK"
echo ""

# Step 3: Install nginx-ingress (hostNetwork mode for speed)
echo "[3/7] Installing nginx-ingress..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx &>/dev/null
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.hostNetwork=true \
  --set controller.kind=DaemonSet \
  --set controller.service.enabled=false \
  --set controller.daemonset.useHostPort=true \
  --set controller.terminationGracePeriodSeconds=0 \
  --set controller.metrics.enabled=false \
  --set controller.admissionWebhooks.enabled=false &>/dev/null
echo "OK"
echo ""

# Step 4: Install SigNoz
echo "[4/7] Installing SigNoz (this takes 3-5 min)..."
helm repo add signoz https://charts.signoz.io &>/dev/null
helm upgrade --install my-release signoz/signoz \
  --namespace platform --create-namespace \
  -f "${SCRIPT_DIR}/signoz-values.yaml" &>/dev/null
echo "Waiting for SigNoz pods..."
for i in $(seq 1 120); do
  READY=$(kubectl get pods -n platform --no-headers 2>/dev/null | grep -c "Running\|Completed" || true)
  TOTAL=$(kubectl get pods -n platform --no-headers 2>/dev/null | wc -l || true)
  if [ "$READY" -eq "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
    echo "All $TOTAL pods ready"
    break
  fi
  printf "\r  Progress: %d/%d pods ready..." $READY $TOTAL
  sleep 5
done
echo ""
echo "OK"
echo ""

# Step 5: Deploy Basic Demo
echo "[5/7] Deploying basic demo app..."
kubectl apply -f "${SCRIPT_DIR}/demo/basic-demo/deploy.yaml" &>/dev/null
kubectl wait --for=condition=available --timeout=2m -n demo deployment/basic-demo &>/dev/null
echo "OK"
echo ""

# Step 6: Install OTel Operator + K8s collector
echo "[6/7] Installing OpenTelemetry Operator..."
helm repo add jetstack https://charts.jetstack.io &>/dev/null
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts &>/dev/null
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set installCRDs=true \
  --set prometheus.enabled=false \
  --set webhook.resources.requests.cpu=10m \
  --set webhook.resources.requests.memory=32Mi \
  --set cainjector.resources.requests.cpu=10m \
  --set cainjector.resources.requests.memory=32Mi \
  --set resources.requests.cpu=10m \
  --set resources.requests.memory=32Mi &>/dev/null

kubectl wait --for=condition=available --timeout=2m -n cert-manager deployment/cert-manager &>/dev/null

helm upgrade --install opentelemetry-operator open-telemetry/opentelemetry-operator \
  --namespace opentelemetry-operator-system --create-namespace \
  --set "manager.collectorImage.repository=ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-k8s" \
  --set admissionWebhooks.certManager.enabled=false \
  --set admissionWebhooks.autoGenerateCert.enabled=true \
  --set manager.resources.requests.cpu=20m \
  --set manager.resources.requests.memory=64Mi &>/dev/null

kubectl wait --for=condition=available --timeout=2m -n opentelemetry-operator-system deployment/opentelemetry-operator &>/dev/null

kubectl apply -f "${SCRIPT_DIR}/otel-collector-daemonset.yaml" &>/dev/null
echo "OK"
echo ""

# Step 7: Setup DNS
echo "[7/7] Configuring DNS..."
for i in $(seq 1 30); do
  INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
  [ -n "$INGRESS_IP" ] && break
  sleep 2
done

if [ -z "$INGRESS_IP" ]; then
  INGRESS_IP="127.0.0.1"
fi

if grep -q "signoz.local" /etc/hosts 2>/dev/null; then
  sudo sed -i '' "s/.*signoz.local/${INGRESS_IP} signoz.local/" /etc/hosts
else
  echo "${INGRESS_IP} signoz.local" | sudo tee -a /etc/hosts &>/dev/null
fi
echo "OK"
echo ""

echo "========================================="
echo "  Setup Complete!"
echo "========================================="
echo ""
echo "Access SigNoz: http://signoz.local"
echo ""
echo "Generate traces:"
echo "  kubectl port-forward -n demo svc/basic-demo 8080:80 &"
echo "  curl -s http://localhost:8080/"
echo "  curl -s http://localhost:8080/api/users"
echo "  curl -s http://localhost:8080/api/users/1"
echo ""
echo "Check status: kubectl get pods -A"
echo ""
