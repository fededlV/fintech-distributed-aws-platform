#!/usr/bin/env bash
set -e #Directiva de seguridad para que el script se detenga si ocurre un error.

# 1. Validación de parámetros.
if [ -z "$1" ]; then
    echo "Uso: $0 <USUARIO_DOCKER_HUB>"
    echo "Ejemplo: $0 fededlv"
    exit 1
fi

DOCKER_USER=$1

echo "=== Iniciando Build y Push para el usuario $DOCKER_USER ==="

#2. Build de imágenes.
echo "--> Construyendo imagen api-clientes..."
docker build -t "$DOCKER_USER/api-clientes:1.0.0" api-clientes/

echo "--> Construyendo imagen api-facturas..."
docker build -t "$DOCKER_USER/api-facturas:1.0.0" -f api-facturas/Dockerfile . 

echo "--> Construyendo imagen api-pagos..."
docker build -t "$DOCKER_USER/api-pagos:1.0.0" api-pagos/

echo "--> Construyendo imagen api-tarjetas..."
docker build -t "$DOCKER_USER/api-tarjetas:1.0.0" -f api-tarjetas/Dockerfile .

echo "--> Construyendo imagen api-transacciones..."
docker build -t "$DOCKER_USER/api-transacciones:1.0.1" -f api-transacciones/Dockerfile .

echo "--> Construyendo imagen db..."
docker build -t "$DOCKER_USER/db:1.0.0" -f db/Dockerfile . 

echo "--> Construyendo imagen web..."
docker build -t "$DOCKER_USER/web:1.0.1" -f web/Dockerfile .

#3. Push de imágenes a Docker Hub..
echo "--> Subiendo api-clientes a Docker Hub..."
docker push "$DOCKER_USER/api-clientes:1.0.0"

echo "--> Subiendo api-facturas a Docker Hub..."
docker push "$DOCKER_USER/api-facturas:1.0.0"

echo "--> Subiendo api-pagos a Docker Hub..."
docker push "$DOCKER_USER/api-pagos:1.0.0"

echo "--> Subiendo api-tarjetas a Docker Hub..."
docker push "$DOCKER_USER/api-tarjetas:1.0.0"

echo "--> Subiendo api-transacciones a Docker Hub..."
docker push "$DOCKER_USER/api-transacciones:1.0.1"

echo "--> Subiendo db a Docker Hub..."
docker push "$DOCKER_USER/db:1.0.0"

echo "--> Subiendo web a Docker Hub..."
docker push "$DOCKER_USER/web:1.0.1"

echo "=== Build y Push finalizados ==="
