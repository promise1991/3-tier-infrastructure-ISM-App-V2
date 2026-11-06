
#!/bin/bash
set -euo pipefail

# Update package lists
apt-get update -y

# Install Nginx and required utilities
apt-get install -y curl gnupg nginx git

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get update -y
apt-get install -y nodejs

# Enable Nginx to start automatically
systemctl enable nginx

# Verify installations
node --version
npm --version
nginx -v

echo "Custom web-tier AMI preparation completed."
