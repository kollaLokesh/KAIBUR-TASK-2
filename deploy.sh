#!/bin/bash
# Task 2: Kubernetes Deployment Script
# This script automates the deployment of the Task Management API to Kubernetes

set -e

echo "=== Task 2: Kubernetes Deployment ==="
echo "Starting deployment process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker Desktop first."
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if Kubernetes cluster is running
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Kubernetes cluster is not running. Please start your cluster first."
        exit 1
    fi
    
    print_status "Prerequisites check passed!"
}

# Build Docker image
build_image() {
    print_status "Building Docker image..."
    
    # Navigate to the Java backend directory
    cd ../task1-java-backend
    
    # Build the image
    docker build -t task-management-api:latest .
    
    if [ $? -eq 0 ]; then
        print_status "Docker image built successfully!"
    else
        print_error "Failed to build Docker image"
        exit 1
    fi
    
    # Return to task2 directory
    cd ../task2-kubernetes
}

# Deploy to Kubernetes
deploy_to_k8s() {
    print_status "Deploying to Kubernetes..."
    
    # Create namespace
    print_status "Creating namespace..."
    kubectl apply -f namespace.yaml
    
    # Deploy MongoDB with persistent storage
    print_status "Deploying MongoDB with persistent storage..."
    kubectl apply -f mongodb-pv.yaml
    kubectl apply -f mongodb-deployment.yaml
    
    # Deploy RBAC
    print_status "Deploying RBAC configuration..."
    kubectl apply -f rbac.yaml
    
    # Deploy application
    print_status "Deploying application..."
    kubectl apply -f app-deployment.yaml
    
    print_status "Deployment completed!"
}

# Wait for pods to be ready
wait_for_pods() {
    print_status "Waiting for pods to be ready..."
    
    # Wait for MongoDB pod
    kubectl wait --for=condition=ready pod -l app=mongodb -n task-management --timeout=300s
    
    # Wait for application pods
    kubectl wait --for=condition=ready pod -l app=task-management-app -n task-management --timeout=300s
    
    print_status "All pods are ready!"
}

# Verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    echo ""
    echo "=== Pod Status ==="
    kubectl get pods -n task-management
    
    echo ""
    echo "=== Services ==="
    kubectl get services -n task-management
    
    echo ""
    echo "=== Persistent Volumes ==="
    kubectl get pv
    
    echo ""
    echo "=== Persistent Volume Claims ==="
    kubectl get pvc -n task-management
    
    echo ""
    echo "=== External Access Information ==="
    kubectl get service task-management-service -n task-management
}

# Test application endpoints
test_endpoints() {
    print_status "Testing application endpoints..."
    
    # Get the external IP
    EXTERNAL_IP=$(kubectl get service task-management-service -n task-management -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    
    if [ -z "$EXTERNAL_IP" ]; then
        print_warning "LoadBalancer IP not available. You may need to use port-forwarding:"
        print_warning "kubectl port-forward service/task-management-service 8080:8080 -n task-management"
        EXTERNAL_IP="localhost"
    fi
    
    echo ""
    print_status "Testing health endpoint..."
    curl -f http://$EXTERNAL_IP:8080/tasks/health || print_warning "Health check failed - service may still be starting"
    
    echo ""
    print_status "Testing task creation..."
    curl -X PUT http://$EXTERNAL_IP:8080/tasks \
      -H "Content-Type: application/json" \
      -d '{
        "id": "k8s-test-001",
        "name": "Kubernetes Test Task",
        "owner": "Kubernetes User",
        "command": "echo Hello from Kubernetes!"
      }' || print_warning "Task creation failed - service may still be starting"
    
    echo ""
    print_status "Testing task retrieval..."
    curl http://$EXTERNAL_IP:8080/tasks || print_warning "Task retrieval failed"
}

# Main execution
main() {
    echo "Task 2: Kubernetes Deployment Script"
    echo "====================================="
    
    check_prerequisites
    build_image
    deploy_to_k8s
    wait_for_pods
    verify_deployment
    test_endpoints
    
    echo ""
    print_status "Deployment completed successfully!"
    print_status "Please take screenshots of the kubectl commands and curl tests as required for Task 2."
    print_status "External access: kubectl get service task-management-service -n task-management"
}

# Run main function
main "$@"
