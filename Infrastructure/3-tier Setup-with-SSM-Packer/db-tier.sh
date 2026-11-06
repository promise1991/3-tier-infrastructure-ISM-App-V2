#!/bin/bash
set -u

exec > /var/log/mongodb-user-data.log 2>&1

echo "Waiting for system readiness..."
sleep 30

apt-get update -y
apt-get install -y curl gnupg

echo "Adding MongoDB GPG key..."
curl -fsSL https://pgp.mongodb.com/server-6.0.asc \
  | gpg --dearmor \
  | tee /usr/share/keyrings/mongodb-server-6.0.gpg > /dev/null

echo "Adding MongoDB repository..."
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] \
https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" \
| tee /etc/apt/sources.list.d/mongodb-org-6.0.list

apt-get update -y
apt-get install -y mongodb-org

echo "Starting MongoDB..."
systemctl daemon-reexec
systemctl enable mongod
systemctl start mongod

echo "Configuring MongoDB bind IP..."
sed -i "s/^  bindIp: .*/  bindIp: 0.0.0.0/" /etc/mongod.conf
systemctl restart mongod

echo "MongoDB installation complete"