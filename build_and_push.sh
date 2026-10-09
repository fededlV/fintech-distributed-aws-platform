#!/usr/bin/env bash
set -e # Security directive to stop the script if an error occurs.

# 1. Parameter validation.
if [ -z "$1" ]; then
    echo "Usage: $0 <DOCKER_HUB_USER>"
    echo "Example: $0 fededlv"
    exit 1
fi

DOCKER_USER=$1

echo "=== Starting build and push for user $DOCKER_USER ==="

# 2. Image build.
echo "--> Building api-clients image..."
docker build -t "$DOCKER_USER/api-clients:1.0.0" api-clients/

echo "--> Building api-invoices image..."
docker build -t "$DOCKER_USER/api-invoices:1.0.0" -f api-invoices/Dockerfile .

echo "--> Building api-payments image..."
docker build -t "$DOCKER_USER/api-payments:1.0.0" api-payments/

echo "--> Building api-cards image..."
docker build -t "$DOCKER_USER/api-cards:1.0.0" -f api-cards/Dockerfile .

echo "--> Building api-transactions image..."
docker build -t "$DOCKER_USER/api-transactions:1.0.0" -f api-transactions/Dockerfile .

echo "--> Building db image..."
docker build -t "$DOCKER_USER/db:1.0.0" -f db/Dockerfile . 

echo "--> Building web image..."
docker build -t "$DOCKER_USER/web:1.0.0" -f web/Dockerfile .

# 3. Push images to Docker Hub.
echo "--> Pushing api-clients to Docker Hub..."
docker push "$DOCKER_USER/api-clients:1.0.0"

echo "--> Pushing api-invoices to Docker Hub..."
docker push "$DOCKER_USER/api-invoices:1.0.0"

echo "--> Pushing api-payments to Docker Hub..."
docker push "$DOCKER_USER/api-payments:1.0.0"

echo "--> Pushing api-cards to Docker Hub..."
docker push "$DOCKER_USER/api-cards:1.0.0"

echo "--> Pushing api-transactions to Docker Hub..."
docker push "$DOCKER_USER/api-transactions:1.0.0"

echo "--> Pushing db to Docker Hub..."
docker push "$DOCKER_USER/db:1.0.0"

echo "--> Pushing web to Docker Hub..."
docker push "$DOCKER_USER/web:1.0.0"

echo "=== Build and push completed ==="
