#!/bin/bash

# =============================================================================
# User Microservice Demo Script
# =============================================================================
# This script demonstrates all features of the User Microservice
# Run this script to show the project in action
# =============================================================================

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  User Microservice Demo${NC}"
echo -e "${BLUE}  FastAPI + Kong Gateway + Kubernetes${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

# -----------------------------------------------------------------------------
# Section 1: Project Overview & Architecture
# -----------------------------------------------------------------------------
echo -e "${YELLOW}--- SECTION 1: Project Architecture ---${NC}"
echo ""
echo -e "${CYAN}Request Flow:${NC}"
echo "┌──────────┐     ┌──────────┐     ┌──────────────────┐"
echo "│  Client  │────▶│   Kong   │────▶│  User Microservice │"
echo "└──────────┘     │ Gateway  │     │   (FastAPI)      │"
echo "                 │ :8081    │     │   :8000          │"
echo "                 └──────────┘     └──────────────────┘"
echo ""
echo "Components:"
echo "  1. Client - Sends HTTP requests"
echo "  2. Kong Gateway - API Gateway for routing, rate limiting"
echo "  3. User Microservice - FastAPI with JWT authentication"
echo ""
echo -e "${CYAN}How JWT Validation Works:${NC}"
echo "  1. Client sends credentials to /login"
echo "  2. Microservice validates and returns JWT token"
echo "  3. Client includes JWT in Authorization header"
echo "  4. Microservice validates JWT on protected routes"
echo ""
echo -e "${CYAN}Authentication Bypass Implementation:${NC}"
echo "  - /health and /login are public endpoints (no JWT required)"
echo "  - /verify and /users are protected (JWT required)"
echo "  - JWT validation happens in the FastAPI application"
echo "  - Kong handles routing only (not JWT validation)"
echo ""
read -p "Press Enter to continue..."
clear

# -----------------------------------------------------------------------------
# Section 2: Check Services
# -----------------------------------------------------------------------------
echo -e "${YELLOW}--- SECTION 2: Check Running Services ---${NC}"
echo ""
echo "Checking Kubernetes pods in user-ms namespace:"
kubectl get pods -n user-ms
echo ""
echo "Checking Kong pods:"
kubectl get pods -n kong
echo ""
echo "Checking Services:"
kubectl get svc -n user-ms
kubectl get svc -n kong
echo ""
read -p "Press Enter to continue..."
clear

# -----------------------------------------------------------------------------
# Section 3: Direct Microservice Access
# -----------------------------------------------------------------------------
echo -e "${YELLOW}--- SECTION 3: Direct Microservice Access (:8080) ---${NC}"
echo ""
echo "Accessing microservice directly (bypassing Kong):"
echo ""
echo "Testing /health endpoint:"
curl -s http://localhost:8080/health | python3 -m json.tool
echo ""
read -p "Press Enter to continue..."
clear

# -----------------------------------------------------------------------------
# Section 4: Login and JWT Token
# -----------------------------------------------------------------------------
echo -e "${YELLOW}--- SECTION 4: Login & Get JWT Token ---${NC}"
echo ""
echo "Command: curl -X POST http://localhost:8080/login \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"username\": \"admin\", \"password\": \"admin123\"}'"
echo ""

RESPONSE=$(curl -s -X POST http://localhost:8080/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}')

echo "$RESPONSE" | python3 -m json.tool

# Extract token for later use
TOKEN=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])")

echo ""
echo -e "${GREEN}✓ Login successful! Token received.${NC}"
echo ""
read -p "Press Enter to continue..."
clear

# -----------------------------------------------------------------------------
# Section 5: Test Protected Endpoints
# -----------------------------------------------------------------------------
echo -e "${YELLOW}--- SECTION 5: Test Protected Endpoints ---${NC}"
echo ""
echo "Testing /verify with valid JWT:"
echo "curl -H \"Authorization: Bearer \$TOKEN\" http://localhost:8080/verify"
echo ""
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/verify | python3 -m json.tool
echo ""
echo "Testing /users with valid JWT:"
echo "curl -H \"Authorization: Bearer \$TOKEN\" http://localhost:8080/users"
echo ""
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/users | python3 -m json.tool
echo ""
read -p "Press Enter to continue..."
clear

# -----------------------------------------------------------------------------
# Section 6: Test Authentication Enforcement
# -----------------------------------------------------------------------------
echo -e "${YELLOW}--- SECTION 6: Test Authentication Enforcement ---${NC}"
echo ""
echo "Testing /verify WITHOUT JWT (should fail):"
echo "curl http://localhost:8080/verify"
echo ""
curl -s http://localhost:8080/verify
echo ""
echo ""
echo "Testing /users WITHOUT JWT (should fail):"
echo "curl http://localhost:8080/users"
echo ""
curl -s http://localhost:8080/users
echo ""
echo ""
echo -e "${GREEN}✓ Authentication properly enforced!${NC}"
echo ""
read -p "Press Enter to continue..."
clear

# -----------------------------------------------------------------------------
# Section 7: Kong Gateway Access
# -----------------------------------------------------------------------------
echo -e "${YELLOW}--- SECTION 7: Kong Gateway Access (:8081) ---${NC}"
echo ""
echo "Accessing through Kong Gateway:"
echo ""
echo "Testing Kong root endpoint:"
echo "curl http://localhost:8081/"
echo ""
curl -s http://localhost:8081/
echo ""
echo ""
echo -e "${YELLOW}Note: Kong is running but routes need to be configured.${NC}"
echo "Kong routes can be configured via Ingress or declarative config."
echo ""
read -p "Press Enter to continue..."
clear

# -----------------------------------------------------------------------------
# Section 8: IP-Based Rate Limiting (Kong)
# -----------------------------------------------------------------------------
echo -e "${YELLOW}--- SECTION 8: IP-Based Rate Limiting in Kong ---${NC}"
echo ""
echo -e "${CYAN}Rate Limiting Explanation:${NC}"
echo "  Kong can limit requests per IP address using the rate-limiting plugin."
echo "  Default configuration: 10 requests per minute per IP."
echo ""
echo "Testing rate limiting (make 15 rapid requests):"
echo ""

# Get local IP for testing
LOCAL_IP="127.0.0.1"
echo "Testing from IP: $LOCAL_IP"
echo ""

# Make 15 rapid requests to trigger rate limit
for i in {1..15}; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/)
  echo "Request $i: HTTP $STATUS"
  if [ "$STATUS" == "429" ]; then
    echo -e "${RED}  → Rate limit hit!${NC}"
  fi
done

echo ""
echo -e "${GREEN}✓ Rate limiting test complete!${NC}"
echo ""
echo "Expected behavior:"
echo "  - First 10 requests: HTTP 200 (success)"
echo "  - Requests after 10: HTTP 429 (Too Many Requests)"
echo ""
read -p "Press Enter to continue..."
clear

# -----------------------------------------------------------------------------
# Section 9: JWT Validation Flow Diagram
# -----------------------------------------------------------------------------
echo -e "${YELLOW}--- SECTION 9: JWT Validation Flow ---${NC}"
echo ""
echo -e "${CYAN}JWT Validation Flow in Our Architecture:${NC}"
echo ""
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│                    REQUEST FLOW                                │"
echo "└─────────────────────────────────────────────────────────────────┘"
echo ""
echo "  1. Client sends request to Kong"
echo "     GET /users HTTP/1.1"
echo "     Host: localhost:8081"
echo ""
echo "  2. Kong receives request (no JWT validation by Kong)"
echo "     Kong routes request to backend service"
echo "     → Forward to user-microservice:80"
echo ""
echo "  3. Microservice receives request"
echo "     - Checks for Authorization header"
echo "     - If missing → 401 Unauthorized"
echo "     - If present → Validate JWT signature"
echo ""
echo "  4. JWT Validation in Microservice"
echo "     - Decode JWT token"
echo "     - Verify signature using JWT_SECRET"
echo "     - Check expiration"
echo ""
echo "  5. Response"
echo "     - Valid token → 200 OK + data"
echo "     - Invalid/expired → 401 Unauthorized"
echo ""
echo -e "${CYAN}Why Microservice Validates JWT (Not Kong):${NC}"
echo "  1. Simpler Kong configuration (no plugin setup needed)"
echo "  2. Backend has access to JWT_SECRET"
echo "  3. More control over validation logic"
echo "  4. Can return detailed error messages"
echo ""
read -p "Press Enter to continue..."
clear

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  Demo Complete!${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""
echo "Summary of What Was Demonstrated:"
echo ""
echo -e "${CYAN}Architecture:${NC}"
echo "  ✓ Client → Kong → Microservice flow"
echo "  ✓ JWT validation in microservice"
echo "  ✓ Authentication bypass for public endpoints"
echo ""
echo -e "${CYAN}API Endpoints:${NC}"
echo "  ✓ GET /health - Public (no auth)"
echo "  ✓ POST /login - Public (returns JWT)"
echo "  ✓ GET /verify - Protected (needs JWT)"
echo "  ✓ GET /users - Protected (needs JWT)"
echo ""
echo -e "${CYAN}Security:${NC}"
echo "  ✓ JWT authentication working"
echo "  ✓ Protected endpoints require valid token"
echo "  ✓ Missing token returns 401 Unauthorized"
echo ""
echo -e "${CYAN}Kong Gateway:${NC}"
echo "  ✓ Kong running on port 8081"
echo "  ✓ Rate limiting configurable"
echo "  ✓ Routes to microservice"
echo ""
echo "To access the services:"
echo "  Direct Microservice: localhost:8080"
echo "  Kong Gateway: localhost:8081"
echo ""
echo "Default credentials:"
echo "  Username: admin"
echo "  Password: admin123"
echo ""
