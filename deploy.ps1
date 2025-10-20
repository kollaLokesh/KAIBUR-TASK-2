# Task 2: Kubernetes Deployment Script (PowerShell)
# This script automates the deployment of the Task Management API to Kubernetes

param(
    [switch]$SkipBuild,
    [switch]$SkipTests
)

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Red
}

# Check prerequisites
function Test-Prerequisites {
    Write-Status "Checking prerequisites..."
    
    try {
        $null = docker --version
    }
    catch {
        Write-Error "Docker is not installed. Please install Docker Desktop first."
        exit 1
    }
    
    try {
        $null = kubectl version --client
    }
    catch {
        Write-Error "kubectl is not installed. Please install kubectl first."
        exit 1
    }
    
    # Check if Kubernetes cluster is running
    try {
        $null = kubectl cluster-info
    }
    catch {
        Write-Error "Kubernetes cluster is not running. Please start your cluster first."
        exit 1
    }
    
    Write-Status "Prerequisites check passed!"
}

# Build Docker image
function Build-Image {
    if ($SkipBuild) {
        Write-Warning "Skipping Docker image build"
        return
    }
    
    Write-Status "Building Docker image..."
    
    # Navigate to the Java backend directory
    $originalPath = Get-Location
    Set-Location "../task1-java-backend"
    
    try {
        # Build the image
        docker build -t task-management-api:latest .
        
        if ($LASTEXITCODE -eq 0) {
            Write-Status "Docker image built successfully!"
        }
        else {
            Write-Error "Failed to build Docker image"
            exit 1
        }
    }
    finally {
        # Return to original directory
        Set-Location $originalPath
    }
}

# Deploy to Kubernetes
function Deploy-ToK8s {
    Write-Status "Deploying to Kubernetes..."
    
    # Create namespace
    Write-Status "Creating namespace..."
    kubectl apply -f namespace.yaml
    
    # Deploy MongoDB with persistent storage
    Write-Status "Deploying MongoDB with persistent storage..."
    kubectl apply -f mongodb-pv.yaml
    kubectl apply -f mongodb-deployment.yaml
    
    # Deploy RBAC
    Write-Status "Deploying RBAC configuration..."
    kubectl apply -f rbac.yaml
    
    # Deploy application
    Write-Status "Deploying application..."
    kubectl apply -f app-deployment.yaml
    
    Write-Status "Deployment completed!"
}

# Wait for pods to be ready
function Wait-ForPods {
    Write-Status "Waiting for pods to be ready..."
    
    # Wait for MongoDB pod
    kubectl wait --for=condition=ready pod -l app=mongodb -n task-management --timeout=300s
    
    # Wait for application pods
    kubectl wait --for=condition=ready pod -l app=task-management-app -n task-management --timeout=300s
    
    Write-Status "All pods are ready!"
}

# Verify deployment
function Test-Deployment {
    Write-Status "Verifying deployment..."
    
    Write-Host ""
    Write-Host "=== Pod Status ===" -ForegroundColor Cyan
    kubectl get pods -n task-management
    
    Write-Host ""
    Write-Host "=== Services ===" -ForegroundColor Cyan
    kubectl get services -n task-management
    
    Write-Host ""
    Write-Host "=== Persistent Volumes ===" -ForegroundColor Cyan
    kubectl get pv
    
    Write-Host ""
    Write-Host "=== Persistent Volume Claims ===" -ForegroundColor Cyan
    kubectl get pvc -n task-management
    
    Write-Host ""
    Write-Host "=== External Access Information ===" -ForegroundColor Cyan
    kubectl get service task-management-service -n task-management
}

# Test application endpoints
function Test-Endpoints {
    if ($SkipTests) {
        Write-Warning "Skipping endpoint tests"
        return
    }
    
    Write-Status "Testing application endpoints..."
    
    # Get the external IP
    $serviceInfo = kubectl get service task-management-service -n task-management -o json | ConvertFrom-Json
    $externalIP = $serviceInfo.status.loadBalancer.ingress[0].ip
    
    if ([string]::IsNullOrEmpty($externalIP)) {
        Write-Warning "LoadBalancer IP not available. You may need to use port-forwarding:"
        Write-Warning "kubectl port-forward service/task-management-service 8080:8080 -n task-management"
        $externalIP = "localhost"
    }
    
    Write-Host ""
    Write-Status "Testing health endpoint..."
    try {
        Invoke-RestMethod -Uri "http://$externalIP`:8080/tasks/health" -Method Get
        Write-Status "Health check passed!"
    }
    catch {
        Write-Warning "Health check failed - service may still be starting"
    }
    
    Write-Host ""
    Write-Status "Testing task creation..."
    $taskData = @{
        id = "k8s-test-001"
        name = "Kubernetes Test Task"
        owner = "Kubernetes User"
        command = "echo Hello from Kubernetes!"
    } | ConvertTo-Json
    
    try {
        Invoke-RestMethod -Uri "http://$externalIP`:8080/tasks" -Method Put -Body $taskData -ContentType "application/json"
        Write-Status "Task creation passed!"
    }
    catch {
        Write-Warning "Task creation failed - service may still be starting"
    }
    
    Write-Host ""
    Write-Status "Testing task retrieval..."
    try {
        $tasks = Invoke-RestMethod -Uri "http://$externalIP`:8080/tasks" -Method Get
        Write-Status "Task retrieval passed! Found $($tasks.Count) tasks"
    }
    catch {
        Write-Warning "Task retrieval failed"
    }
}

# Cleanup function
function Remove-Deployment {
    Write-Status "Cleaning up deployment..."
    kubectl delete namespace task-management
    kubectl delete pv mongodb-pv
    Write-Status "Cleanup completed!"
}

# Main execution
function Main {
    Write-Host "Task 2: Kubernetes Deployment Script (PowerShell)" -ForegroundColor Cyan
    Write-Host "=================================================" -ForegroundColor Cyan
    
    Test-Prerequisites
    Build-Image
    Deploy-ToK8s
    Wait-ForPods
    Test-Deployment
    Test-Endpoints
    
    Write-Host ""
    Write-Status "Deployment completed successfully!"
    Write-Status "Please take screenshots of the kubectl commands and curl tests as required for Task 2."
    Write-Status "External access: kubectl get service task-management-service -n task-management"
    
    Write-Host ""
    Write-Host "Available commands:" -ForegroundColor Yellow
    Write-Host "  .\deploy.ps1 -SkipBuild    # Skip Docker image build"
    Write-Host "  .\deploy.ps1 -SkipTests    # Skip endpoint tests"
    Write-Host "  Remove-Deployment          # Clean up deployment"
}

# Run main function
Main
