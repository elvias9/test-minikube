#!/bin/bash

# Variables
CHART_NAME="helm-chart"
HELM_DIR="./helm-chart"
NAMESPACE="default"

# Stop execution if any command returns a non-zero exit status
handle_error() {
    echo "An error occurred on line $1"
    exit 1
}

trap 'handle_error $LINENO' ERR

echo "🚀 Start deployment..."

# Step 1: Start Minikube if it is not started
echo "Check Minikube status..."
minikube_status=$(minikube status --format='{{.Host}}')
if [[ "$minikube_status" == "Stopped" ]]; then
    echo "Minikube is stopped. Starting minikube..."
    minikube start
else
    echo "Minikube is "$minikube_status""
fi

# Step 2: Set Docker env to Minikube
echo "🔧 Configure Docker to use Minikube's daemon..."
eval $(minikube docker-env)

# Step 3: Build Docker images
echo "🐳 Build Docker images..."
cd containers
docker-compose build
# docker build -t hello-world:1.0 . 
# docker build -t reverse-app:1.0 . 

# Step 4: Helm install or upgrade
echo "📦 Deploy Helm chart..."
cd ..
helm upgrade --install $CHART_NAME $HELM_DIR --namespace $NAMESPACE

# Step 5: Wait for pods to be ready
echo "⏳ Wait for pods to be ready..."
kubectl wait --for=condition=Ready pod -l app=hello-world --timeout=150s
kubectl wait --for=condition=Ready pod -l app=reverse-app --timeout=150s

# Step 6: Port-forward hello-world for local access
echo "🌐 Set up port-forward to hello-world on localhost:4000..."
kubectl port-forward service/hello-world 4000:4000 &

# Get the last background process
pid=$!
echo "Port forwarding started (PID: $pid)."

# Test the hello-world server
sleep 5
echo "🔁 Test hello-world endpoint..."
curl http://localhost:4000/

# Stop the port-forward
echo "Stopping port-forward..."
kill $pid
echo "Port-forward stopped."

# Step 7: Run Port-forward reverse-app for local access
echo "🌐 Set up port-forward to reverse-app on localhost:3000..."
kubectl port-forward service/reverse-app 3000:3000 &

pf_pid=$!

echo "Port forwarding started (PID: $pf_pid)."

# Test the reverse-app server
sleep 5
echo "🔁 Test reverse-app endpoint..."
curl http://localhost:3000

# Stop the port-forward
echo "Stopping port-forward..."
kill $pf_pid
echo "Port-forward stopped."

echo "✅ Deployment completed successfully!"