# Task 2: Kubernetes Deployment Guide

## Overview
This guide provides step-by-step instructions to deploy the Task Management API to Kubernetes with MongoDB, following the Task 2 requirements.

## Prerequisites Setup

### 1. Install Docker Desktop
1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop/
2. Install and start Docker Desktop
3. Enable Kubernetes in Docker Desktop:
   - Go to Settings → Kubernetes
   - Check "Enable Kubernetes"
   - Click "Apply & Restart"

### 2. Install kubectl (if not included with Docker Desktop)
```bash
# Windows (using Chocolatey)
choco install kubernetes-cli

# Or download directly from:
# https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
```

### 3. Verify Installation
```bash
docker --version
kubectl version --client
kubectl cluster-info
```

## Deployment Steps

### Step 1: Build Docker Image
```bash
# Navigate to the Java backend directory
cd task1-java-backend

# Build the Docker image
docker build -t task-management-api:latest .

# Verify the image was created
docker images | grep task-management-api
```

### Step 2: Deploy to Kubernetes

#### 2.1 Create Namespace
```bash
kubectl apply -f task2-kubernetes/namespace.yaml
```

#### 2.2 Deploy MongoDB with Persistent Storage
```bash
# Deploy persistent volume and claim
kubectl apply -f task2-kubernetes/mongodb-pv.yaml

# Deploy MongoDB
kubectl apply -f task2-kubernetes/mongodb-deployment.yaml

# Verify MongoDB is running
kubectl get pods -n task-management
kubectl get pv
kubectl get pvc -n task-management
```

#### 2.3 Deploy RBAC
```bash
kubectl apply -f task2-kubernetes/rbac.yaml
```

#### 2.4 Deploy Application
```bash
kubectl apply -f task2-kubernetes/app-deployment.yaml

# Verify application is running
kubectl get pods -n task-management
kubectl get services -n task-management
```

### Step 3: Verify Deployment

#### 3.1 Check Pod Status
```bash
kubectl get pods -n task-management
kubectl describe pod <pod-name> -n task-management
```

#### 3.2 Check Services
```bash
kubectl get services -n task-management
kubectl describe service task-management-service -n task-management
```

#### 3.3 Get External IP/Port
```bash
# For LoadBalancer service
kubectl get service task-management-service -n task-management

# For NodePort service (if using minikube)
minikube service task-management-service -n task-management
```

### Step 4: Test Application Endpoints

#### 4.1 Health Check
```bash
curl http://<EXTERNAL-IP>:8080/tasks/health
```

#### 4.2 Create a Task
```bash
curl -X PUT http://<EXTERNAL-IP>:8080/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "id": "k8s-test-001",
    "name": "Kubernetes Test Task",
    "owner": "Kubernetes User",
    "command": "echo Hello from Kubernetes!"
  }'
```

#### 4.3 Get All Tasks
```bash
curl http://<EXTERNAL-IP>:8080/tasks
```

#### 4.4 Execute Task
```bash
curl -X PUT http://<EXTERNAL-IP>:8080/tasks/k8s-test-001/execute
```

#### 4.5 Search Tasks
```bash
curl "http://<EXTERNAL-IP>:8080/tasks/search?name=Kubernetes"
```

## Required Screenshots for Task 2

Take screenshots of the following commands and their outputs:

1. **kubectl get pods -n task-management**
   - Shows both MongoDB and application pods running

2. **kubectl get services -n task-management**
   - Shows services and external IPs

3. **kubectl get pv**
   - Shows persistent volumes

4. **kubectl get pvc -n task-management**
   - Shows persistent volume claims

5. **curl command testing application endpoint**
   - Shows successful API response from host machine

## Troubleshooting

### Common Issues

1. **Pods not starting**
   ```bash
   kubectl describe pod <pod-name> -n task-management
   kubectl logs <pod-name> -n task-management
   ```

2. **MongoDB connection issues**
   ```bash
   kubectl logs deployment/mongodb -n task-management
   kubectl exec -it <mongodb-pod> -n task-management -- mongo --host localhost
   ```

3. **Service not accessible**
   ```bash
   kubectl get endpoints -n task-management
   kubectl describe service task-management-service -n task-management
   ```

4. **Persistent volume issues**
   ```bash
   kubectl describe pvc mongodb-pvc -n task-management
   kubectl describe pv mongodb-pv
   ```

### Cleanup
```bash
kubectl delete namespace task-management
kubectl delete pv mongodb-pv
```

## Verification Checklist

- [ ] Docker image built successfully
- [ ] Namespace created
- [ ] MongoDB pod running with persistent storage
- [ ] Application pod running
- [ ] Services created and accessible
- [ ] Health endpoint responding
- [ ] Task CRUD operations working
- [ ] Task execution working
- [ ] Data persists after pod restart
- [ ] Screenshots captured

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐
│   Host Machine  │    │  Kubernetes     │
│                 │    │  Cluster        │
│  curl commands  │◄───┤                 │
│                 │    │  ┌─────────────┐│
└─────────────────┘    │  │   Service   ││
                       │  │ LoadBalancer││
                       │  └─────────────┘│
                       │         │      │
                       │  ┌──────▼─────┐ │
                       │  │    App    │ │
                       │  │   Pods    │ │
                       │  └──────┬─────┘ │
                       │         │      │
                       │  ┌──────▼─────┐ │
                       │  │  MongoDB   │ │
                       │  │    Pod    │ │
                       │  └──────┬─────┘ │
                       │         │      │
                       │  ┌──────▼─────┐ │
                       │  │Persistent │ │
                       │  │  Volume   │ │
                       │  └───────────┘ │
                       └─────────────────┘
```

## Environment Variables

The application uses these environment variables:
- `MONGODB_URI`: MongoDB connection string
- `SPRING_PROFILES_ACTIVE`: Spring profile (kubernetes)

## Security Features

- Non-root user in containers
- RBAC for pod creation permissions
- Resource limits and requests
- Health checks and probes
- Persistent storage for data

## Next Steps

After successful deployment:
1. Test all API endpoints
2. Verify data persistence
3. Take required screenshots
4. Document any issues encountered
5. Clean up resources when done
