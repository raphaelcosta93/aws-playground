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

# Replace nginx.conf to remove the built-in default server block,
# which conflicts with app.conf and takes priority over it on Amazon Linux 2023.
cat > /etc/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    keepalive_timeout   65;
    types_hash_max_size 4096;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    include /etc/nginx/conf.d/*.conf;
}
EOF

systemctl enable nginx
systemctl start nginx
