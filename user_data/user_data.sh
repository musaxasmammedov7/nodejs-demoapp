#!/bin/bash
set -e

# Log output to a file
exec > >(tee /var/log/user-data.log) 2>&1

echo "=== Starting User Data Script ==="
echo "Environment: ${environment}"
echo "Timestamp: $(date)"

# Update system packages
yum update -y

# Install Docker
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create app directory
mkdir -p /opt/app
cd /opt/app

# Create docker-compose.yml for the nodejs-demoapp
cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  app:
    image: bencuk/nodejs-demoapp:latest
    container_name: nodejs-demoapp
    ports:
      - "8080:3000"
    environment:
      - NODE_ENV=production
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
EOF

# Start the application
docker-compose up -d

echo "=== User Data Script Completed ==="
