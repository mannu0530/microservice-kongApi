#!/bin/bash
# =============================================================================
# Destroy User Microservice from Kubernetes
# =============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${RED}========================================${NC}"
echo -e "${RED}Destroying User Microservice from Kubernetes${NC}"
echo -e "${RED}========================================${NC}"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Check if namespace exists
if kubectl get namespace user-microservice &> /dev/null; then
    echo -e "${YELLOW}Deleting namespace and all resources...${NC}"
    kubectl delete namespace user-microservice
    
    echo -e "${GREEN}Waiting for namespace to be deleted...${NC}"
    kubectl wait --for=delete namespace/user-microservice --timeout=60s || true
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}User Microservice destroyed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
else
    echo -e "${YELLOW}Namespace user-microservice does not exist. Nothing to destroy.${NC}"
fi
