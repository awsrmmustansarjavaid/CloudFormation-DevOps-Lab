#!/bin/bash

# ================================================================
# ☕ Charlie Cafe — EC2 Environment Verification Script
# ================================================================
#
# File:
#   verify-charlie-cafe-ec2.sh
#
# Purpose:
#   Read-only verification of the EC2 environment prepared by:
#
#       ec2-userdata.sh
#
# Operating System:
#   Amazon Linux 2023
#
# IMPORTANT:
#   This script performs READ-ONLY verification.
#
#   It does NOT intentionally:
#
#       - Install packages
#       - Update packages
#       - Create AWS resources
#       - Delete AWS resources
#       - Modify AWS resources
#       - Restart services
#       - Stop services
#       - Change permissions
#       - Change ownership
#       - Modify Apache configuration
#       - Modify Docker configuration
#       - Modify PHP configuration
#
# Recommended execution:
#
#       chmod +x verify-charlie-cafe-ec2.sh
#       sudo bash verify-charlie-cafe-ec2.sh
#
# Log:
#
#       /var/log/charlie-cafe-verification.log
#
# ================================================================


# ================================================================
# 0. Require Root
# ================================================================

if [[ "${EUID}" -ne 0 ]]; then

    echo "ERROR: This verification script should be run as root."
    echo
    echo "Run:"
    echo
    echo "    sudo bash verify-charlie-cafe-ec2.sh"
    echo

    exit 1

fi


# ================================================================
# 1. Verification Log
# ================================================================

LOG_FILE="/var/log/charlie-cafe-verification.log"

touch "${LOG_FILE}"

exec > >(tee -a "${LOG_FILE}") 2>&1


# ================================================================
# 2. Bash Safety
# ================================================================

set -u
set -o pipefail


# ================================================================
# 3. Verification Counters
# ================================================================

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0


# ================================================================
# 4. Helper Functions
# ================================================================

section() {

    echo
    echo "==============================================================="
    echo "$1"
    echo "==============================================================="

}


pass() {

    echo "[PASS] $1"
    PASS_COUNT=$((PASS_COUNT + 1))

}


fail() {

    echo "[FAIL] $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))

}


warn() {

    echo "[WARN] $1"
    WARN_COUNT=$((WARN_COUNT + 1))

}


info() {

    echo "[INFO] $1"

}


command_exists() {

    command -v "$1" >/dev/null 2>&1

}


package_installed() {

    rpm -q "$1" >/dev/null 2>&1

}


service_active() {

    systemctl is-active --quiet "$1"

}


service_enabled() {

    systemctl is-enabled --quiet "$1"

}


# ================================================================
# 5. Verification Start
# ================================================================

echo
echo "==============================================================="
echo "☕ CHARLIE CAFE EC2 ENVIRONMENT VERIFICATION"
echo "==============================================================="
echo
echo "Date       : $(date)"
echo "Hostname   : $(hostname)"
echo "User       : $(whoami)"
echo "UID        : $(id -u)"
echo "Log File   : ${LOG_FILE}"
echo


# ================================================================
# 6. Operating System Verification
# ================================================================

section "1. Operating System Verification"


if [[ -f /etc/os-release ]]; then

    source /etc/os-release

    info "OS Name    : ${NAME}"
    info "OS Version : ${VERSION}"
    info "OS ID      : ${ID}"

    if [[ "${ID}" == "amzn" ]]; then
        pass "Amazon Linux detected."
    else
        fail "System is not Amazon Linux."
    fi

else

    fail "/etc/os-release does not exist."

fi


# ================================================================
# 7. DNF Verification
# ================================================================

section "2. DNF Package Manager Verification"


if command_exists dnf; then

    pass "DNF package manager is available."

    echo
    dnf --version | head -n 1

else

    fail "DNF package manager is not available."

fi


# ================================================================
# 8. Apache Verification
# ================================================================

section "3. Apache HTTP Server Verification"


if command_exists httpd; then

    pass "Apache command is installed."

    echo
    httpd -v | head -n 1

else

    fail "Apache command is not installed."

fi


if package_installed httpd; then

    pass "Apache RPM package is installed."

else

    fail "Apache RPM package is not installed."

fi


if service_active httpd; then

    pass "Apache service is running."

else

    fail "Apache service is not running."

    systemctl status httpd --no-pager 2>/dev/null || true

fi


if service_enabled httpd; then

    pass "Apache is enabled at boot."

else

    warn "Apache is not enabled at boot."

fi


# ================================================================
# 9. Apache Configuration Verification
# ================================================================

section "4. Apache Configuration Verification"


if command_exists httpd; then

    if httpd -t >/dev/null 2>&1; then

        pass "Apache configuration syntax is valid."

    else

        fail "Apache configuration syntax is invalid."

        httpd -t || true

    fi

fi


# ================================================================
# 10. PHP Verification
# ================================================================

section "5. PHP Verification"


if command_exists php; then

    pass "PHP command is available."

    echo
    php -v | head -n 1

else

    fail "PHP command is not available."

fi


if package_installed php; then

    pass "PHP RPM package is installed."

else

    fail "PHP RPM package is not installed."

fi


# ================================================================
# 11. PHP Extension Verification
# ================================================================

section "6. PHP Extension Verification"


if command_exists php; then


    if php -m | grep -qi '^mysqli$'; then
        pass "PHP mysqli extension is available."
    else
        fail "PHP mysqli extension is missing."
    fi


    if php -m | grep -qi '^mysqlnd$'; then
        pass "PHP mysqlnd extension is available."
    else
        fail "PHP mysqlnd extension is missing."
    fi


    if php -m | grep -qi '^mbstring$'; then
        pass "PHP mbstring extension is available."
    else
        fail "PHP mbstring extension is missing."
    fi


    if php -m | grep -qi '^xml$'; then
        pass "PHP XML extension is available."
    else
        fail "PHP XML extension is missing."
    fi


    if php -m | grep -qi '^json$'; then
        pass "PHP JSON extension is available."
    else
        warn "PHP JSON extension was not detected explicitly."
    fi

fi


# ================================================================
# 12. PHP-FPM Verification
# ================================================================

section "7. PHP-FPM Verification"


if command_exists php-fpm; then

    pass "PHP-FPM command is available."

else

    fail "PHP-FPM command is not available."

fi


if package_installed php-fpm; then

    pass "PHP-FPM RPM package is installed."

else

    fail "PHP-FPM RPM package is not installed."

fi


if service_active php-fpm; then

    pass "PHP-FPM service is running."

else

    fail "PHP-FPM service is not running."

    systemctl status php-fpm --no-pager 2>/dev/null || true

fi


if service_enabled php-fpm; then

    pass "PHP-FPM is enabled at boot."

else

    warn "PHP-FPM is not enabled at boot."

fi


# ================================================================
# 13. MariaDB/MySQL Client Verification
# ================================================================

section "8. MariaDB / MySQL Client Verification"


if command_exists mariadb; then

    pass "MariaDB client command is available."

    echo
    mariadb --version

elif command_exists mysql; then

    pass "MySQL client command is available."

    echo
    mysql --version

else

    fail "MariaDB/MySQL client command was not found."

fi


if package_installed mariadb105; then

    pass "MariaDB 10.5 client package is installed."

else

    warn "mariadb105 RPM package was not detected."

fi


# ================================================================
# 14. Docker Verification
# ================================================================

section "9. Docker Verification"


if command_exists docker; then

    pass "Docker command is available."

    echo
    docker --version

else

    fail "Docker command is not available."

fi


if package_installed docker; then

    pass "Docker RPM package is installed."

else

    fail "Docker RPM package is not installed."

fi


if service_active docker; then

    pass "Docker service is running."

else

    fail "Docker service is not running."

    systemctl status docker --no-pager 2>/dev/null || true

fi


if service_enabled docker; then

    pass "Docker is enabled at boot."

else

    warn "Docker is not enabled at boot."

fi


# ================================================================
# 15. Docker Daemon Verification
# ================================================================

section "10. Docker Daemon Verification"


if command_exists docker; then

    if docker info >/dev/null 2>&1; then

        pass "Docker daemon is responding."

    else

        fail "Docker daemon is not responding to docker info."

    fi

fi


# ================================================================
# 16. Docker Group Verification
# ================================================================

section "11. Docker Group Verification"


if getent group docker >/dev/null 2>&1; then

    pass "Docker group exists."

    echo
    getent group docker

else

    fail "Docker group does not exist."

fi


if id ec2-user >/dev/null 2>&1; then

    if id -nG ec2-user | tr ' ' '\n' | grep -qx docker; then

        pass "ec2-user belongs to the docker group."

    else

        fail "ec2-user does not belong to the docker group."

    fi

else

    fail "ec2-user account does not exist."

fi


# ================================================================
# 17. Docker Compose Verification
# ================================================================

section "12. Docker Compose v2 Verification"


if command_exists docker; then

    if docker compose version >/dev/null 2>&1; then

        pass "Docker Compose v2 is available."

        echo
        docker compose version

    else

        fail "Docker Compose v2 is not available."

    fi

fi


DOCKER_PLUGIN="/usr/local/lib/docker/cli-plugins/docker-compose"


if [[ -f "${DOCKER_PLUGIN}" ]]; then

    pass "Docker Compose CLI plugin exists."

else

    warn "Docker Compose CLI plugin was not found at:"
    warn "${DOCKER_PLUGIN}"

fi


if [[ -x "${DOCKER_PLUGIN}" ]]; then

    pass "Docker Compose CLI plugin is executable."

else

    warn "Docker Compose CLI plugin is not executable."

fi


# ================================================================
# 18. Git Verification
# ================================================================

section "13. Git Verification"


if command_exists git; then

    pass "Git is installed."

    echo
    git --version

else

    fail "Git is not installed."

fi


# ================================================================
# 19. DevOps Utilities Verification
# ================================================================

section "14. DevOps Utilities Verification"


for utility in htop unzip wget nano vim tar; do

    if command_exists "${utility}"; then

        pass "${utility} is available."

    else

        fail "${utility} is not available."

    fi

done


# ================================================================
# 20. curl Verification
# ================================================================

section "15. curl Verification"


if command_exists curl; then

    pass "curl is available."

    echo
    curl --version | head -n 1

else

    fail "curl is not available."

fi


# ================================================================
# 21. AWS CLI Verification
# ================================================================

section "16. AWS CLI Verification"


if command_exists aws; then

    pass "AWS CLI is installed."

    echo
    aws --version

else

    fail "AWS CLI is not installed."

fi


# ================================================================
# 22. AWS IAM Identity Verification
# ================================================================

section "17. AWS IAM Role / Identity Verification"


IDENTITY_FILE="/tmp/charlie-cafe-verification-identity.json"


if command_exists aws; then

    if aws sts get-caller-identity \
        --output json \
        > "${IDENTITY_FILE}" 2>/dev/null; then

        pass "AWS STS caller identity is available."

        echo
        echo "AWS identity:"
        cat "${IDENTITY_FILE}"

        rm -f "${IDENTITY_FILE}"

    else

        warn "AWS STS caller identity could not be verified."

        echo
        echo "Possible reasons:"
        echo "  - No IAM role attached to EC2"
        echo "  - Instance metadata unavailable"
        echo "  - AWS credentials unavailable"
        echo "  - Network/connectivity issue"

    fi

fi


# ================================================================
# 23. Web Directory Verification
# ================================================================

section "18. Apache Web Directory Verification"


WEB_ROOT="/var/www/html"


if [[ -d "${WEB_ROOT}" ]]; then

    pass "Apache web root exists: ${WEB_ROOT}"

else

    fail "Apache web root does not exist: ${WEB_ROOT}"

fi


if [[ -r "${WEB_ROOT}" ]]; then

    pass "Apache web root is readable."

else

    fail "Apache web root is not readable."

fi


# ================================================================
# 24. Charlie Cafe index.php Verification
# ================================================================

section "19. Charlie Cafe Application Page Verification"


INDEX_FILE="${WEB_ROOT}/index.php"


if [[ -f "${INDEX_FILE}" ]]; then

    pass "Charlie Cafe index.php exists."

else

    fail "Charlie Cafe index.php does not exist."

fi


if [[ -r "${INDEX_FILE}" ]]; then

    pass "index.php is readable."

else

    fail "index.php is not readable."

fi


if [[ -f "${INDEX_FILE}" ]]; then

    if grep -q "Charlie Cafe" "${INDEX_FILE}"; then

        pass "index.php contains Charlie Cafe application content."

    else

        warn "index.php exists but Charlie Cafe text was not detected."

    fi

fi


# ================================================================
# 25. PHP Info Page Verification
# ================================================================

section "20. PHP Info Page Verification"


PHP_INFO_FILE="${WEB_ROOT}/info.php"


if [[ -f "${PHP_INFO_FILE}" ]]; then

    pass "info.php exists."

else

    fail "info.php does not exist."

fi


if [[ -r "${PHP_INFO_FILE}" ]]; then

    pass "info.php is readable."

else

    fail "info.php is not readable."

fi


# ================================================================
# 26. Apache HTTP Verification
# ================================================================

section "21. Apache HTTP Response Verification"


if command_exists curl; then

    HTTP_STATUS="$(
        curl -s \
            -o /dev/null \
            -w "%{http_code}" \
            --max-time 10 \
            http://localhost
    )"

    echo "HTTP status: ${HTTP_STATUS}"


    if [[ "${HTTP_STATUS}" == "200" ||
          "${HTTP_STATUS}" == "301" ||
          "${HTTP_STATUS}" == "302" ]]; then

        pass "Apache HTTP endpoint responded successfully."

    else

        fail "Apache HTTP endpoint returned unexpected status."

    fi

fi


# ================================================================
# 27. PHP Execution Verification
# ================================================================

section "22. PHP Execution Verification"


if command_exists curl; then

    PHP_STATUS="$(
        curl -s \
            -o /dev/null \
            -w "%{http_code}" \
            --max-time 10 \
            http://localhost/index.php
    )"

    echo "index.php HTTP status: ${PHP_STATUS}"


    if [[ "${PHP_STATUS}" == "200" ]]; then

        pass "PHP application page returned HTTP 200."

    else

        fail "PHP application page did not return HTTP 200."

    fi

fi


# ================================================================
# 28. PHP Content Verification
# ================================================================

section "23. PHP Application Content Verification"


if command_exists curl; then

    PHP_CONTENT="$(
        curl -s \
            --max-time 10 \
            http://localhost/index.php
    )"


    if echo "${PHP_CONTENT}" | grep -q "Charlie Cafe"; then

        pass "Charlie Cafe content is being served by PHP."

    else

        fail "Charlie Cafe content was not detected in HTTP response."

    fi


    if echo "${PHP_CONTENT}" | grep -q "PHP Version"; then

        pass "PHP version information is being rendered."

    else

        warn "PHP version information was not detected."

    fi

fi


# ================================================================
# 29. PHP Info HTTP Verification
# ================================================================

section "24. PHP Info HTTP Verification"


if command_exists curl; then

    PHP_INFO_STATUS="$(
        curl -s \
            -o /dev/null \
            -w "%{http_code}" \
            --max-time 10 \
            http://localhost/info.php
    )"

    echo "info.php HTTP status: ${PHP_INFO_STATUS}"


    if [[ "${PHP_INFO_STATUS}" == "200" ]]; then

        pass "PHP info page returned HTTP 200."

    else

        fail "PHP info page did not return HTTP 200."

    fi

fi


# ================================================================
# 30. PHP-FPM Socket / Process Verification
# ================================================================

section "25. PHP-FPM Process Verification"


if pgrep -x php-fpm >/dev/null 2>&1; then

    pass "PHP-FPM process is running."

else

    fail "PHP-FPM process was not detected."

fi


# ================================================================
# 31. Listening Port Verification
# ================================================================

section "26. Listening Port Verification"


if command_exists ss; then

    echo
    echo "Listening TCP ports:"
    echo

    ss -lntp || true


    if ss -lnt | grep -q ':80 '; then

        pass "Port 80 is listening."

    else

        fail "Port 80 is not listening."

    fi


    if ss -lnt | grep -q ':8080 '; then

        info "Port 8080 is currently listening."

    else

        info "Port 8080 is not currently listening."

    fi

else

    warn "ss command is not available."

fi


# ================================================================
# 32. Bootstrap Log Verification
# ================================================================

section "27. Bootstrap Log Verification"


BOOTSTRAP_LOG="/var/log/charlie-cafe-bootstrap.log"


if [[ -f "${BOOTSTRAP_LOG}" ]]; then

    pass "Bootstrap log exists."

    echo
    echo "Bootstrap log size:"
    du -h "${BOOTSTRAP_LOG}"


    if grep -q "BOOTSTRAP COMPLETED SUCCESSFULLY" "${BOOTSTRAP_LOG}"; then

        pass "Bootstrap log contains successful completion message."

    else

        warn "Bootstrap completion message was not detected in the log."

    fi

else

    fail "Bootstrap log does not exist."

fi


# ================================================================
# 33. Bootstrap Completion Marker
# ================================================================

section "28. Bootstrap Completion Marker Verification"


COMPLETION_FILE="/var/log/charlie-cafe-bootstrap-complete.txt"


if [[ -f "${COMPLETION_FILE}" ]]; then

    pass "Bootstrap completion marker exists."

    echo
    echo "Completion marker:"
    echo "---------------------------------------------------------------"
    cat "${COMPLETION_FILE}"
    echo "---------------------------------------------------------------"

else

    fail "Bootstrap completion marker does not exist."

fi


# ================================================================
# 34. Web File Permissions
# ================================================================

section "29. Web File Permission Verification"


if [[ -d "${WEB_ROOT}" ]]; then

    WEB_OWNER="$(stat -c '%U:%G' "${WEB_ROOT}")"

    echo "Web root owner: ${WEB_OWNER}"


    if [[ "${WEB_OWNER}" == "apache:apache" ]]; then

        pass "Apache owns the web root."

    else

        warn "Web root ownership is ${WEB_OWNER}; expected apache:apache."

    fi

fi


if [[ -f "${INDEX_FILE}" ]]; then

    INDEX_PERMISSION="$(stat -c '%a' "${INDEX_FILE}")"

    echo "index.php permissions: ${INDEX_PERMISSION}"


    if [[ "${INDEX_PERMISSION}" == "644" ]]; then

        pass "index.php permissions are 644."

    else

        warn "index.php permissions are ${INDEX_PERMISSION}; expected 644."

    fi

fi


if [[ -f "${PHP_INFO_FILE}" ]]; then

    INFO_PERMISSION="$(stat -c '%a' "${PHP_INFO_FILE}")"

    echo "info.php permissions: ${INFO_PERMISSION}"


    if [[ "${INFO_PERMISSION}" == "644" ]]; then

        pass "info.php permissions are 644."

    else

        warn "info.php permissions are ${INFO_PERMISSION}; expected 644."

    fi

fi


# ================================================================
# 35. Disk Space Verification
# ================================================================

section "30. Disk Space Verification"


echo
df -h /


ROOT_USAGE="$(
    df -P / |
    awk 'NR==2 {gsub("%","",$5); print $5}'
)"


if [[ "${ROOT_USAGE}" =~ ^[0-9]+$ ]]; then

    if (( ROOT_USAGE < 90 )); then

        pass "Root filesystem usage is below 90%."

    else

        warn "Root filesystem usage is ${ROOT_USAGE}%."

    fi

fi


# ================================================================
# 36. Memory Verification
# ================================================================

section "31. Memory Verification"


if command_exists free; then

    echo
    free -h

    pass "Memory information is available."

else

    warn "free command is not available."

fi


# ================================================================
# 37. Docker Functional Test
# ================================================================

section "32. Docker Functional Verification"


if command_exists docker && service_active docker; then

    if docker info >/dev/null 2>&1; then

        DOCKER_VERSION="$(
            docker version \
                --format '{{.Server.Version}}' \
                2>/dev/null
        )"

        if [[ -n "${DOCKER_VERSION}" ]]; then

            pass "Docker server version detected: ${DOCKER_VERSION}"

        else

            warn "Docker daemon is running but server version could not be read."

        fi


        # --------------------------------------------------------
        # Read-only Docker image/container inspection
        # --------------------------------------------------------

        echo
        echo "Docker images:"
        docker images || true

        echo
        echo "Docker containers:"
        docker ps -a || true

    else

        fail "Docker daemon functional test failed."

    fi

fi


# ================================================================
# 38. IAM Metadata Verification
# ================================================================

section "33. EC2 Instance Metadata Verification"


TOKEN="$(
    curl -sS \
        --max-time 3 \
        -X PUT \
        -H "X-aws-ec2-metadata-token-ttl-seconds: 60" \
        http://169.254.169.254/latest/api/token \
        2>/dev/null || true
)"


if [[ -n "${TOKEN}" ]]; then

    pass "EC2 Instance Metadata Service is reachable."

else

    warn "EC2 Instance Metadata Service token could not be obtained."

fi


# ================================================================
# 39. System Information
# ================================================================

section "34. System Information"


echo
echo "Hostname:"
hostname


echo
echo "Kernel:"
uname -r


echo
echo "Architecture:"
uname -m


echo
echo "Uptime:"
uptime


# ================================================================
# 40. Service Summary
# ================================================================

section "35. Service Status Summary"


echo
echo "Apache:"
systemctl is-active httpd || true


echo
echo "PHP-FPM:"
systemctl is-active php-fpm || true


echo
echo "Docker:"
systemctl is-active docker || true


# ================================================================
# 41. Software Summary
# ================================================================

section "36. Installed Software Summary"


echo
echo "Apache:"
httpd -v 2>/dev/null | head -n 1 || true


echo
echo "PHP:"
php -v 2>/dev/null | head -n 1 || true


echo
echo "PHP-FPM:"
php-fpm --version 2>/dev/null | head -n 1 || true


echo
echo "Docker:"
docker --version 2>/dev/null || true


echo
echo "Docker Compose:"
docker compose version 2>/dev/null || true


echo
echo "Git:"
git --version 2>/dev/null || true


echo
echo "AWS CLI:"
aws --version 2>/dev/null || true


echo
echo "Database Client:"

if command_exists mariadb; then

    mariadb --version

elif command_exists mysql; then

    mysql --version

else

    echo "Not installed"

fi


# ================================================================
# 42. Final Verification Summary
# ================================================================

section "37. FINAL VERIFICATION SUMMARY"


echo
echo "==============================================================="
echo "                 CHARLIE CAFE VERIFICATION"
echo "==============================================================="
echo
echo "PASS : ${PASS_COUNT}"
echo "FAIL : ${FAIL_COUNT}"
echo "WARN : ${WARN_COUNT}"
echo


# ================================================================
# 43. Overall Result
# ================================================================

if [[ "${FAIL_COUNT}" -eq 0 ]]; then

    echo "==============================================================="
    echo "✅ CHARLIE CAFE EC2 VERIFICATION PASSED"
    echo "==============================================================="
    echo
    echo "The EC2 environment passed all required checks."
    echo
    echo "Warnings: ${WARN_COUNT}"
    echo
    echo "Verification log:"
    echo "  ${LOG_FILE}"
    echo
    echo "==============================================================="

    exit 0

else

    echo "==============================================================="
    echo "❌ CHARLIE CAFE EC2 VERIFICATION FAILED"
    echo "==============================================================="
    echo
    echo "Failed checks: ${FAIL_COUNT}"
    echo "Warnings      : ${WARN_COUNT}"
    echo
    echo "Review the verification log:"
    echo
    echo "  sudo cat ${LOG_FILE}"
    echo
    echo "==============================================================="

    exit 1

fi

