#!/bin/bash

# Stop execution if any command returns a non-zero exit status
#set -e

handle_error() {
    echo "An error occurred on line $1"
    >&2 echo "error"
    exit 1
}

trap 'handle_error $LINENO' ERR

# Variables
CHART_NAME="helm-chart"
HELM_DIR="./helm-chart"
HELLO_WORLD_DIR="./containers/hello_world_server"
REVERSE_APP_DIR="./containers/reverse-app"
NAMESPACE="default"

echo "🚀 Start deployment..."

# Step 1: Start Minikube
echo "Starting Minikube..."
minikube start

# Step 2: Set Docker env to Minikube
echo "🔧 Configure Docker to use Minikube's daemon..."
eval $(minikube docker-env)

# Step 3: Build Docker images
echo "🐳 Build Docker images..."
docker build -t hello-world:1.0 . $HELLO_WORLD_DIR
docker build -t reverse-app:1.0 . $REVERSE_APP_DIR

# Step 4: Helm install or upgrade
echo "📦 Deploy Helm chart..."
helm upgrade --install $CHART_NAME $HELM_DIR --namespace $NAMESPACE

# Step 5: Wait for pods to be ready
echo "⏳ Wait for pods to be ready..."
kubectl wait --for=condition=Ready pod -l app=hello-world --timeout=60s
kubectl wait --for=condition=Ready pod -l app=reverse-app --timeout=60s

# Step 6: Port-forward hello-world for local access
echo "🌐 Set up port-forward to hello-world on localhost:4000..."
kubectl port-forward service/hello-world 4000:4000 &

# Step 7: Test the hello-world server
sleep 5
echo "🔁 Test hello-world endpoint..."
curl http://localhost:4000/

# Step 8: Port-forward reverse-app for local access
echo "🌐 Set up port-forward to reverse-app on localhost:3000..."
kubectl port-forward service/reverse-app 3000:3000 &

# Step 9: Test the app
sleep 5
echo "🔁 Test reverse-app endpoint..."
curl http://localhost:3000/

echo "✅ Deployment completed successfully!"