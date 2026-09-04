cat > install-ec2-devops-tools.sh <<'EOF'
#!/bin/bash

set -e

echo "======================================================"
echo " Charlie Cafe - EC2 DevOps Tools Installation"
echo " Amazon Linux 2023 x86_64"
echo "======================================================"

echo
echo "[1/8] Updating system..."
sudo dnf upgrade -y

echo
echo "[2/8] Installing Linux utilities..."
sudo dnf install -y \
    git \
    htop \
    curl \
    wget \
    unzip \
    tar \
    gzip \
    bzip2 \
    jq \
    vim \
    nano \
    bind-utils \
    iproute

echo
echo "[3/8] Installing Apache and PHP..."
sudo dnf install -y \
    httpd \
    php \
    php-fpm \
    php-mysqli \
    php-json \
    php-mbstring \
    php-xml \
    php-opcache \
    php-devel

sudo systemctl enable --now httpd
sudo systemctl enable --now php-fpm

echo
echo "[4/8] Installing MariaDB client..."
sudo dnf install -y mariadb || true

echo
echo "[5/8] Installing Docker..."
sudo dnf install -y docker

sudo systemctl enable --now docker

sudo usermod -aG docker ec2-user

echo
echo "[6/8] Installing Docker Compose..."

sudo mkdir -p /usr/local/lib/docker/cli-plugins

if ! docker compose version >/dev/null 2>&1; then
    sudo curl -SL \
        https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
        -o /usr/local/lib/docker/cli-plugins/docker-compose

    sudo chmod +x \
        /usr/local/lib/docker/cli-plugins/docker-compose
fi

echo
echo "[7/8] Installing kubectl..."

cd /tmp

curl -LO \
    "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

sudo install -o root -g root -m 0755 \
    kubectl /usr/local/bin/kubectl

rm -f kubectl

echo
echo "[8/8] Installing eksctl..."

cd /tmp

curl -L \
    https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz \
    -o eksctl.tar.gz

tar -xzf eksctl.tar.gz

sudo install -m 0755 \
    eksctl /usr/local/bin/eksctl

rm -f eksctl.tar.gz eksctl

echo
echo "Installing Helm..."

curl -fsSL -o /tmp/get_helm.sh \
    https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

chmod 700 /tmp/get_helm.sh

sudo /tmp/get_helm.sh

rm -f /tmp/get_helm.sh

echo
echo "Installing kind..."

cd /tmp

curl -Lo kind \
    https://kind.sigs.k8s.io/dl/v0.33.0/kind-linux-amd64

chmod +x kind

sudo mv kind /usr/local/bin/kind

echo
echo "======================================================"
echo " Installation Complete"
echo "======================================================"

echo
echo "NOTE:"
echo "Docker group membership was added to ec2-user."
echo "Reconnect to SSH or run: newgrp docker"

echo
echo "Installed versions:"
echo "------------------------------------------------------"

git --version || true
httpd -v 2>&1 | head -n1 || true
php -v 2>&1 | head -n1 || true
php-fpm -v 2>&1 | head -n1 || true
mariadb --version 2>&1 || true
sudo docker --version 2>&1 || true
sudo docker compose version 2>&1 || true
aws --version 2>&1 || true
kubectl version --client 2>&1 | head -n1 || true
eksctl version 2>&1 || true
helm version --short 2>&1 || true
kind version 2>&1 || true

echo
echo "======================================================"
echo " Installation Finished"
echo "======================================================"
EOF