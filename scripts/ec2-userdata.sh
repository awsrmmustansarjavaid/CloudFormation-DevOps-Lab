#!/bin/bash

# =========================================================
# ☕ Charlie Cafe — EC2 User Data / Bootstrap Script
# =========================================================
#
# Operating System:
#   Amazon Linux 2023
#
# Purpose:
#   Prepare an EC2 instance for the Charlie Cafe DevOps Lab.
#
# Installs:
#   - Apache HTTP Server
#   - PHP
#   - PHP-FPM
#   - PHP MySQL support
#   - MariaDB/MySQL client
#   - Docker
#   - Docker Compose v2
#   - Git
#   - AWS CLI
#   - Common DevOps utilities
#
# Configures:
#   - Apache
#   - PHP-FPM
#   - Docker
#   - ec2-user Docker permissions
#   - Apache web directory
#
# Creates:
#   - PHP test page
#   - Apache/PHP health page
#   - Bootstrap log
#   - Bootstrap completion marker
#
# Performs:
#   - OS verification
#   - Software verification
#   - Apache HTTP test
#   - PHP execution test
#   - Docker daemon test
#   - AWS IAM identity test
#
# IMPORTANT:
#   EC2 User Data runs as root.
#
#   If running manually, use:
#
#       sudo bash ./ec2-userdata.sh
#
# Bootstrap log:
#
#       /var/log/charlie-cafe-bootstrap.log
#
# Completion marker:
#
#       /var/log/charlie-cafe-bootstrap-complete.txt
#
# =========================================================


# =========================================================
# 0. Require Root
# =========================================================
#
# EC2 User Data normally runs as root.
#
# If somebody executes this script manually as ec2-user,
# this check stops the script with a clear message instead
# of producing confusing permission errors.
# =========================================================

if [[ "${EUID}" -ne 0 ]]; then

    echo "ERROR: This script must be run as root."
    echo
    echo "Run it with:"
    echo "  sudo bash ./ec2-userdata.sh"
    exit 1

fi


# =========================================================
# 1. Bootstrap Log
# =========================================================
#
# Everything printed by this script is written to:
#
#   /var/log/charlie-cafe-bootstrap.log
#
# This is extremely useful for troubleshooting EC2 User Data.
# =========================================================

LOG_FILE="/var/log/charlie-cafe-bootstrap.log"

touch "$LOG_FILE"

exec > >(tee -a "$LOG_FILE" | logger -t charlie-cafe-bootstrap -s 2>/dev/console) 2>&1


# =========================================================
# 2. Bash Safety Settings
# =========================================================
#
# -e:
#   Stop when an important command fails.
#
# -u:
#   Detect undefined variables.
#
# pipefail:
#   Detect failures inside pipelines.
#
# We deliberately handle optional tests separately later.
# =========================================================

set -Eeuo pipefail


# =========================================================
# 3. Error Handler
# =========================================================
#
# If an unexpected command fails, print:
#
#   - exit code
#   - line number
#   - failed command
#   - log location
#
# This makes future troubleshooting much easier.
# =========================================================

trap 'EXIT_CODE=$?; echo; echo "========================================================="; echo "❌ CHARLIE CAFE BOOTSTRAP FAILED"; echo "========================================================="; echo "Exit Code : ${EXIT_CODE}"; echo "Line      : ${LINENO}"; echo "Command   : ${BASH_COMMAND}"; echo "Log File  : ${LOG_FILE}"; echo; echo "Review the log with:"; echo "sudo cat ${LOG_FILE}"; echo "========================================================="; exit "${EXIT_CODE}"' ERR


# =========================================================
# 4. Helper Function
# =========================================================

step() {

    echo
    echo "========================================================="
    echo "$1"
    echo "========================================================="

}


# =========================================================
# 5. Bootstrap Start
# =========================================================

echo
echo "========================================================="
echo "☕ Charlie Cafe EC2 Bootstrap Started"
echo "========================================================="
echo
echo "Date       : $(date)"
echo "User       : $(whoami)"
echo "UID        : $(id -u)"
echo "Hostname   : $(hostname)"
echo "Log File   : ${LOG_FILE}"
echo


# =========================================================
# 6. Verify Operating System
# =========================================================

step "1. Verifying Operating System"


if [[ ! -f /etc/os-release ]]; then

    echo "ERROR: /etc/os-release does not exist."
    exit 1

fi


# Load operating system information
source /etc/os-release


echo "OS Name    : ${NAME}"
echo "OS Version : ${VERSION}"
echo "OS ID      : ${ID}"


# ---------------------------------------------------------
# Confirm Amazon Linux
# ---------------------------------------------------------

if [[ "${ID}" != "amzn" ]]; then

    echo "ERROR: This script is designed for Amazon Linux."
    exit 1

fi


echo "Amazon Linux detected successfully."


# =========================================================
# 7. Verify DNF
# =========================================================

step "2. Verifying DNF package manager"


if ! command -v dnf >/dev/null 2>&1; then

    echo "ERROR: dnf package manager was not found."
    exit 1

fi


echo "DNF:"
dnf --version | head -n 1


# =========================================================
# 8. Update Amazon Linux
# =========================================================

step "3. Updating Amazon Linux packages"


dnf update -y


echo "Operating system update completed successfully."


# =========================================================
# 9. Install Apache
# =========================================================

step "4. Installing Apache HTTP Server"


dnf install -y httpd


echo "Apache package installed."


# ---------------------------------------------------------
# Enable Apache at boot
# ---------------------------------------------------------

systemctl enable httpd


# ---------------------------------------------------------
# Start Apache
# ---------------------------------------------------------

systemctl start httpd


# ---------------------------------------------------------
# Verify Apache
# ---------------------------------------------------------

if systemctl is-active --quiet httpd; then

    echo "[PASS] Apache service is running."

else

    echo "[FAIL] Apache service is not running."
    systemctl status httpd --no-pager || true
    exit 1

fi


# ---------------------------------------------------------
# Apache version
# ---------------------------------------------------------

echo
echo "Apache version:"
httpd -v | head -n 1


# =========================================================
# 10. Install PHP
# =========================================================

step "5. Installing PHP and PHP extensions"


dnf install -y \
    php \
    php-cli \
    php-common \
    php-fpm \
    php-mysqlnd \
    php-mbstring \
    php-xml \
    php-json


echo "PHP installation completed."


# ---------------------------------------------------------
# PHP version
# ---------------------------------------------------------

echo
echo "PHP version:"
php -v | head -n 1


# =========================================================
# 11. Verify PHP MySQL Support
# =========================================================

step "6. Verifying PHP extensions"


if php -m | grep -qi '^mysqli$'; then

    echo "[PASS] PHP mysqli extension installed."

else

    echo "[FAIL] PHP mysqli extension is missing."
    exit 1

fi


if php -m | grep -qi '^mysqlnd$'; then

    echo "[PASS] PHP mysqlnd extension installed."

else

    echo "[FAIL] PHP mysqlnd extension is missing."
    exit 1

fi


if php -m | grep -qi '^mbstring$'; then

    echo "[PASS] PHP mbstring extension installed."

else

    echo "[FAIL] PHP mbstring extension is missing."
    exit 1

fi


if php -m | grep -qi '^xml$'; then

    echo "[PASS] PHP XML extension installed."

else

    echo "[FAIL] PHP XML extension is missing."
    exit 1

fi


# =========================================================
# 12. Configure PHP-FPM
# =========================================================

step "7. Configuring PHP-FPM"


# Enable PHP-FPM at boot
systemctl enable php-fpm


# Start PHP-FPM
systemctl start php-fpm


# Verify PHP-FPM
if systemctl is-active --quiet php-fpm; then

    echo "[PASS] PHP-FPM service is running."

else

    echo "[FAIL] PHP-FPM service is not running."
    systemctl status php-fpm --no-pager || true
    exit 1

fi


# =========================================================
# 13. Configure Apache Web Directory
# =========================================================

step "8. Configuring Apache web directory"


# Create web directory if it doesn't exist
mkdir -p /var/www/html


# ---------------------------------------------------------
# IMPORTANT
# ---------------------------------------------------------
#
# We do NOT blindly change ownership of the entire
# /var/www directory every time.
#
# Apache only needs access to the web files.
# =========================================================

chown -R apache:apache /var/www/html


# Standard directory permissions
find /var/www/html -type d -exec chmod 755 {} \;


# Standard file permissions
find /var/www/html -type f -exec chmod 644 {} \;


echo "Apache web directory configured."


echo
echo "Web directory:"
ls -ld /var/www
ls -ld /var/www/html


# =========================================================
# 14. Install MariaDB/MySQL Client
# =========================================================

step "9. Installing MariaDB/MySQL client"


# ---------------------------------------------------------
# IMPORTANT:
#
# We install the CLIENT only.
#
# We do NOT install a local database server.
#
# Charlie Cafe can use Amazon RDS MySQL as the database.
# =========================================================

if dnf list installed mariadb105 >/dev/null 2>&1; then

    echo "MariaDB 10.5 client package is already installed."

else

    dnf install -y mariadb105

fi


echo "MariaDB/MySQL client installation completed."


# ---------------------------------------------------------
# Verify MariaDB/MySQL client
# ---------------------------------------------------------

if command -v mariadb >/dev/null 2>&1; then

    echo "MariaDB client:"
    mariadb --version

elif command -v mysql >/dev/null 2>&1; then

    echo "MySQL client:"
    mysql --version

else

    echo "ERROR: MariaDB/MySQL client command was not found."
    exit 1

fi


# =========================================================
# 15. Install Docker
# =========================================================

step "10. Installing Docker"


dnf install -y docker


echo "Docker package installed."


# ---------------------------------------------------------
# Enable Docker
# ---------------------------------------------------------

systemctl enable docker


# ---------------------------------------------------------
# Start Docker
# ---------------------------------------------------------

systemctl start docker


# ---------------------------------------------------------
# Verify Docker
# ---------------------------------------------------------

if systemctl is-active --quiet docker; then

    echo "[PASS] Docker service is running."

else

    echo "[FAIL] Docker service is not running."
    systemctl status docker --no-pager || true
    exit 1

fi


# ---------------------------------------------------------
# Docker version
# ---------------------------------------------------------

docker --version


# =========================================================
# 16. Configure Docker Permissions
# =========================================================

step "11. Configuring Docker permissions for ec2-user"


# ---------------------------------------------------------
# Make sure docker group exists
# ---------------------------------------------------------

if getent group docker >/dev/null 2>&1; then

    echo "Docker group already exists."

else

    groupadd docker
    echo "Docker group created."

fi


# ---------------------------------------------------------
# Add ec2-user to Docker group
# ---------------------------------------------------------

if id ec2-user >/dev/null 2>&1; then

    usermod -aG docker ec2-user

    echo "[PASS] ec2-user added to docker group."

else

    echo "WARNING: ec2-user does not exist."
    echo "Docker group configuration skipped."

fi


echo
echo "Docker group:"
getent group docker


# =========================================================
# 17. Install Docker Compose v2
# =========================================================

step "12. Installing Docker Compose v2"


# ---------------------------------------------------------
# IMPORTANT:
#
# Docker Compose v2 is installed as a Docker CLI plugin.
#
# This allows:
#
#     docker compose version
#
# instead of the old:
#
#     docker-compose version
# =========================================================


DOCKER_PLUGIN_DIR="/usr/local/lib/docker/cli-plugins"

mkdir -p "${DOCKER_PLUGIN_DIR}"


# ---------------------------------------------------------
# IMPORTANT CURL FIX
# ---------------------------------------------------------
#
# Amazon Linux 2023 commonly has:
#
#     curl-minimal
#
# already installed.
#
# We DO NOT install the full "curl" package because it
# conflicts with curl-minimal.
#
# Instead, we simply verify that curl already exists.
# =========================================================

if command -v curl >/dev/null 2>&1; then

    echo "[PASS] curl is already available."

else

    echo "ERROR: curl command is not available."
    exit 1

fi


echo
echo "curl version:"
curl --version | head -n 1


# ---------------------------------------------------------
# Download Docker Compose
# ---------------------------------------------------------

COMPOSE_URL="https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64"

echo
echo "Downloading Docker Compose from:"
echo "${COMPOSE_URL}"


curl -fSL \
    --retry 5 \
    --retry-delay 3 \
    --connect-timeout 15 \
    --max-time 300 \
    "${COMPOSE_URL}" \
    -o "${DOCKER_PLUGIN_DIR}/docker-compose"


# ---------------------------------------------------------
# Make Docker Compose executable
# ---------------------------------------------------------

chmod +x "${DOCKER_PLUGIN_DIR}/docker-compose"


# ---------------------------------------------------------
# Verify Docker Compose
# ---------------------------------------------------------

if docker compose version; then

    echo "[PASS] Docker Compose v2 installed successfully."

else

    echo "[FAIL] Docker Compose installation failed."
    exit 1

fi


# =========================================================
# 18. Install Git
# =========================================================

step "13. Installing Git"


dnf install -y git


echo "Git installed."


git --version


# =========================================================
# 19. Install DevOps Utilities
# =========================================================

step "14. Installing DevOps utilities"


# ---------------------------------------------------------
# IMPORTANT:
#
# DO NOT add "curl" here.
#
# Amazon Linux 2023 already provides curl-minimal.
#
# Installing full "curl" together with curl-minimal causes:
#
#   package curl-minimal conflicts with curl
#
# which was the exact cause of the previous bootstrap
# failure.
# =========================================================

dnf install -y \
    htop \
    unzip \
    wget \
    nano \
    vim-enhanced \
    tar


echo "DevOps utilities installed successfully."


# ---------------------------------------------------------
# Verify utilities
# ---------------------------------------------------------

echo
echo "curl:"
curl --version | head -n 1

echo
echo "wget:"
wget --version | head -n 1

echo
echo "unzip:"
unzip -v | head -n 1

echo
echo "tar:"
tar --version | head -n 1


# =========================================================
# 20. Install AWS CLI
# =========================================================

step "15. Installing AWS CLI"


# ---------------------------------------------------------
# Amazon Linux 2023 provides AWS CLI through DNF.
#
# Installing through DNF keeps package management simple
# and avoids unnecessary manual installation.
# =========================================================

dnf install -y awscli


echo "AWS CLI installed."


# ---------------------------------------------------------
# AWS CLI version
# ---------------------------------------------------------

aws --version


# =========================================================
# 21. Create PHP Test Page
# =========================================================

step "16. Creating PHP test page"


cat > /var/www/html/info.php <<'PHP'
<?php

phpinfo();

?>
PHP


# Set ownership
chown apache:apache /var/www/html/info.php


# Set permissions
chmod 644 /var/www/html/info.php


echo "PHP info page created."


ls -l /var/www/html/info.php


# =========================================================
# 22. Create Charlie Cafe Health Page
# =========================================================

step "17. Creating Charlie Cafe application test page"


cat > /var/www/html/index.php <<'PHP'
<?php

echo "<!DOCTYPE html>";
echo "<html>";
echo "<head>";
echo "<title>Charlie Cafe</title>";
echo "</head>";

echo "<body>";

echo "<h1>☕ Charlie Cafe EC2 Server</h1>";

echo "<p><strong>Apache:</strong> Working</p>";
echo "<p><strong>PHP:</strong> Working</p>";
echo "<p><strong>Server:</strong> Amazon Linux 2023</p>";

echo "<p><strong>Hostname:</strong> " . htmlspecialchars(gethostname()) . "</p>";

echo "<p><strong>PHP Version:</strong> " . htmlspecialchars(PHP_VERSION) . "</p>";

echo "</body>";
echo "</html>";

?>
PHP


# Set ownership
chown apache:apache /var/www/html/index.php


# Set permissions
chmod 644 /var/www/html/index.php


echo "Charlie Cafe test page created."


# =========================================================
# 23. Apache Configuration Test
# =========================================================

step "18. Testing Apache configuration"


if httpd -t; then

    echo "[PASS] Apache configuration is valid."

else

    echo "[FAIL] Apache configuration is invalid."
    exit 1

fi


# =========================================================
# 24. Restart Apache and PHP-FPM
# =========================================================

step "19. Restarting Apache and PHP-FPM"


systemctl restart php-fpm

systemctl restart httpd


echo "Apache and PHP-FPM restarted."


# =========================================================
# 25. Verify Services
# =========================================================

step "20. Verifying required services"


echo
echo "Apache:"
systemctl is-active httpd


echo
echo "PHP-FPM:"
systemctl is-active php-fpm


echo
echo "Docker:"
systemctl is-active docker


# ---------------------------------------------------------
# Strict verification
# ---------------------------------------------------------

if ! systemctl is-active --quiet httpd; then

    echo "ERROR: Apache is not running."
    exit 1

fi


if ! systemctl is-active --quiet php-fpm; then

    echo "ERROR: PHP-FPM is not running."
    exit 1

fi


if ! systemctl is-active --quiet docker; then

    echo "ERROR: Docker is not running."
    exit 1

fi


echo
echo "[PASS] Required services are running."


# =========================================================
# 26. Verify Installed Software
# =========================================================

step "21. Verifying installed software"


echo
echo "Apache:"
httpd -v | head -n 1


echo
echo "PHP:"
php -v | head -n 1


echo
echo "Docker:"
docker --version


echo
echo "Docker Compose:"
docker compose version


echo
echo "Git:"
git --version


echo
echo "AWS CLI:"
aws --version


echo
echo "MariaDB/MySQL client:"

if command -v mariadb >/dev/null 2>&1; then

    mariadb --version

elif command -v mysql >/dev/null 2>&1; then

    mysql --version

else

    echo "ERROR: Database client not found."
    exit 1

fi


# =========================================================
# 27. Test Apache HTTP
# =========================================================

step "22. Testing Apache HTTP response"


HTTP_STATUS="$(
    curl -s \
        -o /dev/null \
        -w "%{http_code}" \
        --max-time 10 \
        http://localhost
)"


echo "Apache HTTP status: ${HTTP_STATUS}"


if [[ "${HTTP_STATUS}" == "200" ||
      "${HTTP_STATUS}" == "301" ||
      "${HTTP_STATUS}" == "302" ]]; then

    echo "[PASS] Apache HTTP test."

else

    echo "[FAIL] Apache HTTP test."
    exit 1

fi


# =========================================================
# 28. Test PHP Execution
# =========================================================

step "23. Testing PHP execution"


PHP_STATUS="$(
    curl -s \
        -o /dev/null \
        -w "%{http_code}" \
        --max-time 10 \
        http://localhost/index.php
)"


echo "PHP HTTP status: ${PHP_STATUS}"


if [[ "${PHP_STATUS}" == "200" ]]; then

    echo "[PASS] PHP execution test."

else

    echo "[FAIL] PHP execution test."
    exit 1

fi


# =========================================================
# 29. Test PHP Info Page
# =========================================================

step "24. Testing PHP info page"


PHP_INFO_STATUS="$(
    curl -s \
        -o /dev/null \
        -w "%{http_code}" \
        --max-time 10 \
        http://localhost/info.php
)"


echo "PHP info HTTP status: ${PHP_INFO_STATUS}"


if [[ "${PHP_INFO_STATUS}" == "200" ]]; then

    echo "[PASS] PHP info page test."

else

    echo "[FAIL] PHP info page test."
    exit 1

fi


# =========================================================
# 30. Test Docker
# =========================================================

step "25. Testing Docker daemon"


if docker info >/dev/null 2>&1; then

    echo "[PASS] Docker daemon test."

else

    echo "WARNING: Docker service is running, but docker info"
    echo "could not be executed successfully."

    echo
    echo "This can happen because the bootstrap runs as root"
    echo "and ec2-user Docker group membership only applies"
    echo "after a new login session."

    echo
    echo "After reconnecting as ec2-user, run:"
    echo
    echo "    docker info"
    echo
    echo "    docker run hello-world"

fi


# =========================================================
# 31. Test AWS IAM Identity
# =========================================================

step "26. Testing AWS IAM role"


# ---------------------------------------------------------
# This does NOT create or modify AWS resources.
#
# It only asks AWS STS:
#
#   Who am I?
#
# The EC2 instance should have an IAM role attached.
# =========================================================

IDENTITY_FILE="/tmp/charlie-cafe-identity.json"


if aws sts get-caller-identity > "${IDENTITY_FILE}" 2>/dev/null; then

    echo "[PASS] AWS IAM identity test."

    echo
    echo "AWS identity:"
    cat "${IDENTITY_FILE}"

    rm -f "${IDENTITY_FILE}"

else

    echo
    echo "WARNING: AWS identity could not be verified."

    echo "Possible reasons:"
    echo "  1. EC2 has no IAM role."
    echo "  2. Instance metadata is unavailable."
    echo "  3. AWS CLI configuration is not available."

    echo
    echo "This does not stop the bootstrap."

fi


# =========================================================
# 32. Display Listening Ports
# =========================================================

step "27. Checking listening ports"


if command -v ss >/dev/null 2>&1; then

    echo
    echo "Listening TCP ports:"
    ss -lntp || true

fi


# =========================================================
# 33. Create Bootstrap Completion Marker
# =========================================================

step "28. Creating bootstrap completion marker"


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

---------------------------------------------------------
Software
---------------------------------------------------------

Apache:
$(httpd -v 2>&1 | head -n 1)

PHP:
$(php -v 2>&1 | head -n 1)

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
Web Files
---------------------------------------------------------

Web Root:
/var/www/html

Application Test:
/var/www/html/index.php

PHP Info:
/var/www/html/info.php

---------------------------------------------------------
Logs
---------------------------------------------------------

Bootstrap Log:
/var/log/charlie-cafe-bootstrap.log

Completion Marker:
/var/log/charlie-cafe-bootstrap-complete.txt

=========================================================
EOF


echo "Bootstrap completion marker created."


# =========================================================
# 34. Final Verification Summary
# =========================================================

step "29. Final Charlie Cafe verification"


echo
echo "[PASS] Amazon Linux detected"
echo "[PASS] System packages updated"
echo "[PASS] Apache installed and running"
echo "[PASS] PHP installed"
echo "[PASS] PHP extensions verified"
echo "[PASS] PHP-FPM installed and running"
echo "[PASS] MariaDB/MySQL client installed"
echo "[PASS] Docker installed and running"
echo "[PASS] ec2-user added to Docker group"
echo "[PASS] Docker Compose v2 installed"
echo "[PASS] Git installed"
echo "[PASS] DevOps utilities installed"
echo "[PASS] AWS CLI installed"
echo "[PASS] Apache configuration verified"
echo "[PASS] Apache HTTP test passed"
echo "[PASS] PHP execution test passed"
echo "[PASS] PHP info page test passed"
echo "[PASS] Bootstrap completion marker created"


# =========================================================
# 35. Final Success Message
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
echo "Bootstrap log:"
echo "  ${LOG_FILE}"
echo
echo "Completion marker:"
echo "  ${COMPLETION_FILE}"
echo
echo "Web root:"
echo "  /var/www/html"
echo
echo "Charlie Cafe test page:"
echo "  http://<EC2-PUBLIC-IP>/index.php"
echo
echo "PHP information page:"
echo "  http://<EC2-PUBLIC-IP>/info.php"
echo
echo "---------------------------------------------------------"
echo "IMPORTANT DOCKER NOTE"
echo "---------------------------------------------------------"
echo
echo "ec2-user was added to the docker group."
echo
echo "You MUST reconnect to EC2 before using Docker as"
echo "ec2-user so the new group membership takes effect."
echo
echo "After reconnecting, test:"
echo
echo "  docker --version"
echo "  docker compose version"
echo "  docker info"
echo
echo "Optional Docker test:"
echo
echo "  docker run hello-world"
echo
echo "========================================================="
echo "☕ Charlie Cafe Bootstrap Finished"
echo "========================================================="
echo