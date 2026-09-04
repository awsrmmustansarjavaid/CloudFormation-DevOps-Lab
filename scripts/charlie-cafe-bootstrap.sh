#!/bin/bash

# =============================================================================
# ☕ Charlie Cafe — Amazon Linux 2023 EC2 Bootstrap Script
# =============================================================================
#
# PURPOSE
# -------
# Prepare an Amazon Linux 2023 EC2 instance for the Charlie Cafe DevOps Lab.
#
# TARGET
# ------
# Amazon Linux 2023
# x86_64 and aarch64
#
# INSTALLS / CONFIGURES
# ---------------------
# 1. Linux utilities
# 2. Apache HTTP Server
# 3. PHP + PHP-FPM
# 4. PHP extensions
# 5. MariaDB/MySQL client
# 6. Docker
# 7. Docker Compose v2
# 8. AWS CLI v2
# 9. kubectl
# 10. eksctl
# 11. Helm
# 12. kind
# 13. Apache -> PHP-FPM integration
# 14. Test web pages
# 15. Verification
#
# IMPORTANT AMAZON LINUX 2023 NOTE
# --------------------------------
# AL2023 normally provides:
#
#     curl-minimal
#     libcurl-minimal
#
# The curl-minimal package provides the normal:
#
#     /usr/bin/curl
#
# Therefore THIS SCRIPT DOES NOT install "curl".
#
# Installing the full "curl" package blindly can create:
#
#     curl-minimal vs curl
#
# package conflicts.
#
# AWS documents curl-minimal as the default curl implementation in
# Amazon Linux 2023.
#
# SAFETY
# ------
# - Must run as root.
# - Uses retry logic for DNF/network operations.
# - Does not intentionally delete user data.
# - Does not modify AWS resources.
# - AWS STS verification is informational only.
#
# LOG FILE
# --------
# /var/log/charlie-cafe-bootstrap.log
#
# COMPLETION FILE
# ---------------
# /var/log/charlie-cafe-bootstrap-complete.txt
#
# =============================================================================


# =============================================================================
# 0. STRICT SHELL SETTINGS
# =============================================================================

set -Eeuo pipefail


# =============================================================================
# 1. GLOBAL VARIABLES
# =============================================================================

SCRIPT_NAME="charlie-cafe-bootstrap.sh"

WEB_ROOT="/var/www/html"

PHP_FPM_CONFIG="/etc/php-fpm.d/www.conf"

APACHE_PHP_CONFIG="/etc/httpd/conf.d/php-fpm.conf"

LOG_FILE="/var/log/charlie-cafe-bootstrap.log"

COMPLETION_FILE="/var/log/charlie-cafe-bootstrap-complete.txt"

DOCKER_COMPOSE_PLUGIN_DIR="/usr/local/lib/docker/cli-plugins"

ARCH="$(uname -m)"

START_TIME="$(date '+%Y-%m-%d %H:%M:%S %Z')"


# =============================================================================
# 2. ROOT CHECK
# =============================================================================

if [[ "${EUID}" -ne 0 ]]; then

    echo
    echo "ERROR: This script must be executed as root."
    echo
    echo "Example:"
    echo
    echo "sudo bash ${SCRIPT_NAME}"
    echo

    exit 1

fi


# =============================================================================
# 3. LOGGING
# =============================================================================
#
# Everything printed by this script is written to:
#
#     /var/log/charlie-cafe-bootstrap.log
#
# AND displayed on the terminal.
#
# =============================================================================

touch "${LOG_FILE}"

chmod 600 "${LOG_FILE}"

exec > >(tee -a "${LOG_FILE}") 2>&1


# =============================================================================
# 4. ERROR HANDLER
# =============================================================================

error_handler() {

    local exit_code="${1:-1}"
    local line_number="${2:-unknown}"
    local command="${3:-unknown}"

    echo
    echo "======================================================================"
    echo "❌ BOOTSTRAP FAILED"
    echo "======================================================================"
    echo
    echo "Exit code : ${exit_code}"
    echo "Line      : ${line_number}"
    echo "Command   : ${command}"
    echo
    echo "Log file:"
    echo "  ${LOG_FILE}"
    echo
    echo "Last 50 log lines:"
    echo "----------------------------------------------------------------------"

    tail -n 50 "${LOG_FILE}" || true

    echo "----------------------------------------------------------------------"
    echo

}

trap 'error_handler "$?" "$LINENO" "$BASH_COMMAND"' ERR


# =============================================================================
# 5. BASIC HELPER FUNCTIONS
# =============================================================================

section() {

    echo
    echo "======================================================================"
    echo "$1"
    echo "======================================================================"
    echo

}


info() {

    echo "[INFO] $1"

}


success() {

    echo "[PASS] $1"

}


warning() {

    echo "[WARN] $1"

}


failure() {

    echo "[FAIL] $1"

}


# =============================================================================
# 6. DNF RETRY FUNCTION
# =============================================================================
#
# DNF can occasionally fail because:
#
# - repository temporarily unavailable
# - network interruption
# - metadata lock
# - mirror problem
#
# Retry several times before giving up.
#
# =============================================================================

dnf_retry() {

    local description="$1"

    shift

    local attempt=1

    local max_attempts=5


    while [[ "${attempt}" -le "${max_attempts}" ]]; do

        info "${description} — attempt ${attempt}/${max_attempts}"

        if dnf "$@"; then

            success "${description}"

            return 0

        fi

        warning "${description} failed."

        if [[ "${attempt}" -lt "${max_attempts}" ]]; then

            info "Waiting 10 seconds before retry..."

            sleep 10

        fi

        attempt=$((attempt + 1))

    done


    failure "${description} failed after ${max_attempts} attempts."

    return 1

}


# =============================================================================
# 7. PACKAGE INSTALL FUNCTION
# =============================================================================

install_packages() {

    local description="$1"

    shift

    local packages=( "$@" )

    echo
    info "${description}"

    echo "Packages:"
    printf '  - %s\n' "${packages[@]}"

    echo


    dnf_retry \
        "Installing package group: ${description}" \
        install \
        -y \
        "${packages[@]}"

}


# =============================================================================
# 8. OPTIONAL PACKAGE INSTALLER
# =============================================================================
#
# Some AL2023 package names can change between repository revisions.
#
# Optional packages are therefore tested individually.
#
# This prevents one optional package from breaking the entire bootstrap.
#
# =============================================================================

install_optional_package() {

    local package="$1"


    if rpm -q "${package}" >/dev/null 2>&1; then

        success "Package already installed: ${package}"

        return 0

    fi


    if dnf list --available "${package}" >/dev/null 2>&1; then

        info "Installing optional package: ${package}"

        if dnf install -y "${package}"; then

            success "Installed optional package: ${package}"

        else

            warning "Could not install optional package: ${package}"

        fi

    else

        warning "Optional package not available: ${package}"

    fi

}


# =============================================================================
# 9. COMMAND VERIFICATION FUNCTION
# =============================================================================

require_command() {

    local command_name="$1"

    local display_name="${2:-${command_name}}"


    if command -v "${command_name}" >/dev/null 2>&1; then

        success "${display_name}: $(command -v "${command_name}")"

        return 0

    fi


    failure "${display_name}: command not found"

    return 1

}


# =============================================================================
# 10. START MESSAGE
# =============================================================================

section "☕ Charlie Cafe EC2 Bootstrap Started"

echo "Script:"
echo "  ${SCRIPT_NAME}"

echo

echo "Start time:"
echo "  ${START_TIME}"

echo

echo "Hostname:"
hostname

echo

echo "Current user:"
whoami

echo

echo "Architecture:"
uname -m

echo

echo "Kernel:"
uname -r

echo


# =============================================================================
# 11. VERIFY OPERATING SYSTEM
# =============================================================================

section "1. Verify Operating System"


if [[ ! -f /etc/os-release ]]; then

    failure "/etc/os-release does not exist."

    exit 1

fi


# shellcheck disable=SC1091
source /etc/os-release


echo "OS:"
echo "  ${PRETTY_NAME:-unknown}"

echo

echo "ID:"
echo "  ${ID:-unknown}"

echo

echo "VERSION_ID:"
echo "  ${VERSION_ID:-unknown}"

echo


if [[ "${ID}" != "amzn" ]]; then

    failure "This script requires Amazon Linux."

    exit 1

fi


if [[ "${VERSION_ID}" != "2023" ]]; then

    failure "This script requires Amazon Linux 2023."

    exit 1

fi


success "Amazon Linux 2023 detected."


# =============================================================================
# 12. VERIFY DNF
# =============================================================================

section "2. Verify DNF Package Manager"


require_command dnf "DNF"

echo

dnf --version | head -n 1


# =============================================================================
# 13. REFRESH DNF METADATA
# =============================================================================
#
# We intentionally do NOT run:
#
#     dnf update -y
#
# during this bootstrap.
#
# A full system update can introduce unnecessary package changes and can
# increase the chance of unrelated package transactions interfering with
# bootstrap installation.
#
# We only refresh repository metadata here.
#
# =============================================================================

section "3. Refresh DNF Repository Metadata"


dnf_retry \
    "Refreshing DNF metadata" \
    makecache \
    --refresh


# =============================================================================
# 14. VERIFY CURL
# =============================================================================
#
# DO NOT install "curl".
#
# Amazon Linux 2023 commonly provides:
#
#     curl-minimal
#     libcurl-minimal
#
# and the executable is still:
#
#     /usr/bin/curl
#
# =============================================================================

section "4. Verify curl-minimal"


if command -v curl >/dev/null 2>&1; then

    CURL_PATH="$(command -v curl)"

    success "curl command exists: ${CURL_PATH}"

else

    failure "curl command is missing."

    exit 1

fi


echo

curl --version | head -n 1


echo

if rpm -q curl-minimal >/dev/null 2>&1; then

    success "curl-minimal RPM is installed."

elif rpm -q curl >/dev/null 2>&1; then

    success "Full curl RPM is installed."

else

    warning "curl command exists but RPM ownership could not be detected."

fi


# =============================================================================
# 15. TEST INTERNET ACCESS
# =============================================================================

section "5. Test HTTPS Connectivity"


if curl \
    --fail \
    --silent \
    --show-error \
    --location \
    --connect-timeout 15 \
    --max-time 30 \
    https://aws.amazon.com/ \
    >/dev/null; then

    success "HTTPS connectivity test passed."

else

    failure "HTTPS connectivity test failed."

    exit 1

fi


# =============================================================================
# 16. INSTALL BASIC LINUX UTILITIES
# =============================================================================

section "6. Install Linux Utilities"


install_packages \
    "Linux utilities" \
    git \
    htop \
    wget \
    unzip \
    tar \
    gzip \
    bzip2 \
    xz \
    jq \
    vim \
    nano \
    bind-utils \
    iproute \
    iputils \
    which


# =============================================================================
# 17. INSTALL APACHE
# =============================================================================

section "7. Install Apache HTTP Server"


install_packages \
    "Apache HTTP Server" \
    httpd


success "Apache package installed."


# =============================================================================
# 18. INSTALL PHP
# =============================================================================
#
# We install the normal AL2023 PHP package names.
#
# php-json is intentionally NOT required as a separate hard dependency.
#
# Modern PHP builds commonly provide JSON through the core/common PHP
# installation.
#
# =============================================================================

section "8. Install PHP and PHP-FPM"


install_packages \
    "PHP base packages" \
    php \
    php-cli \
    php-common \
    php-fpm \
    php-mysqlnd \
    php-mbstring \
    php-xml \
    php-opcache


# =============================================================================
# 19. VERIFY PHP
# =============================================================================

section "9. Verify PHP Installation"


require_command php "PHP CLI"

echo

php -v | head -n 2


# =============================================================================
# 20. IDENTIFY PHP-FPM PACKAGE
# =============================================================================
#
# IMPORTANT:
#
# Do NOT assume:
#
#     rpm -q php-fpm
#
# is always the correct test.
#
# Instead identify the RPM that owns the php-fpm executable.
#
# =============================================================================

section "10. Verify PHP-FPM"


if command -v php-fpm >/dev/null 2>&1; then

    PHP_FPM_BINARY="$(command -v php-fpm)"

    success "php-fpm command exists: ${PHP_FPM_BINARY}"

else

    failure "php-fpm command is missing."

    exit 1

fi


echo

php-fpm -v | head -n 2


echo

PHP_FPM_OWNER="$(rpm -qf "${PHP_FPM_BINARY}" 2>/dev/null || true)"


if [[ -n "${PHP_FPM_OWNER}" ]]; then

    success "PHP-FPM RPM owner: ${PHP_FPM_OWNER}"

else

    warning "Could not determine PHP-FPM RPM owner."

fi


# =============================================================================
# 21. VERIFY PHP EXTENSIONS
# =============================================================================

section "11. Verify Required PHP Extensions"


PHP_MODULES=(
    "mysqli"
    "mysqlnd"
    "mbstring"
    "xml"
    "json"
    "pdo_mysql"
    "Zend OPcache"
)


for module in "${PHP_MODULES[@]}"; do

    if php -m 2>/dev/null | grep -Fqi "${module}"; then

        success "PHP extension/module: ${module}"

    else

        failure "PHP extension/module missing: ${module}"

        exit 1

    fi

done


# =============================================================================
# 22. CONFIGURE PHP-FPM
# =============================================================================

section "12. Configure PHP-FPM"


if [[ ! -f "${PHP_FPM_CONFIG}" ]]; then

    failure "PHP-FPM configuration file not found:"
    echo "  ${PHP_FPM_CONFIG}"

    exit 1

fi


# -----------------------------------------------------------------------------
# Configure PHP-FPM user/group
# -----------------------------------------------------------------------------

sed -i \
    -E 's/^[;[:space:]]*user[[:space:]]*=.*/user = apache/' \
    "${PHP_FPM_CONFIG}"


sed -i \
    -E 's/^[;[:space:]]*group[[:space:]]*=.*/group = apache/' \
    "${PHP_FPM_CONFIG}"


# -----------------------------------------------------------------------------
# Configure Unix socket
# -----------------------------------------------------------------------------

sed -i \
    -E 's#^[;[:space:]]*listen[[:space:]]*=.*#listen = /run/php-fpm/www.sock#' \
    "${PHP_FPM_CONFIG}"


sed -i \
    -E 's/^[;[:space:]]*listen.owner[[:space:]]*=.*/listen.owner = apache/' \
    "${PHP_FPM_CONFIG}"


sed -i \
    -E 's/^[;[:space:]]*listen.group[[:space:]]*=.*/listen.group = apache/' \
    "${PHP_FPM_CONFIG}"


sed -i \
    -E 's/^[;[:space:]]*listen.mode[[:space:]]*=.*/listen.mode = 0660/' \
    "${PHP_FPM_CONFIG}"


# -----------------------------------------------------------------------------
# Ensure required directives exist.
# -----------------------------------------------------------------------------

grep -qE '^[[:space:]]*user[[:space:]]*=' "${PHP_FPM_CONFIG}" || \
    echo "user = apache" >> "${PHP_FPM_CONFIG}"


grep -qE '^[[:space:]]*group[[:space:]]*=' "${PHP_FPM_CONFIG}" || \
    echo "group = apache" >> "${PHP_FPM_CONFIG}"


grep -qE '^[[:space:]]*listen[[:space:]]*=' "${PHP_FPM_CONFIG}" || \
    echo "listen = /run/php-fpm/www.sock" >> "${PHP_FPM_CONFIG}"


grep -qE '^[[:space:]]*listen.owner[[:space:]]*=' "${PHP_FPM_CONFIG}" || \
    echo "listen.owner = apache" >> "${PHP_FPM_CONFIG}"


grep -qE '^[[:space:]]*listen.group[[:space:]]*=' "${PHP_FPM_CONFIG}" || \
    echo "listen.group = apache" >> "${PHP_FPM_CONFIG}"


grep -qE '^[[:space:]]*listen.mode[[:space:]]*=' "${PHP_FPM_CONFIG}" || \
    echo "listen.mode = 0660" >> "${PHP_FPM_CONFIG}"


# =============================================================================
# 23. TEST PHP-FPM CONFIGURATION
# =============================================================================

section "13. Test PHP-FPM Configuration"


if php-fpm -t; then

    success "PHP-FPM configuration syntax is valid."

else

    failure "PHP-FPM configuration test failed."

    exit 1

fi


# =============================================================================
# 24. ENABLE AND START PHP-FPM
# =============================================================================

section "14. Start PHP-FPM"


systemctl enable php-fpm

systemctl restart php-fpm


sleep 2


if systemctl is-active --quiet php-fpm; then

    success "PHP-FPM service is running."

else

    failure "PHP-FPM service is not running."

    systemctl status php-fpm --no-pager || true

    exit 1

fi


# =============================================================================
# 25. VERIFY PHP-FPM SOCKET
# =============================================================================

section "15. Verify PHP-FPM Socket"


PHP_SOCKET="/run/php-fpm/www.sock"


if [[ -S "${PHP_SOCKET}" ]]; then

    success "PHP-FPM Unix socket exists:"
    echo "  ${PHP_SOCKET}"

else

    failure "PHP-FPM Unix socket does not exist:"
    echo "  ${PHP_SOCKET}"

    exit 1

fi


# =============================================================================
# 26. CONFIGURE APACHE -> PHP-FPM
# =============================================================================

section "16. Configure Apache -> PHP-FPM"


cat > "${APACHE_PHP_CONFIG}" <<'EOF'
# =============================================================================
# Charlie Cafe
# Apache -> PHP-FPM configuration
# =============================================================================

# Send PHP requests to the PHP-FPM Unix socket.
<FilesMatch "\.php$">
    SetHandler "proxy:unix:/run/php-fpm/www.sock|fcgi://localhost/"
</FilesMatch>

# Prefer index.html and then index.php.
DirectoryIndex index.html index.php
EOF


success "Apache PHP-FPM configuration created:"
echo "  ${APACHE_PHP_CONFIG}"


# =============================================================================
# 27. VERIFY APACHE MODULES
# =============================================================================

section "17. Verify Apache Required Modules"


if httpd -M 2>/dev/null | grep -q "proxy_module"; then

    success "Apache mod_proxy is loaded."

else

    failure "Apache mod_proxy is not loaded."

    exit 1

fi


if httpd -M 2>/dev/null | grep -q "proxy_fcgi_module"; then

    success "Apache mod_proxy_fcgi is loaded."

else

    failure "Apache mod_proxy_fcgi is not loaded."

    exit 1

fi


# =============================================================================
# 28. CREATE WEB ROOT
# =============================================================================

section "18. Prepare Apache Web Root"


mkdir -p "${WEB_ROOT}"


# =============================================================================
# 29. CREATE INDEX.HTML
# =============================================================================

cat > "${WEB_ROOT}/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Charlie Cafe</title>
</head>

<body>

    <h1>☕ Charlie Cafe</h1>

    <p>Amazon Linux 2023 EC2 Web Server</p>

    <hr>

    <h2>DevOps Lab Status</h2>

    <ul>
        <li>Apache HTTP Server: Installed</li>
        <li>PHP: Installed</li>
        <li>PHP-FPM: Installed</li>
        <li>Docker: Installed</li>
        <li>AWS CLI: Installed</li>
        <li>Kubernetes Tools: Installed</li>
    </ul>

    <p>
        Charlie Cafe EC2 bootstrap completed successfully.
    </p>

</body>
</html>
EOF


success "Created ${WEB_ROOT}/index.html"


# =============================================================================
# 30. CREATE PHP TEST PAGE
# =============================================================================

cat > "${WEB_ROOT}/info.php" <<'EOF'
<?php

echo "<!DOCTYPE html>";
echo "<html lang='en'>";
echo "<head>";
echo "<meta charset='UTF-8'>";
echo "<meta name='viewport' content='width=device-width, initial-scale=1.0'>";
echo "<title>Charlie Cafe PHP Test</title>";
echo "</head>";

echo "<body>";

echo "<h1>☕ Charlie Cafe PHP Test</h1>";

echo "<p><strong>PHP is working through Apache + PHP-FPM.</strong></p>";

echo "<hr>";

echo "<h2>PHP Version</h2>";

echo "<p>" . htmlspecialchars(PHP_VERSION) . "</p>";

echo "<h2>Server Software</h2>";

echo "<p>" . htmlspecialchars($_SERVER['SERVER_SOFTWARE'] ?? 'unknown') . "</p>";

echo "<h2>PHP SAPI</h2>";

echo "<p>" . htmlspecialchars(PHP_SAPI) . "</p>";

echo "</body>";
echo "</html>";

?>
EOF


success "Created ${WEB_ROOT}/info.php"


# =============================================================================
# 31. SET WEB PERMISSIONS
# =============================================================================

section "19. Set Web File Permissions"


chown -R apache:apache "${WEB_ROOT}"


find "${WEB_ROOT}" -type d -exec chmod 755 {} \;


find "${WEB_ROOT}" -type f -exec chmod 644 {} \;


success "Apache web-root permissions configured."


# =============================================================================
# 32. TEST APACHE CONFIGURATION
# =============================================================================

section "20. Test Apache Configuration"


if httpd -t; then

    success "Apache configuration syntax is valid."

else

    failure "Apache configuration test failed."

    exit 1

fi


# =============================================================================
# 33. ENABLE AND START APACHE
# =============================================================================

section "21. Start Apache"


systemctl enable httpd

systemctl restart httpd


sleep 2


if systemctl is-active --quiet httpd; then

    success "Apache service is running."

else

    failure "Apache service is not running."

    systemctl status httpd --no-pager || true

    exit 1

fi


# =============================================================================
# 34. VERIFY MARIADB / MYSQL CLIENT
# =============================================================================

section "22. Install MariaDB / MySQL Client"


#
# First check whether a compatible client already exists.
#

if command -v mariadb >/dev/null 2>&1; then

    success "MariaDB client already installed."

elif command -v mysql >/dev/null 2>&1; then

    success "MySQL-compatible client already installed."

else

    info "MariaDB/MySQL client not found."

    #
    # AL2023 repository package naming can vary.
    #
    # Try common package names.
    #

    MARIADB_INSTALLED="false"


    MARIADB_PACKAGES=(
        "mariadb"
        "mariadb105"
        "mariadb1011"
        "mariadb114"
        "mariadb118"
        "mariadb123"
    )


    for package in "${MARIADB_PACKAGES[@]}"; do

        if rpm -q "${package}" >/dev/null 2>&1; then

            info "Found installed MariaDB package: ${package}"

            MARIADB_INSTALLED="true"

            break

        fi


        if dnf list --available "${package}" >/dev/null 2>&1; then

            info "Installing MariaDB client package: ${package}"

            if dnf install -y "${package}"; then

                success "Installed MariaDB package: ${package}"

                MARIADB_INSTALLED="true"

                break

            else

                warning "Package installation failed: ${package}"

            fi

        fi

    done


    if [[ "${MARIADB_INSTALLED}" != "true" ]]; then

        #
        # Last-resort repository lookup.
        #
        # Search for a package that provides the mariadb executable.
        #

        info "Searching DNF repository for package providing mariadb command..."

        PROVIDER_PACKAGE="$(
            dnf provides '*/mariadb' 2>/dev/null \
            | awk '/^[A-Za-z0-9_.+-]+(\.x86_64|\.aarch64|\.noarch)?[[:space:]]/ {
                    print $1;
                    exit
                }' \
            || true
        )"


        if [[ -n "${PROVIDER_PACKAGE}" ]]; then

            info "Repository provider found: ${PROVIDER_PACKAGE}"

            dnf install -y "${PROVIDER_PACKAGE}" || true

        fi

    fi

fi


# =============================================================================
# 35. VERIFY DATABASE CLIENT
# =============================================================================

section "23. Verify Database Client"


if command -v mariadb >/dev/null 2>&1; then

    success "MariaDB client available."

    mariadb --version || true

elif command -v mysql >/dev/null 2>&1; then

    success "MySQL-compatible client available."

    mysql --version || true

else

    warning "MariaDB/MySQL client was not installed."

    warning "This does not affect Apache/PHP/Docker installation."

fi


# =============================================================================
# 36. INSTALL DOCKER
# =============================================================================

section "24. Install Docker"


if command -v docker >/dev/null 2>&1; then

    success "Docker command already exists."

else

    install_packages \
        "Docker" \
        docker

fi


# =============================================================================
# 37. CREATE DOCKER GROUP
# =============================================================================

section "25. Configure Docker Group"


if getent group docker >/dev/null 2>&1; then

    success "Docker group exists."

else

    groupadd docker

    success "Docker group created."

fi


# =============================================================================
# 38. ADD EC2 USER TO DOCKER GROUP
# =============================================================================

if id ec2-user >/dev/null 2>&1; then

    usermod -aG docker ec2-user

    success "ec2-user added to docker group."

else

    warning "ec2-user does not exist."

fi


# =============================================================================
# 39. ENABLE AND START DOCKER
# =============================================================================

section "26. Start Docker"


systemctl enable docker

systemctl restart docker


sleep 3


if systemctl is-active --quiet docker; then

    success "Docker service is running."

else

    failure "Docker service is not running."

    systemctl status docker --no-pager || true

    exit 1

fi


# =============================================================================
# 40. VERIFY DOCKER
# =============================================================================

if docker info >/dev/null 2>&1; then

    success "Docker daemon is responding."

else

    warning "Docker daemon could not be queried as root."

fi


echo

docker --version || true


# =============================================================================
# 41. INSTALL DOCKER COMPOSE V2
# =============================================================================

section "27. Install Docker Compose v2"


mkdir -p "${DOCKER_COMPOSE_PLUGIN_DIR}"


DOCKER_COMPOSE_ARCH=""


case "${ARCH}" in

    x86_64)
        DOCKER_COMPOSE_ARCH="x86_64"
        ;;

    aarch64)
        DOCKER_COMPOSE_ARCH="aarch64"
        ;;

    *)
        failure "Unsupported CPU architecture for Docker Compose: ${ARCH}"
        exit 1
        ;;

esac


DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/latest/download/docker-compose-linux-${DOCKER_COMPOSE_ARCH}"

DOCKER_COMPOSE_PATH="${DOCKER_COMPOSE_PLUGIN_DIR}/docker-compose"


info "Docker Compose URL:"
echo "  ${DOCKER_COMPOSE_URL}"


curl \
    --fail \
    --silent \
    --show-error \
    --location \
    --retry 5 \
    --retry-delay 3 \
    --connect-timeout 30 \
    --max-time 600 \
    -o "${DOCKER_COMPOSE_PATH}" \
    "${DOCKER_COMPOSE_URL}"


chmod 755 "${DOCKER_COMPOSE_PATH}"


if "${DOCKER_COMPOSE_PATH}" version >/dev/null 2>&1; then

    success "Docker Compose v2 installed."

    "${DOCKER_COMPOSE_PATH}" version

else

    failure "Docker Compose verification failed."

    exit 1

fi


# =============================================================================
# 42. VERIFY AWS CLI
# =============================================================================
#
# Amazon Linux 2023 already includes AWS CLI v2 on standard AMIs.
#
# We preserve an existing v2 installation.
#
# If missing, install the official AWS CLI v2 bundle.
#
# =============================================================================

section "28. Install / Verify AWS CLI v2"


AWS_CLI_NEEDS_INSTALL="true"


if command -v aws >/dev/null 2>&1; then

    if aws --version 2>&1 | grep -q 'aws-cli/2'; then

        success "AWS CLI v2 is already installed."

        aws --version

        AWS_CLI_NEEDS_INSTALL="false"

    else

        warning "AWS CLI exists but is not version 2."

    fi

fi


if [[ "${AWS_CLI_NEEDS_INSTALL}" == "true" ]]; then

    info "Installing official AWS CLI v2."


    AWS_CLI_ARCH=""


    case "${ARCH}" in

        x86_64)
            AWS_CLI_ARCH="x86_64"
            ;;

        aarch64)
            AWS_CLI_ARCH="aarch64"
            ;;

        *)
            failure "Unsupported architecture for AWS CLI: ${ARCH}"
            exit 1
            ;;

    esac


    AWS_CLI_ZIP="/tmp/awscliv2.zip"

    AWS_CLI_DIR="/tmp/aws"


    rm -rf "${AWS_CLI_DIR}"

    rm -f "${AWS_CLI_ZIP}"


    curl \
        --fail \
        --silent \
        --show-error \
        --location \
        --retry 5 \
        --retry-delay 3 \
        --connect-timeout 30 \
        --max-time 600 \
        -o "${AWS_CLI_ZIP}" \
        "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_CLI_ARCH}.zip"


    unzip -q "${AWS_CLI_ZIP}" -d /tmp


    if [[ -x /tmp/aws/install ]]; then

        /tmp/aws/install \
            --update \
            --install-dir /usr/local/aws-cli \
            --bin-dir /usr/local/bin

    else

        failure "AWS CLI installer was not extracted correctly."

        exit 1

    fi


    rm -rf "${AWS_CLI_DIR}"

    rm -f "${AWS_CLI_ZIP}"


    success "AWS CLI v2 installed."

fi


require_command aws "AWS CLI"


echo

aws --version


# =============================================================================
# 43. AWS STS TEST
# =============================================================================
#
# IMPORTANT:
#
# Failure here does NOT mean AWS CLI is broken.
#
# It normally means:
#
# - EC2 has no IAM role
# - IAM role lacks sts:GetCallerIdentity
# - credentials are unavailable
# - metadata access is restricted
#
# Therefore this is a WARNING only.
#
# =============================================================================

section "29. Test AWS Identity"


if aws sts get-caller-identity >/tmp/charlie-cafe-sts.txt 2>/tmp/charlie-cafe-sts-error.txt; then

    success "AWS STS identity test passed."

    cat /tmp/charlie-cafe-sts.txt

else

    warning "AWS STS identity test failed."

    warning "AWS CLI itself is installed correctly."

    echo

    echo "STS error:"
    cat /tmp/charlie-cafe-sts-error.txt || true

    echo

    echo "If this EC2 instance should access AWS APIs, attach an appropriate"
    echo "IAM instance profile / role."

fi


# =============================================================================
# 44. INSTALL KUBECTL
# =============================================================================

section "30. Install kubectl"


KUBECTL_ARCH=""


case "${ARCH}" in

    x86_64)
        KUBECTL_ARCH="amd64"
        ;;

    aarch64)
        KUBECTL_ARCH="arm64"
        ;;

    *)
        failure "Unsupported architecture for kubectl: ${ARCH}"
        exit 1
        ;;

esac


#
# Get the current stable Kubernetes release.
#
# Example:
#
#     v1.xx.x
#
# =============================================================================

KUBECTL_VERSION="$(
    curl \
        --fail \
        --silent \
        --show-error \
        --location \
        --retry 5 \
        --connect-timeout 30 \
        --max-time 60 \
        https://dl.k8s.io/release/stable.txt
)"


if [[ ! "${KUBECTL_VERSION}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then

    failure "Could not determine valid kubectl stable version."

    echo "Returned value:"
    echo "${KUBECTL_VERSION}"

    exit 1

fi


KUBECTL_URL="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl"


info "Installing kubectl:"
echo "  Version: ${KUBECTL_VERSION}"
echo "  URL: ${KUBECTL_URL}"


curl \
    --fail \
    --silent \
    --show-error \
    --location \
    --retry 5 \
    --retry-delay 3 \
    --connect-timeout 30 \
    --max-time 600 \
    -o /usr/local/bin/kubectl \
    "${KUBECTL_URL}"


chmod 755 /usr/local/bin/kubectl


require_command kubectl "kubectl"


kubectl version --client=true --output=yaml 2>/dev/null | head -n 15 || \
    kubectl version --client=true || true


# =============================================================================
# 45. INSTALL eksctl
# =============================================================================

section "31. Install eksctl"


EKSCTL_ARCH=""


case "${ARCH}" in

    x86_64)
        EKSCTL_ARCH="amd64"
        ;;

    aarch64)
        EKSCTL_ARCH="arm64"
        ;;

    *)
        failure "Unsupported architecture for eksctl: ${ARCH}"
        exit 1
        ;;

esac


EKSCTL_URL="https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_${EKSCTL_ARCH}.tar.gz"


info "eksctl download URL:"
echo "  ${EKSCTL_URL}"


EKSCTL_TMP="/tmp/eksctl.tar.gz"


rm -f "${EKSCTL_TMP}"


curl \
    --fail \
    --silent \
    --show-error \
    --location \
    --retry 5 \
    --retry-delay 3 \
    --connect-timeout 30 \
    --max-time 600 \
    -o "${EKSCTL_TMP}" \
    "${EKSCTL_URL}"


tar \
    -xzf "${EKSCTL_TMP}" \
    -C /usr/local/bin \
    eksctl


chmod 755 /usr/local/bin/eksctl


rm -f "${EKSCTL_TMP}"


require_command eksctl "eksctl"


eksctl version


# =============================================================================
# 46. INSTALL HELM
# =============================================================================

section "32. Install Helm"


HELM_ARCH=""


case "${ARCH}" in

    x86_64)
        HELM_ARCH="amd64"
        ;;

    aarch64)
        HELM_ARCH="arm64"
        ;;

    *)
        failure "Unsupported architecture for Helm: ${ARCH}"
        exit 1
        ;;

esac


#
# Resolve the latest Helm release tag through GitHub's release redirect.
#
# This avoids hard-coding an old Helm version.
#
# =============================================================================

HELM_RELEASE_URL="https://github.com/helm/helm/releases/latest"


HELM_LOCATION="$(
    curl \
        --silent \
        --show-error \
        --location \
        --write-out '%{url_effective}' \
        --output /dev/null \
        "${HELM_RELEASE_URL}" \
        || true
)"


HELM_VERSION="$(
    echo "${HELM_LOCATION}" \
    | sed -n 's#.*/tag/\(v[0-9][^/]*\).*#\1#p'
)"


if [[ ! "${HELM_VERSION}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then

    warning "Could not resolve Helm release automatically."

    warning "Trying official Helm installer."

    curl \
        --fail \
        --silent \
        --show-error \
        --location \
        --retry 5 \
        --connect-timeout 30 \
        --max-time 600 \
        https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 \
        -o /tmp/get-helm.sh


    chmod 700 /tmp/get-helm.sh


    /tmp/get-helm.sh


    rm -f /tmp/get-helm.sh

else

    HELM_TARBALL="helm-${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz"

    HELM_URL="https://get.helm.sh/${HELM_TARBALL}"

    info "Helm version:"
    echo "  ${HELM_VERSION}"

    info "Helm URL:"
    echo "  ${HELM_URL}"


    HELM_TMP="/tmp/${HELM_TARBALL}"


    rm -f "${HELM_TMP}"


    curl \
        --fail \
        --silent \
        --show-error \
        --location \
        --retry 5 \
        --retry-delay 3 \
        --connect-timeout 30 \
        --max-time 600 \
        -o "${HELM_TMP}" \
        "${HELM_URL}"


    rm -rf /tmp/helm-extract

    mkdir -p /tmp/helm-extract


    tar \
        -xzf "${HELM_TMP}" \
        -C /tmp/helm-extract


    install \
        -m 0755 \
        "/tmp/helm-extract/linux-${HELM_ARCH}/helm" \
        /usr/local/bin/helm


    rm -rf /tmp/helm-extract

    rm -f "${HELM_TMP}"

fi


require_command helm "Helm"


helm version


# =============================================================================
# 47. INSTALL KIND
# =============================================================================

section "33. Install kind"


KIND_ARCH=""


case "${ARCH}" in

    x86_64)
        KIND_ARCH="amd64"
        ;;

    aarch64)
        KIND_ARCH="arm64"
        ;;

    *)
        failure "Unsupported architecture for kind: ${ARCH}"
        exit 1
        ;;

esac


KIND_URL="https://kind.sigs.k8s.io/dl/latest/kind-linux-${KIND_ARCH}"


info "kind URL:"
echo "  ${KIND_URL}"


curl \
    --fail \
    --silent \
    --show-error \
    --location \
    --retry 5 \
    --retry-delay 3 \
    --connect-timeout 30 \
    --max-time 600 \
    -o /usr/local/bin/kind \
    "${KIND_URL}"


chmod 755 /usr/local/bin/kind


require_command kind "kind"


kind version


# =============================================================================
# 48. CONFIGURE EC2 USER PATH
# =============================================================================

section "34. Configure ec2-user Environment"


if id ec2-user >/dev/null 2>&1; then

    EC2_HOME="$(getent passwd ec2-user | cut -d: -f6)"


    if [[ -n "${EC2_HOME}" && -d "${EC2_HOME}" ]]; then

        touch "${EC2_HOME}/.bashrc"


        if ! grep -qF '/usr/local/bin' "${EC2_HOME}/.bashrc"; then

            cat >> "${EC2_HOME}/.bashrc" <<'EOF'

# Charlie Cafe DevOps Lab
export PATH="/usr/local/bin:${PATH}"
EOF

        fi


        chown ec2-user:ec2-user "${EC2_HOME}/.bashrc"


        success "ec2-user PATH configured."

    else

        warning "Could not determine ec2-user home directory."

    fi

else

    warning "ec2-user does not exist."

fi


# =============================================================================
# 49. FINAL SERVICE RESTART
# =============================================================================

section "35. Final Service Restart"


systemctl restart php-fpm

systemctl restart httpd

systemctl restart docker


sleep 3


success "PHP-FPM restarted."

success "Apache restarted."

success "Docker restarted."


# =============================================================================
# 50. HTTP TEST — HTML
# =============================================================================

section "36. Test Apache HTML"


HTML_RESPONSE="$(
    curl \
        --fail \
        --silent \
        --show-error \
        --location \
        --connect-timeout 10 \
        --max-time 30 \
        http://127.0.0.1/
)"


if echo "${HTML_RESPONSE}" | grep -q "Charlie Cafe"; then

    success "Apache HTML test passed."

else

    failure "Apache HTML test failed."

    echo "Response:"
    echo "${HTML_RESPONSE}"

    exit 1

fi


# =============================================================================
# 51. HTTP TEST — PHP
# =============================================================================

section "37. Test Apache + PHP-FPM"


PHP_RESPONSE="$(
    curl \
        --fail \
        --silent \
        --show-error \
        --location \
        --connect-timeout 10 \
        --max-time 30 \
        http://127.0.0.1/info.php
)"


if echo "${PHP_RESPONSE}" | grep -q "PHP is working through Apache"; then

    success "Apache + PHP-FPM test passed."

else

    failure "Apache + PHP-FPM test failed."

    echo "Response:"
    echo "${PHP_RESPONSE}"

    exit 1

fi


# =============================================================================
# 52. VERIFY INSTALLED COMMANDS
# =============================================================================

section "38. Verify Required Commands"


REQUIRED_COMMANDS=(
    "git"
    "htop"
    "curl"
    "wget"
    "unzip"
    "tar"
    "gzip"
    "bzip2"
    "xz"
    "jq"
    "vim"
    "nano"
    "dig"
    "ip"
    "ping"
    "php"
    "php-fpm"
    "httpd"
    "docker"
    "aws"
    "kubectl"
    "eksctl"
    "helm"
    "kind"
)


COMMAND_FAILURES=0


for command_name in "${REQUIRED_COMMANDS[@]}"; do

    if command -v "${command_name}" >/dev/null 2>&1; then

        success "${command_name}"

    else

        failure "${command_name}"

        COMMAND_FAILURES=$((COMMAND_FAILURES + 1))

    fi

done


if [[ "${COMMAND_FAILURES}" -gt 0 ]]; then

    failure "${COMMAND_FAILURES} required command(s) are missing."

    exit 1

fi


# =============================================================================
# 53. VERIFY DOCKER COMPOSE
# =============================================================================

section "39. Verify Docker Compose"


if docker compose version >/dev/null 2>&1; then

    success "Docker Compose v2 is working."

    docker compose version

else

    failure "Docker Compose v2 is not working."

    exit 1

fi


# =============================================================================
# 54. VERIFY SERVICES
# =============================================================================

section "40. Verify Services"


SERVICES=(
    "php-fpm"
    "httpd"
    "docker"
)


SERVICE_FAILURES=0


for service in "${SERVICES[@]}"; do

    if systemctl is-active --quiet "${service}"; then

        success "${service}: active"

    else

        failure "${service}: inactive"

        SERVICE_FAILURES=$((SERVICE_FAILURES + 1))

    fi

done


if [[ "${SERVICE_FAILURES}" -gt 0 ]]; then

    failure "One or more required services are inactive."

    exit 1

fi


# =============================================================================
# 55. VERIFY LISTENING PORTS
# =============================================================================

section "41. Verify Listening Ports"


if command -v ss >/dev/null 2>&1; then

    echo "Listening sockets:"
    echo

    ss -lntp || true

fi


# =============================================================================
# 56. DISPLAY IMPORTANT VERSIONS
# =============================================================================

section "42. Installed Software Versions"


echo "------------------------------------------------------------"
echo "Git"
echo "------------------------------------------------------------"
git --version || true


echo
echo "------------------------------------------------------------"
echo "PHP"
echo "------------------------------------------------------------"
php -v | head -n 2 || true


echo
echo "------------------------------------------------------------"
echo "Apache"
echo "------------------------------------------------------------"
httpd -v || true


echo
echo "------------------------------------------------------------"
echo "Docker"
echo "------------------------------------------------------------"
docker --version || true


echo
echo "------------------------------------------------------------"
echo "Docker Compose"
echo "------------------------------------------------------------"
docker compose version || true


echo
echo "------------------------------------------------------------"
echo "AWS CLI"
echo "------------------------------------------------------------"
aws --version || true


echo
echo "------------------------------------------------------------"
echo "kubectl"
echo "------------------------------------------------------------"
kubectl version --client=true 2>/dev/null || true


echo
echo "------------------------------------------------------------"
echo "eksctl"
echo "------------------------------------------------------------"
eksctl version || true


echo
echo "------------------------------------------------------------"
echo "Helm"
echo "------------------------------------------------------------"
helm version || true


echo
echo "------------------------------------------------------------"
echo "kind"
echo "------------------------------------------------------------"
kind version || true


# =============================================================================
# 57. WRITE COMPLETION FILE
# =============================================================================

section "43. Write Bootstrap Completion Marker"


cat > "${COMPLETION_FILE}" <<EOF
======================================================================
Charlie Cafe EC2 Bootstrap Completed Successfully
======================================================================

Script:
${SCRIPT_NAME}

Start Time:
${START_TIME}

Completion Time:
$(date '+%Y-%m-%d %H:%M:%S %Z')

Hostname:
$(hostname)

Architecture:
$(uname -m)

Kernel:
$(uname -r)

Operating System:
${PRETTY_NAME}

----------------------------------------------------------------------
Core Software
----------------------------------------------------------------------

Git:
$(git --version 2>/dev/null || echo "NOT AVAILABLE")

PHP:
$(php -v 2>/dev/null | head -n 1 || echo "NOT AVAILABLE")

Apache:
$(httpd -v 2>/dev/null | head -n 1 || echo "NOT AVAILABLE")

Docker:
$(docker --version 2>/dev/null || echo "NOT AVAILABLE")

Docker Compose:
$(docker compose version 2>/dev/null || echo "NOT AVAILABLE")

AWS CLI:
$(aws --version 2>/dev/null || echo "NOT AVAILABLE")

kubectl:
$(kubectl version --client=true 2>/dev/null | head -n 1 || echo "NOT AVAILABLE")

eksctl:
$(eksctl version 2>/dev/null || echo "NOT AVAILABLE")

Helm:
$(helm version 2>/dev/null | head -n 1 || echo "NOT AVAILABLE")

kind:
$(kind version 2>/dev/null || echo "NOT AVAILABLE")

----------------------------------------------------------------------
Services
----------------------------------------------------------------------

PHP-FPM:
$(systemctl is-active php-fpm 2>/dev/null || echo "UNKNOWN")

Apache:
$(systemctl is-active httpd 2>/dev/null || echo "UNKNOWN")

Docker:
$(systemctl is-active docker 2>/dev/null || echo "UNKNOWN")

----------------------------------------------------------------------
Web Tests
----------------------------------------------------------------------

Apache HTML:
http://127.0.0.1/

PHP Test:
http://127.0.0.1/info.php

----------------------------------------------------------------------
Important Files
----------------------------------------------------------------------

Bootstrap Log:
${LOG_FILE}

Bootstrap Completion:
${COMPLETION_FILE}

Apache Web Root:
${WEB_ROOT}

PHP-FPM Config:
${PHP_FPM_CONFIG}

Apache PHP-FPM Config:
${APACHE_PHP_CONFIG}

PHP-FPM Socket:
${PHP_SOCKET}

======================================================================
EOF


chmod 600 "${COMPLETION_FILE}"


success "Bootstrap completion marker created:"
echo "  ${COMPLETION_FILE}"


# =============================================================================
# 58. FINAL SUCCESS SUMMARY
# =============================================================================

section "☕ CHARLIE CAFE BOOTSTRAP COMPLETED SUCCESSFULLY"


echo
echo "                    🎉 SUCCESS"
echo
echo "======================================================================"
echo
echo "Amazon Linux 2023 EC2 instance is ready for the Charlie Cafe"
echo "DevOps / Cloud Engineering lab."
echo
echo "======================================================================"
echo
echo "INSTALLED / CONFIGURED"
echo "---------------------------------------------------------------------"
echo
echo "[PASS] Linux utilities"
echo "[PASS] Git"
echo "[PASS] htop"
echo "[PASS] curl command"
echo "[PASS] Apache HTTP Server"
echo "[PASS] PHP"
echo "[PASS] PHP-FPM"
echo "[PASS] PHP MySQL support"
echo "[PASS] PHP mbstring"
echo "[PASS] PHP XML"
echo "[PASS] PHP OPcache"
echo "[PASS] Apache -> PHP-FPM"
echo "[PASS] Docker"
echo "[PASS] Docker Compose v2"
echo "[PASS] AWS CLI v2"
echo "[PASS] kubectl"
echo "[PASS] eksctl"
echo "[PASS] Helm"
echo "[PASS] kind"
echo
echo "======================================================================"
echo
echo "WEB TESTS"
echo "---------------------------------------------------------------------"
echo
echo "Apache:"
echo "  http://127.0.0.1/"
echo
echo "PHP:"
echo "  http://127.0.0.1/info.php"
echo
echo "======================================================================"
echo
echo "LOG FILE"
echo "---------------------------------------------------------------------"
echo
echo "${LOG_FILE}"
echo
echo "======================================================================"
echo
echo "COMPLETION FILE"
echo "---------------------------------------------------------------------"
echo
echo "${COMPLETION_FILE}"
echo
echo "======================================================================"
echo
echo "IMPORTANT"
echo "---------------------------------------------------------------------"
echo
echo "If you are currently connected as ec2-user, disconnect and reconnect"
echo "before using Docker without sudo."
echo
echo "This is required because the docker group membership was changed."
echo
echo "AWS STS failure does NOT mean AWS CLI installation failed."
echo "It normally means the EC2 instance does not currently have usable"
echo "AWS credentials / an IAM instance role."
echo
echo "======================================================================"
echo
echo "☕ Charlie Cafe EC2 bootstrap is complete."
echo
echo "======================================================================"
echo


# =============================================================================
# 59. EXIT SUCCESSFULLY
# =============================================================================

exit 0