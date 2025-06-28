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


# Step 2: Build Docker images
echo "🐳 Build Docker images..."
cd containers

docker-compose build

# Step 3: Push images to Ducker Hub
# Load variables from .env file
if [ -f .env ]; then
    set -a && source .env && set +a
else
    echo ".env file not found!"
    _handle_error
fi

echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

docker push "$DOCKER_USERNAME"/hello-world:1.0
docker push "$DOCKER_USERNAME"/reverse-app:1.0

# Step 4: Deploy apps with helm install or upgrade
echo "📦 Deploy Helm chart..."
cd ..
helm upgrade --install $CHART_NAME $HELM_DIR --namespace $NAMESPACE

# Wait for pods to be ready
echo "⏳ Wait for pods to be ready..."
kubectl wait --for=condition=Ready pod -l app=hello-world --timeout=150s
kubectl wait --for=condition=Ready pod -l app=reverse-app --timeout=150s

# Step 5: Print HTTP responses of applications.
declare -a pids=()

cleanup() {
    echo "Cleaning up port-forwards..."
    for pid in "${pf_pids[@]}"; do
        kill "$pid" 2>/dev/null
        wait "$pid" 2>/dev/null
    done
}
trap cleanup EXIT

kubectl port-forward service/hello-world 4000:4000 &
pids+=($!)

kubectl port-forward service/reverse-app 3000:3000 &
pids+=($!)

echo "Started port-forwarding with PIDs: ${pids[*]}"

# Print responses from servers
sleep 10
echo "🔁 Test hello-world endpoint..."
curl http://localhost:4000/
echo "🔁 Test reverse-app endpoint..."
curl http://localhost:3000

# Kill all background port-forwards
for pid in "${pids[@]}"; do
    echo "Stopping port-forward PID $pid"
    kill "$pid"
done

echo "All port-forwards stopped."

echo "✅ Script completed successfully!"