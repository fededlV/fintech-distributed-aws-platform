#!/usr/bin/env bash
set -e

# 1. Parameter validation.
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <EC2_IP> <PEM_KEY_PATH>"
    echo "Example: $0 50.16.48.137 ~/.ssh/key.pem"
    exit 1
fi

EC2_IP=$1
KEY_PATH=$2
REMOTE_USER="ec2-user"
REMOTE_DIR="~/fintech-distributed"

# SSH options to avoid blocking on confirmation prompts
SSH_OPTS="-i $KEY_PATH -o StrictHostKeyChecking=no"

echo "=== Starting deployment on EC2 ($EC2_IP) ==="

# 2. Instance provisioning.
echo "--> Configuring Docker on Amazon Linux 2023..."
ssh $SSH_OPTS $REMOTE_USER@$EC2_IP bash << 'EOF'
    set -e
    
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker..."
        sudo dnf update -y
        sudo dnf install -y docker
        
        echo "Installing Docker Compose..."
        # AL2023 sometimes does not include the compose plugin in dnf; the safest approach is to download the official binary from GitHub:
        sudo mkdir -p /usr/local/lib/docker/cli-plugins
        sudo curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" -o /usr/local/lib/docker/cli-plugins/docker-compose
        sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
        
        echo "Starting the Docker service..."
        sudo systemctl enable --now docker
        
        echo "Granting permissions to the ec2-user user..."
        sudo usermod -aG docker ec2-user
    fi
EOF

# 3. Copy files to the remote server (EC2).
echo "--> Copying environment files and docker-compose..."
# Create the base folder on the EC2 instance
ssh $SSH_OPTS $REMOTE_USER@$EC2_IP "mkdir -p $REMOTE_DIR/db"

# Copy the docker-compose file
scp $SSH_OPTS docker-compose.yml $REMOTE_USER@$EC2_IP:$REMOTE_DIR/

# Copy the full ENVS folder
# With -r, all contents are copied in one step
scp -r $SSH_OPTS envs $REMOTE_USER@$EC2_IP:$REMOTE_DIR/

# Copy the database scripts
scp -r $SSH_OPTS db/init-scripts $REMOTE_USER@$EC2_IP:$REMOTE_DIR/db/

# 4. Deploy containers on the EC2 instance.
echo "--> Pulling images and starting the stack with Docker Compose..."
ssh $SSH_OPTS $REMOTE_USER@$EC2_IP bash << EOF
    set -e
    cd $REMOTE_DIR

    # Pull the 6 images from the different Docker Hub repositories
    sudo docker compose pull

    # Start the full stack in the background (detached)
    sudo docker compose up -d
EOF

# 5. Smoke tests (functionality checks)
echo "--> Checking service status (Smoke Tests)..."
echo "Waiting 20 seconds for MariaDB and the APIs to start..."
sleep 20
ENDPOINTS=(
    "https://$EC2_IP/healthz"
    "https://$EC2_IP/"
    "https://$EC2_IP/api/clientes"
    "https://$EC2_IP/api/pagos"
    "https://$EC2_IP/api/facturas"
    "https://$EC2_IP/api/transacciones"
    "https://$EC2_IP/api/tarjetas"
)

TODOS_OK=true
MAX_ATTEMPTS=12 # 12 attempts of 5 seconds each = 60 seconds

for URL in "${ENDPOINTS[@]}"; do
    echo -n "Testing $URL ... "
    
    for ((i=1; i<=MAX_ATTEMPTS; i++)); do
        STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" "$URL" || echo "Error")
        
        if [ "$STATUS" == "200" ]; then
            echo "[OK]"
            break
        fi
        
        # If it is not the last attempt, wait and try again
        if [ "$i" -lt "$MAX_ATTEMPTS" ]; then
            sleep 5
        fi
    done
    # If the loop exits and the status is still not 200, it failed definitively
    if [ "$STATUS" != "200" ]; then
        echo "[FAILED] (Last status: $STATUS)"
        TODOS_OK=false
    fi
done
if [ "$TODOS_OK" = true ]; then
    echo "================================================="
    echo "Deployment completed successfully! Everything is working."
    echo "================================================="
else
    echo "Warning: One or more services did not start in time."
    exit 1
fi