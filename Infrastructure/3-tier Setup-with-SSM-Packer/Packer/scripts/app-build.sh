#!/bin/bash
set -euo pipefail

# Update system packages
apt-get update -y

# Install base dependencies
apt-get install -y curl gnupg git awscli jq

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get update -y
apt-get install -y nodejs

# Install PM2
npm install -g pm2

# Verify installations
node --version
npm --version
pm2 --version
aws --version
jq --version

echo "Custom application AMI preparation completed."