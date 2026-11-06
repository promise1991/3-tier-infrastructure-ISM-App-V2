

# ------------------------------------------------------------------
# Application setup for frontend
# ------------------------------------------------------------------


cd /home/ubuntu/Apps-For-Testing-in-AWS-infrastructure/Frontend

# ------------------------------------------------------------------
# Frontend build
# ------------------------------------------------------------------
npm install
npm run build   # assuming this generates a 'dist' or 'build' folder

# Optional: serve frontend with Nginx
rm -rf /var/www/html/*
cp -r build/* /var/www/html/
systemctl restart nginx

nginx -t
systemctl reload nginx
# ------------------------------------------------------------------
# Assuming you dont want to remove other files in /var/www/html/
# ------------------------------------------------------------------
# APP_NAME=ims
# APP_ROOT=/var/www/html/$APP_NAME

# rm -rf "$APP_ROOT"/*
# cp -r build/* "$APP_ROOT"/

# ------------------------------------------------------------------
# Nginx configuration (use your repo's nginx.conf)
# ------------------------------------------------------------------
#  cp nginx.conf /etc/nginx/sites-available/shopsphere
#  ln -sf /etc/nginx/sites-available/shopsphere /etc/nginx/sites-enabled/shopsphere
#  rm -f /etc/nginx/sites-enabled/default

# nginx -t
# systemctl enable nginx
# systemctl restart nginx