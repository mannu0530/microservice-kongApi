# User Microservice

A minimal FastAPI-based user microservice with JWT authentication, SQLite database, and Kong API Gateway integration.

## Features

- **FastAPI** - Modern Python web framework for building APIs
- **SQLite** - File-based database (auto-created on startup)
- **bcrypt** - Secure password hashing
- **PyJWT** - JWT token-based authentication
- **Kong Gateway** - API Gateway for routing and rate limiting
- **Kubernetes** - Deployable to Kubernetes via Helm chart
- **Auto Database Creation** - Tables created automatically at startup

## Project Structure

```
user_service/
├── config.py              # Configuration and environment variables
├── database.py            # Database models and SQLAlchemy operations
├── auth.py                # JWT and password hashing utilities
├── main.py                # FastAPI application and endpoints
├── requirements.txt       # Python dependencies
├── Dockerfile             # Docker container image
├── README.md              # This file
├── helm/                  # Helm chart for Kubernetes
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── secret.yaml
│       ├── pvc.yaml
│       └── NOTES.txt
├── k8s/                   # Kubernetes manifests (alternative to Helm)
└── kong/                  # Kong Gateway configuration
```

## Quick Start

### Prerequisites

- Python 3.11+
- Docker
- Minikube or Kubernetes cluster
- kubectl
- Helm 3+

## Local Development

### Installation

```bash
cd user_service
pip install -r requirements.txt
```

### Running Locally

```bash
python main.py
# OR
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

## Docker Deployment

### Build Image

```bash
cd user_service
docker build -t user-microservice:latest .
```

### Run Container

```bash
docker run -d \
  --name user-microservice \
  -p 8000:8000 \
  -e JWT_SECRET=your-secret-key \
  user-microservice:latest
```

## Kubernetes Deployment (Helm Chart)

### Prerequisites

- Minikube started: `minikube start`
- Docker image built and loaded into Minikube

### Deploy with Helm

```bash
# Load Docker image into Minikube
minikube image load user-microservice:latest

# Create namespace
kubectl create namespace user-ms

# Deploy using Helm
cd user_service/helm
helm install user-microservice . --namespace user-ms
```

### Access the Service

```bash
# Port forward to the service
kubectl port-forward -n user-ms svc/user-microservice-user-microservice 8080:80
```

## Kong Gateway Deployment

### Install Kong

```bash
# Add Kong Helm repo
helm repo add kong https://charts.konghq.com
helm repo update

# Install Kong
helm install kong kong/kong -n kong --create-namespace \
  --set ingressController.enabled=false \
  --set proxy.type=NodePort
```

### Access Kong

```bash
# Port forward to Kong
kubectl port-forward -n kong svc/kong-kong-proxy 8081:80
```

## API Endpoints

### 1. Health Check (Public)
```
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2026-02-28T06:38:24.397828",
  "database": "connected"
}
```

---

### 2. Login (Public)
```
POST /login
```

**Request Body:**
```json
{
  "username": "admin",
  "password": "admin123"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 60
}
```

---

### 3. Verify Token (Protected)
```
GET /verify
```

**Headers:**
```
Authorization: Bearer <your-jwt-token>
```

**Response (Success):**
```json
{
  "valid": true,
  "username": "admin",
  "user_id": "1",
  "expires_at": "2026-02-28T07:38:25"
}
```

**Response (No Token):**
```json
{
  "detail": "No token provided"
}
```

---

### 4. Get Users (Protected)
```
GET /users
```

**Headers:**
```
Authorization: Bearer <your-jwt-token>
```

**Response:**
```json
{
  "users": [
    {
      "id": 1,
      "username": "admin",
      "email": "admin@example.com",
      "is_active": true,
      "created_at": null
    }
  ],
  "total": 1
}
```

---

## Testing with cURL

### 1. Health Check
```bash
curl http://localhost:8080/health
```

**Expected Output:**
```json
{"status":"healthy","timestamp":"2026-02-28T06:38:24.397828","database":"connected"}
```

---

### 2. Login
```bash
curl -X POST http://localhost:8080/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}'
```

**Expected Output:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 60
}
```

---

### 3. Verify Token (With JWT)
```bash
TOKEN="<your-jwt-token>"
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/verify
```

**Expected Output:**
```json
{
  "valid": true,
  "username": "admin",
  "user_id": "1",
  "expires_at": "2026-02-28T07:38:25"
}
```

---

### 4. Get Users (With JWT)
```bash
TOKEN="<your-jwt-token>"
curl -H "Authorization: Bearer $TOKEN" http://localhost:808**Expected Output:**
```json
{
0/users
```

  "users": [
    {
      "id": 1,
      "username": "admin",
      "email": "admin@example.com",
      "is_active": true,
      "created_at": null
    }
  ],
  "total": 1
}
```

---

### 5. Verify Token (Without JWT - Should Fail)
```bash
curl http://localhost:8080/verify
```

**Expected Output:**
```json
{"detail":"No token provided"}
```

**HTTP Status:** 401 Unauthorized

---

### 6. Get Users (Without JWT - Should Fail)
```bash
curl http://localhost:8080/users
```

**Expected Output:**
```json
{"detail":"Authentication required"}
```

**HTTP Status:** 401 Unauthorized

---

## Test Results Summary

| Endpoint | Auth Required | Status | Result |
|----------|---------------|--------|--------|
| GET /health | No | 200 ✅ | Healthy |
| POST /login | No | 200 ✅ | Token received |
| GET /verify | Yes (JWT) | 200 ✅ | Valid token |
| GET /users | Yes (JWT) | 200 ✅ | User data returned |
| GET /verify | No | 401 ❌ | No token provided |
| GET /users | No | 401 ❌ | Authentication required |

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `JWT_SECRET` | `dev-secret-key-change-in-production` | Secret key for signing JWT tokens |
| `JWT_ALGORITHM` | `HS256` | JWT algorithm |
| `JWT_EXPIRATION_MINUTES` | `60` | Token expiration time in minutes |
| `DATABASE_URL` | `/app/data/users.db` | SQLite database file path |
| `HOST` | `0.0.0.0` | Server host address |
| `PORT` | `8000` | Server port number |
| `DEBUG` | `false` | Enable debug mode |

## Default User

On first startup, a default admin user is created:
- **Username:** `admin`
- **Password:** `admin123`

**Important:** Change the default password in production!

## Helm Chart Values

The Helm chart supports configurable values:

```yaml
# values.yaml
image:
  repository: user-microservice
  tag: latest
  pullPolicy: IfNotPresent

replicaCount: 1

service:
  type: ClusterIP
  port: 80
  targetPort: 8000
  containerPort: 8000

persistence:
  enabled: true
  size: 1Gi
  mountPath: /app/data

secrets:
  jwtSecret: "change-me-in-production"
  adminUsername: "admin"
  adminPassword: "admin123"

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 256Mi
```

## Clean Up

### Remove Helm Deployment

```bash
helm uninstall user-microservice -n user-ms
kubectl delete namespace user-ms
```

### Remove Kong

```bash
helm uninstall kong -n kong
kubectl delete namespace kong
```

### Stop Minikube

```bash
minikube stop
# OR
minikube delete
```

## Interactive API Documentation

FastAPI provides automatic interactive API documentation:

- **Swagger UI:** http://localhost:8080/docs
- **ReDoc:** http://localhost:8080/redoc

## Troubleshooting

### Pod not starting

Check pod logs:
```bash
kubectl describe pod <pod-name> -n user-ms
kubectl logs <pod-name> -n user-ms
```

### Database permission error

Ensure the `/app/data` directory exists and has proper permissions. The Dockerfile creates this directory with correct ownership.

### Kong readiness probe failure

Kong 3.x has a known issue with readiness probes. Patch with:
```bash
kubectl patch deployment kong-kong -n kong -p '{"spec":{"template":{"spec":{"containers":[{"name":"proxy","readinessProbe":{"httpGet":{"path":"/status","port":8100}}}]}}}}'
```

## License

MIT
