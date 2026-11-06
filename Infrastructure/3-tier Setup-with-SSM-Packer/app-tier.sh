#!/bin/bash

set -u           

exec > /var/log/user-data.log 2>&1

SECRET_ARN="${secret_arn}"
AWS_REGION="us-east-1"
# This allows Terraform to insert the secret ARN into the deployment script.

echo "Waiting for network..."

sleep 30
# ------------------------------------------------------------------
# Non-interactive & safe defaults
# ------------------------------------------------------------------
# export DEBIAN_FRONTEND=noninteractive
# export HOME=/root

# ------------------------------------------------------------------
# System update (NO apt upgrade in cloud-init)
# ------------------------------------------------------------------

apt-get update -y

# ------------------------------------------------------------------
# Base packages
# ------------------------------------------------------------------
apt-get install -y curl gnupg nginx git awscli jq

# ------------------------------------------------------------------
# Node.js 18 (NodeSource) + npm
# ------------------------------------------------------------------


echo "Adding NodeSource repo..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash - || {
  echo "NodeSource setup failed"
  exit 1
}

apt-get update -y
apt-get install -y nodejs

node -v
npm -v
nginx -v



# ------------------------------------------------------------------
# Application setup for backend
# ------------------------------------------------------------------
cd /home/ubuntu

git clone https://github.com/promise1991/Apps-For-Testing-in-AWS-infrastructure.git
cd Apps-For-Testing-in-AWS-infrastructure

# -------------------------------------------
# Setup Backend
# -------------------------------------------
cd Backend
npm install

# ------------------------------------------------------------------
# create .env file
# ------------------------------------------------------------------
# Retrieve application configuration from AWS Secrets Manager
echo "Retrieving application configuration..."

SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_ARN" \
  --region "$AWS_REGION" \
  --query SecretString \
  --output text) || {
    echo "Failed to retrieve application secret"
    exit 1
  }

MONGO_URI=$(printf '%s' "$SECRET_JSON" | jq -er '.MONGO_URI') || {
  echo "MONGO_URI is missing from the secret"
  exit 1
}

JWT_SECRET=$(printf '%s' "$SECRET_JSON" | jq -er '.JWT_SECRET') || {
  echo "JWT_SECRET is missing from the secret"
  exit 1
}

# Create the environment file with restricted permissions
umask 077

cat > .env <<EOF
NODE_ENV=production
PORT=5000
MONGO_URI=$MONGO_URI
JWT_SECRET=$JWT_SECRET
EOF

chown ubuntu:ubuntu .env
chmod 600 .env

unset SECRET_JSON MONGO_URI JWT_SECRET

echo "Application configuration retrieved successfully."

# ------------------------------------------------------------------
# Process manager setup (PM2)
# # ------------------------------------------------------------------
# npm install -g pm2

# Optional: run backend with pm2 for process management
# ------------------------------------------------------------------
# Process manager setup (PM2) - run application as ubuntu
# ------------------------------------------------------------------

npm install -g pm2

chown -R ubuntu:ubuntu /home/ubuntu/Apps-For-Testing-in-AWS-infrastructure

sudo -u ubuntu -H bash -c '
  cd /home/ubuntu/Apps-For-Testing-in-AWS-infrastructure/Backend
  pm2 start index.js --name backend-app
  pm2 save
'

env PATH=$PATH:/usr/bin pm2 startup systemd -u ubuntu --hp /home/ubuntu

echo "Backend application started under ubuntu user."

# Why this is better:
# - PM2 runs as ubuntu, not root.
# - The application files belong to ubuntu.
# - PM2 saves its process list under the correct user's home directory.
# - Systemd is configured to restore that user's PM2 processes after a reboot.