#!/bin/bash
set -e

# Install dependencies
dnf install -y nodejs npm git nginx

# Install PM2 globally
npm install -g pm2

# Clone the repo
git clone https://github.com/raphaelcosta93/aws-playground.git /app
cd /app/app

# Install app dependencies
npm install --omit=dev

# Create PM2 ecosystem file with environment variables injected by Terraform
cat > /app/app/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'app',
    script: 'server.js',
    env: {
      NODE_ENV: 'production',
      PORT: 3000,
      AWS_REGION: '${region}',
      S3_BUCKET: '${s3_bucket}',
      DYNAMO_TABLE: '${dynamo_table}'
    }
  }]
}
EOF

# Start app with PM2 and configure it to restart on reboot
pm2 start /app/app/ecosystem.config.js
pm2 startup systemd -u root --hp /root
pm2 save

# Configure NGINX as reverse proxy
cat > /etc/nginx/conf.d/app.conf << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

# Remove default NGINX page and start NGINX
rm -f /etc/nginx/conf.d/default.conf
systemctl enable nginx
systemctl start nginx
