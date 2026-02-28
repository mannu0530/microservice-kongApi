#!/bin/bash
# =============================================================================
# Kong Gateway Installation Script
# =============================================================================
# Installs Kong Gateway OSS in DB-less mode on Kubernetes (Minikube)
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Kong Gateway Installation ===${NC}"

# -----------------------------------------------------------------------------
# Step 1: Create namespace
# -----------------------------------------------------------------------------
echo -e "${YELLOW}Creating kong namespace...${NC}"
kubectl create ns kong || true

# -----------------------------------------------------------------------------
# Step 2: Add Kong Helm repo if not present
# -----------------------------------------------------------------------------
echo -e "${YELLOW}Checking Kong Helm repository...${NC}"
helm repo add kong https://charts.konghq.com || true
helm repo update

# -----------------------------------------------------------------------------
# Step 3: Create ConfigMap for declarative configuration
# -----------------------------------------------------------------------------
echo -e "${YELLOW}Creating Kong declarative config ConfigMap...${NC}"
kubectl create configmap kong-declarative-config \
    -n kong \
    --from-file=kong.yaml=./kong.yaml \
    --dry-run=client -o yaml | kubectl apply -f -

# -----------------------------------------------------------------------------
# Step 4: Install Kong using Helm
# -----------------------------------------------------------------------------
echo -e "${YELLOW}Installing Kong Gateway via Helm...${NC}"
helm install kong kong/kong \
    -n kong \
    -f ./values.yaml \
    --set ingressController.enabled=true \
    --set ingressController.installCRDs=false \
    --set ingressController.env.kong_admin_url=http://kong-kong-admin:8001

# -----------------------------------------------------------------------------
# Step 5: Wait for Kong to be ready
# -----------------------------------------------------------------------------
echo -e "${YELLOW}Waiting for Kong pods to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=kong -n kong --timeout=120s || true

# -----------------------------------------------------------------------------
# Step 6: Display status
# -----------------------------------------------------------------------------
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo ""
echo "Kong Gateway has been installed in DB-less mode."
echo ""
echo "Services:"
kubectl get svc -n kong
echo ""
echo "Pods:"
kubectl get pods -n kong
echo ""
echo -e "${GREEN}Access Kong Gateway:${NC}"
echo "  NodePort: minikube ip:30080"
echo "  Or use port-forward: kubectl port-forward -n kong svc/kong-kong-proxy 8080:80"
echo ""
echo -e "${GREEN}Test Kong:${NC}"
echo "  curl http://\$(minikube ip):30080"
echo ""
