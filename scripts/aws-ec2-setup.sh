#!/bin/bash

# ================================================================
# ☕ Charlie Cafe — Amazon Linux 2023 EC2 Bootstrap Script
# ================================================================
#
# PURPOSE
# ----------------------------------------------------------------
# Prepare an Amazon Linux 2023 EC2 instance for the Charlie Cafe
# DevOps / Cloud / Docker / Kubernetes laboratory.
#
# OPERATING SYSTEM
# ----------------------------------------------------------------
# Amazon Linux 2023
#
# SOFTWARE INSTALLED
# ----------------------------------------------------------------
# Linux / Utilities
#   - Git
#   - htop
#   - curl
#   - wget
#   - unzip
#   - tar
#   - gzip
#   - bzip2
#   - xz
#   - jq
#   - vim
#   - nano
#   - bind-utils
#   - iproute
#   - iputils
#
# Web Stack
#   - Apache HTTP Server
#   - PHP
#   - PHP CLI
#   - PHP-FPM
#   - PHP MySQL
#   - PHP mbstring
#   - PHP XML
#   - PHP OPcache
#
# Database Client
#   - MariaDB/MySQL compatible client
#
# Containers
#   - Docker
#   - Docker Compose v2
#
# AWS
#   - AWS CLI v2
#
# Kubernetes
#   - kubectl
#   - eksctl
#   - Helm
#   - kind
#
# CONFIGURATION
# ----------------------------------------------------------------
#   - Apache
#   - PHP-FPM
#   - Apache -> PHP-FPM
#   - Docker service
#   - ec2-user Docker permissions
#   - ec2-user PATH
#
# CREATED FILES
# ----------------------------------------------------------------
#   /var/www/html/index.html
#   /var/www/html/info.php
#   /var/log/charlie-cafe-bootstrap.log
#   /var/log/charlie-cafe-bootstrap-complete.txt
#
# IMPORTANT
# ----------------------------------------------------------------
# EC2 User Data runs as root.
#
# Manual execution:
#
#   sudo bash ec2-userdata.sh
#
# ================================================================


# ================================================================
# 1. ROOT CHECK
# ================================================================

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: This script must be run as root."
    echo "Run:"
    echo "sudo bash ec2-userdata.sh"
    exit 1
fi


# ================================================================
# 2. VARIABLES
# ================================================================

WEB_ROOT="/var/www/html"

PHP_FPM_CONFIG="/etc/php-fpm.d/www.conf"

PHP_APACHE_CONFIG="/etc/httpd/conf.d/php-fpm.conf"

LOG_FILE="/var/log/charlie-cafe-bootstrap.log"

COMPLETION_FILE="/var/log/charlie-cafe-bootstrap-complete.txt"

ARCH="$(uname -m)"


# ================================================================
# 3. LOGGING
# ================================================================

touch "${LOG_FILE}"

exec > >(tee -a "${LOG_FILE}") 2>&1


# ================================================================
# 4. STRICT MODE
# ================================================================

set -Eeuo pipefail


# ================================================================
# 5. ERROR HANDLER
# ================================================================

trap '
EXIT_CODE=$?

echo
echo "========================================================="
echo "❌ CHARLIE CAFE BOOTSTRAP FAILED"
echo "========================================================="
echo "Exit Code : ${EXIT_CODE}"
echo "Line      : ${LINENO}"
echo "Command   : ${BASH_COMMAND}"
echo "Log File  : ${LOG_FILE}"
echo
echo "Review:"
echo "  sudo less ${LOG_FILE}"
echo "========================================================="

exit "${EXIT_CODE}"
' ERR


# ================================================================
# 6. HELPER: SECTION HEADER
# ================================================================

step() {

    echo
    echo "========================================================="
    echo "$1"
    echo "========================================================="

}


# ================================================================
# 7. HELPER: DNF INSTALL WITH RETRIES
# ================================================================
#
# IMPORTANT:
# We intentionally DO NOT use the previous 900-second timeout.
#
# Instead, DNF commands are retried a few times if another package
# operation is temporarily using the RPM database.
#
# ================================================================

dnf_install() {

    local attempt=1
    local max_attempts=5

    while (( attempt <= max_attempts )); do

        echo
        echo "DNF install attempt ${attempt}/${max_attempts}:"
        echo "dnf install -y $*"

        if dnf install -y "$@"; then
            return 0
        fi

        echo
        echo "DNF installation attempt failed."

        if (( attempt < max_attempts )); then

            echo "Retrying in 10 seconds..."

            sleep 10

        fi

        attempt=$((attempt + 1))

    done

    echo
    echo "ERROR: DNF installation failed after ${max_attempts} attempts."

    return 1
}


# ================================================================
# 8. HELPER: DNF UPDATE WITH RETRIES
# ================================================================

dnf_update() {

    local attempt=1
    local max_attempts=5

    while (( attempt <= max_attempts )); do

        echo
        echo "DNF update attempt ${attempt}/${max_attempts}"

        if dnf update -y; then
            return 0
        fi

        echo
        echo "DNF update failed."

        if (( attempt < max_attempts )); then

            echo "Retrying in 10 seconds..."

            sleep 10

        fi

        attempt=$((attempt + 1))

    done

    echo
    echo "ERROR: DNF update failed."

    return 1
}


# ================================================================
# 9. HELPER: DOWNLOAD FILE
# ================================================================

download_file() {

    local URL="$1"
    local OUTPUT="$2"

    echo
    echo "Downloading:"
    echo "${URL}"

    curl \
        --fail \
        --silent \
        --show-error \
        --location \
        --retry 5 \
        --retry-delay 3 \
        --connect-timeout 30 \
        --max-time 600 \
        "${URL}" \
        -o "${OUTPUT}"

}


# ================================================================
# 10. START
# ================================================================

step "☕ Charlie Cafe EC2 Bootstrap Started"

echo "Date       : $(date)"
echo "Hostname   : $(hostname)"
echo "User       : $(whoami)"
echo "UID        : $(id -u)"
echo "Architecture: ${ARCH}"
echo "Log File   : ${LOG_FILE}"


# ================================================================
# 11. VERIFY AMAZON LINUX 2023
# ================================================================

step "1. Verifying Amazon Linux 2023"

if [[ ! -f /etc/os-release ]]; then

    echo "ERROR: /etc/os-release not found."

    exit 1

fi


source /etc/os-release


echo "NAME       : ${NAME}"
echo "VERSION    : ${VERSION}"
echo "ID         : ${ID}"
echo "VERSION_ID : ${VERSION_ID}"


if [[ "${ID}" != "amzn" ]]; then

    echo "ERROR: This script requires Amazon Linux."

    exit 1

fi


if [[ "${VERSION_ID}" != "2023" ]]; then

    echo "ERROR: This script requires Amazon Linux 2023."

    exit 1

fi


echo "[PASS] Amazon Linux 2023 detected."


# ================================================================
# 12. VERIFY DNF
# ================================================================

step "2. Verifying DNF"

if ! command -v dnf >/dev/null 2>&1; then

    echo "ERROR: DNF is not installed."

    exit 1

fi


dnf --version | head -n 1

echo "[PASS] DNF available."


# ================================================================
# 13. INITIAL PACKAGE UPDATE
# ================================================================

step "3. Updating Amazon Linux packages"

dnf_update

echo "[PASS] System packages updated."


# ================================================================
# 14. INSTALL BASE PACKAGES
# ================================================================

step "4. Installing base packages"

dnf_install \
    httpd \
    git \
    htop \
    curl \
    wget \
    unzip \
    tar \
    gzip \
    bzip2 \
    xz \
    nano \
    vim-enhanced \
    ca-certificates \
    openssl \
    findutils \
    procps-ng \
    iproute \
    iputils \
    bind-utils \
    jq \
    which \
    util-linux \
    shadow-utils \
    sed \
    grep \
    coreutils


echo "[PASS] Base packages installed."


# ================================================================
# 15. HARD VERIFY GIT
# ================================================================

step "5. Verifying Git"

if ! command -v git >/dev/null 2>&1; then

    echo "[FAIL] Git installation failed."

    echo
    echo "DNF package information:"
    rpm -q git || true

    exit 1

fi


git --version

echo "[PASS] Git installed."


# ================================================================
# 16. HARD VERIFY HTOP
# ================================================================

step "6. Verifying htop"

if ! command -v htop >/dev/null 2>&1; then

    echo "[FAIL] htop installation failed."

    echo
    echo "DNF package information:"
    rpm -q htop || true

    exit 1

fi


htop --version || true

echo "[PASS] htop installed."


# ================================================================
# 17. VERIFY CURL
# ================================================================

step "7. Verifying curl"

if ! command -v curl >/dev/null 2>&1; then

    echo "ERROR: curl is unavailable."

    exit 1

fi


curl --version | head -n 1

echo "[PASS] curl available."


# ================================================================
# 18. INSTALL PHP
# ================================================================

step "8. Installing PHP"

dnf_install \
    php \
    php-cli \
    php-common \
    php-fpm \
    php-mysqlnd \
    php-mbstring \
    php-xml \
    php-opcache \
    php-json


echo "[PASS] PHP packages installed."


# ================================================================
# 19. VERIFY PHP
# ================================================================

step "9. Verifying PHP"

if ! command -v php >/dev/null 2>&1; then

    echo "ERROR: PHP command not found."

    exit 1

fi


php -v | head -n 1

echo "[PASS] PHP installed."


# ================================================================
# 20. VERIFY PHP EXTENSIONS
# ================================================================

step "10. Verifying PHP extensions"

REQUIRED_EXTENSIONS=(
    "mysqli"
    "mysqlnd"
    "mbstring"
    "xml"
    "json"
    "opcache"
    "pdo_mysql"
)


for EXT in "${REQUIRED_EXTENSIONS[@]}"; do

    if php -m | grep -qi "^${EXT}$"; then

        echo "[PASS] PHP extension: ${EXT}"

    else

        echo "[FAIL] PHP extension missing: ${EXT}"

        exit 1

    fi

done


# ================================================================
# 21. CONFIGURE PHP-FPM
# ================================================================

step "11. Configuring PHP-FPM"

if [[ ! -f "${PHP_FPM_CONFIG}" ]]; then

    echo "ERROR: ${PHP_FPM_CONFIG} not found."

    exit 1

fi


# ---------------------------------------------------------------
# PHP-FPM user
# ---------------------------------------------------------------

if grep -q '^user = ' "${PHP_FPM_CONFIG}"; then

    sed -i 's/^user = .*/user = apache/' "${PHP_FPM_CONFIG}"

else

    echo "user = apache" >> "${PHP_FPM_CONFIG}"

fi


# ---------------------------------------------------------------
# PHP-FPM group
# ---------------------------------------------------------------

if grep -q '^group = ' "${PHP_FPM_CONFIG}"; then

    sed -i 's/^group = .*/group = apache/' "${PHP_FPM_CONFIG}"

else

    echo "group = apache" >> "${PHP_FPM_CONFIG}"

fi


# ---------------------------------------------------------------
# PHP-FPM socket
# ---------------------------------------------------------------

if grep -q '^listen = ' "${PHP_FPM_CONFIG}"; then

    sed -i \
        's|^listen = .*|listen = /run/php-fpm/www.sock|' \
        "${PHP_FPM_CONFIG}"

else

    echo "listen = /run/php-fpm/www.sock" >> "${PHP_FPM_CONFIG}"

fi


# ---------------------------------------------------------------
# Socket owner
# ---------------------------------------------------------------

if grep -q '^listen.owner' "${PHP_FPM_CONFIG}"; then

    sed -i \
        's|^listen.owner.*|listen.owner = apache|' \
        "${PHP_FPM_CONFIG}"

else

    sed -i \
        's|^;listen.owner.*|listen.owner = apache|' \
        "${PHP_FPM_CONFIG}" || true

fi


if ! grep -q '^listen.owner' "${PHP_FPM_CONFIG}"; then

    echo "listen.owner = apache" >> "${PHP_FPM_CONFIG}"

fi


# ---------------------------------------------------------------
# Socket group
# ---------------------------------------------------------------

if grep -q '^listen.group' "${PHP_FPM_CONFIG}"; then

    sed -i \
        's|^listen.group.*|listen.group = apache|' \
        "${PHP_FPM_CONFIG}"

else

    sed -i \
        's|^;listen.group.*|listen.group = apache|' \
        "${PHP_FPM_CONFIG}" || true

fi


if ! grep -q '^listen.group' "${PHP_FPM_CONFIG}"; then

    echo "listen.group = apache" >> "${PHP_FPM_CONFIG}"

fi


# ---------------------------------------------------------------
# Socket mode
# ---------------------------------------------------------------

if grep -q '^listen.mode' "${PHP_FPM_CONFIG}"; then

    sed -i \
        's|^listen.mode.*|listen.mode = 0660|' \
        "${PHP_FPM_CONFIG}"

else

    sed -i \
        's|^;listen.mode.*|listen.mode = 0660|' \
        "${PHP_FPM_CONFIG}" || true

fi


if ! grep -q '^listen.mode' "${PHP_FPM_CONFIG}"; then

    echo "listen.mode = 0660" >> "${PHP_FPM_CONFIG}"

fi


echo "[PASS] PHP-FPM configuration updated."


# ================================================================
# 22. TEST PHP-FPM CONFIGURATION
# ================================================================

step "12. Testing PHP-FPM configuration"

php-fpm -t

echo "[PASS] PHP-FPM configuration valid."


# ================================================================
# 23. START PHP-FPM
# ================================================================

step "13. Starting PHP-FPM"

systemctl daemon-reload

systemctl enable php-fpm

systemctl restart php-fpm


if systemctl is-active --quiet php-fpm; then

    echo "[PASS] PHP-FPM running."

else

    echo "[FAIL] PHP-FPM failed."

    systemctl status php-fpm --no-pager || true

    journalctl -u php-fpm --no-pager -n 100 || true

    exit 1

fi


if [[ -S /run/php-fpm/www.sock ]]; then

    echo "[PASS] PHP-FPM socket exists."

else

    echo "[FAIL] PHP-FPM socket missing."

    exit 1

fi


# ================================================================
# 24. CONFIGURE APACHE + PHP-FPM
# ================================================================

step "14. Configuring Apache -> PHP-FPM"

cat > "${PHP_APACHE_CONFIG}" <<'APACHE'
# =========================================================
# Charlie Cafe - Apache PHP-FPM Configuration
# =========================================================

<FilesMatch "\.php$">
    SetHandler "proxy:unix:/run/php-fpm/www.sock|fcgi://localhost/"
</FilesMatch>

DirectoryIndex index.html index.php
APACHE


echo "[PASS] Apache PHP-FPM configuration created."


# ================================================================
# 25. VERIFY APACHE MODULES
# ================================================================

step "15. Verifying Apache modules"

if httpd -M 2>/dev/null | grep -q "proxy_module"; then

    echo "[PASS] mod_proxy loaded."

else

    echo "[FAIL] mod_proxy missing."

    exit 1

fi


if httpd -M 2>/dev/null | grep -q "proxy_fcgi_module"; then

    echo "[PASS] mod_proxy_fcgi loaded."

else

    echo "[FAIL] mod_proxy_fcgi missing."

    exit 1

fi


# ================================================================
# 26. CREATE WEB ROOT
# ================================================================

step "16. Configuring Apache web root"

mkdir -p "${WEB_ROOT}"


# Remove only our test PHP file if it exists.
# Existing application files are not intentionally deleted.

rm -f "${WEB_ROOT}/index.php"


# ================================================================
# 27. CREATE CHARLIE CAFE HTML PAGE
# ================================================================

step "17. Creating Charlie Cafe index.html"

cat > "${WEB_ROOT}/index.html" <<'HTML'
<!DOCTYPE html>

<html lang="en">

<head>

    <meta charset="UTF-8">

    <meta
        name="viewport"
        content="width=device-width, initial-scale=1.0"
    >

    <title>Charlie Cafe</title>

    <style>

        body {
            font-family: Arial, sans-serif;
            background: #f7f7f7;
            margin: 0;
            padding: 40px;
        }

        .container {
            max-width: 800px;
            margin: auto;
            background: white;
            padding: 40px;
            border-radius: 12px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
        }

        h1 {
            margin-top: 0;
        }

        .status {
            padding: 12px;
            margin: 10px 0;
            border-radius: 6px;
            background: #f0f0f0;
        }

        .links {
            margin-top: 25px;
        }

        a {
            text-decoration: none;
        }

    </style>

</head>

<body>

<div class="container">

    <h1>☕ Charlie Cafe</h1>

    <div class="status">
        Apache HTTP Server: Working
    </div>

    <div class="status">
        Amazon Linux 2023: Working
    </div>

    <div class="status">
        Docker: Installed
    </div>

    <div class="status">
        Kubernetes Tools: Installed
    </div>

    <div class="links">

        <p>
            <a href="/info.php">
                PHP Information
            </a>
        </p>

    </div>

</div>

</body>

</html>
HTML


echo "[PASS] index.html created."


# ================================================================
# 28. CREATE PHP INFO PAGE
# ================================================================

step "18. Creating PHP info page"

cat > "${WEB_ROOT}/info.php" <<'PHP'
<?php

phpinfo();

?>
PHP


echo "[PASS] info.php created."


# ================================================================
# 29. WEB PERMISSIONS
# ================================================================

step "19. Setting web permissions"

chown -R apache:apache "${WEB_ROOT}"

find "${WEB_ROOT}" -type d -exec chmod 755 {} \;

find "${WEB_ROOT}" -type f -exec chmod 644 {} \;


echo "[PASS] Web permissions configured."


# ================================================================
# 30. TEST APACHE
# ================================================================

step "20. Testing Apache configuration"

httpd -t

echo "[PASS] Apache configuration valid."


# ================================================================
# 31. START APACHE
# ================================================================

step "21. Starting Apache"

systemctl enable httpd

systemctl restart httpd


if systemctl is-active --quiet httpd; then

    echo "[PASS] Apache running."

else

    echo "[FAIL] Apache failed."

    systemctl status httpd --no-pager || true

    journalctl -u httpd --no-pager -n 100 || true

    exit 1

fi


# ================================================================
# 32. INSTALL MARIADB CLIENT
# ================================================================

step "22. Installing MariaDB/MySQL client"

#
# AL2023 package names can change between repository versions.
# We first check several known MariaDB client package names.
#

MARIADB_PACKAGE=""


for PACKAGE in \
    mariadb105 \
    mariadb1011 \
    mariadb114 \
    mariadb118 \
    mariadb123
do

    if dnf list --available "${PACKAGE}" >/dev/null 2>&1; then

        MARIADB_PACKAGE="${PACKAGE}"

        break

    fi

done


if [[ -z "${MARIADB_PACKAGE}" ]]; then

    echo "ERROR: Could not find a supported MariaDB package."

    echo
    echo "Searching available MariaDB packages:"

    dnf search mariadb || true

    exit 1

fi


echo "Selected MariaDB package:"
echo "${MARIADB_PACKAGE}"


dnf_install "${MARIADB_PACKAGE}"


if command -v mariadb >/dev/null 2>&1; then

    mariadb --version

    echo "[PASS] MariaDB client installed."

elif command -v mysql >/dev/null 2>&1; then

    mysql --version

    echo "[PASS] MySQL-compatible client installed."

else

    echo "[FAIL] MariaDB/MySQL client command not found."

    exit 1

fi


# ================================================================
# 33. INSTALL DOCKER
# ================================================================

step "23. Installing Docker"

if command -v docker >/dev/null 2>&1; then

    echo "Docker already installed."

else

    #
    # AWS documents Docker installation on AL2023 through the
    # normal package manager.
    #

    dnf_install docker

fi


if ! command -v docker >/dev/null 2>&1; then

    echo "[FAIL] Docker installation failed."

    exit 1

fi


docker --version

echo "[PASS] Docker installed."


# ================================================================
# 34. CONFIGURE DOCKER GROUP
# ================================================================

step "24. Configuring Docker group"

if ! getent group docker >/dev/null 2>&1; then

    groupadd docker

fi


if id ec2-user >/dev/null 2>&1; then

    usermod -aG docker ec2-user

    echo "[PASS] ec2-user added to docker group."

else

    echo "WARNING: ec2-user does not exist."

fi


# ================================================================
# 35. START DOCKER
# ================================================================

step "25. Starting Docker"

systemctl enable docker

systemctl restart docker


if systemctl is-active --quiet docker; then

    echo "[PASS] Docker running."

else

    echo "[FAIL] Docker failed."

    systemctl status docker --no-pager || true

    journalctl -u docker --no-pager -n 100 || true

    exit 1

fi


# ================================================================
# 36. TEST DOCKER
# ================================================================

step "26. Testing Docker daemon"

if docker info >/dev/null 2>&1; then

    echo "[PASS] Docker daemon responding."

else

    echo "[FAIL] Docker daemon not responding."

    exit 1

fi


# ================================================================
# 37. INSTALL DOCKER COMPOSE V2
# ================================================================

step "27. Installing Docker Compose v2"

DOCKER_PLUGIN_DIR="/usr/local/lib/docker/cli-plugins"

mkdir -p "${DOCKER_PLUGIN_DIR}"


case "${ARCH}" in

    x86_64)

        COMPOSE_ARCH="x86_64"

        ;;

    aarch64)

        COMPOSE_ARCH="aarch64"

        ;;

    *)

        echo "ERROR: Unsupported architecture: ${ARCH}"

        exit 1

        ;;

esac


COMPOSE_URL="https://github.com/docker/compose/releases/latest/download/docker-compose-linux-${COMPOSE_ARCH}"


download_file \
    "${COMPOSE_URL}" \
    "${DOCKER_PLUGIN_DIR}/docker-compose"


chmod 0755 "${DOCKER_PLUGIN_DIR}/docker-compose"


if docker compose version >/dev/null 2>&1; then

    docker compose version

    echo "[PASS] Docker Compose v2 installed."

else

    echo "[FAIL] Docker Compose v2 unavailable."

    exit 1

fi


# ================================================================
# 38. INSTALL AWS CLI V2
# ================================================================

step "28. Installing AWS CLI v2"

case "${ARCH}" in

    x86_64)

        AWS_ZIP_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"

        ;;

    aarch64)

        AWS_ZIP_URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"

        ;;

    *)

        echo "ERROR: Unsupported architecture: ${ARCH}"

        exit 1

        ;;

esac


if command -v aws >/dev/null 2>&1; then

    AWS_VERSION="$(aws --version 2>&1)"

    echo "${AWS_VERSION}"

    if echo "${AWS_VERSION}" | grep -q "aws-cli/2"; then

        echo "[PASS] AWS CLI v2 already installed."

    else

        echo "Existing AWS CLI is not v2."
        echo "Installing official AWS CLI v2."

        rm -f /usr/local/bin/aws
        rm -f /usr/bin/aws

        TMP_AWS="/tmp/charlie-awscli"

        rm -rf "${TMP_AWS}"

        mkdir -p "${TMP_AWS}"

        download_file \
            "${AWS_ZIP_URL}" \
            "${TMP_AWS}/awscliv2.zip"

        unzip -q \
            "${TMP_AWS}/awscliv2.zip" \
            -d "${TMP_AWS}"

        "${TMP_AWS}/aws/install" \
            --update \
            --bin-dir /usr/local/bin \
            --install-dir /usr/local/aws-cli

        rm -rf "${TMP_AWS}"

    fi

else

    TMP_AWS="/tmp/charlie-awscli"

    rm -rf "${TMP_AWS}"

    mkdir -p "${TMP_AWS}"

    download_file \
        "${AWS_ZIP_URL}" \
        "${TMP_AWS}/awscliv2.zip"

    unzip -q \
        "${TMP_AWS}/awscliv2.zip" \
        -d "${TMP_AWS}"

    "${TMP_AWS}/aws/install" \
        --bin-dir /usr/local/bin \
        --install-dir /usr/local/aws-cli

    rm -rf "${TMP_AWS}"

fi


if ! command -v aws >/dev/null 2>&1; then

    echo "[FAIL] AWS CLI installation failed."

    exit 1

fi


AWS_VERSION="$(aws --version 2>&1)"

echo "${AWS_VERSION}"


if ! echo "${AWS_VERSION}" | grep -q "aws-cli/2"; then

    echo "[FAIL] AWS CLI v2 verification failed."

    exit 1

fi


echo "[PASS] AWS CLI v2 installed."


# ================================================================
# 39. INSTALL KUBECTL
# ================================================================

step "29. Installing kubectl"

case "${ARCH}" in

    x86_64)

        KUBECTL_ARCH="amd64"

        ;;

    aarch64)

        KUBECTL_ARCH="arm64"

        ;;

    *)

        echo "ERROR: Unsupported architecture: ${ARCH}"

        exit 1

        ;;

esac


#
# AWS EKS currently documents Kubernetes 1.36.2 with the
# 2026-07-05 build for Linux.
#

KUBECTL_VERSION="1.36.2"

KUBECTL_DATE="2026-07-05"

KUBECTL_URL="https://s3.us-west-2.amazonaws.com/amazon-eks/${KUBECTL_VERSION}/${KUBECTL_DATE}/bin/linux/${KUBECTL_ARCH}/kubectl"


rm -f /tmp/kubectl


download_file \
    "${KUBECTL_URL}" \
    /tmp/kubectl


chmod 0755 /tmp/kubectl


install -m 0755 \
    /tmp/kubectl \
    /usr/local/bin/kubectl


rm -f /tmp/kubectl


if ! command -v kubectl >/dev/null 2>&1; then

    echo "[FAIL] kubectl installation failed."

    exit 1

fi


kubectl version --client

echo "[PASS] kubectl installed."


# ================================================================
# 40. INSTALL EKSCTL
# ================================================================

step "30. Installing eksctl"

case "${ARCH}" in

    x86_64)

        EKSCTL_ARCH="amd64"

        ;;

    aarch64)

        EKSCTL_ARCH="arm64"

        ;;

    *)

        echo "ERROR: Unsupported architecture: ${ARCH}"

        exit 1

        ;;

esac


EKSCTL_URL="https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_${EKSCTL_ARCH}.tar.gz"


rm -rf /tmp/charlie-eksctl

mkdir -p /tmp/charlie-eksctl


download_file \
    "${EKSCTL_URL}" \
    /tmp/charlie-eksctl.tar.gz


tar \
    -xzf /tmp/charlie-eksctl.tar.gz \
    -C /tmp/charlie-eksctl


if [[ ! -f /tmp/charlie-eksctl/eksctl ]]; then

    echo "[FAIL] eksctl binary was not found after extraction."

    exit 1

fi


install -m 0755 \
    /tmp/charlie-eksctl/eksctl \
    /usr/local/bin/eksctl


rm -rf /tmp/charlie-eksctl

rm -f /tmp/charlie-eksctl.tar.gz


if ! command -v eksctl >/dev/null 2>&1; then

    echo "[FAIL] eksctl installation failed."

    exit 1

fi


eksctl version

echo "[PASS] eksctl installed."


# ================================================================
# 41. INSTALL HELM
# ================================================================

step "31. Installing Helm"

#
# Helm 4 is currently the stable major version.
#
# We use the official Helm installer.
#

HELM_INSTALL_SCRIPT="/tmp/get_helm.sh"


rm -f "${HELM_INSTALL_SCRIPT}"


download_file \
    "https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4" \
    "${HELM_INSTALL_SCRIPT}"


chmod 0700 "${HELM_INSTALL_SCRIPT}"


"${HELM_INSTALL_SCRIPT}"


rm -f "${HELM_INSTALL_SCRIPT}"


if ! command -v helm >/dev/null 2>&1; then

    echo "[FAIL] Helm installation failed."

    exit 1

fi


helm version

echo "[PASS] Helm installed."


# ================================================================
# 42. INSTALL KIND
# ================================================================

step "32. Installing kind"

case "${ARCH}" in

    x86_64)

        KIND_ARCH="amd64"

        ;;

    aarch64)

        KIND_ARCH="arm64"

        ;;

    *)

        echo "ERROR: Unsupported architecture: ${ARCH}"

        exit 1

        ;;

esac


KIND_URL="https://kind.sigs.k8s.io/dl/latest/kind-linux-${KIND_ARCH}"


rm -f /tmp/kind


download_file \
    "${KIND_URL}" \
    /tmp/kind


chmod 0755 /tmp/kind


install -m 0755 \
    /tmp/kind \
    /usr/local/bin/kind


rm -f /tmp/kind


if ! command -v kind >/dev/null 2>&1; then

    echo "[FAIL] kind installation failed."

    exit 1

fi


kind version

echo "[PASS] kind installed."


# ================================================================
# 43. CONFIGURE EC2-USER PATH
# ================================================================

step "33. Configuring ec2-user environment"

if id ec2-user >/dev/null 2>&1; then

    EC2_BASHRC="/home/ec2-user/.bashrc"

    touch "${EC2_BASHRC}"


    if ! grep -q '/usr/local/bin' "${EC2_BASHRC}"; then

        echo 'export PATH="/usr/local/bin:$PATH"' \
            >> "${EC2_BASHRC}"

    fi


    chown ec2-user:ec2-user "${EC2_BASHRC}"


    #
    # Make /usr/local/bin available immediately in this
    # root shell as well.
    #

    export PATH="/usr/local/bin:${PATH}"


    echo "[PASS] ec2-user PATH configured."

fi


# ================================================================
# 44. HARD KUBERNETES TOOL VERIFICATION
# ================================================================

step "34. Verifying ALL Kubernetes tools"

KUBERNETES_TOOLS=(
    kubectl
    eksctl
    helm
    kind
)


for TOOL in "${KUBERNETES_TOOLS[@]}"; do

    if command -v "${TOOL}" >/dev/null 2>&1; then

        echo "[PASS] ${TOOL}: $(command -v "${TOOL}")"

    else

        echo "[FAIL] Kubernetes tool missing: ${TOOL}"

        exit 1

    fi

done


echo
echo "kubectl:"
kubectl version --client


echo
echo "eksctl:"
eksctl version


echo
echo "helm:"
helm version --short


echo
echo "kind:"
kind version


echo
echo "[PASS] All Kubernetes tools installed."


# ================================================================
# 45. HARD VERIFY ALL REQUIRED COMMANDS
# ================================================================

step "35. Final command verification"

REQUIRED_COMMANDS=(
    git
    htop
    curl
    wget
    php
    php-fpm
    httpd
    docker
    aws
    kubectl
    eksctl
    helm
    kind
)


for COMMAND in "${REQUIRED_COMMANDS[@]}"; do

    if command -v "${COMMAND}" >/dev/null 2>&1; then

        echo "[PASS] ${COMMAND}"

    else

        echo "[FAIL] Required command missing: ${COMMAND}"

        exit 1

    fi

done


# ================================================================
# 46. RESTART SERVICES
# ================================================================

step "36. Restarting services"

systemctl restart php-fpm

systemctl restart httpd

systemctl restart docker


if ! systemctl is-active --quiet php-fpm; then

    echo "[FAIL] PHP-FPM is not running."

    exit 1

fi


if ! systemctl is-active --quiet httpd; then

    echo "[FAIL] Apache is not running."

    exit 1

fi


if ! systemctl is-active --quiet docker; then

    echo "[FAIL] Docker is not running."

    exit 1

fi


echo "[PASS] PHP-FPM running."

echo "[PASS] Apache running."

echo "[PASS] Docker running."


# ================================================================
# 47. TEST APACHE HTML
# ================================================================

step "37. Testing Apache index.html"

HTTP_STATUS="$(
    curl \
        --silent \
        --show-error \
        --output /tmp/charlie-index.html \
        --write-out "%{http_code}" \
        --max-time 15 \
        http://127.0.0.1/
)"


echo "HTTP status: ${HTTP_STATUS}"


if [[ "${HTTP_STATUS}" != "200" ]]; then

    echo "[FAIL] Apache index.html HTTP test."

    cat /tmp/charlie-index.html || true

    exit 1

fi


if grep -q "Charlie Cafe" /tmp/charlie-index.html; then

    echo "[PASS] Charlie Cafe HTML served."

else

    echo "[FAIL] Charlie Cafe content missing."

    cat /tmp/charlie-index.html || true

    exit 1

fi


rm -f /tmp/charlie-index.html


# ================================================================
# 48. TEST PHP-FPM
# ================================================================

step "38. Testing PHP through Apache + PHP-FPM"

PHP_STATUS="$(
    curl \
        --silent \
        --show-error \
        --output /tmp/charlie-php-info.html \
        --write-out "%{http_code}" \
        --max-time 15 \
        http://127.0.0.1/info.php
)"


echo "PHP HTTP status: ${PHP_STATUS}"


if [[ "${PHP_STATUS}" != "200" ]]; then

    echo "[FAIL] PHP-FPM HTTP test."

    echo
    echo "Apache error log:"

    tail -n 100 /var/log/httpd/error_log || true

    echo
    echo "PHP-FPM status:"

    systemctl status php-fpm --no-pager || true

    exit 1

fi


if grep -qi "PHP Version" /tmp/charlie-php-info.html; then

    echo "[PASS] PHP-FPM execution verified."

else

    echo "[FAIL] PHP output not detected."

    exit 1

fi


rm -f /tmp/charlie-php-info.html


# ================================================================
# 49. TEST DOCKER
# ================================================================

step "39. Testing Docker"

docker --version

docker info >/dev/null

echo "[PASS] Docker daemon."


# ================================================================
# 50. TEST DOCKER COMPOSE
# ================================================================

step "40. Testing Docker Compose"

docker compose version

echo "[PASS] Docker Compose v2."


# ================================================================
# 51. TEST GIT
# ================================================================

step "41. Testing Git"

git --version

echo "[PASS] Git."


# ================================================================
# 52. TEST HTOP
# ================================================================

step "42. Testing htop"

htop --version || true

echo "[PASS] htop."


# ================================================================
# 53. TEST AWS CLI
# ================================================================

step "43. Testing AWS CLI"

aws --version


IDENTITY_FILE="/tmp/charlie-cafe-identity.json"


if aws sts get-caller-identity \
    --output json \
    > "${IDENTITY_FILE}" 2>/dev/null; then

    echo "[PASS] EC2 IAM identity available."

    cat "${IDENTITY_FILE}"

    rm -f "${IDENTITY_FILE}"

else

    echo
    echo "WARNING:"
    echo "AWS CLI is installed, but an EC2 IAM role was not"
    echo "available for sts:GetCallerIdentity."

    echo
    echo "This does NOT fail the bootstrap."

fi


# ================================================================
# 54. TEST KUBECTL
# ================================================================

step "44. Testing kubectl"

kubectl version --client

echo "[PASS] kubectl."


# ================================================================
# 55. TEST EKSCTL
# ================================================================

step "45. Testing eksctl"

eksctl version

echo "[PASS] eksctl."


# ================================================================
# 56. TEST HELM
# ================================================================

step "46. Testing Helm"

helm version --short

echo "[PASS] Helm."


# ================================================================
# 57. TEST KIND
# ================================================================

step "47. Testing kind"

kind version

echo "[PASS] kind."


# ================================================================
# 58. FINAL SERVICE VERIFICATION
# ================================================================

step "48. Final service verification"

SERVICES=(
    httpd
    php-fpm
    docker
)


for SERVICE in "${SERVICES[@]}"; do

    if systemctl is-active --quiet "${SERVICE}"; then

        echo "[PASS] ${SERVICE}"

    else

        echo "[FAIL] ${SERVICE}"

        exit 1

    fi

done


# ================================================================
# 59. CHECK LISTENING PORTS
# ================================================================

step "49. Checking listening ports"

if command -v ss >/dev/null 2>&1; then

    ss -lntp || true

fi


# ================================================================
# 60. CREATE COMPLETION MARKER
# ================================================================

step "50. Creating completion marker"

cat > "${COMPLETION_FILE}" <<EOF
=========================================================
Charlie Cafe EC2 Bootstrap Completed Successfully
=========================================================

Date:
$(date)

Hostname:
$(hostname)

Operating System:
${NAME} ${VERSION}

Architecture:
$(uname -m)

---------------------------------------------------------
Linux Tools
---------------------------------------------------------

Git:
$(git --version 2>&1)

htop:
$(htop --version 2>&1 | head -n 1 || true)

curl:
$(curl --version 2>&1 | head -n 1)

---------------------------------------------------------
Web Stack
---------------------------------------------------------

Apache:
$(httpd -v 2>&1 | head -n 1)

PHP:
$(php -v 2>&1 | head -n 1)

PHP-FPM:
$(php-fpm -v 2>&1 | head -n 1)

---------------------------------------------------------
Database
---------------------------------------------------------

MariaDB:
$(mariadb --version 2>&1 || mysql --version 2>&1)

---------------------------------------------------------
Containers
---------------------------------------------------------

Docker:
$(docker --version 2>&1)

Docker Compose:
$(docker compose version 2>&1)

---------------------------------------------------------
AWS
---------------------------------------------------------

AWS CLI:
$(aws --version 2>&1)

---------------------------------------------------------
Kubernetes
---------------------------------------------------------

kubectl:
$(kubectl version --client 2>&1 | head -n 1)

eksctl:
$(eksctl version 2>&1 | head -n 1)

Helm:
$(helm version --short 2>&1)

kind:
$(kind version 2>&1)

---------------------------------------------------------
Services
---------------------------------------------------------

Apache:
$(systemctl is-active httpd)

PHP-FPM:
$(systemctl is-active php-fpm)

Docker:
$(systemctl is-active docker)

---------------------------------------------------------
Web Root
---------------------------------------------------------

${WEB_ROOT}

---------------------------------------------------------
Application
---------------------------------------------------------

http://<EC2-PUBLIC-IP>/index.html

---------------------------------------------------------
PHP Information
---------------------------------------------------------

http://<EC2-PUBLIC-IP>/info.php

---------------------------------------------------------
Logs
---------------------------------------------------------

Bootstrap:
${LOG_FILE}

Apache:
/var/log/httpd/

PHP-FPM:
journalctl -u php-fpm

Docker:
journalctl -u docker

=========================================================
EOF


chmod 0644 "${COMPLETION_FILE}"


# ================================================================
# 61. FINAL SUMMARY
# ================================================================

step "51. Final Charlie Cafe Verification"

echo "[PASS] Amazon Linux 2023"

echo "[PASS] DNF package manager"

echo "[PASS] System packages updated"

echo "[PASS] Git installed"

echo "[PASS] htop installed"

echo "[PASS] curl installed"

echo "[PASS] Apache installed"

echo "[PASS] Apache running"

echo "[PASS] PHP installed"

echo "[PASS] PHP extensions verified"

echo "[PASS] PHP-FPM installed"

echo "[PASS] PHP-FPM running"

echo "[PASS] PHP-FPM socket verified"

echo "[PASS] Apache -> PHP-FPM configured"

echo "[PASS] index.html created"

echo "[PASS] info.php created"

echo "[PASS] PHP execution verified"

echo "[PASS] PHP MySQL support verified"

echo "[PASS] MariaDB client installed"

echo "[PASS] Docker installed"

echo "[PASS] Docker running"

echo "[PASS] Docker Compose v2 installed"

echo "[PASS] AWS CLI v2 installed"

echo "[PASS] kubectl installed"

echo "[PASS] eksctl installed"

echo "[PASS] Helm installed"

echo "[PASS] kind installed"

echo "[PASS] All required commands verified"

echo "[PASS] Completion marker created"


# ================================================================
# 62. SUCCESS
# ================================================================

echo
echo
echo "========================================================="
echo "✅ CHARLIE CAFE EC2 BOOTSTRAP COMPLETED SUCCESSFULLY"
echo "========================================================="

echo

echo "Hostname:"
echo "  $(hostname)"

echo

echo "Architecture:"
echo "  $(uname -m)"

echo

echo "Bootstrap log:"
echo "  ${LOG_FILE}"

echo

echo "Completion marker:"
echo "  ${COMPLETION_FILE}"

echo

echo "Web root:"
echo "  ${WEB_ROOT}"

echo

echo "Charlie Cafe:"
echo "  http://<EC2-PUBLIC-IP>/index.html"

echo

echo "PHP Info:"
echo "  http://<EC2-PUBLIC-IP>/info.php"

echo

echo "---------------------------------------------------------"
echo "Installed DevOps Tools"
echo "---------------------------------------------------------"

echo

echo "Git:"
git --version

echo

echo "htop:"
htop --version || true

echo

echo "Docker:"
docker --version

echo

echo "Docker Compose:"
docker compose version

echo

echo "AWS CLI:"
aws --version

echo

echo "kubectl:"
kubectl version --client

echo

echo "eksctl:"
eksctl version

echo

echo "Helm:"
helm version --short

echo

echo "kind:"
kind version

echo

echo "---------------------------------------------------------"
echo "Docker Group"
echo "---------------------------------------------------------"

echo

echo "ec2-user has been added to the docker group."

echo

echo "IMPORTANT:"
echo "Reconnect to EC2 before running Docker without sudo."

echo

echo "Then test:"

echo "  docker --version"
echo "  docker compose version"
echo "  docker info"

echo

echo "Optional Docker test:"

echo "  docker run hello-world"

echo

echo "---------------------------------------------------------"
echo "Kubernetes"
echo "---------------------------------------------------------"

echo

echo "kubectl:"
echo "  kubectl version --client"

echo

echo "Amazon EKS:"
echo "  eksctl version"

echo

echo "Helm:"
echo "  helm version"

echo

echo "kind:"
echo "  kind version"

echo

echo "To create a local Kubernetes lab later:"

echo "  kind create cluster --name charlie-cafe"

echo

echo "Then:"

echo "  kubectl get nodes"

echo

echo "========================================================="
echo "☕ Charlie Cafe Bootstrap Finished"
echo "========================================================="

