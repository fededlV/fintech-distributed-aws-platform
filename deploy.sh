#!/usr/bin/env bash
set -e

# 1. Validación de parámetros.
if [ "$#" -lt 2 ]; then
    echo "Uso: $0 <IP_EC2> <RUTA_KEY_PEM>"
    echo "Ejemplo: $0 50.16.48.137 ~/.ssh/grupo16.pem"
    exit 1
fi

EC2_IP=$1
KEY_PATH=$2
REMOTE_USER="ec2-user"
REMOTE_DIR="~/tp-grupo16"

# Opciones de SSH para evitar frenos por confirmaciones
SSH_OPTS="-i $KEY_PATH -o StrictHostKeyChecking=no"

echo "=== Iniciando Deploy en EC2 ($EC2_IP) ==="

# 2. Provisionamiento de la instancia.
echo "--> Configurando Docker en Amazon Linux 2023..."
ssh $SSH_OPTS $REMOTE_USER@$EC2_IP bash << 'EOF'
    set -e
    
    if ! command -v docker &> /dev/null; then
        echo "Instalando Docker..."
        sudo dnf update -y
        sudo dnf install -y docker
        
        echo "Instalando Docker Compose..."
        # AL2023 a veces no trae el plugin de compose en dnf, la forma más segura es bajar el binario oficial de GitHub:
        sudo mkdir -p /usr/local/lib/docker/cli-plugins
        sudo curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" -o /usr/local/lib/docker/cli-plugins/docker-compose
        sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
        
        echo "Iniciando servicio de Docker..."
        sudo systemctl enable --now docker
        
        echo "Dando permisos al usuario ec2-user..."
        sudo usermod -aG docker ec2-user
    fi
EOF

# 3. Copiar archivos al servidor remoto (EC2).
echo "--> Copiando archivos de entorno y docker-compose..."
# Se crea la carpeta base en la EC2
ssh $SSH_OPTS $REMOTE_USER@$EC2_IP "mkdir -p $REMOTE_DIR/db"

# Se copia el docker-compose
scp $SSH_OPTS docker-compose.yml $REMOTE_USER@$EC2_IP:$REMOTE_DIR/

# Copiamos la carpeta ENVS completa 
# Con -r se copia todo el contenido de la carpeta de una sola vez
scp -r $SSH_OPTS envs $REMOTE_USER@$EC2_IP:$REMOTE_DIR/

# Copiamos los scripts de la base de datos
scp -r $SSH_OPTS db/init-scripts $REMOTE_USER@$EC2_IP:$REMOTE_DIR/db/

# 4. Despliegue de contenedores en la instancia EC2.
echo "--> Pulleando imágenes y levantando el stack con Docker Compose..."
ssh $SSH_OPTS $REMOTE_USER@$EC2_IP bash << EOF
    set -e
    cd $REMOTE_DIR

    # Baja las 6 imágenes desde los distintos Docker Hubs
    sudo docker compose pull

    # Levanta el stack completo en segundo plano (detached)
    sudo docker compose up -d
EOF

# 5. Smoke Tests (Pruebas de funcionamiento)
echo "--> Verificando estado de los servicios (Smoke Tests)..."
echo "Esperando 20 segundos para que levante MariaDB y las APIs..."
sleep 20
ENDPOINTS=(
    "https://$EC2_IP/"
    "https://$EC2_IP/api/clientes"
    "https://$EC2_IP/api/pagos"
    "https://$EC2_IP/api/facturas"
    "https://$EC2_IP/api/transacciones"
    "https://$EC2_IP/api/tarjetas"
)

TODOS_OK=true
MAX_INTENTOS=12 # 12 intentos de 5 segundos = 60 segundos

for URL in "${ENDPOINTS[@]}"; do
    echo -n "Probando $URL ... "
    
    for ((i=1; i<=MAX_INTENTOS; i++)); do
        STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" "$URL" || echo "Error")
        
        if [ "$STATUS" == "200" ]; then
            echo "[OK]"
            break
        fi
        
        # Si no es el último intento, espera y vuelve a probar
        if [ "$i" -lt "$MAX_INTENTOS" ]; then
            sleep 5
        fi
    done
    # Si salió del bucle y el estado sigue sin ser 200, entonces falló definitivamente
    if [ "$STATUS" != "200" ]; then
        echo "[FALLO] (Último estado: $STATUS)"
        TODOS_OK=false
    fi
done
if [ "$TODOS_OK" = true ]; then
    echo "================================================="
    echo "¡Despliegue finalizado con éxito! Todo funcionando."
    echo "================================================="
else
    echo "Atención: Algún servicio no levantó a tiempo."
    exit 1
fi