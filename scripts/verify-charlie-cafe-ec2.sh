#!/bin/bash

# =========================================================
# ☕ Charlie Cafe — EC2 Bootstrap Verification Script
# =========================================================
#
# PURPOSE
# ---------------------------------------------------------
# This script verifies the EC2 instance after running:
#
#   charlie-cafe EC2 User Data / Bootstrap Script
#
# Operating System:
#   Amazon Linux 2023
#
# IMPORTANT
# ---------------------------------------------------------
# THIS IS A READ-ONLY VERIFICATION SCRIPT.
#
# It does NOT:
#
#   - Install software
#   - Update packages
#   - Remove packages
#   - Modify configuration
#   - Restart services
#   - Create users
#   - Create groups
#   - Change permissions
#   - Create Docker containers
#   - Create Kubernetes clusters
#
# It only READS the current EC2 state and reports:
#
#   [PASS] Everything is correct
#   [FAIL] Something is missing or incorrect
#   [WARN] Optional/expected condition is unavailable
#
# =========================================================


# =========================================================
# 0. ROOT CHECK
# =========================================================

if [[ "${EUID}" -ne 0 ]]; then

    echo
    echo "ERROR: This verification script should be run as root."
    echo
    echo "Run:"
    echo
    echo "  sudo bash verify-charlie-cafe-ec2.sh"
    echo

    exit 1

fi


# =========================================================
# 1. STRICT MODE
# =========================================================

set -u
set -o pipefail


# =========================================================
# 2. VARIABLES
# =========================================================

WEB_ROOT="/var/www/html"

PHP_FPM_CONFIG="/etc/php-fpm.d/www.conf"

PHP_APACHE_CONFIG="/etc/httpd/conf.d/php-fpm.conf"

COMPLETION_FILE="/var/log/charlie-cafe-bootstrap-complete.txt"

BOOTSTRAP_LOG="/var/log/charlie-cafe-bootstrap.log"

PHP_FPM_SOCKET="/run/php-fpm/www.sock"

EXPECTED_SOCKET_OWNER="apache"

EXPECTED_SOCKET_GROUP="apache"

EXPECTED_SOCKET_MODE="660"

FAIL_COUNT=0

PASS_COUNT=0

WARN_COUNT=0


# =========================================================
# 3. COLORS
# =========================================================
#
# Colors are only used when the terminal supports them.
#

if [[ -t 1 ]]; then

    RED="\033[31m"
    GREEN="\033[32m"
    YELLOW="\033[33m"
    BLUE="\033[34m"
    RESET="\033[0m"

else

    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    RESET=""

fi


# =========================================================
# 4. HELPER FUNCTIONS
# =========================================================


section() {

    echo
    echo "========================================================="
    echo "$1"
    echo "========================================================="

}


pass() {

    echo -e "${GREEN}[PASS]${RESET} $1"

    PASS_COUNT=$((PASS_COUNT + 1))

}


fail() {

    echo -e "${RED}[FAIL]${RESET} $1"

    FAIL_COUNT=$((FAIL_COUNT + 1))

}


warn() {

    echo -e "${YELLOW}[WARN]${RESET} $1"

    WARN_COUNT=$((WARN_COUNT + 1))

}


info() {

    echo -e "${BLUE}[INFO]${RESET} $1"

}


command_exists() {

    command -v "$1" >/dev/null 2>&1

}


check_command() {

    local COMMAND_NAME="$1"

    if command_exists "${COMMAND_NAME}"; then

        pass "${COMMAND_NAME} command is available."

        return 0

    else

        fail "${COMMAND_NAME} command is missing."

        return 1

    fi

}


check_package() {

    local PACKAGE="$1"

    if rpm -q "${PACKAGE}" >/dev/null 2>&1; then

        pass "Package installed: ${PACKAGE}"

    else

        fail "Package missing: ${PACKAGE}"

    fi

}


check_file() {

    local FILE="$1"

    if [[ -f "${FILE}" ]]; then

        pass "File exists: ${FILE}"

    else

        fail "File missing: ${FILE}"

    fi

}


check_directory() {

    local DIRECTORY="$1"

    if [[ -d "${DIRECTORY}" ]]; then

        pass "Directory exists: ${DIRECTORY}"

    else

        fail "Directory missing: ${DIRECTORY}"

    fi

}


check_service_active() {

    local SERVICE="$1"

    if systemctl is-active --quiet "${SERVICE}"; then

        pass "Service active: ${SERVICE}"

    else

        fail "Service NOT active: ${SERVICE}"

    fi

}


check_service_enabled() {

    local SERVICE="$1"

    if systemctl is-enabled --quiet "${SERVICE}"; then

        pass "Service enabled at boot: ${SERVICE}"

    else

        fail "Service NOT enabled at boot: ${SERVICE}"

    fi

}


# =========================================================
# 5. START
# =========================================================

section "☕ Charlie Cafe EC2 Verification Started"

echo
echo "Date:"
date

echo
echo "Hostname:"
hostname

echo
echo "Current user:"
whoami

echo
echo "UID:"
id -u

echo
echo "Architecture:"
uname -m

echo
echo "Kernel:"
uname -r

echo


# =========================================================
# 6. OPERATING SYSTEM
# =========================================================

section "1. Amazon Linux 2023 Verification"


if [[ ! -f /etc/os-release ]]; then

    fail "/etc/os-release does not exist."

else

    # shellcheck disable=SC1091
    source /etc/os-release

    echo "OS Name       : ${NAME:-unknown}"
    echo "OS ID         : ${ID:-unknown}"
    echo "Version       : ${VERSION:-unknown}"
    echo "Version ID    : ${VERSION_ID:-unknown}"

    if [[ "${ID:-}" == "amzn" ]]; then

        pass "Amazon Linux detected."

    else

        fail "Operating system is not Amazon Linux."

    fi


    if [[ "${VERSION_ID:-}" == "2023" ]]; then

        pass "Amazon Linux 2023 detected."

    else

        fail "Operating system is not Amazon Linux 2023."

    fi

fi


# =========================================================
# 7. DNF
# =========================================================

section "2. DNF Package Manager Verification"


if check_command dnf; then

    dnf --version | head -n 1

fi


# =========================================================
# 8. BASE PACKAGES
# =========================================================

section "3. Base Package Verification"


BASE_PACKAGES=(

    httpd
    git
    wget
    unzip
    tar
    gzip
    bzip2
    xz
    nano
    vim-enhanced
    htop
    curl
    ca-certificates
    openssl
    findutils
    procps-ng
    iproute
    iputils
    bind-utils
    jq
    which
    util-linux
    shadow-utils

)


for PACKAGE in "${BASE_PACKAGES[@]}"; do

    check_package "${PACKAGE}"

done


# =========================================================
# 9. CURL
# =========================================================

section "4. curl Verification"


if check_command curl; then

    curl --version | head -n 1

fi


# =========================================================
# 10. APACHE
# =========================================================

section "5. Apache HTTP Server Verification"


check_command httpd

if command_exists httpd; then

    httpd -v 2>&1 | head -n 1

fi


check_package httpd


# ---------------------------------------------------------
# Apache service
# ---------------------------------------------------------

check_service_active httpd

check_service_enabled httpd


# ---------------------------------------------------------
# Apache configuration
# ---------------------------------------------------------

if command_exists httpd; then

    if httpd -t >/dev/null 2>&1; then

        pass "Apache configuration syntax is valid."

    else

        fail "Apache configuration syntax is invalid."

        echo
        echo "Apache configuration test:"
        httpd -t || true

    fi

fi


# =========================================================
# 11. APACHE MODULES
# =========================================================

section "6. Apache PHP-FPM Module Verification"


if command_exists httpd; then


    if httpd -M 2>/dev/null | grep -q "proxy_module"; then

        pass "Apache mod_proxy is loaded."

    else

        fail "Apache mod_proxy is NOT loaded."

    fi


    if httpd -M 2>/dev/null | grep -q "proxy_fcgi_module"; then

        pass "Apache mod_proxy_fcgi is loaded."

    else

        fail "Apache mod_proxy_fcgi is NOT loaded."

    fi

fi


# =========================================================
# 12. PHP PACKAGES
# =========================================================

section "7. PHP Package Verification"


PHP_PACKAGES=(

    php
    php-cli
    php-common
    php-fpm
    php-mysqlnd
    php-mbstring
    php-xml
    php-opcache

)


for PACKAGE in "${PHP_PACKAGES[@]}"; do

    check_package "${PACKAGE}"

done


# ---------------------------------------------------------
# php-json is included in the original bootstrap package
# list. Depending on the AL2023 PHP packaging generation,
# JSON may also be provided by the main PHP package.
# Therefore we verify the actual PHP extension below.
# ---------------------------------------------------------

if rpm -q php-json >/dev/null 2>&1; then

    pass "Package installed: php-json"

else

    warn "php-json is not a separate RPM package; verifying JSON extension through PHP."

fi


# =========================================================
# 13. PHP COMMAND
# =========================================================

section "8. PHP Verification"


if check_command php; then

    php -v | head -n 1

fi


# =========================================================
# 14. PHP EXTENSIONS
# =========================================================

section "9. PHP Extension Verification"


REQUIRED_EXTENSIONS=(

    mysqli
    mysqlnd
    mbstring
    xml
    json
    opcache
    pdo_mysql

)


if command_exists php; then

    for EXT in "${REQUIRED_EXTENSIONS[@]}"; do

        if php -m 2>/dev/null | grep -qi "^${EXT}$"; then

            pass "PHP extension available: ${EXT}"

        else

            fail "PHP extension missing: ${EXT}"

        fi

    done

fi


# =========================================================
# 15. PHP-FPM CONFIGURATION
# =========================================================

section "10. PHP-FPM Configuration Verification"


check_file "${PHP_FPM_CONFIG}"


if [[ -f "${PHP_FPM_CONFIG}" ]]; then


    # -----------------------------------------------------
    # PHP-FPM user
    # -----------------------------------------------------

    if grep -Eq '^[[:space:]]*user[[:space:]]*=[[:space:]]*apache' \
        "${PHP_FPM_CONFIG}"; then

        pass "PHP-FPM user is configured as apache."

    else

        fail "PHP-FPM user is NOT configured as apache."

    fi


    # -----------------------------------------------------
    # PHP-FPM group
    # -----------------------------------------------------

    if grep -Eq '^[[:space:]]*group[[:space:]]*=[[:space:]]*apache' \
        "${PHP_FPM_CONFIG}"; then

        pass "PHP-FPM group is configured as apache."

    else

        fail "PHP-FPM group is NOT configured as apache."

    fi


    # -----------------------------------------------------
    # PHP-FPM socket
    # -----------------------------------------------------

    if grep -Eq '^listen[[:space:]]*=[[:space:]]*/run/php-fpm/www.sock' \
        "${PHP_FPM_CONFIG}"; then

        pass "PHP-FPM listen socket is correctly configured."

    else

        fail "PHP-FPM listen socket is incorrectly configured."

    fi


    # -----------------------------------------------------
    # Socket owner
    # -----------------------------------------------------

    if grep -Eq '^listen\.owner[[:space:]]*=[[:space:]]*apache' \
        "${PHP_FPM_CONFIG}"; then

        pass "PHP-FPM socket owner is apache."

    else

        fail "PHP-FPM socket owner is NOT apache."

    fi


    # -----------------------------------------------------
    # Socket group
    # -----------------------------------------------------

    if grep -Eq '^listen\.group[[:space:]]*=[[:space:]]*apache' \
        "${PHP_FPM_CONFIG}"; then

        pass "PHP-FPM socket group is apache."

    else

        fail "PHP-FPM socket group is NOT apache."

    fi


    # -----------------------------------------------------
    # Socket mode
    # -----------------------------------------------------

    if grep -Eq '^listen\.mode[[:space:]]*=[[:space:]]*0660' \
        "${PHP_FPM_CONFIG}"; then

        pass "PHP-FPM socket mode is 0660."

    else

        fail "PHP-FPM socket mode is NOT 0660."

    fi

fi


# =========================================================
# 16. PHP-FPM CONFIG TEST
# =========================================================

section "11. PHP-FPM Configuration Syntax"


if command_exists php-fpm; then

    php-fpm -t >/dev/null 2>&1

    if [[ $? -eq 0 ]]; then

        pass "PHP-FPM configuration syntax is valid."

    else

        fail "PHP-FPM configuration syntax is invalid."

        php-fpm -t || true

    fi

else

    fail "php-fpm command is missing."

fi


# =========================================================
# 17. PHP-FPM SERVICE
# =========================================================

section "12. PHP-FPM Service Verification"


check_service_active php-fpm

check_service_enabled php-fpm


# =========================================================
# 18. PHP-FPM SOCKET
# =========================================================

section "13. PHP-FPM Socket Verification"


if [[ -S "${PHP_FPM_SOCKET}" ]]; then

    pass "PHP-FPM socket exists: ${PHP_FPM_SOCKET}"

    SOCKET_OWNER="$(stat -c '%U' "${PHP_FPM_SOCKET}")"

    SOCKET_GROUP="$(stat -c '%G' "${PHP_FPM_SOCKET}")"

    SOCKET_MODE="$(stat -c '%a' "${PHP_FPM_SOCKET}")"


    echo
    echo "Socket:"
    echo "  ${PHP_FPM_SOCKET}"

    echo
    echo "Owner:"
    echo "  ${SOCKET_OWNER}"

    echo
    echo "Group:"
    echo "  ${SOCKET_GROUP}"

    echo
    echo "Mode:"
    echo "  ${SOCKET_MODE}"


    if [[ "${SOCKET_OWNER}" == "${EXPECTED_SOCKET_OWNER}" ]]; then

        pass "PHP-FPM socket owner is apache."

    else

        fail "PHP-FPM socket owner is ${SOCKET_OWNER}, expected apache."

    fi


    if [[ "${SOCKET_GROUP}" == "${EXPECTED_SOCKET_GROUP}" ]]; then

        pass "PHP-FPM socket group is apache."

    else

        fail "PHP-FPM socket group is ${SOCKET_GROUP}, expected apache."

    fi


    if [[ "${SOCKET_MODE}" == "${EXPECTED_SOCKET_MODE}" ]]; then

        pass "PHP-FPM socket mode is 660."

    else

        fail "PHP-FPM socket mode is ${SOCKET_MODE}, expected 660."

    fi


else

    fail "PHP-FPM socket does not exist: ${PHP_FPM_SOCKET}"

fi


# =========================================================
# 19. APACHE PHP-FPM CONFIGURATION
# =========================================================

section "14. Apache → PHP-FPM Configuration"


check_file "${PHP_APACHE_CONFIG}"


if [[ -f "${PHP_APACHE_CONFIG}" ]]; then


    if grep -q "proxy_module" "${PHP_APACHE_CONFIG}"; then

        pass "Apache PHP-FPM config references mod_proxy."

    else

        fail "Apache PHP-FPM config missing mod_proxy configuration."

    fi


    if grep -q "proxy_fcgi_module" "${PHP_APACHE_CONFIG}"; then

        pass "Apache PHP-FPM config references mod_proxy_fcgi."

    else

        fail "Apache PHP-FPM config missing mod_proxy_fcgi configuration."

    fi


    if grep -q "proxy:unix:/run/php-fpm/www.sock" \
        "${PHP_APACHE_CONFIG}"; then

        pass "Apache configured to use PHP-FPM Unix socket."

    else

        fail "Apache PHP-FPM Unix socket configuration missing."

    fi


    if grep -q '<FilesMatch "\\.php\$">' \
        "${PHP_APACHE_CONFIG}"; then

        pass "Apache PHP FilesMatch configuration exists."

    else

        fail "Apache PHP FilesMatch configuration missing."

    fi


    if grep -q "DirectoryIndex index.html index.php" \
        "${PHP_APACHE_CONFIG}"; then

        pass "Apache DirectoryIndex configuration is correct."

    else

        fail "Apache DirectoryIndex configuration missing."

    fi

fi


# =========================================================
# 20. WEB ROOT
# =========================================================

section "15. Apache Web Root Verification"


check_directory "${WEB_ROOT}"


if [[ -d "${WEB_ROOT}" ]]; then

    WEB_OWNER="$(stat -c '%U' "${WEB_ROOT}")"

    WEB_GROUP="$(stat -c '%G' "${WEB_ROOT}")"

    WEB_MODE="$(stat -c '%a' "${WEB_ROOT}")"


    echo
    echo "Web root owner : ${WEB_OWNER}"
    echo "Web root group : ${WEB_GROUP}"
    echo "Web root mode  : ${WEB_MODE}"


    if [[ "${WEB_OWNER}" == "apache" ]]; then

        pass "Web root owner is apache."

    else

        fail "Web root owner is ${WEB_OWNER}, expected apache."

    fi


    if [[ "${WEB_GROUP}" == "apache" ]]; then

        pass "Web root group is apache."

    else

        fail "Web root group is ${WEB_GROUP}, expected apache."

    fi

fi


# =========================================================
# 21. INDEX.HTML
# =========================================================

section "16. index.html Verification"


INDEX_FILE="${WEB_ROOT}/index.html"


check_file "${INDEX_FILE}"


if [[ -f "${INDEX_FILE}" ]]; then


    if grep -q "Charlie Cafe" "${INDEX_FILE}"; then

        pass "index.html contains Charlie Cafe."

    else

        fail "index.html does not contain Charlie Cafe."

    fi


    if grep -q "Apache HTTP Server: Working" "${INDEX_FILE}"; then

        pass "index.html contains Apache status."

    else

        fail "index.html missing Apache status."

    fi


    if grep -q "Amazon Linux 2023: Working" "${INDEX_FILE}"; then

        pass "index.html contains Amazon Linux 2023 status."

    else

        fail "index.html missing Amazon Linux 2023 status."

    fi


    if grep -q "Docker: Installed" "${INDEX_FILE}"; then

        pass "index.html contains Docker status."

    else

        fail "index.html missing Docker status."

    fi


    if grep -q "Kubernetes Tools: Installed" "${INDEX_FILE}"; then

        pass "index.html contains Kubernetes status."

    else

        fail "index.html missing Kubernetes status."

    fi


    if grep -q 'href="/info.php"' "${INDEX_FILE}"; then

        pass "index.html contains info.php link."

    else

        fail "index.html missing info.php link."

    fi

fi


# =========================================================
# 22. INFO.PHP
# =========================================================

section "17. info.php Verification"


INFO_FILE="${WEB_ROOT}/info.php"


check_file "${INFO_FILE}"


if [[ -f "${INFO_FILE}" ]]; then


    if grep -q "phpinfo" "${INFO_FILE}"; then

        pass "info.php contains phpinfo()."

    else

        fail "info.php does not contain phpinfo()."

    fi

fi


# =========================================================
# 23. WEB FILE PERMISSIONS
# =========================================================

section "18. Web File Permission Verification"


if [[ -d "${WEB_ROOT}" ]]; then


    BAD_DIRS="$(find "${WEB_ROOT}" -type d ! -perm 755 -print 2>/dev/null)"

    if [[ -z "${BAD_DIRS}" ]]; then

        pass "All web directories use permission 755."

    else

        fail "One or more web directories do not use permission 755."

        echo "${BAD_DIRS}"

    fi


    BAD_FILES="$(find "${WEB_ROOT}" -type f ! -perm 644 -print 2>/dev/null)"

    if [[ -z "${BAD_FILES}" ]]; then

        pass "All web files use permission 644."

    else

        fail "One or more web files do not use permission 644."

        echo "${BAD_FILES}"

    fi


fi


# =========================================================
# 24. INDEX.PHP MUST NOT EXIST
# =========================================================

section "19. index.php Verification"


if [[ -e "${WEB_ROOT}/index.php" ]]; then

    fail "Unexpected index.php exists."

else

    pass "index.php does not exist."

fi


# =========================================================
# 25. APACHE HTTP TEST
# =========================================================

section "20. Apache HTTP index.html Test"


HTTP_OUTPUT="/tmp/charlie-cafe-index-verification.html"


HTTP_STATUS="$(
    curl \
        --silent \
        --show-error \
        --output "${HTTP_OUTPUT}" \
        --write-out "%{http_code}" \
        --max-time 15 \
        http://127.0.0.1/ \
        2>/dev/null
)"


echo "HTTP status: ${HTTP_STATUS}"


if [[ "${HTTP_STATUS}" == "200" ]]; then

    pass "Apache returned HTTP 200 for /."

else

    fail "Apache did not return HTTP 200 for /."

fi


if [[ -f "${HTTP_OUTPUT}" ]]; then


    if grep -q "Charlie Cafe" "${HTTP_OUTPUT}"; then

        pass "HTTP response contains Charlie Cafe."

    else

        fail "HTTP response does not contain Charlie Cafe."

    fi


    rm -f "${HTTP_OUTPUT}"

fi


# =========================================================
# 26. PHP HTTP TEST
# =========================================================

section "21. Apache → PHP-FPM HTTP Test"


PHP_OUTPUT="/tmp/charlie-cafe-php-verification.html"


PHP_STATUS="$(
    curl \
        --silent \
        --show-error \
        --output "${PHP_OUTPUT}" \
        --write-out "%{http_code}" \
        --max-time 15 \
        http://127.0.0.1/info.php \
        2>/dev/null
)"


echo "PHP HTTP status: ${PHP_STATUS}"


if [[ "${PHP_STATUS}" == "200" ]]; then

    pass "Apache returned HTTP 200 for /info.php."

else

    fail "Apache did not return HTTP 200 for /info.php."

fi


if [[ -f "${PHP_OUTPUT}" ]]; then


    if grep -qi "PHP Version" "${PHP_OUTPUT}"; then

        pass "PHP executed successfully through Apache/PHP-FPM."

    else

        fail "PHP output was not detected."

    fi


    rm -f "${PHP_OUTPUT}"

fi


# =========================================================
# 27. MARIADB CLIENT
# =========================================================

section "22. MariaDB / MySQL Client Verification"


MARIADB_FOUND="false"


for PACKAGE in \
    mariadb123 \
    mariadb118 \
    mariadb114 \
    mariadb1011 \
    mariadb105
do

    if rpm -q "${PACKAGE}" >/dev/null 2>&1; then

        pass "MariaDB package installed: ${PACKAGE}"

        MARIADB_FOUND="true"

    fi

done


if [[ "${MARIADB_FOUND}" == "false" ]]; then

    warn "No expected MariaDB package name was detected."

fi


if command_exists mariadb; then

    pass "mariadb command is available."

    mariadb --version

elif command_exists mysql; then

    pass "mysql-compatible client command is available."

    mysql --version

else

    fail "Neither mariadb nor mysql client command is available."

fi


# =========================================================
# 28. DOCKER PACKAGE
# =========================================================

section "23. Docker Installation Verification"


check_package docker

check_command docker


if command_exists docker; then

    docker --version

fi


# =========================================================
# 29. DOCKER GROUP
# =========================================================

section "24. Docker Group Verification"


if getent group docker >/dev/null 2>&1; then

    pass "docker group exists."

    echo
    echo "Docker group:"
    getent group docker

else

    fail "docker group does not exist."

fi


# ---------------------------------------------------------
# ec2-user
# ---------------------------------------------------------

if id ec2-user >/dev/null 2>&1; then

    pass "ec2-user exists."


    if id -nG ec2-user | tr ' ' '\n' | grep -qx docker; then

        pass "ec2-user belongs to docker group."

    else

        fail "ec2-user is NOT a member of docker group."

    fi

else

    fail "ec2-user does not exist."

fi


# =========================================================
# 30. DOCKER SERVICE
# =========================================================

section "25. Docker Service Verification"


check_service_active docker

check_service_enabled docker


# =========================================================
# 31. DOCKER DAEMON
# =========================================================

section "26. Docker Daemon Verification"


if command_exists docker; then


    if docker info >/dev/null 2>&1; then

        pass "Docker daemon is responding."

    else

        fail "Docker daemon is NOT responding."

    fi

fi


# =========================================================
# 32. DOCKER COMPOSE
# =========================================================

section "27. Docker Compose v2 Verification"


DOCKER_PLUGIN_DIR="/usr/local/lib/docker/cli-plugins"

DOCKER_COMPOSE_PLUGIN="${DOCKER_PLUGIN_DIR}/docker-compose"


if [[ -f "${DOCKER_COMPOSE_PLUGIN}" ]]; then

    pass "Docker Compose CLI plugin exists."

else

    fail "Docker Compose CLI plugin is missing."

fi


if [[ -x "${DOCKER_COMPOSE_PLUGIN}" ]]; then

    pass "Docker Compose plugin is executable."

else

    fail "Docker Compose plugin is not executable."

fi


if command_exists docker; then


    if docker compose version >/dev/null 2>&1; then

        pass "Docker Compose v2 command works."

        docker compose version

    else

        fail "docker compose command does not work."

    fi

fi


# =========================================================
# 33. GIT
# =========================================================

section "28. Git Verification"


check_package git

if check_command git; then

    git --version

fi


# =========================================================
# 34. AWS CLI
# =========================================================

section "29. AWS CLI v2 Verification"


if check_command aws; then


    AWS_VERSION="$(aws --version 2>&1)"

    echo "${AWS_VERSION}"


    if echo "${AWS_VERSION}" | grep -q "aws-cli/2"; then

        pass "AWS CLI v2 detected."

    else

        fail "AWS CLI is installed but is NOT version 2."

    fi

fi


# =========================================================
# 35. AWS STS / IAM ROLE
# =========================================================

section "30. EC2 IAM Role / AWS STS Verification"


if command_exists aws; then


    IDENTITY_FILE="/tmp/charlie-cafe-verification-identity.json"


    if aws sts get-caller-identity \
        --output json \
        > "${IDENTITY_FILE}" 2>/dev/null; then


        pass "AWS STS get-caller-identity succeeded."

        echo
        echo "AWS identity:"
        cat "${IDENTITY_FILE}"

        rm -f "${IDENTITY_FILE}"


    else

        warn "AWS CLI works, but EC2 IAM credentials are not currently available."

        echo
        echo "This can happen if the EC2 instance has no IAM role."

        echo "The original bootstrap script intentionally did NOT fail in this situation."

    fi

fi


# =========================================================
# 36. KUBECTL
# =========================================================

section "31. kubectl Verification"


if check_command kubectl; then

    kubectl version --client

fi


# =========================================================
# 37. EKSCTL
# =========================================================

section "32. eksctl Verification"


if check_command eksctl; then

    eksctl version

fi


# =========================================================
# 38. HELM
# =========================================================

section "33. Helm Verification"


if check_command helm; then

    helm version --short

fi


# =========================================================
# 39. KIND
# =========================================================

section "34. kind Verification"


if check_command kind; then

    kind version

fi


# =========================================================
# 40. KUBERNETES TOOL SUMMARY
# =========================================================

section "35. Kubernetes Tools Final Verification"


K8S_TOOLS=(

    kubectl
    eksctl
    helm
    kind

)


for TOOL in "${K8S_TOOLS[@]}"; do

    if command_exists "${TOOL}"; then

        pass "Kubernetes tool available: ${TOOL}"

    else

        fail "Kubernetes tool missing: ${TOOL}"

    fi

done


# =========================================================
# 41. EC2-USER .BASHRC
# =========================================================

section "36. ec2-user Environment Verification"


EC2_BASHRC="/home/ec2-user/.bashrc"


if id ec2-user >/dev/null 2>&1; then


    check_file "${EC2_BASHRC}"


    if [[ -f "${EC2_BASHRC}" ]]; then


        if grep -q 'export PATH="/usr/local/bin:$PATH"' \
            "${EC2_BASHRC}"; then

            pass "ec2-user .bashrc contains /usr/local/bin PATH configuration."

        else

            fail "ec2-user .bashrc is missing /usr/local/bin PATH configuration."

        fi


        BASHRC_OWNER="$(stat -c '%U' "${EC2_BASHRC}")"

        BASHRC_GROUP="$(stat -c '%G' "${EC2_BASHRC}")"


        if [[ "${BASHRC_OWNER}" == "ec2-user" ]]; then

            pass "ec2-user .bashrc owner is ec2-user."

        else

            fail "ec2-user .bashrc owner is ${BASHRC_OWNER}."

        fi


        if [[ "${BASHRC_GROUP}" == "ec2-user" ]]; then

            pass "ec2-user .bashrc group is ec2-user."

        else

            fail "ec2-user .bashrc group is ${BASHRC_GROUP}."

        fi

    fi

fi


# =========================================================
# 42. REQUIRED DIRECTORIES
# =========================================================

section "37. Required Directory Verification"


REQUIRED_DIRECTORIES=(

    /var/www/html
    /etc/php-fpm.d
    /etc/httpd
    /etc/httpd/conf.d
    /usr/local/bin
    /usr/local/lib/docker/cli-plugins

)


for DIRECTORY in "${REQUIRED_DIRECTORIES[@]}"; do

    check_directory "${DIRECTORY}"

done


# =========================================================
# 43. COMPLETION MARKER
# =========================================================

section "38. Bootstrap Completion Marker Verification"


check_file "${COMPLETION_FILE}"


if [[ -f "${COMPLETION_FILE}" ]]; then


    if grep -q "Charlie Cafe EC2 Bootstrap Completed Successfully" \
        "${COMPLETION_FILE}"; then

        pass "Bootstrap completion marker contains success message."

    else

        fail "Bootstrap completion marker does not contain expected success message."

    fi


    echo
    echo "Completion marker:"
    echo "---------------------------------------------------------"

    sed -n '1,80p' "${COMPLETION_FILE}"

    echo "---------------------------------------------------------"

fi


# =========================================================
# 44. BOOTSTRAP LOG
# =========================================================

section "39. Bootstrap Log Verification"


check_file "${BOOTSTRAP_LOG}"


if [[ -f "${BOOTSTRAP_LOG}" ]]; then


    LOG_SIZE="$(stat -c '%s' "${BOOTSTRAP_LOG}")"


    echo "Bootstrap log size: ${LOG_SIZE} bytes"


    if (( LOG_SIZE > 0 )); then

        pass "Bootstrap log contains data."

    else

        fail "Bootstrap log is empty."

    fi


    if grep -q "CHARLIE CAFE EC2 BOOTSTRAP COMPLETED SUCCESSFULLY" \
        "${BOOTSTRAP_LOG}"; then

        pass "Bootstrap log contains successful completion message."

    else

        warn "Successful completion message was not found in bootstrap log."

    fi

fi


# =========================================================
# 45. APACHE LOG DIRECTORY
# =========================================================

section "40. Apache Log Verification"


if [[ -d /var/log/httpd ]]; then

    pass "Apache log directory exists."

else

    fail "Apache log directory does not exist."

fi


# =========================================================
# 46. SERVICE FINAL STATUS
# =========================================================

section "41. Final Service Status"


SERVICES=(

    httpd
    php-fpm
    docker

)


for SERVICE in "${SERVICES[@]}"; do


    echo
    echo "Service: ${SERVICE}"


    systemctl is-active "${SERVICE}" 2>/dev/null || true

    systemctl is-enabled "${SERVICE}" 2>/dev/null || true


    if systemctl is-active --quiet "${SERVICE}"; then

        pass "${SERVICE} is active."

    else

        fail "${SERVICE} is NOT active."

    fi


    if systemctl is-enabled --quiet "${SERVICE}"; then

        pass "${SERVICE} is enabled."

    else

        fail "${SERVICE} is NOT enabled."

    fi

done


# =========================================================
# 47. LISTENING PORTS
# =========================================================

section "42. Listening Port Verification"


if command_exists ss; then


    echo
    echo "Current listening TCP ports:"
    echo

    ss -lntp || true


    if ss -lnt 2>/dev/null | grep -Eq 'LISTEN.*:80[[:space:]]'; then

        pass "Port 80 is listening."

    else

        fail "Port 80 is NOT listening."

    fi

else

    warn "ss command is unavailable."

fi


# =========================================================
# 48. LOCAL HTTP CONNECTIVITY
# =========================================================

section "43. Local Web Connectivity"


if curl \
    --silent \
    --show-error \
    --max-time 10 \
    http://127.0.0.1/ \
    >/dev/null 2>&1; then

    pass "Local HTTP connectivity to Apache works."

else

    fail "Local HTTP connectivity to Apache failed."

fi


# =========================================================
# 49. PHP-FPM LOCAL HEALTH
# =========================================================

section "44. PHP-FPM Local Health"


if systemctl is-active --quiet php-fpm; then

    pass "PHP-FPM systemd service is healthy."

else

    fail "PHP-FPM systemd service is unhealthy."

fi


if [[ -S "${PHP_FPM_SOCKET}" ]]; then

    pass "PHP-FPM Unix socket is healthy."

else

    fail "PHP-FPM Unix socket is unavailable."

fi


# =========================================================
# 50. DOCKER LOCAL HEALTH
# =========================================================

section "45. Docker Local Health"


if systemctl is-active --quiet docker; then


    if docker info >/dev/null 2>&1; then

        pass "Docker daemon health check passed."

    else

        fail "Docker daemon health check failed."

    fi

else

    fail "Docker service is not active."

fi


# =========================================================
# 51. INSTALLED TOOL VERSION SUMMARY
# =========================================================

section "46. Installed DevOps Tool Versions"


echo

echo "---------------------------------------------------------"
echo "Apache"
echo "---------------------------------------------------------"

httpd -v 2>&1 | head -n 1 || true


echo

echo "---------------------------------------------------------"
echo "PHP"
echo "---------------------------------------------------------"

php -v 2>&1 | head -n 1 || true


echo

echo "---------------------------------------------------------"
echo "PHP-FPM"
echo "---------------------------------------------------------"

php-fpm -v 2>&1 | head -n 1 || true


echo

echo "---------------------------------------------------------"
echo "Docker"
echo "---------------------------------------------------------"

docker --version 2>&1 || true


echo

echo "---------------------------------------------------------"
echo "Docker Compose"
echo "---------------------------------------------------------"

docker compose version 2>&1 || true


echo

echo "---------------------------------------------------------"
echo "Git"
echo "---------------------------------------------------------"

git --version 2>&1 || true


echo

echo "---------------------------------------------------------"
echo "AWS CLI"
echo "---------------------------------------------------------"

aws --version 2>&1 || true


echo

echo "---------------------------------------------------------"
echo "kubectl"
echo "---------------------------------------------------------"

kubectl version --client 2>&1 | head -n 1 || true


echo

echo "---------------------------------------------------------"
echo "eksctl"
echo "---------------------------------------------------------"

eksctl version 2>&1 || true


echo

echo "---------------------------------------------------------"
echo "Helm"
echo "---------------------------------------------------------"

helm version --short 2>&1 || true


echo

echo "---------------------------------------------------------"
echo "kind"
echo "---------------------------------------------------------"

kind version 2>&1 || true


echo

echo "---------------------------------------------------------"
echo "MariaDB / MySQL"
echo "---------------------------------------------------------"

mariadb --version 2>&1 || mysql --version 2>&1 || true


# =========================================================
# 52. IMPORTANT FILE INVENTORY
# =========================================================

section "47. Charlie Cafe File Inventory"


echo
echo "Web root:"
find "${WEB_ROOT}" -maxdepth 2 -type f -printf '%M %U:%G %p\n' 2>/dev/null || true


echo
echo "PHP-FPM configuration:"
ls -l "${PHP_FPM_CONFIG}" 2>/dev/null || true


echo
echo "Apache PHP-FPM configuration:"
ls -l "${PHP_APACHE_CONFIG}" 2>/dev/null || true


echo
echo "Docker Compose plugin:"
ls -l "${DOCKER_COMPOSE_PLUGIN}" 2>/dev/null || true


# =========================================================
# 53. FINAL APPLICATION TEST
# =========================================================

section "48. Final Charlie Cafe Application Test"


FINAL_HTML="/tmp/charlie-cafe-final-test.html"


FINAL_STATUS="$(
    curl \
        --silent \
        --show-error \
        --output "${FINAL_HTML}" \
        --write-out "%{http_code}" \
        --max-time 15 \
        http://127.0.0.1/index.html \
        2>/dev/null
)"


if [[ "${FINAL_STATUS}" == "200" ]]; then

    pass "Charlie Cafe index.html final HTTP test passed."

else

    fail "Charlie Cafe index.html final HTTP test failed."

fi


if [[ -f "${FINAL_HTML}" ]]; then


    if grep -q "Charlie Cafe" "${FINAL_HTML}"; then

        pass "Charlie Cafe application content detected."

    else

        fail "Charlie Cafe application content missing."

    fi


    rm -f "${FINAL_HTML}"

fi


# =========================================================
# 54. FINAL PHP TEST
# =========================================================

section "49. Final PHP Application Test"


FINAL_PHP="/tmp/charlie-cafe-final-php.html"


FINAL_PHP_STATUS="$(
    curl \
        --silent \
        --show-error \
        --output "${FINAL_PHP}" \
        --write-out "%{http_code}" \
        --max-time 15 \
        http://127.0.0.1/info.php \
        2>/dev/null
)"


if [[ "${FINAL_PHP_STATUS}" == "200" ]]; then

    pass "Charlie Cafe PHP final HTTP test passed."

else

    fail "Charlie Cafe PHP final HTTP test failed."

fi


if [[ -f "${FINAL_PHP}" ]]; then


    if grep -qi "PHP Version" "${FINAL_PHP}"; then

        pass "PHP-FPM final execution test passed."

    else

        fail "PHP-FPM final execution test failed."

    fi


    rm -f "${FINAL_PHP}"

fi


# =========================================================
# 55. FINAL SUMMARY
# =========================================================

section "☕ CHARLIE CAFE EC2 VERIFICATION SUMMARY"


echo
echo "PASS COUNT : ${PASS_COUNT}"
echo "FAIL COUNT : ${FAIL_COUNT}"
echo "WARN COUNT : ${WARN_COUNT}"
echo


# =========================================================
# 56. PASS/FAIL DECISION
# =========================================================

if (( FAIL_COUNT == 0 )); then


    echo
    echo "========================================================="
    echo -e "${GREEN}✅ CHARLIE CAFE EC2 VERIFICATION PASSED${RESET}"
    echo "========================================================="
    echo
    echo "All required bootstrap components passed verification."
    echo
    echo "The EC2 instance contains the expected:"
    echo
    echo "  ✓ Amazon Linux 2023"
    echo "  ✓ Apache"
    echo "  ✓ PHP"
    echo "  ✓ PHP-FPM"
    echo "  ✓ Apache → PHP-FPM"
    echo "  ✓ index.html"
    echo "  ✓ info.php"
    echo "  ✓ MariaDB/MySQL client"
    echo "  ✓ Docker"
    echo "  ✓ Docker Compose v2"
    echo "  ✓ Git"
    echo "  ✓ AWS CLI v2"
    echo "  ✓ kubectl"
    echo "  ✓ eksctl"
    echo "  ✓ Helm"
    echo "  ✓ kind"
    echo
    echo "Services:"
    echo
    echo "  ✓ Apache"
    echo "  ✓ PHP-FPM"
    echo "  ✓ Docker"
    echo
    echo "Web tests:"
    echo
    echo "  ✓ index.html HTTP test"
    echo "  ✓ PHP-FPM HTTP test"
    echo
    echo "========================================================="
    echo "☕ Charlie Cafe EC2 is ready."
    echo "========================================================="
    echo


    exit 0


else


    echo
    echo "========================================================="
    echo -e "${RED}❌ CHARLIE CAFE EC2 VERIFICATION FAILED${RESET}"
    echo "========================================================="
    echo
    echo "Failures detected: ${FAIL_COUNT}"
    echo "Warnings detected: ${WARN_COUNT}"
    echo
    echo "Review the [FAIL] messages above."
    echo
    echo "Useful logs:"
    echo
    echo "  sudo less ${BOOTSTRAP_LOG}"
    echo
    echo "  sudo journalctl -u httpd --no-pager"
    echo
    echo "  sudo journalctl -u php-fpm --no-pager"
    echo
    echo "  sudo journalctl -u docker --no-pager"
    echo
    echo "========================================================="


    exit 1

fi

