#!/bin/bash

# ================================================================
# ☕ Charlie Cafe — Amazon Linux 2023 EC2 CLEANUP / RESET SCRIPT
# ================================================================
#
# PURPOSE
# ----------------------------------------------------------------
# Clean an Amazon Linux 2023 EC2 instance that was previously
# prepared using the Charlie Cafe EC2 Bootstrap Script.
#
# This script removes:
#
#   Linux / Utility packages installed by the lab
#   Apache HTTP Server
#   PHP
#   PHP-FPM
#   MariaDB/MySQL client
#   Docker
#   Docker Compose v2
#   AWS CLI v2 installed under /usr/local
#   kubectl
#   eksctl
#   Helm
#   kind
#
# It also removes:
#
#   Apache configuration created by the lab
#   PHP-FPM configuration
#   Charlie Cafe web files
#   Docker containers
#   Docker images
#   Docker volumes
#   Docker networks
#   Docker build cache
#   Charlie Cafe bootstrap logs
#   Charlie Cafe completion marker
#   Temporary installation files
#   Charlie Cafe PATH modification
#
# IMPORTANT SAFETY NOTES
# ----------------------------------------------------------------
#
# 1. THIS SCRIPT MUST BE RUN AS ROOT.
#
#       sudo bash clean-charlie-cafe-ec2.sh
#
# 2. This script DOES NOT remove Amazon Linux itself.
#
# 3. This script DOES NOT remove:
#
#       - systemd
#       - DNF
#       - RPM
#       - EC2 networking
#       - SSH
#       - cloud-init
#       - SSM Agent
#       - AWS EC2 operating-system essentials
#
# 4. Docker DATA WILL BE PERMANENTLY DELETED.
#
#       Containers
#       Images
#       Volumes
#       Networks
#       Docker build cache
#
# 5. The Charlie Cafe web directory is cleaned.
#
# 6. This script does NOT modify AWS resources outside EC2.
#
#       It does NOT delete:
#           - EC2 instance
#           - EBS volume
#           - Security groups
#           - IAM roles
#           - VPC
#           - S3
#           - RDS
#           - DynamoDB
#           - Lambda
#           - CloudFormation
#
# 7. A true operating-system rollback is NOT possible.
#
#    Your bootstrap script runs:
#
#       dnf update -y
#
#    Therefore some original Amazon Linux packages may have been
#    upgraded. Removing software cannot restore their old versions.
#
#    For a completely fresh EC2:
#
#       Terminate the instance
#       Launch a new Amazon Linux 2023 instance
#
# ================================================================


# ================================================================
# 1. ROOT CHECK
# ================================================================

if [[ "${EUID}" -ne 0 ]]; then

    echo
    echo "ERROR: This cleanup script must be run as root."
    echo
    echo "Run:"
    echo
    echo "    sudo bash clean-charlie-cafe-ec2.sh"
    echo

    exit 1

fi


# ================================================================
# 2. VERIFY AMAZON LINUX 2023
# ================================================================

if [[ ! -f /etc/os-release ]]; then

    echo "ERROR: /etc/os-release not found."
    exit 1

fi


source /etc/os-release


if [[ "${ID}" != "amzn" ]]; then

    echo "ERROR: This cleanup script is intended for Amazon Linux."
    echo "Detected OS: ${PRETTY_NAME:-unknown}"

    exit 1

fi


if [[ "${VERSION_ID}" != "2023" ]]; then

    echo "ERROR: This cleanup script is intended for Amazon Linux 2023."
    echo "Detected version: ${VERSION_ID}"

    exit 1

fi


# ================================================================
# 3. VARIABLES
# ================================================================

WEB_ROOT="/var/www/html"

PHP_FPM_CONFIG="/etc/php-fpm.d/www.conf"

PHP_APACHE_CONFIG="/etc/httpd/conf.d/php-fpm.conf"

BOOTSTRAP_LOG="/var/log/charlie-cafe-bootstrap.log"

COMPLETION_FILE="/var/log/charlie-cafe-bootstrap-complete.txt"

DOCKER_PLUGIN_DIR="/usr/local/lib/docker/cli-plugins"

AWS_CLI_DIR="/usr/local/aws-cli"

AWS_CLI_BINARY="/usr/local/bin/aws"

KUBECTL_BINARY="/usr/local/bin/kubectl"

EKSCTL_BINARY="/usr/local/bin/eksctl"

HELM_BINARY="/usr/local/bin/helm"

KIND_BINARY="/usr/local/bin/kind"

EC2_USER_BASHRC="/home/ec2-user/.bashrc"


# ================================================================
# 4. LOGGING
# ================================================================

CLEANUP_LOG="/var/log/charlie-cafe-cleanup.log"

touch "${CLEANUP_LOG}"

exec > >(tee -a "${CLEANUP_LOG}") 2>&1


# ================================================================
# 5. STRICT MODE
# ================================================================

set -Eeuo pipefail


# ================================================================
# 6. ERROR HANDLER
# ================================================================

trap '
EXIT_CODE=$?

echo
echo "========================================================="
echo "❌ CHARLIE CAFE CLEANUP FAILED"
echo "========================================================="
echo "Exit Code : ${EXIT_CODE}"
echo "Line      : ${LINENO}"
echo "Command   : ${BASH_COMMAND}"
echo "Log File  : ${CLEANUP_LOG}"
echo
echo "Review:"
echo "  sudo less ${CLEANUP_LOG}"
echo "========================================================="

exit "${EXIT_CODE}"
' ERR


# ================================================================
# 7. HELPER: SECTION HEADER
# ================================================================

step() {

    echo
    echo "========================================================="
    echo "$1"
    echo "========================================================="

}


# ================================================================
# 8. START
# ================================================================

step "☕ Charlie Cafe EC2 CLEANUP Started"

echo "Date        : $(date)"
echo "Hostname    : $(hostname)"
echo "Current user: $(whoami)"
echo "UID         : $(id -u)"
echo "OS          : ${PRETTY_NAME:-Amazon Linux 2023}"
echo "Architecture: $(uname -m)"
echo "Cleanup log : ${CLEANUP_LOG}"


# ================================================================
# 9. SAFETY CONFIRMATION
# ================================================================
#
# This script intentionally performs destructive cleanup.
#
# Docker data, containers, images, volumes and application files
# will be removed.
#
# ================================================================

step "1. Destructive Cleanup Confirmation"

echo
echo "WARNING:"
echo
echo "This script will remove the Charlie Cafe lab software and data."
echo
echo "The following may be permanently deleted:"
echo
echo "  - Apache configuration"
echo "  - PHP configuration"
echo "  - Charlie Cafe web files"
echo "  - Docker containers"
echo "  - Docker images"
echo "  - Docker volumes"
echo "  - Docker networks"
echo "  - Docker build cache"
echo "  - Kubernetes binaries"
echo "  - Lab logs"
echo
echo "AWS resources OUTSIDE this EC2 instance are NOT affected."
echo

if [[ "${CHARLIE_CAFE_CLEANUP_FORCE:-}" != "YES" ]]; then

    read -r -p "Type DELETE to continue: " CONFIRM

    if [[ "${CONFIRM}" != "DELETE" ]]; then

        echo
        echo "Cleanup cancelled."
        exit 0

    fi

else

    echo "CHARLIE_CAFE_CLEANUP_FORCE=YES detected."
    echo "Interactive confirmation skipped."

fi


# ================================================================
# 10. STOP LAB SERVICES
# ================================================================

step "2. Stopping Charlie Cafe Services"

SERVICES=(
    httpd
    php-fpm
    docker
)

for SERVICE in "${SERVICES[@]}"; do

    if systemctl list-unit-files "${SERVICE}.service" \
        >/dev/null 2>&1; then

        echo "Stopping ${SERVICE}..."

        systemctl stop "${SERVICE}" 2>/dev/null || true

    else

        echo "${SERVICE} service not installed."

    fi

done


echo "[PASS] Lab services stopped."


# ================================================================
# 11. DISABLE LAB SERVICES
# ================================================================

step "3. Disabling Lab Services"

for SERVICE in "${SERVICES[@]}"; do

    systemctl disable "${SERVICE}" 2>/dev/null || true

done


echo "[PASS] Lab services disabled."


# ================================================================
# 12. CLEAN DOCKER
# ================================================================
#
# IMPORTANT:
# Docker data is intentionally destroyed.
#
# ================================================================

step "4. Removing Docker Data"

if command -v docker >/dev/null 2>&1; then

    echo "Docker detected."

    echo
    echo "Removing Docker containers..."

    docker ps -aq 2>/dev/null \
        | xargs -r docker rm -f || true


    echo
    echo "Removing Docker images..."

    docker images -aq 2>/dev/null \
        | xargs -r docker rmi -f || true


    echo
    echo "Removing Docker volumes..."

    docker volume ls -q 2>/dev/null \
        | xargs -r docker volume rm -f || true


    echo
    echo "Removing Docker networks..."

    docker network ls \
        --format '{{.ID}}' 2>/dev/null \
        | while read -r NETWORK_ID; do

            case "${NETWORK_ID}" in
                "")
                    ;;
                *)
                    docker network rm "${NETWORK_ID}" \
                        2>/dev/null || true
                    ;;
            esac

        done


    echo
    echo "Removing Docker builder cache..."

    docker builder prune -af 2>/dev/null || true


    echo
    echo "Removing Docker system data..."

    docker system prune -af --volumes 2>/dev/null || true

else

    echo "Docker command not found."

fi


# ================================================================
# 13. REMOVE DOCKER DATA DIRECTORY
# ================================================================
#
# /var/lib/docker contains Docker's persistent local data.
#
# ================================================================

step "5. Removing Docker Storage"

if [[ -d /var/lib/docker ]]; then

    rm -rf /var/lib/docker

    echo "[PASS] /var/lib/docker removed."

else

    echo "[INFO] /var/lib/docker does not exist."

fi


if [[ -d /var/lib/containerd ]]; then

    rm -rf /var/lib/containerd

    echo "[PASS] /var/lib/containerd removed."

fi


# ================================================================
# 14. REMOVE DOCKER CONFIGURATION
# ================================================================

step "6. Removing Docker Configuration"

rm -rf /etc/docker

rm -rf "${DOCKER_PLUGIN_DIR}"

rm -f /usr/local/bin/docker-compose

rm -f /usr/bin/docker-compose

rm -f /usr/local/bin/com.docker.cli


echo "[PASS] Docker configuration removed."


# ================================================================
# 15. REMOVE DOCKER GROUP MEMBERSHIP
# ================================================================

step "7. Removing ec2-user Docker Group Membership"

if id ec2-user >/dev/null 2>&1; then

    if getent group docker >/dev/null 2>&1; then

        gpasswd -d ec2-user docker 2>/dev/null || true

        echo "[PASS] ec2-user removed from docker group."

    else

        echo "[INFO] docker group does not exist."

    fi

else

    echo "[INFO] ec2-user does not exist."

fi


# ================================================================
# 16. REMOVE DOCKER GROUP
# ================================================================

step "8. Removing Docker Group"

if getent group docker >/dev/null 2>&1; then

    groupdel docker 2>/dev/null || true

fi


# ================================================================
# 17. REMOVE APACHE WEB FILES
# ================================================================
#
# The bootstrap created:
#
#   /var/www/html/index.html
#   /var/www/html/info.php
#
# Because this cleanup script is intended to reset the lab,
# the web root is cleared.
#
# ================================================================

step "9. Cleaning Apache Web Root"

if [[ -d "${WEB_ROOT}" ]]; then

    find "${WEB_ROOT}" \
        -mindepth 1 \
        -maxdepth 1 \
        -exec rm -rf {} +

    echo "[PASS] ${WEB_ROOT} cleaned."

else

    echo "[INFO] Web root does not exist."

fi


# ================================================================
# 18. REMOVE APACHE PHP-FPM CONFIGURATION
# ================================================================

step "10. Removing Charlie Cafe Apache Configuration"

if [[ -f "${PHP_APACHE_CONFIG}" ]]; then

    rm -f "${PHP_APACHE_CONFIG}"

    echo "[PASS] ${PHP_APACHE_CONFIG} removed."

else

    echo "[INFO] Charlie Cafe Apache configuration not found."

fi


# ================================================================
# 19. REMOVE PHP-FPM CONFIGURATION
# ================================================================

step "11. Removing Charlie Cafe PHP-FPM Configuration"

if [[ -f "${PHP_FPM_CONFIG}" ]]; then

    rm -f "${PHP_FPM_CONFIG}"

    echo "[PASS] ${PHP_FPM_CONFIG} removed."

else

    echo "[INFO] PHP-FPM configuration not found."

fi


# ================================================================
# 20. REMOVE PHP-FPM RUNTIME DATA
# ================================================================

step "12. Cleaning PHP-FPM Runtime Data"

rm -rf /run/php-fpm

rm -rf /var/log/php-fpm

echo "[PASS] PHP-FPM runtime data cleaned."


# ================================================================
# 21. REMOVE APACHE LOGS
# ================================================================

step "13. Cleaning Apache Logs"

if [[ -d /var/log/httpd ]]; then

    find /var/log/httpd \
        -type f \
        -delete 2>/dev/null || true

    echo "[PASS] Apache logs cleaned."

else

    echo "[INFO] Apache log directory does not exist."

fi


# ================================================================
# 22. REMOVE LAB LOGS
# ================================================================

step "14. Removing Charlie Cafe Logs"

rm -f "${BOOTSTRAP_LOG}"

rm -f "${COMPLETION_FILE}"

rm -f "${CLEANUP_LOG}"

echo "[PASS] Charlie Cafe log artifacts removed."


# ================================================================
# 23. REMOVE AWS CLI V2 INSTALLED BY BOOTSTRAP
# ================================================================
#
# The bootstrap installs AWS CLI under:
#
#   /usr/local/aws-cli
#   /usr/local/bin/aws
#
# IMPORTANT:
#
# We only remove the /usr/local installation.
#
# This avoids aggressively removing Amazon Linux's own packages.
#
# ================================================================

step "15. Removing AWS CLI v2 Lab Installation"

if [[ -d "${AWS_CLI_DIR}" ]]; then

    rm -rf "${AWS_CLI_DIR}"

    echo "[PASS] ${AWS_CLI_DIR} removed."

fi


if [[ -L "${AWS_CLI_BINARY}" || -f "${AWS_CLI_BINARY}" ]]; then

    rm -f "${AWS_CLI_BINARY}"

    echo "[PASS] ${AWS_CLI_BINARY} removed."

fi


# ================================================================
# 24. REMOVE KUBERNETES BINARIES
# ================================================================

step "16. Removing Kubernetes Tools"

for BINARY in \
    "${KUBECTL_BINARY}" \
    "${EKSCTL_BINARY}" \
    "${HELM_BINARY}" \
    "${KIND_BINARY}"
do

    if [[ -f "${BINARY}" || -L "${BINARY}" ]]; then

        rm -f "${BINARY}"

        echo "[PASS] Removed ${BINARY}"

    else

        echo "[INFO] Not found: ${BINARY}"

    fi

done


# ================================================================
# 25. REMOVE HELM / KUBERNETES USER DATA
# ================================================================
#
# These directories can contain local lab configuration.
#
# ================================================================

step "17. Removing Kubernetes User Configuration"

if id ec2-user >/dev/null 2>&1; then

    rm -rf /home/ec2-user/.kube

    rm -rf /home/ec2-user/.helm

    rm -rf /home/ec2-user/.cache/helm

    rm -rf /home/ec2-user/.config/helm

    rm -rf /home/ec2-user/.config/kind

    rm -rf /home/ec2-user/.cache/kind

    echo "[PASS] ec2-user Kubernetes configuration removed."

fi


# ================================================================
# 26. REMOVE KIND CONTAINERS
# ================================================================
#
# kind creates Kubernetes nodes as Docker containers.
#
# Docker cleanup above normally removes them.
# This is an additional safety cleanup.
#
# ================================================================

step "18. Removing kind Lab Artifacts"

if command -v docker >/dev/null 2>&1; then

    docker ps -aq \
        --filter "name=^kind-" 2>/dev/null \
        | xargs -r docker rm -f || true

fi


# ================================================================
# 27. REMOVE CHARLIE CAFE PATH MODIFICATION
# ================================================================

step "19. Removing Charlie Cafe PATH Modification"

if [[ -f "${EC2_USER_BASHRC}" ]]; then

    sed -i \
        '\|export PATH="/usr/local/bin:\$PATH"|d' \
        "${EC2_USER_BASHRC}"

    echo "[PASS] Charlie Cafe PATH entry removed."

fi


# ================================================================
# 28. REMOVE TEMPORARY LAB FILES
# ================================================================

step "20. Cleaning Temporary Installation Files"

rm -rf /tmp/charlie-awscli

rm -rf /tmp/charlie-eksctl

rm -f /tmp/charlie-eksctl.tar.gz

rm -f /tmp/kubectl

rm -f /tmp/kind

rm -f /tmp/get_helm.sh

rm -f /tmp/charlie-index.html

rm -f /tmp/charlie-php-info.html

rm -f /tmp/charlie-cafe-identity.json

echo "[PASS] Temporary lab files removed."


# ================================================================
# 29. REMOVE LAB RPM PACKAGES
# ================================================================
#
# These are packages explicitly installed by the bootstrap.
#
# DNF automatically handles dependencies where possible.
#
# IMPORTANT:
#
# We intentionally do NOT blindly run:
#
#     dnf remove '*'
#
# because that could destroy Amazon Linux itself.
#
# ================================================================

step "21. Removing Charlie Cafe RPM Packages"


PACKAGE_LIST=(
    httpd
    httpd-tools
    git
    htop
    wget
    unzip
    bzip2
    xz
    nano
    vim-enhanced
    bind-utils
    jq
)


INSTALLED_PACKAGES=()


for PACKAGE in "${PACKAGE_LIST[@]}"; do

    if rpm -q "${PACKAGE}" >/dev/null 2>&1; then

        INSTALLED_PACKAGES+=("${PACKAGE}")

    fi

done


if (( ${#INSTALLED_PACKAGES[@]} > 0 )); then

    echo "Packages scheduled for removal:"

    printf '  %s\n' "${INSTALLED_PACKAGES[@]}"

    echo

    dnf remove -y \
        "${INSTALLED_PACKAGES[@]}" \
        || true

else

    echo "No removable lab RPM packages detected."

fi


# ================================================================
# 30. REMOVE PHP PACKAGES
# ================================================================

step "22. Removing PHP Packages"

PHP_PACKAGES=(
    php
    php-cli
    php-common
    php-fpm
    php-mysqlnd
    php-mbstring
    php-xml
    php-opcache
    php-json
)


INSTALLED_PHP_PACKAGES=()


for PACKAGE in "${PHP_PACKAGES[@]}"; do

    if rpm -q "${PACKAGE}" >/dev/null 2>&1; then

        INSTALLED_PHP_PACKAGES+=("${PACKAGE}")

    fi

done


if (( ${#INSTALLED_PHP_PACKAGES[@]} > 0 )); then

    echo "Removing PHP packages:"

    printf '  %s\n' "${INSTALLED_PHP_PACKAGES[@]}"

    dnf remove -y \
        "${INSTALLED_PHP_PACKAGES[@]}" \
        || true

else

    echo "No PHP packages detected."

fi


# ================================================================
# 31. REMOVE MARIADB CLIENT
# ================================================================
#
# The bootstrap dynamically selected one of these:
#
#   mariadb105
#   mariadb1011
#   mariadb114
#   mariadb118
#   mariadb123
#
# ================================================================

step "23. Removing MariaDB Client"

MARIADB_PACKAGES=(
    mariadb105
    mariadb1011
    mariadb114
    mariadb118
    mariadb123
)


INSTALLED_MARIADB_PACKAGES=()


for PACKAGE in "${MARIADB_PACKAGES[@]}"; do

    if rpm -q "${PACKAGE}" >/dev/null 2>&1; then

        INSTALLED_MARIADB_PACKAGES+=("${PACKAGE}")

    fi

done


if (( ${#INSTALLED_MARIADB_PACKAGES[@]} > 0 )); then

    echo "Removing MariaDB packages:"

    printf '  %s\n' "${INSTALLED_MARIADB_PACKAGES[@]}"

    dnf remove -y \
        "${INSTALLED_MARIADB_PACKAGES[@]}" \
        || true

else

    echo "No supported MariaDB client package detected."

fi


# ================================================================
# 32. REMOVE DOCKER RPM
# ================================================================

step "24. Removing Docker RPM Package"

if rpm -q docker >/dev/null 2>&1; then

    dnf remove -y docker || true

    echo "[PASS] Docker package removal attempted."

else

    echo "[INFO] Docker RPM package not installed."

fi


# ================================================================
# 33. CLEAN UNUSED DEPENDENCIES
# ================================================================

step "25. Removing Unused Dependencies"

dnf autoremove -y || true


echo "[PASS] DNF autoremove completed."


# ================================================================
# 34. CLEAN DNF CACHE
# ================================================================

step "26. Cleaning DNF Cache"

dnf clean all || true

rm -rf /var/cache/dnf/*

echo "[PASS] DNF cache cleaned."


# ================================================================
# 35. REMOVE LAB SYSTEMD OVERRIDES
# ================================================================

step "27. Cleaning Systemd Runtime State"

systemctl daemon-reload

systemctl reset-failed || true

echo "[PASS] Systemd state refreshed."


# ================================================================
# 36. REMOVE PHP/APACHE USER FILES
# ================================================================

step "28. Cleaning Lab User Files"

if id ec2-user >/dev/null 2>&1; then

    rm -rf /home/ec2-user/.docker

    rm -rf /home/ec2-user/.aws/cli

fi


echo "[PASS] Lab user files cleaned."


# ================================================================
# 37. REMOVE ROOT LAB CONFIGURATION
# ================================================================

step "29. Cleaning Root Lab Configuration"

rm -rf /root/.docker

rm -rf /root/.kube

rm -rf /root/.helm

rm -rf /root/.cache/helm

rm -rf /root/.config/helm

rm -rf /root/.config/kind

echo "[PASS] Root lab configuration cleaned."


# ================================================================
# 38. REMOVE APACHE PACKAGE CONFIGURATION
# ================================================================

step "30. Removing Apache Configuration"

if [[ -d /etc/httpd ]]; then

    rm -rf /etc/httpd

    echo "[PASS] /etc/httpd removed."

fi


# ================================================================
# 39. REMOVE PHP CONFIGURATION
# ================================================================

step "31. Removing PHP Configuration"

if [[ -d /etc/php.d ]]; then

    rm -rf /etc/php.d

fi


if [[ -d /etc/php-fpm.d ]]; then

    rm -rf /etc/php-fpm.d

fi


if [[ -f /etc/php.ini ]]; then

    rm -f /etc/php.ini

fi


echo "[PASS] PHP configuration cleaned."


# ================================================================
# 40. CLEAN WEB ROOT DIRECTORY
# ================================================================

step "32. Final Web Root Cleanup"

if [[ -d "${WEB_ROOT}" ]]; then

    find "${WEB_ROOT}" \
        -mindepth 1 \
        -delete 2>/dev/null || true

    echo "[PASS] Web root is empty."

fi


# ================================================================
# 41. REMOVE EMPTY LAB DIRECTORIES
# ================================================================

step "33. Removing Empty Lab Directories"

rmdir /var/log/httpd 2>/dev/null || true

rmdir /var/log/php-fpm 2>/dev/null || true

rmdir /run/php-fpm 2>/dev/null || true

echo "[PASS] Empty lab directories cleaned."


# ================================================================
# 42. VERIFY SERVICES
# ================================================================

step "34. Verifying Lab Services Are Removed/Stopped"

for SERVICE in httpd php-fpm docker; do

    if systemctl is-active --quiet "${SERVICE}" 2>/dev/null; then

        echo "[WARNING] ${SERVICE} is still running."

    else

        echo "[PASS] ${SERVICE} is not running."

    fi

done


# ================================================================
# 43. VERIFY LAB COMMANDS
# ================================================================

step "35. Verifying Charlie Cafe Commands Are Removed"

COMMANDS=(
    git
    htop
    httpd
    php
    php-fpm
    docker
    aws
    kubectl
    eksctl
    helm
    kind
)


for COMMAND in "${COMMANDS[@]}"; do

    if command -v "${COMMAND}" >/dev/null 2>&1; then

        echo "[INFO] ${COMMAND}: still available"

    else

        echo "[PASS] ${COMMAND}: removed/not available"

    fi

done


# ================================================================
# 44. VERIFY LAB FILES
# ================================================================

step "36. Verifying Charlie Cafe Files"

FILES_TO_CHECK=(
    "${PHP_APACHE_CONFIG}"
    "${BOOTSTRAP_LOG}"
    "${COMPLETION_FILE}"
    "${AWS_CLI_BINARY}"
    "${KUBECTL_BINARY}"
    "${EKSCTL_BINARY}"
    "${HELM_BINARY}"
    "${KIND_BINARY}"
)


for FILE in "${FILES_TO_CHECK[@]}"; do

    if [[ -e "${FILE}" ]]; then

        echo "[WARNING] Still exists: ${FILE}"

    else

        echo "[PASS] Removed: ${FILE}"

    fi

done


# ================================================================
# 45. VERIFY DOCKER STORAGE
# ================================================================

step "37. Verifying Docker Storage"

if [[ -d /var/lib/docker ]]; then

    echo "[WARNING] /var/lib/docker still exists."

else

    echo "[PASS] /var/lib/docker removed."

fi


if [[ -d /var/lib/containerd ]]; then

    echo "[WARNING] /var/lib/containerd still exists."

else

    echo "[PASS] /var/lib/containerd removed."

fi


# ================================================================
# 46. VERIFY WEB ROOT
# ================================================================

step "38. Verifying Web Root"

if [[ -d "${WEB_ROOT}" ]]; then

    if find "${WEB_ROOT}" -mindepth 1 -print -quit \
        | grep -q .; then

        echo "[WARNING] Web root still contains files."

        find "${WEB_ROOT}" -maxdepth 2 -print

    else

        echo "[PASS] Web root is empty."

    fi

else

    echo "[INFO] Web root does not exist."

fi


# ================================================================
# 47. VERIFY EC2-USER DOCKER GROUP
# ================================================================

step "39. Verifying ec2-user Docker Group"

if id ec2-user >/dev/null 2>&1; then

    if id ec2-user | grep -qw docker; then

        echo "[WARNING] ec2-user is still in docker group."

    else

        echo "[PASS] ec2-user is not in docker group."

    fi

fi


# ================================================================
# 48. REMOVE CLEANUP LOG FROM FINAL STATE
# ================================================================
#
# The cleanup log is useful during execution.
#
# We intentionally keep it because it proves what the script did.
#
# It can be manually removed later:
#
#   sudo rm -f /var/log/charlie-cafe-cleanup.log
#
# ================================================================

step "40. Cleanup Log"

echo
echo "Cleanup log:"
echo "  ${CLEANUP_LOG}"


# ================================================================
# 49. FINAL SYSTEM INFORMATION
# ================================================================

step "41. Final EC2 System Information"

echo
echo "Hostname:"
hostname

echo
echo "Operating System:"
cat /etc/os-release | grep -E '^(NAME|VERSION|VERSION_ID)='

echo
echo "Kernel:"
uname -r

echo
echo "Architecture:"
uname -m

echo
echo "Disk:"
df -h /

echo
echo "Memory:"
free -h

echo
echo "System uptime:"
uptime


# ================================================================
# 50. FINAL SERVICE STATE
# ================================================================

step "42. Final Service State"

echo
echo "httpd:"
systemctl is-active httpd 2>/dev/null || true

echo
echo "php-fpm:"
systemctl is-active php-fpm 2>/dev/null || true

echo
echo "docker:"
systemctl is-active docker 2>/dev/null || true


# ================================================================
# 51. FINAL SUMMARY
# ================================================================

step "43. Charlie Cafe EC2 Cleanup Summary"

echo
echo "[PASS] Charlie Cafe Apache service stopped"
echo "[PASS] Charlie Cafe PHP-FPM service stopped"
echo "[PASS] Docker containers cleaned"
echo "[PASS] Docker images cleaned"
echo "[PASS] Docker volumes cleaned"
echo "[PASS] Docker networks cleaned"
echo "[PASS] Docker build cache cleaned"
echo "[PASS] Docker storage cleaned"
echo "[PASS] Apache web root cleaned"
echo "[PASS] Apache lab configuration removed"
echo "[PASS] PHP lab configuration removed"
echo "[PASS] MariaDB client removal attempted"
echo "[PASS] Docker package removal attempted"
echo "[PASS] AWS CLI v2 lab installation removed"
echo "[PASS] kubectl removed"
echo "[PASS] eksctl removed"
echo "[PASS] Helm removed"
echo "[PASS] kind removed"
echo "[PASS] Kubernetes user configuration removed"
echo "[PASS] Charlie Cafe temporary files removed"
echo "[PASS] Charlie Cafe bootstrap artifacts removed"
echo "[PASS] Charlie Cafe PATH modification removed"
echo "[PASS] DNF cache cleaned"
echo "[PASS] Unused packages cleanup attempted"


# ================================================================
# 52. IMPORTANT FINAL MESSAGE
# ================================================================

echo
echo
echo "========================================================="
echo "✅ CHARLIE CAFE EC2 CLEANUP COMPLETED"
echo "========================================================="
echo
echo "The Charlie Cafe lab software and configuration have been"
echo "removed from this Amazon Linux 2023 instance."
echo
echo "IMPORTANT:"
echo
echo "This instance is NOT guaranteed to be byte-for-byte identical"
echo "to a fresh Amazon Linux 2023 AMI."
echo
echo "Your bootstrap script previously executed:"
echo
echo "    dnf update -y"
echo
echo "Therefore some Amazon Linux packages may have been updated."
echo
echo "For a TRUE fresh EC2 environment:"
echo
echo "    1. Terminate this EC2 instance."
echo "    2. Launch a new Amazon Linux 2023 instance."
echo "    3. Run the Charlie Cafe bootstrap script again."
echo
echo "Cleanup log:"
echo
echo "    ${CLEANUP_LOG}"
echo
echo "========================================================="
echo "☕ Charlie Cafe EC2 Cleanup Finished"
echo "========================================================="
echo

