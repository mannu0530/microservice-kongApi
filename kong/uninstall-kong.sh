#!/bin/bash
# =============================================================================
# Uninstall Kong Gateway from Kubernetes
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}========================================${NC}"
echo -e "${RED}Uninstalling Kong Gateway${NC}"
echo -e "${RED}========================================${NC}"

# Uninstall Kong
echo -e "${YELLOW}Uninstalling Kong via Helm...${NC}"
helm uninstall kong -n kong || true

# Delete namespace
echo -e "${YELLOW}Deleting Kong namespace...${NC}"
kubectl delete namespace kong --wait=true --timeout=60s || true

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Kong Gateway uninstalled successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
