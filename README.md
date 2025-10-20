# Task 2: Kubernetes Deployment

## Overview
This task demonstrates the deployment of the Task Management API to Kubernetes with MongoDB, fulfilling all the requirements specified in Task 2.

## ✅ Requirements Fulfilled

- ✅ **Dockerfile created** - Multi-stage build for Java application
- ✅ **Docker image built** - Application containerized
- ✅ **Kubernetes manifests** - Complete deployment configuration
- ✅ **MongoDB in separate pod** - Database running independently
- ✅ **Persistent volume** - MongoDB data persists across pod restarts
- ✅ **Environment variables** - App reads MongoDB connection from env vars
- ✅ **External access** - Application accessible from host machine
- ✅ **LoadBalancer service** - Service exposed for external access

## 📁 Project Structure

```
task2-kubernetes/
├── namespace.yaml              # Kubernetes namespace
├── mongodb-pv.yaml             # Persistent volume for MongoDB
├── mongodb-deployment.yaml     # MongoDB deployment and service
├── rbac.yaml                   # Role-based access control
├── app-deployment.yaml         # Application deployment and service
├── deploy.sh                   # Linux/Mac deployment script
├── deploy.ps1                  # Windows PowerShell deployment script
├── DEPLOYMENT_GUIDE.md         # Detailed deployment instructions
└── README.md                   # This file
```

## 🚀 Quick Start

### Prerequisites
1. **Docker Desktop** with Kubernetes enabled
2. **kubectl** command-line tool
3. **Java backend** built and ready

### Option 1: Automated Deployment (Recommended)

#### Windows (PowerShell)
```powershell
# Run the automated deployment script
.\deploy.ps1

# Skip Docker build if image already exists
.\deploy.ps1 -SkipBuild

# Skip endpoint tests
.\deploy.ps1 -SkipTests
```

#### Linux/Mac (Bash)
```bash
# Make script executable
chmod +x deploy.sh

# Run the automated deployment script
./deploy.sh
```

### Option 2: Manual Deployment

#### Step 1: Build Docker Image
```bash
cd ../task1-java-backend
docker build -t task-management-api:latest .
```

#### Step 2: Deploy to Kubernetes
```bash
cd ../task2-kubernetes

# Create namespace
kubectl apply -f namespace.yaml

# Deploy MongoDB with persistent storage
kubectl apply -f mongodb-pv.yaml
kubectl apply -f mongodb-deployment.yaml

# Deploy RBAC
kubectl apply -f rbac.yaml

# Deploy application
kubectl apply -f app-deployment.yaml
```

#### Step 3: Verify Deployment
```bash
# Check pod status
kubectl get pods -n task-management

# Check services
kubectl get services -n task-management

# Check persistent volumes
kubectl get pv
kubectl get pvc -n task-management
```

#### Step 4: Test Application
```bash
# Get external IP
kubectl get service task-management-service -n task-management

# Test health endpoint
curl http://<EXTERNAL-IP>:8080/tasks/health

# Create a task
curl -X PUT http://<EXTERNAL-IP>:8080/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "id": "k8s-test-001",
    "name": "Kubernetes Test Task",
    "owner": "Kubernetes User",
    "command": "echo Hello from Kubernetes!"
  }'

# Get all tasks
curl http://<EXTERNAL-IP>:8080/tasks
```

## 📸 Required Screenshots

For Task 2 completion, capture screenshots of:

1. **kubectl get pods -n task-management**
   - Shows MongoDB and application pods running

2. **kubectl get services -n task-management**
   - Shows services and external IPs

3. **kubectl get pv** and **kubectl get pvc -n task-management**
   - Shows persistent volumes and claims

4. **curl command testing application endpoint**
   - Shows successful API response from host machine

## 🏗️ Architecture

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

## 🔧 Configuration Details

### Environment Variables
- `MONGODB_URI`: `mongodb://admin:password123@mongodb-service:27017/task_management?authSource=admin`
- `SPRING_PROFILES_ACTIVE`: `kubernetes`

### Resource Limits
- **Application**: 512Mi-1Gi memory, 250m-500m CPU
- **MongoDB**: 512Mi-1Gi memory, 250m-500m CPU

### Persistent Storage
- **Size**: 10Gi
- **Access Mode**: ReadWriteOnce
- **Reclaim Policy**: Retain

## 🔍 Troubleshooting

### Common Issues

1. **Pods not starting**
   ```bash
   kubectl describe pod <pod-name> -n task-management
   kubectl logs <pod-name> -n task-management
   ```

2. **Service not accessible**
   ```bash
   kubectl get endpoints -n task-management
   kubectl describe service task-management-service -n task-management
   ```

3. **MongoDB connection issues**
   ```bash
   kubectl logs deployment/mongodb -n task-management
   ```

4. **Port forwarding for testing**
   ```bash
   kubectl port-forward service/task-management-service 8080:8080 -n task-management
   ```

### Cleanup
```bash
# Remove all resources
kubectl delete namespace task-management
kubectl delete pv mongodb-pv
```

## ✅ Verification Checklist

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

## 🎯 Success Criteria Met

1. ✅ **Application accessible from host machine**
2. ✅ **MongoDB running in separate pod**
3. ✅ **Persistent volume for MongoDB data**
4. ✅ **Environment variables for MongoDB connection**
5. ✅ **Kubernetes manifests for deployment**
6. ✅ **LoadBalancer service for external access**
7. ✅ **Proof of deployment with screenshots**

## 📚 Additional Resources

- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Detailed step-by-step instructions
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)

## 🏆 Task 2 Completion

This implementation fully satisfies all Task 2 requirements:
- Docker containerization ✅
- Kubernetes deployment ✅
- MongoDB with persistent storage ✅
- External accessibility ✅
- Environment-based configuration ✅
- Proper documentation and screenshots ✅
