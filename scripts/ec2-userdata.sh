#!/bin/bash
# =========================================================
# ☕ Charlie Cafe — EC2 Bootstrap Script (Production Ready)
# Amazon Linux 2023
# LAMP + Docker + DevOps Tools
# =========================================================

set -e  # Stop on error

echo "🚀 Starting EC2 Setup..."

# ---------------------------------------------------------
# 1️⃣ Update OS (MANDATORY)
# ---------------------------------------------------------
dnf update -y

# ---------------------------------------------------------
# 2️⃣ Install Apache (httpd)
# ---------------------------------------------------------
dnf install -y httpd
systemctl enable httpd
systemctl start httpd

# ---------------------------------------------------------
# 3️⃣ Install PHP + MySQL Support
# ---------------------------------------------------------
dnf install -y \
php \
php-mysqlnd \
php-cli \
php-common \
php-mbstring \
php-xml

# ---------------------------------------------------------
# 4️⃣ Fix Web Directory Permissions
# ---------------------------------------------------------
chown -R apache:apache /var/www
chmod -R 755 /var/www

# ---------------------------------------------------------
# 5️⃣ Install MySQL Client (MariaDB)
# ---------------------------------------------------------
dnf install -y mariadb105

# ---------------------------------------------------------
# 6️⃣ Install Docker
# ---------------------------------------------------------
dnf install -y docker

systemctl enable docker
systemctl start docker

# Allow ec2-user to run docker without sudo
usermod -aG docker ec2-user

# ---------------------------------------------------------
# 7️⃣ Install Docker Compose (v2)
# ---------------------------------------------------------
mkdir -p /usr/local/lib/docker/cli-plugins/

curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
-o /usr/local/lib/docker/cli-plugins/docker-compose

chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Verify
docker compose version

# ---------------------------------------------------------
# 8️⃣ Install Git
# ---------------------------------------------------------
dnf install -y git

# ---------------------------------------------------------
# 9️⃣ Install Useful DevOps Tools
# ---------------------------------------------------------
dnf install -y \
htop \
unzip \
curl \
wget \
nano \
vim \
tar

# ---------------------------------------------------------
# 🔟 Install AWS CLI (already included in AL2023 but ensure)
# ---------------------------------------------------------
dnf install -y awscli

# ---------------------------------------------------------
# 1️⃣1️⃣ Create PHP Info Page (Optional)
# ---------------------------------------------------------
echo "<?php phpinfo(); ?>" > /var/www/html/info.php

# ---------------------------------------------------------
# 1️⃣2️⃣ Restart Apache
# ---------------------------------------------------------
systemctl restart httpd

# ---------------------------------------------------------
# ✅ Done
# ---------------------------------------------------------
echo "✅ EC2 Setup Completed Successfully!"