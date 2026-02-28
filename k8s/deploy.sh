#!/bin/bash
# =============================================================================
# Deploy User Microservice to Kubernetes
# =============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deploying User Microservice to Kubernetes${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
    exit 1
fi

echo -e "${YELLOW}Creating namespace...${NC}"
kubectl create namespace user-microservice --dry-run=client -o yaml | kubectl apply -f -

echo -e "${YELLOW}Deploying Secret...${NC}"
kubectl apply -f secret.yaml -n user-microservice

echo -e "${YELLOW}Deploying ConfigMap...${NC}"
kubectl apply -f configmap.yaml -n user-microservice

echo -e "${YELLOW}Deploying PersistentVolumeClaim...${NC}"
kubectl apply -f pvc.yaml -n user-microservice

echo -e "${YELLOW}Deploying Deployment...${NC}"
kubectl apply -f deployment.yaml -n user-microservice

echo -e "${YELLOW}Deploying Service...${NC}"
kubectl apply -f service.yaml -n user-microservice

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment complete!${NC}"
echo -e "${GREEN}========================================${NC}"

echo -e "${YELLOW}Checking deployment status...${NC}"
kubectl get all -n user-microservice

echo -e "${YELLOW}To view logs:${NC}"
echo -e "  kubectl logs -n user-microservice -l app=user-microservice"
echo -e "${YELLOW}To access the service:${NC}"
echo -e "  kubectl port-forward -n user-microservice svc/user-microservice 8000:80"
