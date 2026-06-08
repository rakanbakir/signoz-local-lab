#!/bin/bash
set -e

echo "========================================="
echo "  DNS Setup for signoz.local"
echo "========================================="
echo ""

# Get the nginx-ingress LoadBalancer IP
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

if [ -z "$INGRESS_IP" ]; then
  echo "Error: Could not get nginx-ingress LoadBalancer IP."
  echo "Make sure nginx-ingress is installed and has an external IP assigned."
  echo ""
  echo "Current ingress service status:"
  kubectl get svc -n ingress-nginx ingress-nginx-controller
  exit 1
fi

echo "nginx-ingress LoadBalancer IP: ${INGRESS_IP}"
echo ""

# Check if entry already exists
if grep -q "signoz.local" /etc/hosts 2>/dev/null; then
  echo "signoz.local already exists in /etc/hosts. Updating..."
  sudo sed -i '' "s/.*signoz.local/${INGRESS_IP} signoz.local/" /etc/hosts
else
  echo "Adding signoz.local to /etc/hosts..."
  echo "${INGRESS_IP} signoz.local" | sudo tee -a /etc/hosts
fi

echo ""
echo "DNS configured successfully!"
echo ""
echo "You can now access SigNoz at: http://signoz.local"
echo ""
echo "Verify with: curl -H 'Host: signoz.local' http://localhost"
echo ""
