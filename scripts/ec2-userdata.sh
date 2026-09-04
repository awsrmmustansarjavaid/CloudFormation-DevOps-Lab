#!/bin/bash

# =========================================================
# ☕ Charlie Cafe — Amazon Linux 2023 EC2 Bootstrap
# =========================================================
#
# Purpose:
#   Prepare an Amazon Linux 2023 EC2 instance for the
#   Charlie Cafe DevOps Lab.
#
# Installs:
#   - Apache HTTP Server
#   - PHP
#   - PHP-FPM
#   - PHP MySQL/MariaDB support
#   - MariaDB client
#   - Docker
#   - Docker Compose v2
#   - Git
#   - AWS CLI v2
#   - Common Linux/DevOps utilities
#
# Configures:
#   - Apache
#   - PHP-FPM
#   - Apache -> PHP-FPM
#   - Docker
#   - ec2-user Docker permissions
#   - Apache document root
#
# Creates:
#   - /var/www/html/index.php
#   - /var/www/html/info.php
#   - /var/log/charlie-cafe-bootstrap.log
#   - /var/log/charlie-cafe-bootstrap-complete.txt
#
# IMPORTANT:
#   EC2 User Data runs as root.
#
# Manual execution:
#
#   sudo bash ec2-userdata.sh
#
# Bootstrap log:
#
#   /var/log/charlie-cafe-bootstrap.log
#
# =========================================================


# =========================================================
# 0. ROOT CHECK
# =========================================================

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: This script must be run as root."
    echo "Use:"
    echo "  sudo bash ./ec2-userdata.sh"
    exit 1
fi


# =========================================================
# 1. LOGGING
# =========================================================

LOG_FILE="/var/log/charlie-cafe-bootstrap.log"

touch "${LOG_FILE}"

exec > >(tee -a "${LOG_FILE}") 2>&1


# =========================================================
# 2. STRICT MODE
# =========================================================

set -Eeuo pipefail


# =========================================================
# 3. ERROR HANDLER
# =========================================================

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
echo "Check the log:"
echo "  sudo less ${LOG_FILE}"
echo "========================================================="
exit "${EXIT_CODE}"
' ERR


# =========================================================
# 4. HELPER
# =========================================================

step() {
    echo
    echo "========================================================="
    echo "$1"
    echo "========================================================="
}


# =========================================================
# 5. START
# =========================================================

step "☕ Charlie Cafe EC2 Bootstrap Started"

echo "Date     : $(date)"
echo "Hostname : $(hostname)"
echo "User     : $(whoami)"
echo "UID      : $(id -u)"
echo "Log      : ${LOG_FILE}"


# =========================================================
# 6. OPERATING SYSTEM CHECK
# =========================================================

step "1. Verifying Amazon Linux 2023"

if [[ ! -f /etc/os-release ]]; then
    echo "ERROR: /etc/os-release not found."
    exit 1
fi

source /etc/os-release

echo "NAME    : ${NAME}"
echo "VERSION : ${VERSION}"
echo "ID      : ${ID}"
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


# =========================================================
# 7. VERIFY DNF
# =========================================================

step "2. Verifying DNF"

if ! command -v dnf >/dev/null 2>&1; then
    echo "ERROR: dnf is not installed."
    exit 1
fi

echo "[PASS] DNF available."
dnf --version | head -n 1


# =========================================================
# 8. UPDATE SYSTEM
# =========================================================

step "3. Updating Amazon Linux packages"

dnf update -y

echo "[PASS] System update completed."


# =========================================================
# 9. INSTALL BASE UTILITIES
# =========================================================

step "4. Installing base utilities"

dnf install -y \
    httpd \
    git \
    wget \
    unzip \
    tar \
    nano \
    vim-enhanced \
    htop \
    curl-minimal \
    ca-certificates \
    openssl \
    findutils \
    procps-ng \
    iproute

echo "[PASS] Base utilities installed."


# =========================================================
# 10. VERIFY CURL
# =========================================================

step "5. Verifying curl"

if ! command -v curl >/dev/null 2>&1; then
    echo "ERROR: curl is unavailable."
    exit 1
fi

curl --version | head -n 1

echo "[PASS] curl available."


# =========================================================
# 11. INSTALL PHP
# =========================================================

step "6. Installing PHP"

dnf install -y \
    php \
    php-cli \
    php-common \
    php-fpm \
    php-mysqlnd \
    php-mbstring \
    php-xml \
    php-opcache

echo "[PASS] PHP packages installed."


# =========================================================
# 12. PHP VERSION
# =========================================================

step "7. Verifying PHP"

if ! command -v php >/dev/null 2>&1; then
    echo "ERROR: PHP command not found."
    exit 1
fi

php -v | head -n 1

echo "[PASS] PHP installed."


# =========================================================
# 13. VERIFY PHP EXTENSIONS
# =========================================================

step "8. Verifying PHP extensions"

REQUIRED_EXTENSIONS=(
    "mysqli"
    "mysqlnd"
    "mbstring"
    "xml"
    "json"
    "opcache"
)

for EXT in "${REQUIRED_EXTENSIONS[@]}"; do

    if php -m | grep -qi "^${EXT}$"; then
        echo "[PASS] PHP extension: ${EXT}"
    else
        echo "[FAIL] PHP extension missing: ${EXT}"
        exit 1
    fi

done


# =========================================================
# 14. CONFIGURE PHP-FPM
# =========================================================

step "9. Configuring PHP-FPM"


PHP_FPM_CONFIG="/etc/php-fpm.d/www.conf"

if [[ ! -f "${PHP_FPM_CONFIG}" ]]; then
    echo "ERROR: ${PHP_FPM_CONFIG} not found."
    exit 1
fi


# ---------------------------------------------------------
# Configure PHP-FPM worker user/group
# ---------------------------------------------------------

sed -i 's/^user = .*/user = apache/' "${PHP_FPM_CONFIG}"
sed -i 's/^group = .*/group = apache/' "${PHP_FPM_CONFIG}"


# ---------------------------------------------------------
# Configure Unix socket
# ---------------------------------------------------------

sed -i 's|^listen = .*|listen = /run/php-fpm/www.sock|' "${PHP_FPM_CONFIG}"


# ---------------------------------------------------------
# Configure socket permissions
# ---------------------------------------------------------

if grep -q '^;listen.owner' "${PHP_FPM_CONFIG}"; then
    sed -i 's|^;listen.owner.*|listen.owner = apache|' "${PHP_FPM_CONFIG}"
elif grep -q '^listen.owner' "${PHP_FPM_CONFIG}"; then
    sed -i 's|^listen.owner.*|listen.owner = apache|' "${PHP_FPM_CONFIG}"
else
    echo "listen.owner = apache" >> "${PHP_FPM_CONFIG}"
fi


if grep -q '^;listen.group' "${PHP_FPM_CONFIG}"; then
    sed -i 's|^;listen.group.*|listen.group = apache|' "${PHP_FPM_CONFIG}"
elif grep -q '^listen.group' "${PHP_FPM_CONFIG}"; then
    sed -i 's|^listen.group.*|listen.group = apache|' "${PHP_FPM_CONFIG}"
else
    echo "listen.group = apache" >> "${PHP_FPM_CONFIG}"
fi


if grep -q '^;listen.mode' "${PHP_FPM_CONFIG}"; then
    sed -i 's|^;listen.mode.*|listen.mode = 0660|' "${PHP_FPM_CONFIG}"
elif grep -q '^listen.mode' "${PHP_FPM_CONFIG}"; then
    sed -i 's|^listen.mode.*|listen.mode = 0660|' "${PHP_FPM_CONFIG}"
else
    echo "listen.mode = 0660" >> "${PHP_FPM_CONFIG}"
fi


echo "[PASS] PHP-FPM configuration updated."


# =========================================================
# 15. PHP-FPM CONFIG TEST
# =========================================================

step "10. Testing PHP-FPM configuration"

php-fpm -t

echo "[PASS] PHP-FPM configuration valid."


# =========================================================
# 16. ENABLE + START PHP-FPM
# =========================================================

step "11. Starting PHP-FPM"

systemctl daemon-reload

systemctl enable php-fpm

systemctl restart php-fpm


if systemctl is-active --quiet php-fpm; then
    echo "[PASS] PHP-FPM is running."
else
    echo "[FAIL] PHP-FPM failed to start."
    systemctl status php-fpm --no-pager || true
    journalctl -u php-fpm --no-pager -n 100 || true
    exit 1
fi


# ---------------------------------------------------------
# Verify PHP-FPM socket
# ---------------------------------------------------------

if [[ -S /run/php-fpm/www.sock ]]; then
    echo "[PASS] PHP-FPM socket exists:"
    echo "       /run/php-fpm/www.sock"
else
    echo "[FAIL] PHP-FPM socket was not created."
    exit 1
fi


# =========================================================
# 17. CONFIGURE APACHE -> PHP-FPM
# =========================================================

step "12. Configuring Apache PHP-FPM integration"


PHP_APACHE_CONFIG="/etc/httpd/conf.d/php-fpm.conf"


cat > "${PHP_APACHE_CONFIG}" <<'APACHE'
# =========================================================
# Charlie Cafe - Apache PHP-FPM Configuration
# =========================================================

<IfModule proxy_module>
    LoadModule proxy_module modules/mod_proxy.so
</IfModule>

<IfModule proxy_fcgi_module>
    LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so
</IfModule>

<FilesMatch "\.php$">
    SetHandler "proxy:unix:/run/php-fpm/www.sock|fcgi://localhost/"
</FilesMatch>

DirectoryIndex index.php index.html
APACHE


echo "[PASS] Apache PHP-FPM configuration created:"
echo "${PHP_APACHE_CONFIG}"


# =========================================================
# 18. VERIFY APACHE MODULES
# =========================================================

step "13. Verifying Apache proxy modules"

if httpd -M 2>/dev/null | grep -q "proxy_module"; then
    echo "[PASS] mod_proxy loaded."
else
    echo "[FAIL] mod_proxy is not loaded."
    exit 1
fi


if httpd -M 2>/dev/null | grep -q "proxy_fcgi_module"; then
    echo "[PASS] mod_proxy_fcgi loaded."
else
    echo "[FAIL] mod_proxy_fcgi is not loaded."
    exit 1
fi


# =========================================================
# 19. CONFIGURE APACHE
# =========================================================

step "14. Configuring Apache"

mkdir -p /var/www/html


# ---------------------------------------------------------
# Remove default test files if present
# ---------------------------------------------------------

rm -f /var/www/html/index.html


# ---------------------------------------------------------
# Web permissions
# ---------------------------------------------------------

chown -R apache:apache /var/www/html

find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;


# ---------------------------------------------------------
# Apache configuration test
# ---------------------------------------------------------

httpd -t

echo "[PASS] Apache configuration valid."


# =========================================================
# 20. START APACHE
# =========================================================

step "15. Starting Apache"

systemctl enable httpd

systemctl restart httpd


if systemctl is-active --quiet httpd; then
    echo "[PASS] Apache is running."
else
    echo "[FAIL] Apache failed to start."
    systemctl status httpd --no-pager || true
    journalctl -u httpd --no-pager -n 100 || true
    exit 1
fi


# =========================================================
# 21. INSTALL MARIADB CLIENT
# =========================================================

step "16. Installing MariaDB/MySQL client"

if dnf list --available mariadb105 >/dev/null 2>&1; then

    echo "Installing MariaDB 10.5 client..."
    dnf install -y mariadb105

elif dnf list --available mariadb1011 >/dev/null 2>&1; then

    echo "Installing MariaDB 10.11 client..."
    dnf install -y mariadb1011

elif dnf list --available mariadb114 >/dev/null 2>&1; then

    echo "Installing MariaDB 11.4 client..."
    dnf install -y mariadb114

elif dnf list --available mariadb123 >/dev/null 2>&1; then

    echo "Installing MariaDB 12.3 client..."
    dnf install -y mariadb123

else

    echo "ERROR: No supported MariaDB client package found."
    dnf search mariadb | head -n 50 || true
    exit 1

fi


# ---------------------------------------------------------
# Verify client
# ---------------------------------------------------------

if command -v mariadb >/dev/null 2>&1; then

    echo "[PASS] MariaDB client installed."
    mariadb --version

elif command -v mysql >/dev/null 2>&1; then

    echo "[PASS] MySQL-compatible client installed."
    mysql --version

else

    echo "[FAIL] Database client command not found."
    exit 1

fi


# =========================================================
# 22. INSTALL DOCKER
# =========================================================

step "17. Installing Docker"

dnf install -y docker

echo "[PASS] Docker package installed."


# =========================================================
# 23. DOCKER GROUP
# =========================================================

step "18. Configuring Docker group"

if ! getent group docker >/dev/null 2>&1; then
    groupadd docker
fi


if id ec2-user >/dev/null 2>&1; then

    usermod -aG docker ec2-user

    echo "[PASS] ec2-user added to docker group."

else

    echo "WARNING: ec2-user does not exist."
    echo "Docker group membership skipped."

fi


# =========================================================
# 24. START DOCKER
# =========================================================

step "19. Starting Docker"

systemctl enable docker

systemctl restart docker


if systemctl is-active --quiet docker; then
    echo "[PASS] Docker is running."
else
    echo "[FAIL] Docker failed to start."
    systemctl status docker --no-pager || true
    journalctl -u docker --no-pager -n 100 || true
    exit 1
fi


docker --version


# =========================================================
# 25. DOCKER DAEMON TEST
# =========================================================

step "20. Testing Docker daemon"

if docker info >/dev/null 2>&1; then
    echo "[PASS] Docker daemon responding."
else
    echo "[FAIL] Docker daemon is not responding."
    exit 1
fi


# =========================================================
# 26. INSTALL DOCKER COMPOSE V2
# =========================================================

step "21. Installing Docker Compose v2"


# ---------------------------------------------------------
# Detect CPU architecture
# ---------------------------------------------------------

ARCH="$(uname -m)"

case "${ARCH}" in

    x86_64)
        COMPOSE_ARCH="x86_64"
        ;;

    aarch64|arm64)
        COMPOSE_ARCH="aarch64"
        ;;

    *)
        echo "ERROR: Unsupported architecture: ${ARCH}"
        exit 1
        ;;

esac


echo "Detected architecture: ${ARCH}"
echo "Docker Compose architecture: ${COMPOSE_ARCH}"


# ---------------------------------------------------------
# Compose plugin directory
# ---------------------------------------------------------

DOCKER_PLUGIN_DIR="/usr/local/lib/docker/cli-plugins"

mkdir -p "${DOCKER_PLUGIN_DIR}"


# ---------------------------------------------------------
# Download current Compose v2
# ---------------------------------------------------------

COMPOSE_URL="https://github.com/docker/compose/releases/latest/download/docker-compose-linux-${COMPOSE_ARCH}"

echo "Downloading:"
echo "${COMPOSE_URL}"


curl -fL \
    --retry 5 \
    --retry-delay 3 \
    --connect-timeout 20 \
    --max-time 300 \
    "${COMPOSE_URL}" \
    -o "${DOCKER_PLUGIN_DIR}/docker-compose"


chmod +x "${DOCKER_PLUGIN_DIR}/docker-compose"


# ---------------------------------------------------------
# Verify Compose
# ---------------------------------------------------------

if docker compose version >/dev/null 2>&1; then

    echo "[PASS] Docker Compose v2 installed."
    docker compose version

else

    echo "[FAIL] Docker Compose v2 is not working."
    exit 1

fi


# =========================================================
# 27. VERIFY GIT
# =========================================================

step "22. Verifying Git"

if ! command -v git >/dev/null 2>&1; then
    echo "ERROR: Git not installed."
    exit 1
fi

git --version

echo "[PASS] Git available."


# =========================================================
# 28. VERIFY AWS CLI
# =========================================================

step "23. Verifying AWS CLI"

# AL2023 ships with AWS CLI v2.

if ! command -v aws >/dev/null 2>&1; then

    echo "AWS CLI command not found."
    echo "Installing AWS CLI..."

    dnf install -y awscli

fi


if ! command -v aws >/dev/null 2>&1; then
    echo "ERROR: AWS CLI installation failed."
    exit 1
fi


aws --version

echo "[PASS] AWS CLI available."


# =========================================================
# 29. CREATE CHARLIE CAFE HEALTH PAGE
# =========================================================

step "24. Creating Charlie Cafe PHP health page"


cat > /var/www/html/index.php <<'PHP'
<?php

header('Content-Type: text/html; charset=UTF-8');

$hostname = gethostname();
$phpVersion = PHP_VERSION;

echo '<!DOCTYPE html>';
echo '<html lang="en">';
echo '<head>';
echo '<meta charset="UTF-8">';
echo '<meta name="viewport" content="width=device-width, initial-scale=1.0">';
echo '<title>Charlie Cafe</title>';

echo '<style>';
echo 'body { font-family: Arial, sans-serif; margin: 40px; }';
echo '.box { max-width: 700px; padding: 30px; border: 1px solid #ddd; border-radius: 10px; }';
echo '.ok { font-weight: bold; }';
echo '</style>';

echo '</head>';
echo '<body>';

echo '<div class="box">';

echo '<h1>☕ Charlie Cafe</h1>';

echo '<p class="ok">Apache: Working</p>';
echo '<p class="ok">PHP: Working</p>';
echo '<p class="ok">PHP-FPM: Working</p>';
echo '<p>Operating System: Amazon Linux 2023</p>';

echo '<p>Hostname: ' .
     htmlspecialchars($hostname, ENT_QUOTES, 'UTF-8') .
     '</p>';

echo '<p>PHP Version: ' .
     htmlspecialchars($phpVersion, ENT_QUOTES, 'UTF-8') .
     '</p>';

echo '<p>Server Time: ' .
     htmlspecialchars(date('Y-m-d H:i:s'), ENT_QUOTES, 'UTF-8') .
     '</p>';

echo '</div>';

echo '</body>';
echo '</html>';

?>
PHP


chown apache:apache /var/www/html/index.php
chmod 644 /var/www/html/index.php


echo "[PASS] Charlie Cafe health page created."


# =========================================================
# 30. CREATE PHP INFO PAGE
# =========================================================

step "25. Creating PHP information page"


cat > /var/www/html/info.php <<'PHP'
<?php
phpinfo();
?>
PHP


chown apache:apache /var/www/html/info.php
chmod 644 /var/www/html/info.php


echo "[PASS] PHP info page created."


# =========================================================
# 31. RESTART SERVICES
# =========================================================

step "26. Restarting Apache and PHP-FPM"

systemctl restart php-fpm
systemctl restart httpd


if ! systemctl is-active --quiet php-fpm; then
    echo "ERROR: PHP-FPM is not running."
    exit 1
fi


if ! systemctl is-active --quiet httpd; then
    echo "ERROR: Apache is not running."
    exit 1
fi


echo "[PASS] Apache and PHP-FPM restarted."


# =========================================================
# 32. TEST APACHE
# =========================================================

step "27. Testing Apache HTTP"

HTTP_STATUS="$(
    curl \
        --silent \
        --show-error \
        --output /dev/null \
        --write-out "%{http_code}" \
        --max-time 15 \
        http://127.0.0.1/
)"


echo "HTTP status: ${HTTP_STATUS}"


if [[ "${HTTP_STATUS}" == "200" ]]; then
    echo "[PASS] Apache HTTP test."
else
    echo "[FAIL] Apache HTTP test."
    exit 1
fi


# =========================================================
# 33. TEST PHP
# =========================================================

step "28. Testing PHP through Apache + PHP-FPM"


PHP_RESPONSE="$(
    curl \
        --silent \
        --show-error \
        --max-time 15 \
        http://127.0.0.1/index.php
)"


echo "${PHP_RESPONSE}" | head -n 20


if echo "${PHP_RESPONSE}" | grep -q "Charlie Cafe"; then

    echo "[PASS] PHP is executing correctly through Apache."

else

    echo "[FAIL] PHP execution test failed."

    echo
    echo "Apache error log:"
    tail -n 100 /var/log/httpd/error_log || true

    echo
    echo "PHP-FPM status:"
    systemctl status php-fpm --no-pager || true

    echo
    echo "PHP-FPM log:"
    journalctl -u php-fpm --no-pager -n 100 || true

    exit 1

fi


# =========================================================
# 34. TEST PHP INFO
# =========================================================

step "29. Testing PHP info page"

PHP_INFO_STATUS="$(
    curl \
        --silent \
        --show-error \
        --output /dev/null \
        --write-out "%{http_code}" \
        --max-time 15 \
        http://127.0.0.1/info.php
)"


echo "PHP info status: ${PHP_INFO_STATUS}"


if [[ "${PHP_INFO_STATUS}" == "200" ]]; then
    echo "[PASS] PHP info page."
else
    echo "[FAIL] PHP info page."
    exit 1
fi


# =========================================================
# 35. TEST PHP MYSQL EXTENSION
# =========================================================

step "30. Testing PHP MySQL support"

if php -r 'if (extension_loaded("mysqli")) exit(0); exit(1);'; then
    echo "[PASS] PHP mysqli support."
else
    echo "[FAIL] PHP mysqli support."
    exit 1
fi


if php -r 'if (extension_loaded("pdo_mysql")) exit(0); exit(1);'; then
    echo "[PASS] PHP PDO MySQL support."
else
    echo "[FAIL] PHP PDO MySQL support."
    exit 1
fi


# =========================================================
# 36. TEST DOCKER
# =========================================================

step "31. Testing Docker"

docker version

if docker info >/dev/null 2>&1; then
    echo "[PASS] Docker daemon."
else
    echo "[FAIL] Docker daemon."
    exit 1
fi


# =========================================================
# 37. TEST DOCKER COMPOSE
# =========================================================

step "32. Testing Docker Compose"

docker compose version

if docker compose version >/dev/null 2>&1; then
    echo "[PASS] Docker Compose v2."
else
    echo "[FAIL] Docker Compose v2."
    exit 1
fi


# =========================================================
# 38. TEST AWS IAM ROLE
# =========================================================

step "33. Testing EC2 IAM identity"

IDENTITY_FILE="/tmp/charlie-cafe-identity.json"

if aws sts get-caller-identity \
    --output json \
    > "${IDENTITY_FILE}" 2>/dev/null; then

    echo "[PASS] EC2 IAM identity available."

    cat "${IDENTITY_FILE}"

    rm -f "${IDENTITY_FILE}"

else

    echo "WARNING:"
    echo "AWS CLI is installed, but this EC2 instance does not"
    echo "appear to have a usable IAM role."

    echo
    echo "If this instance is supposed to access AWS services,"
    echo "attach an IAM role to the EC2 instance."

    # Do NOT fail entire bootstrap because IAM role may
    # intentionally be absent.

fi


# =========================================================
# 39. VERIFY SERVICES
# =========================================================

step "34. Final service verification"


SERVICES=(
    "httpd"
    "php-fpm"
    "docker"
)

for SERVICE in "${SERVICES[@]}"; do

    if systemctl is-active --quiet "${SERVICE}"; then
        echo "[PASS] ${SERVICE}"
    else
        echo "[FAIL] ${SERVICE}"
        exit 1
    fi

done


# =========================================================
# 40. CHECK LISTENING PORTS
# =========================================================

step "35. Checking listening ports"

if command -v ss >/dev/null 2>&1; then

    ss -lntp || true

fi


# =========================================================
# 41. CREATE COMPLETION MARKER
# =========================================================

step "36. Creating completion marker"

COMPLETION_FILE="/var/log/charlie-cafe-bootstrap-complete.txt"


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
Software
---------------------------------------------------------

Apache:
$(httpd -v 2>&1 | head -n 1)

PHP:
$(php -v 2>&1 | head -n 1)

PHP-FPM:
$(php-fpm -v 2>&1 | head -n 1)

Docker:
$(docker --version 2>&1)

Docker Compose:
$(docker compose version 2>&1)

Git:
$(git --version 2>&1)

AWS CLI:
$(aws --version 2>&1)

MariaDB/MySQL Client:
$(mariadb --version 2>&1 || mysql --version 2>&1)

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
PHP-FPM Socket
---------------------------------------------------------

/run/php-fpm/www.sock

---------------------------------------------------------
Apache Configuration
---------------------------------------------------------

${PHP_APACHE_CONFIG}

---------------------------------------------------------
Web Root
---------------------------------------------------------

/var/www/html

Application:
http://<EC2-PUBLIC-IP>/index.php

PHP Info:
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

=========================================================
EOF


chmod 644 "${COMPLETION_FILE}"


# =========================================================
# 42. FINAL SUMMARY
# =========================================================

step "37. Final Charlie Cafe Verification"


echo "[PASS] Amazon Linux 2023"
echo "[PASS] System packages updated"
echo "[PASS] Apache installed"
echo "[PASS] Apache running"
echo "[PASS] PHP installed"
echo "[PASS] PHP extensions verified"
echo "[PASS] PHP-FPM installed"
echo "[PASS] PHP-FPM running"
echo "[PASS] PHP-FPM socket verified"
echo "[PASS] Apache -> PHP-FPM configured"
echo "[PASS] PHP execution verified"
echo "[PASS] PHP MySQL support verified"
echo "[PASS] MariaDB/MySQL client installed"
echo "[PASS] Docker installed"
echo "[PASS] Docker running"
echo "[PASS] Docker Compose v2 installed"
echo "[PASS] Git installed"
echo "[PASS] AWS CLI available"
echo "[PASS] Charlie Cafe PHP health page"
echo "[PASS] PHP info page"
echo "[PASS] Completion marker created"


# =========================================================
# 43. SUCCESS
# =========================================================

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
echo "  /var/www/html"
echo
echo "Charlie Cafe:"
echo "  http://<EC2-PUBLIC-IP>/index.php"
echo
echo "PHP Info:"
echo "  http://<EC2-PUBLIC-IP>/info.php"
echo
echo "---------------------------------------------------------"
echo "Docker"
echo "---------------------------------------------------------"
echo
echo "ec2-user has been added to the docker group."
echo
echo "Reconnect to EC2 before running Docker as ec2-user."
echo
echo "Then run:"
echo
echo "  docker --version"
echo "  docker compose version"
echo "  docker info"
echo
echo "Optional:"
echo
echo "  docker run hello-world"
echo
echo "========================================================="
echo "☕ Charlie Cafe Bootstrap Finished"
echo "========================================================="

