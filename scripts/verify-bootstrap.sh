#!/bin/bash

# =========================================================
# ☕ Charlie Cafe — EC2 Bootstrap Verification Script
# Amazon Linux 2023
# =========================================================
#
# Purpose:
#   Verify that the Charlie Cafe EC2 Bootstrap Script
#   completed successfully.
#
# IMPORTANT:
#   This script is READ-ONLY.
#   It does NOT install, modify, create, or delete anything.
#
# Checks:
#   1. Operating System
#   2. Apache/httpd
#   3. Apache service
#   4. Apache HTTP response
#   5. PHP
#   6. PHP extensions
#   7. /var/www permissions
#   8. MariaDB/MySQL client
#   9. Docker
#  10. Docker service
#  11. Docker group membership
#  12. Docker Compose v2
#  13. Git
#  14. DevOps utilities
#  15. AWS CLI
#  16. AWS Identity
#  17. PHP info page
#  18. Overall verification summary
#
# Usage:
#   chmod +x verify-bootstrap.sh
#   ./verify-bootstrap.sh
#
# =========================================================

# ---------------------------------------------------------
# Do NOT use "set -e"
# ---------------------------------------------------------
#
# We intentionally allow individual checks to fail so that
# the script can continue and show ALL problems at once.
#
# ---------------------------------------------------------

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# ---------------------------------------------------------
# Colors
# ---------------------------------------------------------

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

# ---------------------------------------------------------
# Helper Functions
# ---------------------------------------------------------

pass() {
    echo -e "${GREEN}[PASS]${RESET} $1"
    ((PASS_COUNT++))
}

fail() {
    echo -e "${RED}[FAIL]${RESET} $1"
    ((FAIL_COUNT++))
}

warn() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
    ((WARN_COUNT++))
}

info() {
    echo -e "${CYAN}[INFO]${RESET} $1"
}

section() {
    echo
    echo "========================================================="
    echo -e "${BLUE}$1${RESET}"
    echo "========================================================="
}

# =========================================================
# 1. Operating System
# =========================================================

section "1. Operating System Verification"

if [ -f /etc/os-release ]; then

    source /etc/os-release

    echo "OS Name    : $NAME"
    echo "OS Version : $VERSION"
    echo "OS ID      : $ID"

    if [[ "$ID" == "amzn" ]]; then
        pass "Amazon Linux detected"
    else
        warn "This system is not identified as Amazon Linux"
    fi

else

    fail "/etc/os-release not found"

fi

# =========================================================
# 2. Apache Installation
# =========================================================

section "2. Apache/httpd Verification"

if command -v httpd >/dev/null 2>&1; then

    pass "Apache/httpd is installed"

    echo "Apache Version:"
    httpd -v 2>/dev/null | head -n 1

else

    fail "Apache/httpd is not installed"

fi

# =========================================================
# 3. Apache Service
# =========================================================

section "3. Apache Service Verification"

if systemctl is-enabled httpd >/dev/null 2>&1; then
    pass "Apache is enabled at boot"
else
    fail "Apache is NOT enabled at boot"
fi

if systemctl is-active --quiet httpd; then
    pass "Apache service is running"
else
    fail "Apache service is NOT running"
fi

# =========================================================
# 4. Apache HTTP Response
# =========================================================

section "4. Apache HTTP Verification"

if command -v curl >/dev/null 2>&1; then

    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        --max-time 5 \
        http://localhost)

    echo "HTTP Status: $HTTP_STATUS"

    if [[ "$HTTP_STATUS" == "200" ||
          "$HTTP_STATUS" == "301" ||
          "$HTTP_STATUS" == "302" ]]; then

        pass "Apache is responding to HTTP requests"

    else

        fail "Apache HTTP response is unexpected"

    fi

else

    fail "curl is not installed; cannot test Apache HTTP"

fi

# =========================================================
# 5. PHP Installation
# =========================================================

section "5. PHP Verification"

if command -v php >/dev/null 2>&1; then

    pass "PHP is installed"

    echo "PHP Version:"
    php -v | head -n 1

else

    fail "PHP is not installed"

fi

# =========================================================
# 6. PHP Extensions
# =========================================================

section "6. PHP Extension Verification"

REQUIRED_PHP_EXTENSIONS=(
    "mysqli"
    "mysqlnd"
    "mbstring"
    "xml"
)

for EXTENSION in "${REQUIRED_PHP_EXTENSIONS[@]}"; do

    if php -m 2>/dev/null | grep -qi "^${EXTENSION}$"; then

        pass "PHP extension installed: $EXTENSION"

    else

        fail "PHP extension missing: $EXTENSION"

    fi

done

# =========================================================
# 7. /var/www Permissions
# =========================================================

section "7. Web Directory Verification"

if [ -d /var/www ]; then

    pass "/var/www directory exists"

    WEB_OWNER=$(stat -c "%U:%G" /var/www 2>/dev/null)

    echo "/var/www Owner : $WEB_OWNER"

else

    fail "/var/www directory does not exist"

fi

if [ -d /var/www/html ]; then

    pass "/var/www/html directory exists"
else
    fail "/var/www/html directory does not exist"
fi

# ---------------------------------------------------------
# Verify Apache ownership of web files
# ---------------------------------------------------------

if [ -d /var/www ]; then

    if find /var/www -user apache -group apache -print -quit 2>/dev/null | grep -q .; then

        pass "Apache ownership detected under /var/www"

    else

        warn "No apache:apache-owned files detected under /var/www"

    fi

fi

# =========================================================
# 8. MariaDB / MySQL Client
# =========================================================

section "8. MariaDB/MySQL Client Verification"

if command -v mariadb >/dev/null 2>&1; then

    pass "MariaDB client is installed"

    echo "MariaDB Version:"
    mariadb --version

elif command -v mysql >/dev/null 2>&1; then

    pass "MySQL/MariaDB client is installed"

    echo "MySQL/MariaDB Version:"
    mysql --version

else

    fail "MariaDB/MySQL client was not found"

fi

# =========================================================
# 9. Docker Installation
# =========================================================

section "9. Docker Verification"

if command -v docker >/dev/null 2>&1; then

    pass "Docker is installed"

    echo "Docker Version:"
    docker --version

else

    fail "Docker is not installed"

fi

# =========================================================
# 10. Docker Service
# =========================================================

section "10. Docker Service Verification"

if systemctl is-enabled docker >/dev/null 2>&1; then

    pass "Docker is enabled at boot"

else

    fail "Docker is NOT enabled at boot"

fi

if systemctl is-active --quiet docker; then

    pass "Docker service is running"

else

    fail "Docker service is NOT running"

fi

# =========================================================
# 11. Docker Group
# =========================================================

section "11. Docker Group Verification"

if getent group docker >/dev/null 2>&1; then

    pass "Docker group exists"

else

    fail "Docker group does not exist"

fi

if getent group docker | grep -q "ec2-user"; then

    pass "ec2-user belongs to docker group"

else

    fail "ec2-user does NOT belong to docker group"

fi

# ---------------------------------------------------------
# IMPORTANT:
#
# The current SSH session may not yet recognize the new
# docker group membership.
# ---------------------------------------------------------

if id -nG ec2-user 2>/dev/null | grep -qw docker; then

    pass "ec2-user group membership is visible"

else

    warn "Current environment may require a new login for docker group"

fi

# =========================================================
# 12. Docker Compose v2
# =========================================================

section "12. Docker Compose Verification"

if docker compose version >/dev/null 2>&1; then

    pass "Docker Compose v2 is available"

    docker compose version

else

    fail "Docker Compose v2 is not available"

fi

# =========================================================
# 13. Git
# =========================================================

section "13. Git Verification"

if command -v git >/dev/null 2>&1; then

    pass "Git is installed"

    echo "Git Version:"
    git --version

else

    fail "Git is not installed"

fi

# =========================================================
# 14. DevOps Utility Verification
# =========================================================

section "14. DevOps Utility Verification"

TOOLS=(
    "htop"
    "unzip"
    "curl"
    "wget"
    "nano"
    "vim"
    "tar"
)

for TOOL in "${TOOLS[@]}"; do

    if command -v "$TOOL" >/dev/null 2>&1; then

        pass "Tool installed: $TOOL"

    else

        fail "Tool missing: $TOOL"

    fi

done

# =========================================================
# 15. AWS CLI
# =========================================================

section "15. AWS CLI Verification"

if command -v aws >/dev/null 2>&1; then

    pass "AWS CLI is installed"

    echo "AWS CLI Version:"
    aws --version

else

    fail "AWS CLI is not installed"

fi

# =========================================================
# 16. AWS Identity Verification
# =========================================================

section "16. AWS Identity Verification"

if command -v aws >/dev/null 2>&1; then

    if aws sts get-caller-identity >/tmp/charlie-cafe-identity.json 2>/dev/null; then

        pass "AWS credentials/instance role are working"

        echo
        echo "AWS Identity:"
        cat /tmp/charlie-cafe-identity.json

        rm -f /tmp/charlie-cafe-identity.json

    else

        warn "AWS CLI works, but AWS credentials/instance role could not be verified"

        info "Check the EC2 IAM role and AWS credentials configuration"

    fi

fi

# =========================================================
# 17. PHP Info Page
# =========================================================

section "17. PHP Info Page Verification"

PHP_INFO_FILE="/var/www/html/info.php"

if [ -f "$PHP_INFO_FILE" ]; then

    pass "PHP info page exists: $PHP_INFO_FILE"

else

    fail "PHP info page is missing: $PHP_INFO_FILE"

fi

# ---------------------------------------------------------
# Verify PHP is actually executed by Apache
# ---------------------------------------------------------

if command -v curl >/dev/null 2>&1; then

    PHP_INFO_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        --max-time 5 \
        http://localhost/info.php)

    echo "info.php HTTP Status: $PHP_INFO_STATUS"

    if [[ "$PHP_INFO_STATUS" == "200" ]]; then

        PHP_CONTENT=$(curl -s \
            --max-time 5 \
            http://localhost/info.php)

        if echo "$PHP_CONTENT" | grep -qi "PHP Version"; then

            pass "Apache is executing PHP successfully"

        else

            warn "info.php returned HTTP 200, but PHP output was not detected"

        fi

    else

        fail "info.php is not accessible through Apache"

    fi

fi

# =========================================================
# 18. Docker Functional Test
# =========================================================

section "18. Docker Functional Verification"

if command -v docker >/dev/null 2>&1 &&
   systemctl is-active --quiet docker; then

    if docker info >/dev/null 2>&1; then

        pass "Docker daemon is responding"

    else

        warn "Docker is installed and running, but current user cannot access Docker daemon"

        info "If ec2-user was recently added to the docker group, log out and reconnect"

    fi

fi

# =========================================================
# 19. Final Summary
# =========================================================

section "FINAL VERIFICATION SUMMARY"

echo
echo "Charlie Cafe EC2 Bootstrap Verification"
echo "----------------------------------------"
echo -e "${GREEN}PASSED : $PASS_COUNT${RESET}"
echo -e "${RED}FAILED : $FAIL_COUNT${RESET}"
echo -e "${YELLOW}WARNED : $WARN_COUNT${RESET}"
echo

# =========================================================
# Final Result
# =========================================================

if [ "$FAIL_COUNT" -eq 0 ]; then

    echo -e "${GREEN}=========================================================${RESET}"
    echo -e "${GREEN}✅ BOOTSTRAP VERIFICATION PASSED${RESET}"
    echo -e "${GREEN}=========================================================${RESET}"
    echo
    echo "The major components installed by the bootstrap script"
    echo "were successfully verified."

    if [ "$WARN_COUNT" -gt 0 ]; then
        echo
        echo "⚠️  There are warnings above that should be reviewed."
    fi

    exit 0

else

    echo -e "${RED}=========================================================${RESET}"
    echo -e "${RED}❌ BOOTSTRAP VERIFICATION FAILED${RESET}"
    echo -e "${RED}=========================================================${RESET}"
    echo
    echo "One or more verification checks failed."
    echo "Review the [FAIL] messages above."

    exit 1

fi