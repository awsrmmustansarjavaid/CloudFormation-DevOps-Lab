#!/bin/bash

# ==============================================================================
# GitHub ↔ EC2 Complete SSH + Git Setup, Clone and Verification Script
# ==============================================================================
#
# Purpose:
#   Configure an Amazon Linux 2023 EC2 instance to securely communicate with
#   a GitHub repository using SSH authentication.
#
# Main workflow:
#
#   EC2
#    |
#    | SSH authentication
#    v
#   GitHub
#    |
#    | git clone / git pull
#    v
#   Repository on EC2
#
# ------------------------------------------------------------------------------
# WHAT THIS SCRIPT DOES
# ------------------------------------------------------------------------------
#
#   1. Check Bash
#   2. Detect operating system
#   3. Detect current Linux user
#   4. Detect package manager
#   5. Install Git if required
#   6. Configure Git username
#   7. Configure Git email
#   8. Prepare ~/.ssh
#   9. Generate Ed25519 SSH key if required
#  10. Preserve existing SSH keys
#  11. Configure ~/.ssh/config
#  12. Configure GitHub known_hosts
#  13. Start ssh-agent
#  14. Add SSH private key to ssh-agent
#  15. Display public SSH key
#  16. Test Internet connectivity
#  17. Test GitHub SSH authentication
#  18. Retry SSH authentication after user adds key to GitHub
#  19. Test repository access
#  20. Clone repository if it does not exist
#  21. Pull repository if it already exists
#  22. Verify Git remote
#  23. Verify current branch
#  24. Verify working tree
#  25. Display recent commits
#  26. Check common DevOps files
#  27. Check disk space
#  28. Check AWS CLI
#  29. Check AWS identity
#  30. Check EC2 metadata
#  31. Generate detailed verification report
#  32. Display final summary
#
# ------------------------------------------------------------------------------
# IMPORTANT GITHUB SSH CONCEPT
# ------------------------------------------------------------------------------
#
# This script CAN generate an SSH key.
#
# This script CANNOT automatically register that public key in your GitHub
# account unless GitHub API credentials/token or another authenticated GitHub
# mechanism is supplied.
#
# Therefore the normal workflow is:
#
#   1. Script generates:
#
#        ~/.ssh/id_ed25519
#        ~/.ssh/id_ed25519.pub
#
#   2. Script displays:
#
#        ~/.ssh/id_ed25519.pub
#
#   3. YOU add that PUBLIC key to GitHub:
#
#        GitHub
#        → Settings
#        → SSH and GPG keys
#        → New SSH key
#
#   4. Script waits for you.
#
#   5. Press ENTER.
#
#   6. Script tests:
#
#        ssh -T git@github.com
#
#   7. If authentication succeeds:
#
#        git ls-remote
#
#        git clone
#
# ------------------------------------------------------------------------------
# SECURITY
# ------------------------------------------------------------------------------
#
# NEVER:
#
#   - upload ~/.ssh/id_ed25519
#   - commit ~/.ssh/id_ed25519
#   - put GitHub passwords in this script
#   - put GitHub PATs in this script
#   - commit AWS access keys
#   - commit .env files containing secrets
#
# ONLY the PUBLIC key:
#
#   ~/.ssh/id_ed25519.pub
#
# should be added to GitHub.
#
# ------------------------------------------------------------------------------
# EXAMPLE
# ------------------------------------------------------------------------------
#
#   GITHUB_USERNAME="awsrmmustansarjavaid" \
#   GITHUB_REPOSITORY="CloudFormation-DevOps-Lab" \
#   GITHUB_BRANCH="main" \
#   GIT_USER_NAME="awsrmmustansarjavaid" \
#   GIT_USER_EMAIL="aws.rmmustansarjavaid@gmail.com" \
#   ./github-ec2-setup.sh
#
# Or simply run:
#
#   ./github-ec2-setup.sh
#
# and enter the values interactively.
#
# ==============================================================================


# ==============================================================================
# 1. SAFETY SETTINGS
# ==============================================================================

set -Eeuo pipefail


# ==============================================================================
# 2. COLORS
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'


# ==============================================================================
# 3. CONFIGURATION
# ==============================================================================

# ------------------------------------------------------------------------------
# GitHub
# ------------------------------------------------------------------------------

GITHUB_USERNAME="${GITHUB_USERNAME:-}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"
GITHUB_HOST="${GITHUB_HOST:-github.com}"


# ------------------------------------------------------------------------------
# Git identity
# ------------------------------------------------------------------------------

GIT_USER_NAME="${GIT_USER_NAME:-}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"


# ------------------------------------------------------------------------------
# SSH
# ------------------------------------------------------------------------------

SSH_KEY_TYPE="${SSH_KEY_TYPE:-ed25519}"

SSH_KEY_NAME="${SSH_KEY_NAME:-id_ed25519}"

SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/$SSH_KEY_NAME}"

SSH_PUBLIC_KEY_PATH="${SSH_PUBLIC_KEY_PATH:-${SSH_KEY_PATH}.pub}"

SSH_CONFIG_FILE="${SSH_CONFIG_FILE:-$HOME/.ssh/config}"

SSH_KNOWN_HOSTS_FILE="${SSH_KNOWN_HOSTS_FILE:-$HOME/.ssh/known_hosts}"


# ------------------------------------------------------------------------------
# Repository
# ------------------------------------------------------------------------------

REPOSITORY_PARENT_DIR="${REPOSITORY_PARENT_DIR:-$HOME}"

REPOSITORY_DIR="${REPOSITORY_DIR:-}"


# ------------------------------------------------------------------------------
# Report
# ------------------------------------------------------------------------------

REPORT_DIR="${REPORT_DIR:-$HOME/github-ec2-reports}"

REPORT_FILE="${REPORT_FILE:-}"

RECENT_COMMITS="${RECENT_COMMITS:-5}"


# ------------------------------------------------------------------------------
# Behavior
# ------------------------------------------------------------------------------

AUTO_INSTALL_GIT="${AUTO_INSTALL_GIT:-true}"

AUTO_GENERATE_SSH_KEY="${AUTO_GENERATE_SSH_KEY:-true}"

AUTO_PULL="${AUTO_PULL:-true}"

CONFIRM_PULL="${CONFIRM_PULL:-false}"

# If SSH authentication fails, ask the user to add the key to GitHub and retry.
INTERACTIVE_SSH_SETUP="${INTERACTIVE_SSH_SETUP:-true}"


# ==============================================================================
# 4. RUNTIME VARIABLES
# ==============================================================================

SCRIPT_START_TIME="$(date '+%Y-%m-%d %H:%M:%S')"

CURRENT_USER="$(id -un)"

HOSTNAME_VALUE="$(hostname 2>/dev/null || echo "unknown")"

OS_NAME="Unknown"

OS_VERSION="Unknown"

PACKAGE_MANAGER=""

GIT_VERSION="Unknown"

AWS_REGION_VALUE="Unknown"

EC2_INSTANCE_ID="Unknown"

REPOSITORY_URL=""

SSH_TEST_RESULT="NOT TESTED"

REPOSITORY_TEST_RESULT="NOT TESTED"

CLONE_PULL_RESULT="NOT TESTED"

GIT_STATUS_RESULT="NOT TESTED"

OVERALL_STATUS="UNKNOWN"

SSH_AGENT_STARTED="false"


# ==============================================================================
# 5. RESULT COUNTERS
# ==============================================================================

PASS_COUNT=0

WARN_COUNT=0

FAIL_COUNT=0


# ==============================================================================
# 6. REPORT STORAGE
# ==============================================================================

declare -a REPORT_RESULTS=()


# ==============================================================================
# 7. LOGGING FUNCTIONS
# ==============================================================================

log_info() {

    echo -e "${BLUE}[INFO]${NC} $*"

}


log_success() {

    echo -e "${GREEN}[PASS]${NC} $*"

    PASS_COUNT=$((PASS_COUNT + 1))

}


log_warning() {

    echo -e "${YELLOW}[WARN]${NC} $*"

    WARN_COUNT=$((WARN_COUNT + 1))

}


log_error() {

    echo -e "${RED}[FAIL]${NC} $*"

    FAIL_COUNT=$((FAIL_COUNT + 1))

}


log_step() {

    echo

    echo -e "${CYAN}======================================================================${NC}"

    echo -e "${WHITE}$*${NC}"

    echo -e "${CYAN}======================================================================${NC}"

    echo

}


# ==============================================================================
# 8. ERROR HANDLER
# ==============================================================================
#
# IMPORTANT:
#
# The previous version of your script had a major logic problem.
#
# A function such as:
#
#     test_github_ssh
#
# could intentionally return 1 when GitHub authentication failed.
#
# But because:
#
#     set -e
#
# was enabled, Bash could trigger the ERR trap and report:
#
#     UNEXPECTED SCRIPT ERROR
#
# This version only uses the ERR trap for genuinely unhandled failures.
#
# Expected failures are handled with:
#
#     if ! command; then
#
# or:
#
#     command || true
#
# ==============================================================================

error_handler() {

    local exit_code=$?

    local line_number="${1:-unknown}"

    echo

    echo -e "${RED}======================================================================${NC}"

    echo -e "${RED}UNEXPECTED SCRIPT ERROR${NC}"

    echo -e "${RED}======================================================================${NC}"

    echo "Exit code : $exit_code"

    echo "Line      : $line_number"

    echo

    echo "The script encountered an unexpected error."

    echo "Review the generated report if available."

    echo


    REPORT_RESULTS+=(
        "FAIL | Unexpected script error | line=$line_number exit_code=$exit_code"
    )

    OVERALL_STATUS="FAILED"


    # Do not recursively trigger the ERR trap.
    trap - ERR


    return "$exit_code"

}


trap 'error_handler "$LINENO"' ERR


# ==============================================================================
# 9. COMMAND CHECK
# ==============================================================================

command_exists() {

    command -v "$1" >/dev/null 2>&1

}


# ==============================================================================
# 10. CHECK BASH
# ==============================================================================

check_bash_version() {

    log_step "Checking Bash Version"

    log_info "Bash version: ${BASH_VERSION}"

    REPORT_RESULTS+=(
        "PASS | Bash | ${BASH_VERSION}"
    )

}


# ==============================================================================
# 11. DETECT OPERATING SYSTEM
# ==============================================================================

detect_operating_system() {

    log_step "Detecting Operating System"


    if [[ -f /etc/os-release ]]; then

        # shellcheck disable=SC1091
        source /etc/os-release

        OS_NAME="${NAME:-Unknown}"

        OS_VERSION="${VERSION:-Unknown}"


        log_success "Operating system detected."

        log_info "OS Name   : $OS_NAME"

        log_info "OS Version: $OS_VERSION"


        REPORT_RESULTS+=(
            "PASS | Operating system | $OS_NAME"
        )

    else

        log_warning "/etc/os-release was not found."

        REPORT_RESULTS+=(
            "WARN | Operating system | /etc/os-release unavailable"
        )

    fi

}


# ==============================================================================
# 12. CHECK CURRENT USER
# ==============================================================================

check_current_user() {

    log_step "Checking Current Linux User"

    log_info "Current user: $CURRENT_USER"

    log_info "Home       : $HOME"


    if [[ "$CURRENT_USER" == "root" ]]; then

        log_warning "Script is running as root."

        log_warning "For normal EC2 usage, ec2-user is recommended."


        REPORT_RESULTS+=(
            "WARN | Linux user | Running as root"
        )

    else

        log_success "Running as normal Linux user."


        REPORT_RESULTS+=(
            "PASS | Linux user | $CURRENT_USER"
        )

    fi

}


# ==============================================================================
# 13. CHECK PACKAGE MANAGER
# ==============================================================================

check_package_manager() {

    log_step "Detecting Package Manager"


    if command_exists dnf; then

        PACKAGE_MANAGER="dnf"

    elif command_exists yum; then

        PACKAGE_MANAGER="yum"

    elif command_exists apt-get; then

        PACKAGE_MANAGER="apt-get"

    else

        log_error "No supported package manager was found."

        REPORT_RESULTS+=(
            "FAIL | Package manager | Not detected"
        )

        return 1

    fi


    log_success "Package manager: $PACKAGE_MANAGER"


    REPORT_RESULTS+=(
        "PASS | Package manager | $PACKAGE_MANAGER"
    )

}


# ==============================================================================
# 14. INSTALL GIT
# ==============================================================================

install_git_if_required() {

    log_step "Checking Git Installation"


    if command_exists git; then

        GIT_VERSION="$(git --version)"

        log_success "Git is already installed."

        log_info "$GIT_VERSION"


        REPORT_RESULTS+=(
            "PASS | Git | $GIT_VERSION"
        )

        return 0

    fi


    log_warning "Git is not installed."


    if [[ "$AUTO_INSTALL_GIT" != "true" ]]; then

        log_error "AUTO_INSTALL_GIT=false."

        REPORT_RESULTS+=(
            "FAIL | Git | Missing and automatic installation disabled"
        )

        return 1

    fi


    log_info "Installing Git..."


    case "$PACKAGE_MANAGER" in

        dnf)

            if ! sudo dnf install -y git; then

                log_error "dnf could not install Git."

                return 1

            fi

            ;;

        yum)

            if ! sudo yum install -y git; then

                log_error "yum could not install Git."

                return 1

            fi

            ;;

        apt-get)

            if ! sudo apt-get update; then

                log_error "apt-get update failed."

                return 1

            fi

            if ! sudo apt-get install -y git; then

                log_error "apt-get could not install Git."

                return 1

            fi

            ;;

        *)

            log_error "Unsupported package manager."

            return 1

            ;;

    esac


    if command_exists git; then

        GIT_VERSION="$(git --version)"

        log_success "Git installed successfully."

        log_info "$GIT_VERSION"


        REPORT_RESULTS+=(
            "PASS | Git | Installed successfully"
        )

    else

        log_error "Git installation failed."

        REPORT_RESULTS+=(
            "FAIL | Git | Installation failed"
        )

        return 1

    fi

}


# ==============================================================================
# 15. COLLECT CONFIGURATION
# ==============================================================================

collect_configuration() {

    log_step "Collecting Configuration"


    if [[ -z "$GITHUB_USERNAME" ]]; then

        read -r -p "Enter GitHub username: " GITHUB_USERNAME

    fi


    if [[ -z "$GITHUB_REPOSITORY" ]]; then

        read -r -p "Enter GitHub repository name: " GITHUB_REPOSITORY

    fi


    if [[ -z "$GITHUB_BRANCH" ]]; then

        read -r -p "Enter GitHub branch [main]: " GITHUB_BRANCH

        GITHUB_BRANCH="${GITHUB_BRANCH:-main}"

    fi


    if [[ -z "$GIT_USER_NAME" ]]; then

        read -r -p "Enter Git user name: " GIT_USER_NAME

    fi


    if [[ -z "$GIT_USER_EMAIL" ]]; then

        read -r -p "Enter Git email: " GIT_USER_EMAIL

    fi


    if [[ -z "$GITHUB_USERNAME" ]]; then

        log_error "GitHub username cannot be empty."

        return 1

    fi


    if [[ -z "$GITHUB_REPOSITORY" ]]; then

        log_error "GitHub repository cannot be empty."

        return 1

    fi


    if [[ -z "$GITHUB_BRANCH" ]]; then

        log_error "GitHub branch cannot be empty."

        return 1

    fi


    if [[ -z "$GIT_USER_NAME" ]]; then

        log_error "Git user name cannot be empty."

        return 1

    fi


    if [[ -z "$GIT_USER_EMAIL" ]]; then

        log_error "Git email cannot be empty."

        return 1

    fi


    REPOSITORY_URL="git@${GITHUB_HOST}:${GITHUB_USERNAME}/${GITHUB_REPOSITORY}.git"


    if [[ -z "$REPOSITORY_DIR" ]]; then

        REPOSITORY_DIR="${REPOSITORY_PARENT_DIR}/${GITHUB_REPOSITORY}"

    fi


    if [[ -z "$REPORT_FILE" ]]; then

        REPORT_FILE="${REPORT_DIR}/github-ec2-report-$(date '+%Y%m%d-%H%M%S').txt"

    fi


    echo

    log_info "GitHub username  : $GITHUB_USERNAME"

    log_info "GitHub repository: $GITHUB_REPOSITORY"

    log_info "GitHub branch    : $GITHUB_BRANCH"

    log_info "GitHub host      : $GITHUB_HOST"

    log_info "Repository URL   : $REPOSITORY_URL"

    log_info "Repository dir   : $REPOSITORY_DIR"

    log_info "Git user name    : $GIT_USER_NAME"

    log_info "Git user email   : $GIT_USER_EMAIL"

    log_info "Report file      : $REPORT_FILE"

}


# ==============================================================================
# 16. CONFIGURE GIT IDENTITY
# ==============================================================================

configure_git_identity() {

    log_step "Configuring Git Identity"


    git config --global user.name "$GIT_USER_NAME"

    git config --global user.email "$GIT_USER_EMAIL"


    log_success "Git user.name configured."

    log_success "Git user.email configured."


    REPORT_RESULTS+=(
        "PASS | Git user.name | $GIT_USER_NAME"
        "PASS | Git user.email | $GIT_USER_EMAIL"
    )

}


# ==============================================================================
# 17. VERIFY GIT CONFIGURATION
# ==============================================================================

verify_git_configuration() {

    log_step "Verifying Git Configuration"


    local configured_name

    local configured_email


    configured_name="$(git config --global user.name 2>/dev/null || true)"

    configured_email="$(git config --global user.email 2>/dev/null || true)"


    log_info "Configured Git user.name : $configured_name"

    log_info "Configured Git email     : $configured_email"


    if [[ "$configured_name" == "$GIT_USER_NAME" ]]; then

        log_success "Git user.name is correct."

        REPORT_RESULTS+=(
            "PASS | Git user.name verification | Correct"
        )

    else

        log_error "Git user.name is incorrect."

        REPORT_RESULTS+=(
            "FAIL | Git user.name verification | Incorrect"
        )

    fi


    if [[ "$configured_email" == "$GIT_USER_EMAIL" ]]; then

        log_success "Git user.email is correct."

        REPORT_RESULTS+=(
            "PASS | Git user.email verification | Correct"
        )

    else

        log_error "Git user.email is incorrect."

        REPORT_RESULTS+=(
            "FAIL | Git user.email verification | Incorrect"
        )

    fi

}


# ==============================================================================
# 18. PREPARE SSH DIRECTORY
# ==============================================================================

prepare_ssh_directory() {

    log_step "Preparing SSH Directory"


    mkdir -p "$HOME/.ssh"

    chmod 700 "$HOME/.ssh"


    touch "$SSH_CONFIG_FILE"

    touch "$SSH_KNOWN_HOSTS_FILE"


    chmod 600 "$SSH_CONFIG_FILE"

    chmod 600 "$SSH_KNOWN_HOSTS_FILE"


    log_success "SSH directory prepared."


    REPORT_RESULTS+=(
        "PASS | SSH directory | $HOME/.ssh"
    )

}


# ==============================================================================
# 19. GENERATE SSH KEY
# ==============================================================================

generate_ssh_key_if_required() {

    log_step "Checking SSH Key"


    # --------------------------------------------------------------------------
    # Existing complete key pair.
    # --------------------------------------------------------------------------

    if [[ -f "$SSH_KEY_PATH" && -f "$SSH_PUBLIC_KEY_PATH" ]]; then

        log_success "Existing SSH key detected."

        log_info "Private key: $SSH_KEY_PATH"

        log_info "Public key : $SSH_PUBLIC_KEY_PATH"


        REPORT_RESULTS+=(
            "PASS | SSH key | Existing key detected"
        )

        return 0

    fi


    # --------------------------------------------------------------------------
    # Incomplete key pair.
    # --------------------------------------------------------------------------

    if [[ -f "$SSH_KEY_PATH" && ! -f "$SSH_PUBLIC_KEY_PATH" ]]; then

        log_warning "Private key exists but public key is missing."

        log_info "Generating public key from existing private key."


        if ssh-keygen -y -f "$SSH_KEY_PATH" > "$SSH_PUBLIC_KEY_PATH"; then

            chmod 644 "$SSH_PUBLIC_KEY_PATH"

            log_success "Public key regenerated."

            REPORT_RESULTS+=(
                "PASS | SSH public key | Regenerated from private key"
            )

            return 0

        else

            log_error "Could not regenerate public key."

            REPORT_RESULTS+=(
                "FAIL | SSH public key | Regeneration failed"
            )

            return 1

        fi

    fi


    # --------------------------------------------------------------------------
    # Generate new key.
    # --------------------------------------------------------------------------

    if [[ "$AUTO_GENERATE_SSH_KEY" != "true" ]]; then

        log_error "SSH key missing and automatic generation disabled."

        REPORT_RESULTS+=(
            "FAIL | SSH key | Missing"
        )

        return 1

    fi


    log_info "No SSH key found."

    log_info "Generating Ed25519 SSH key..."


    if ssh-keygen \
        -t "$SSH_KEY_TYPE" \
        -C "$GIT_USER_EMAIL" \
        -f "$SSH_KEY_PATH" \
        -N ""; then

        log_success "SSH key generated."

        REPORT_RESULTS+=(
            "PASS | SSH key | New Ed25519 key generated"
        )

    else

        log_error "SSH key generation failed."

        REPORT_RESULTS+=(
            "FAIL | SSH key | Generation failed"
        )

        return 1

    fi

}


# ==============================================================================
# 20. FIX SSH PERMISSIONS
# ==============================================================================

fix_ssh_permissions() {

    log_step "Fixing SSH Permissions"


    chmod 700 "$HOME/.ssh"

    chmod 600 "$SSH_KEY_PATH"

    chmod 644 "$SSH_PUBLIC_KEY_PATH"

    chmod 600 "$SSH_CONFIG_FILE"

    chmod 600 "$SSH_KNOWN_HOSTS_FILE"


    log_success "SSH permissions configured."


    REPORT_RESULTS+=(
        "PASS | SSH permissions | Correct permissions applied"
    )

}


# ==============================================================================
# 21. CONFIGURE SSH CONFIG
# ==============================================================================

configure_github_ssh() {

    log_step "Configuring SSH for GitHub"


    local temp_config

    temp_config="$(mktemp)"


    # --------------------------------------------------------------------------
    # Remove only the configuration block created by this script.
    #
    # Existing user SSH configuration outside this block is preserved.
    # --------------------------------------------------------------------------

    awk '
        BEGIN { skip=0 }

        /^# BEGIN GITHUB-EC2-SETUP$/ {
            skip=1
            next
        }

        /^# END GITHUB-EC2-SETUP$/ {
            skip=0
            next
        }

        skip == 0 {
            print
        }
    ' "$SSH_CONFIG_FILE" > "$temp_config"


    mv "$temp_config" "$SSH_CONFIG_FILE"


    cat >> "$SSH_CONFIG_FILE" <<EOF

# BEGIN GITHUB-EC2-SETUP
# Managed by github-ec2-setup.sh

Host ${GITHUB_HOST}
    HostName ${GITHUB_HOST}
    User git
    IdentityFile ${SSH_KEY_PATH}
    IdentitiesOnly yes
    AddKeysToAgent yes
    StrictHostKeyChecking accept-new

# END GITHUB-EC2-SETUP

EOF


    chmod 600 "$SSH_CONFIG_FILE"


    log_success "GitHub SSH configuration created."


    REPORT_RESULTS+=(
        "PASS | SSH configuration | $SSH_CONFIG_FILE"
    )

}


# ==============================================================================
# 22. CONFIGURE GITHUB KNOWN HOSTS
# ==============================================================================

configure_github_known_hosts() {

    log_step "Configuring GitHub Known Hosts"


    if ! command_exists ssh-keyscan; then

        log_warning "ssh-keyscan is unavailable."

        REPORT_RESULTS+=(
            "WARN | known_hosts | ssh-keyscan unavailable"
        )

        return 0

    fi


    # --------------------------------------------------------------------------
    # Avoid duplicate github.com entries.
    #
    # We do not remove the user's complete known_hosts file.
    # --------------------------------------------------------------------------

    touch "$SSH_KNOWN_HOSTS_FILE"

    chmod 600 "$SSH_KNOWN_HOSTS_FILE"


    if ! grep -qE "^${GITHUB_HOST}[[:space:]]" "$SSH_KNOWN_HOSTS_FILE" 2>/dev/null; then

        log_info "Adding GitHub host key to known_hosts."


        if ssh-keyscan \
            -H \
            "$GITHUB_HOST" \
            >> "$SSH_KNOWN_HOSTS_FILE" 2>/dev/null; then

            log_success "GitHub host key added."

            REPORT_RESULTS+=(
                "PASS | known_hosts | GitHub host added"
            )

        else

            log_warning "Could not retrieve GitHub host key."

            REPORT_RESULTS+=(
                "WARN | known_hosts | GitHub host key unavailable"
            )

        fi

    else

        log_success "GitHub already exists in known_hosts."

        REPORT_RESULTS+=(
            "PASS | known_hosts | GitHub already configured"
        )

    fi

}


# ==============================================================================
# 23. START SSH AGENT
# ==============================================================================

start_ssh_agent() {

    log_step "Starting SSH Agent"


    # --------------------------------------------------------------------------
    # If an agent is already available, use it.
    # --------------------------------------------------------------------------

    if [[ -n "${SSH_AUTH_SOCK:-}" ]] &&
       [[ -S "${SSH_AUTH_SOCK:-}" ]]; then

        log_info "Existing SSH agent detected."

    else

        log_info "Starting a new SSH agent."


        local agent_output

        agent_output="$(ssh-agent -s)"


        # ----------------------------------------------------------------------
        # Export SSH agent variables into current shell.
        # ----------------------------------------------------------------------

        eval "$agent_output" >/dev/null


        SSH_AGENT_STARTED="true"


        log_success "SSH agent started."

    fi


    # --------------------------------------------------------------------------
    # Make sure the key is loaded.
    # --------------------------------------------------------------------------

    if ssh-add -l >/dev/null 2>&1; then

        log_info "SSH agent already contains one or more keys."

    else

        log_info "SSH agent currently has no loaded keys."

    fi


    # --------------------------------------------------------------------------
    # Calculate fingerprint of our key.
    # --------------------------------------------------------------------------

    local key_fingerprint

    key_fingerprint="$(
        ssh-keygen -lf "$SSH_PUBLIC_KEY_PATH" 2>/dev/null |
        awk '{print $2}' |
        head -n 1
    )"


    if [[ -z "$key_fingerprint" ]]; then

        log_error "Could not calculate SSH key fingerprint."

        return 1

    fi


    # --------------------------------------------------------------------------
    # Check whether OUR exact key is already loaded.
    #
    # The old script incorrectly searched ssh-add -l output for:
    #
    #     /home/ec2-user/.ssh/id_ed25519
    #
    # However, ssh-add -l normally displays the fingerprint, not the file path.
    #
    # This version compares fingerprints correctly.
    # --------------------------------------------------------------------------

    if ssh-add -l 2>/dev/null |
        grep -Fq "$key_fingerprint"; then

        log_success "Required SSH key is already loaded."

    else

        log_info "Adding SSH key to ssh-agent."


        if ssh-add "$SSH_KEY_PATH"; then

            log_success "SSH private key added to ssh-agent."

        else

            log_error "Could not add SSH private key to ssh-agent."

            return 1

        fi

    fi


    REPORT_RESULTS+=(
        "PASS | SSH agent | Required SSH key loaded"
    )

}


# ==============================================================================
# 24. DISPLAY PUBLIC KEY
# ==============================================================================

display_public_key() {

    log_step "GitHub Public SSH Key"


    if [[ ! -f "$SSH_PUBLIC_KEY_PATH" ]]; then

        log_error "Public SSH key not found."

        REPORT_RESULTS+=(
            "FAIL | Public SSH key | Missing"
        )

        return 1

    fi


    echo

    echo -e "${MAGENTA}----------------------------------------------------------------------${NC}"

    echo -e "${WHITE}COPY THIS PUBLIC KEY TO GITHUB:${NC}"

    echo -e "${MAGENTA}----------------------------------------------------------------------${NC}"

    cat "$SSH_PUBLIC_KEY_PATH"

    echo -e "${MAGENTA}----------------------------------------------------------------------${NC}"

    echo


    log_warning "GitHub → Settings → SSH and GPG keys → New SSH key"

    log_warning "Title example: Charlie Cafe EC2"

    log_warning "Key type: Authentication Key"

    log_warning "Only copy the .pub public key."

    log_warning "NEVER upload the private key."

    echo


    REPORT_RESULTS+=(
        "PASS | Public SSH key | Displayed"
    )

}


# ==============================================================================
# 25. TEST GITHUB HTTPS CONNECTIVITY
# ==============================================================================

test_github_network() {

    log_step "Testing GitHub HTTPS Connectivity"


    if ! command_exists curl; then

        log_warning "curl is not installed."

        REPORT_RESULTS+=(
            "WARN | GitHub HTTPS | curl unavailable"
        )

        return 0

    fi


    if curl \
        --silent \
        --show-error \
        --fail \
        --connect-timeout 10 \
        --max-time 15 \
        "https://${GITHUB_HOST}" \
        >/dev/null; then

        log_success "HTTPS connectivity to GitHub is working."

        REPORT_RESULTS+=(
            "PASS | GitHub HTTPS | Connectivity successful"
        )

    else

        log_error "HTTPS connectivity to GitHub failed."

        REPORT_RESULTS+=(
            "FAIL | GitHub HTTPS | Connectivity failed"
        )

        return 1

    fi

}


# ==============================================================================
# 26. TEST GITHUB SSH AUTHENTICATION
# ==============================================================================
#
# IMPORTANT:
#
# GitHub's:
#
#     ssh -T git@github.com
#
# commonly exits with code 1 even after successful authentication because
# GitHub does not provide an interactive shell.
#
# Therefore:
#
#     exit code alone is NOT enough.
#
# We inspect the actual response.
#
# ==============================================================================

test_github_ssh() {

    log_step "Testing EC2 → GitHub SSH Authentication"


    local ssh_output=""

    local ssh_exit_code=0


    ssh_output="$(
        ssh \
            -T \
            -o BatchMode=yes \
            -o ConnectTimeout=10 \
            -o ConnectionAttempts=1 \
            -o StrictHostKeyChecking=accept-new \
            "git@${GITHUB_HOST}" \
            2>&1
    )" || ssh_exit_code=$?


    echo "$ssh_output"


    # --------------------------------------------------------------------------
    # SUCCESS CONDITION
    # --------------------------------------------------------------------------
    #
    # GitHub normally returns:
    #
    #   Hi USERNAME! You've successfully authenticated...
    #
    # --------------------------------------------------------------------------

    if echo "$ssh_output" |
        grep -Eqi "successfully authenticated|Hi ${GITHUB_USERNAME}"; then

        SSH_TEST_RESULT="PASS"


        log_success "GitHub SSH authentication succeeded."


        REPORT_RESULTS+=(
            "PASS | GitHub SSH authentication | Successful"
        )


        return 0

    fi


    # --------------------------------------------------------------------------
    # FAILURE CONDITION
    # --------------------------------------------------------------------------

    SSH_TEST_RESULT="FAIL"


    log_error "GitHub SSH authentication failed."


    echo

    echo -e "${YELLOW}SSH diagnostic output:${NC}"

    echo "$ssh_output"

    echo


    REPORT_RESULTS+=(
        "FAIL | GitHub SSH authentication | Failed exit_code=$ssh_exit_code"
    )


    return 1

}


# ==============================================================================
# 27. INTERACTIVE GITHUB KEY REGISTRATION
# ==============================================================================

setup_github_key_interactively() {

    log_step "GitHub SSH Key Registration"


    echo -e "${WHITE}The EC2 SSH key has been generated successfully.${NC}"

    echo

    echo "Your public key is located at:"

    echo

    echo "  $SSH_PUBLIC_KEY_PATH"

    echo


    echo -e "${YELLOW}IMPORTANT:${NC}"

    echo "The public key must be added to GitHub before GitHub will"
    echo "allow this EC2 instance to authenticate."

    echo

    echo "GitHub steps:"

    echo "  1. Sign in to GitHub."

    echo "  2. Open:"
    echo "       Settings"

    echo "  3. Open:"
    echo "       SSH and GPG keys"

    echo "  4. Click:"
    echo "       New SSH key"

    echo "  5. Title:"
    echo "       Charlie Cafe EC2"

    echo "  6. Key type:"
    echo "       Authentication Key"

    echo "  7. Paste the PUBLIC key shown above."

    echo "  8. Save the key."

    echo


    if [[ "$INTERACTIVE_SSH_SETUP" != "true" ]]; then

        log_warning "Interactive SSH setup disabled."

        return 1

    fi


    read -r -p "Press ENTER after adding the public key to GitHub, or Ctrl+C to cancel: " _


    echo

    log_info "Testing GitHub SSH authentication again..."


    if test_github_ssh; then

        log_success "GitHub SSH authentication is now working."

        return 0

    fi


    log_error "GitHub still rejected the SSH key."

    echo

    echo "Possible reasons:"

    echo "  1. Public key was not added to GitHub."

    echo "  2. Wrong GitHub account was used."

    echo "  3. Key was pasted incorrectly."

    echo "  4. The GitHub SSH key was deleted/disabled."

    echo "  5. SSH is using a different key."

    echo "  6. Repository belongs to an organization with additional restrictions."

    echo


    return 1

}


# ==============================================================================
# 28. DISPLAY SSH DIAGNOSTICS
# ==============================================================================

display_ssh_diagnostics() {

    log_step "SSH Diagnostics"


    echo "SSH configuration file:"
    echo "  $SSH_CONFIG_FILE"

    echo

    echo "SSH private key:"
    echo "  $SSH_KEY_PATH"

    echo

    echo "SSH public key:"
    echo "  $SSH_PUBLIC_KEY_PATH"

    echo


    echo "Loaded SSH keys:"

    ssh-add -l 2>/dev/null || echo "  No keys loaded."


    echo

    echo "SSH configuration used for GitHub:"

    ssh -G "git@${GITHUB_HOST}" 2>/dev/null |
        grep -E "^(user|hostname|identityfile|identitiesonly|addkeystoagent)" ||
        true


    echo


    REPORT_RESULTS+=(
        "INFO | SSH diagnostics | Configuration and loaded keys displayed"
    )

}


# ==============================================================================
# 29. TEST REPOSITORY ACCESS
# ==============================================================================

test_repository_access() {

    log_step "Testing GitHub Repository Access"


    local remote_output=""

    local remote_exit_code=0


    remote_output="$(
        git ls-remote "$REPOSITORY_URL" 2>&1
    )" || remote_exit_code=$?


    # --------------------------------------------------------------------------
    # git ls-remote returns exit code 0 when the repository is accessible.
    #
    # The repository can technically be empty, so we should NOT require
    # refs/heads/ to exist.
    # --------------------------------------------------------------------------

    if [[ "$remote_exit_code" -eq 0 ]]; then

        REPOSITORY_TEST_RESULT="PASS"


        if [[ -n "$remote_output" ]]; then

            log_success "GitHub repository is accessible."

            echo

            echo "Remote references:"

            echo "$remote_output" | head -n 10

            echo

        else

            log_success "GitHub repository is accessible but appears empty."

        fi


        REPORT_RESULTS+=(
            "PASS | Repository access | $REPOSITORY_URL"
        )


        return 0

    fi


    REPOSITORY_TEST_RESULT="FAIL"


    log_error "Repository could not be accessed."

    echo

    echo "$remote_output"

    echo


    REPORT_RESULTS+=(
        "FAIL | Repository access | Failed exit_code=$remote_exit_code"
    )


    return 1

}


# ==============================================================================
# 30. CLONE REPOSITORY
# ==============================================================================

clone_repository() {

    log_step "Cloning GitHub Repository"


    # --------------------------------------------------------------------------
    # Parent directory.
    # --------------------------------------------------------------------------

    mkdir -p "$REPOSITORY_PARENT_DIR"


    # --------------------------------------------------------------------------
    # Repository directory does not exist.
    # --------------------------------------------------------------------------

    if [[ ! -e "$REPOSITORY_DIR" ]]; then

        log_info "Repository directory does not exist."

        log_info "Repository will be cloned to:"

        echo "  $REPOSITORY_DIR"

        echo


        # ----------------------------------------------------------------------
        # First verify that requested branch exists.
        # ----------------------------------------------------------------------

        local branch_check=""

        local branch_exit_code=0


        branch_check="$(
            git ls-remote \
                --heads \
                "$REPOSITORY_URL" \
                "refs/heads/${GITHUB_BRANCH}" \
                2>&1
        )" || branch_exit_code=$?


        if [[ "$branch_exit_code" -ne 0 ]]; then

            log_error "Could not verify GitHub branch."

            echo "$branch_check"

            REPORT_RESULTS+=(
                "FAIL | Git branch check | Unable to verify $GITHUB_BRANCH"
            )

            return 1

        fi


        if [[ -z "$branch_check" ]]; then

            log_error "Branch '$GITHUB_BRANCH' does not exist on GitHub."

            log_error "Check the branch name."

            REPORT_RESULTS+=(
                "FAIL | Git branch check | Branch $GITHUB_BRANCH does not exist"
            )

            return 1

        fi


        # ----------------------------------------------------------------------
        # Clone.
        # ----------------------------------------------------------------------

        log_info "Cloning branch: $GITHUB_BRANCH"


        if git clone \
            --branch "$GITHUB_BRANCH" \
            --single-branch \
            "$REPOSITORY_URL" \
            "$REPOSITORY_DIR"; then

            CLONE_PULL_RESULT="PASS"


            log_success "Repository cloned successfully."


            REPORT_RESULTS+=(
                "PASS | Repository clone | $REPOSITORY_DIR"
            )


            return 0

        else

            CLONE_PULL_RESULT="FAIL"


            log_error "Repository clone failed."


            REPORT_RESULTS+=(
                "FAIL | Repository clone | Failed"
            )


            return 1

        fi

    fi


    # --------------------------------------------------------------------------
    # Existing path is not a directory.
    # --------------------------------------------------------------------------

    if [[ ! -d "$REPOSITORY_DIR" ]]; then

        log_error "Target repository path exists but is not a directory."

        log_error "Path: $REPOSITORY_DIR"


        REPORT_RESULTS+=(
            "FAIL | Repository directory | Path is not a directory"
        )


        return 1

    fi


    # --------------------------------------------------------------------------
    # Existing directory but not Git repository.
    #
    # IMPORTANT:
    # We NEVER delete the directory automatically.
    # --------------------------------------------------------------------------

    if [[ ! -d "$REPOSITORY_DIR/.git" ]]; then

        log_error "Target directory already exists but is not a Git repository."

        log_error "Directory: $REPOSITORY_DIR"

        log_error "For safety, the script will NOT delete it."


        REPORT_RESULTS+=(
            "FAIL | Repository directory | Existing directory is not Git repository"
        )


        return 1

    fi


    # --------------------------------------------------------------------------
    # Existing Git repository.
    # --------------------------------------------------------------------------

    log_info "Existing Git repository detected."


    if ! cd "$REPOSITORY_DIR"; then

        log_error "Could not enter repository directory."

        return 1

    fi


    # --------------------------------------------------------------------------
    # Check origin.
    # --------------------------------------------------------------------------

    local existing_origin

    existing_origin="$(git remote get-url origin 2>/dev/null || true)"


    if [[ -z "$existing_origin" ]]; then

        log_warning "Git remote 'origin' does not exist."

        log_info "Adding expected origin."

        git remote add origin "$REPOSITORY_URL"

        existing_origin="$REPOSITORY_URL"


        log_success "origin remote added."


    else

        log_info "Existing origin: $existing_origin"

    fi


    # --------------------------------------------------------------------------
    # If origin points somewhere else, do NOT silently overwrite it.
    # --------------------------------------------------------------------------

    if [[ "$existing_origin" != "$REPOSITORY_URL" ]]; then

        log_error "Existing origin does not match expected repository."

        log_error "Expected: $REPOSITORY_URL"

        log_error "Actual  : $existing_origin"


        REPORT_RESULTS+=(
            "FAIL | Git remote | Existing origin differs"
        )


        return 1

    fi


    # --------------------------------------------------------------------------
    # Pull latest changes.
    # --------------------------------------------------------------------------

    if [[ "$AUTO_PULL" != "true" ]]; then

        log_warning "AUTO_PULL=false. Pull skipped."

        CLONE_PULL_RESULT="WARN"


        REPORT_RESULTS+=(
            "WARN | Repository pull | Disabled"
        )


        return 0

    fi


    if [[ "$CONFIRM_PULL" == "true" ]]; then

        local answer


        read -r -p \
            "Pull latest changes from origin/${GITHUB_BRANCH}? [y/N]: " \
            answer


        if [[ ! "$answer" =~ ^[Yy]$ ]]; then

            log_warning "Pull cancelled by user."

            CLONE_PULL_RESULT="WARN"


            REPORT_RESULTS+=(
                "WARN | Repository pull | Cancelled"
            )


            return 0

        fi

    fi


    log_info "Updating existing repository..."


    # --------------------------------------------------------------------------
    # Fetch first.
    # --------------------------------------------------------------------------

    if ! git fetch origin; then

        CLONE_PULL_RESULT="FAIL"

        log_error "git fetch failed."


        REPORT_RESULTS+=(
            "FAIL | Repository fetch | Failed"
        )


        return 1

    fi


    # --------------------------------------------------------------------------
    # Determine whether requested branch exists locally.
    # --------------------------------------------------------------------------

    if git show-ref \
        --verify \
        --quiet \
        "refs/heads/${GITHUB_BRANCH}"; then

        log_info "Local branch exists: $GITHUB_BRANCH"

    else

        log_info "Local branch does not exist."

        log_info "Creating local branch from origin/$GITHUB_BRANCH."


        if ! git checkout \
            -B "$GITHUB_BRANCH" \
            "origin/$GITHUB_BRANCH"; then

            log_error "Could not checkout $GITHUB_BRANCH."

            return 1

        fi

    fi


    # --------------------------------------------------------------------------
    # Pull.
    # --------------------------------------------------------------------------

    if git pull --ff-only origin "$GITHUB_BRANCH"; then

        CLONE_PULL_RESULT="PASS"


        log_success "Repository updated successfully."


        REPORT_RESULTS+=(
            "PASS | Repository pull | origin/$GITHUB_BRANCH"
        )


        return 0

    else

        CLONE_PULL_RESULT="FAIL"


        log_error "Git pull failed."

        log_error "There may be local changes or divergent history."

        log_error "No destructive reset was performed."


        REPORT_RESULTS+=(
            "FAIL | Repository pull | Failed safely"
        )


        return 1

    fi

}


# ==============================================================================
# 31. VERIFY GIT REMOTE
# ==============================================================================

verify_git_remote() {

    log_step "Verifying Git Remote"


    if ! cd "$REPOSITORY_DIR"; then

        log_error "Cannot enter repository directory."

        return 1

    fi


    local remote_url

    remote_url="$(git remote get-url origin 2>/dev/null || true)"


    if [[ -z "$remote_url" ]]; then

        log_error "origin remote is missing."


        REPORT_RESULTS+=(
            "FAIL | Git remote | origin missing"
        )


        return 1

    fi


    log_info "Configured remote: $remote_url"

    log_info "Expected remote  : $REPOSITORY_URL"


    if [[ "$remote_url" == "$REPOSITORY_URL" ]]; then

        log_success "Git remote is correct."


        REPORT_RESULTS+=(
            "PASS | Git remote | Correct"
        )

    else

        log_error "Git remote differs from expected repository."


        REPORT_RESULTS+=(
            "FAIL | Git remote | Different from configured repository"
        )


        return 1

    fi

}


# ==============================================================================
# 32. VERIFY GIT BRANCH
# ==============================================================================

verify_git_branch() {

    log_step "Verifying Git Branch"


    cd "$REPOSITORY_DIR"


    local current_branch

    current_branch="$(git branch --show-current 2>/dev/null || true)"


    log_info "Expected branch: $GITHUB_BRANCH"

    log_info "Current branch : $current_branch"


    if [[ "$current_branch" == "$GITHUB_BRANCH" ]]; then

        log_success "Correct branch is checked out."


        REPORT_RESULTS+=(
            "PASS | Git branch | $current_branch"
        )

    else

        log_warning "Current branch differs from configured branch."


        REPORT_RESULTS+=(
            "WARN | Git branch | Current=$current_branch Expected=$GITHUB_BRANCH"
        )

    fi

}


# ==============================================================================
# 33. VERIFY GIT STATUS
# ==============================================================================

verify_git_status() {

    log_step "Checking Git Working Tree"


    cd "$REPOSITORY_DIR"


    local status_output

    status_output="$(git status --short 2>/dev/null || true)"


    if [[ -z "$status_output" ]]; then

        GIT_STATUS_RESULT="CLEAN"


        log_success "Git working tree is clean."


        REPORT_RESULTS+=(
            "PASS | Git status | Clean"
        )

    else

        GIT_STATUS_RESULT="CHANGES"


        log_warning "Git working tree contains changes."


        echo

        echo "$status_output"

        echo


        REPORT_RESULTS+=(
            "WARN | Git status | Working tree has changes"
        )

    fi

}


# ==============================================================================
# 34. DISPLAY RECENT COMMITS
# ==============================================================================

display_recent_commits() {

    log_step "Recent Git Commits"


    cd "$REPOSITORY_DIR"


    git log \
        "-${RECENT_COMMITS}" \
        --oneline \
        --decorate \
        --graph \
        2>/dev/null || true


    REPORT_RESULTS+=(
        "PASS | Git history | Recent commits displayed"
    )

}


# ==============================================================================
# 35. CHECK COMMON DEVOPS FILES
# ==============================================================================

check_devops_files() {

    log_step "Checking Common DevOps Files"


    cd "$REPOSITORY_DIR"


    local files_to_check=(
        "README.md"
        "Dockerfile"
        "docker-compose.yml"
        "docker-compose.yaml"
        ".gitignore"
        ".github"
        ".github/workflows"
        "scripts"
        "templates"
        "terraform"
        "main.tf"
        "variables.tf"
        "outputs.tf"
    )


    local found_count=0


    for file in "${files_to_check[@]}"; do

        if [[ -e "$file" ]]; then

            log_success "Found: $file"

            found_count=$((found_count + 1))

        else

            log_info "Not found: $file"

        fi

    done


    REPORT_RESULTS+=(
        "PASS | DevOps file scan | $found_count common files/directories found"
    )

}


# ==============================================================================
# 36. CHECK DISK SPACE
# ==============================================================================

check_disk_space() {

    log_step "Checking Disk Space"


    if df -h "$REPOSITORY_PARENT_DIR"; then

        REPORT_RESULTS+=(
            "PASS | Disk space | Disk usage checked"
        )

    else

        log_warning "Could not check disk space."

        REPORT_RESULTS+=(
            "WARN | Disk space | Check failed"
        )

    fi

}


# ==============================================================================
# 37. CHECK AWS CLI
# ==============================================================================

check_aws_cli() {

    log_step "Checking AWS CLI"


    if command_exists aws; then

        local aws_version

        aws_version="$(aws --version 2>&1)"


        log_success "AWS CLI detected."

        log_info "$aws_version"


        REPORT_RESULTS+=(
            "PASS | AWS CLI | $aws_version"
        )

    else

        log_warning "AWS CLI is not installed."


        REPORT_RESULTS+=(
            "WARN | AWS CLI | Not installed"
        )

    fi

}


# ==============================================================================
# 38. CHECK AWS IDENTITY
# ==============================================================================

check_aws_identity() {

    log_step "Checking AWS Identity"


    if ! command_exists aws; then

        log_warning "AWS CLI unavailable. Identity check skipped."


        REPORT_RESULTS+=(
            "WARN | AWS identity | AWS CLI unavailable"
        )


        return 0

    fi


    local identity_output

    identity_output="$(aws sts get-caller-identity 2>&1)" || true


    if echo "$identity_output" | grep -q '"Account"'; then

        log_success "AWS identity check succeeded."

        echo "$identity_output"


        REPORT_RESULTS+=(
            "PASS | AWS identity | sts get-caller-identity succeeded"
        )

    else

        log_warning "AWS identity could not be determined."

        echo "$identity_output"


        REPORT_RESULTS+=(
            "WARN | AWS identity | No valid AWS credentials or role"
        )

    fi

}


# ==============================================================================
# 39. COLLECT EC2 METADATA
# ==============================================================================

collect_ec2_information() {

    log_step "Checking EC2 Instance Metadata"


    if ! command_exists curl; then

        log_warning "curl is unavailable."


        REPORT_RESULTS+=(
            "WARN | EC2 metadata | curl unavailable"
        )


        return 0

    fi


    local metadata_token


    metadata_token="$(
        curl \
            --silent \
            --fail \
            --max-time 2 \
            -X PUT \
            -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" \
            "http://169.254.169.254/latest/api/token" \
            2>/dev/null
    )" || metadata_token=""


    if [[ -z "$metadata_token" ]]; then

        log_warning "EC2 metadata service unavailable."

        log_warning "This can happen if IMDS is disabled or restricted."


        REPORT_RESULTS+=(
            "WARN | EC2 metadata | IMDSv2 unavailable"
        )


        return 0

    fi


    EC2_INSTANCE_ID="$(
        curl \
            --silent \
            --fail \
            --max-time 2 \
            -H "X-aws-ec2-metadata-token: $metadata_token" \
            "http://169.254.169.254/latest/meta-data/instance-id" \
            2>/dev/null
    )" || EC2_INSTANCE_ID="Unknown"


    local identity_document


    identity_document="$(
        curl \
            --silent \
            --fail \
            --max-time 2 \
            -H "X-aws-ec2-metadata-token: $metadata_token" \
            "http://169.254.169.254/latest/dynamic/instance-identity/document" \
            2>/dev/null
    )" || identity_document=""


    AWS_REGION_VALUE="$(
        echo "$identity_document" |
            grep -o '"region"[[:space:]]*:[[:space:]]*"[^"]*"' |
            cut -d'"' -f4 |
            head -n 1
    )" || AWS_REGION_VALUE=""


    if [[ -z "$AWS_REGION_VALUE" ]]; then

        AWS_REGION_VALUE="Unknown"

    fi


    log_success "EC2 metadata service responded."

    log_info "Instance ID: $EC2_INSTANCE_ID"

    log_info "AWS Region : $AWS_REGION_VALUE"


    REPORT_RESULTS+=(
        "PASS | EC2 metadata | Instance=$EC2_INSTANCE_ID Region=$AWS_REGION_VALUE"
    )

}


# ==============================================================================
# 40. PREPARE REPORT DIRECTORY
# ==============================================================================

prepare_report_directory() {

    mkdir -p "$REPORT_DIR"

}


# ==============================================================================
# 41. GENERATE FINAL REPORT
# ==============================================================================

generate_report() {

    log_step "Generating Final Report"


    OVERALL_STATUS="SUCCESS"


    if [[ "$SSH_TEST_RESULT" == "FAIL" ]]; then

        OVERALL_STATUS="FAILED"

    fi


    if [[ "$REPOSITORY_TEST_RESULT" == "FAIL" ]]; then

        OVERALL_STATUS="FAILED"

    fi


    if [[ "$CLONE_PULL_RESULT" == "FAIL" ]]; then

        OVERALL_STATUS="FAILED"

    fi


    if [[ "$FAIL_COUNT" -gt 0 ]]; then

        OVERALL_STATUS="FAILED"

    fi


    {
        echo "============================================================================="
        echo " GitHub ↔ EC2 Setup and Verification Report"
        echo "============================================================================="
        echo

        echo "Generated:"
        echo "  $SCRIPT_START_TIME"
        echo

        echo "System Information:"
        echo "  Hostname        : $HOSTNAME_VALUE"
        echo "  Current User    : $CURRENT_USER"
        echo "  Operating System: $OS_NAME"
        echo "  OS Version      : $OS_VERSION"
        echo "  EC2 Instance ID : $EC2_INSTANCE_ID"
        echo "  AWS Region      : $AWS_REGION_VALUE"
        echo

        echo "GitHub Configuration:"
        echo "  GitHub Host     : $GITHUB_HOST"
        echo "  GitHub Username : $GITHUB_USERNAME"
        echo "  Repository      : $GITHUB_REPOSITORY"
        echo "  Branch          : $GITHUB_BRANCH"
        echo "  Repository URL  : $REPOSITORY_URL"
        echo

        echo "Git Configuration:"
        echo "  Git User Name   : $GIT_USER_NAME"
        echo "  Git User Email  : $GIT_USER_EMAIL"
        echo

        echo "SSH Configuration:"
        echo "  SSH Key         : $SSH_KEY_PATH"
        echo "  Public Key      : $SSH_PUBLIC_KEY_PATH"
        echo "  SSH Config      : $SSH_CONFIG_FILE"
        echo "  Known Hosts     : $SSH_KNOWN_HOSTS_FILE"
        echo

        echo "Repository:"
        echo "  Repository Dir  : $REPOSITORY_DIR"
        echo

        echo "Verification Results:"
        echo "-----------------------------------------------------------------------------"


        for result in "${REPORT_RESULTS[@]}"; do

            echo "$result"

        done


        echo "-----------------------------------------------------------------------------"
        echo

        echo "Counters:"
        echo "  PASS: $PASS_COUNT"
        echo "  WARN: $WARN_COUNT"
        echo "  FAIL: $FAIL_COUNT"
        echo

        echo "Connection Results:"
        echo "  SSH Authentication: $SSH_TEST_RESULT"
        echo "  Repository Access  : $REPOSITORY_TEST_RESULT"
        echo "  Clone/Pull         : $CLONE_PULL_RESULT"
        echo "  Git Status         : $GIT_STATUS_RESULT"
        echo

        echo "Overall Status:"
        echo "  $OVERALL_STATUS"
        echo


        if [[ -d "$REPOSITORY_DIR/.git" ]]; then

            echo "Git Repository Details:"
            echo "-----------------------------------------------------------------------------"


            cd "$REPOSITORY_DIR"


            echo "Remote:"

            git remote -v 2>/dev/null || true


            echo

            echo "Current Branch:"

            git branch --show-current 2>/dev/null || true


            echo

            echo "Status:"

            git status --short 2>/dev/null || true


            echo

            echo "Latest Commit:"

            git log -1 --oneline --decorate 2>/dev/null || true


            echo

        fi


        echo "============================================================================="
        echo " End of Report"
        echo "============================================================================="

    } > "$REPORT_FILE"


    echo

    log_success "Report saved."

    echo "  $REPORT_FILE"

}


# ==============================================================================
# 42. FINAL SUMMARY
# ==============================================================================

final_summary() {

    log_step "FINAL SUMMARY"


    echo -e "${WHITE}GitHub ↔ EC2 Connection Summary${NC}"

    echo


    echo "GitHub Repository:"

    echo "  $REPOSITORY_URL"

    echo


    echo "Repository Directory:"

    echo "  $REPOSITORY_DIR"

    echo


    echo "SSH Authentication:"

    echo "  $SSH_TEST_RESULT"

    echo


    echo "Repository Access:"

    echo "  $REPOSITORY_TEST_RESULT"

    echo


    echo "Clone/Pull:"

    echo "  $CLONE_PULL_RESULT"

    echo


    echo "Git Working Tree:"

    echo "  $GIT_STATUS_RESULT"

    echo


    echo "-----------------------------------------------"

    echo "PASS: $PASS_COUNT"

    echo "WARN: $WARN_COUNT"

    echo "FAIL: $FAIL_COUNT"

    echo "-----------------------------------------------"

    echo


    if [[ "$OVERALL_STATUS" == "SUCCESS" ]]; then

        echo -e "${GREEN}===============================================${NC}"

        echo -e "${GREEN} SUCCESS: GitHub ↔ EC2 setup completed${NC}"

        echo -e "${GREEN}===============================================${NC}"

        echo

        echo "Repository is available at:"

        echo "  $REPOSITORY_DIR"

    else

        echo -e "${RED}===============================================${NC}"

        echo -e "${RED} FAILED: Review the errors above${NC}"

        echo -e "${RED}===============================================${NC}"

    fi


    echo

    echo "Report:"

    echo "  $REPORT_FILE"

}


# ==============================================================================
# 43. MAIN
# ==============================================================================

main() {

    clear 2>/dev/null || true


    echo

    echo -e "${CYAN}======================================================================${NC}"

    echo -e "${WHITE} GitHub ↔ EC2 Complete SSH + Git Setup${NC}"

    echo -e "${CYAN}======================================================================${NC}"

    echo

    echo "Purpose:"

    echo "  Securely connect this EC2 instance to a GitHub repository."

    echo

    echo "Authentication:"

    echo "  EC2 → GitHub using SSH"

    echo

    echo "Repository:"

    echo "  Clone / Pull / Verify"

    echo

    echo -e "${CYAN}======================================================================${NC}"

    echo


    # --------------------------------------------------------------------------
    # Prepare report directory.
    # --------------------------------------------------------------------------

    prepare_report_directory


    # --------------------------------------------------------------------------
    # Environment.
    # --------------------------------------------------------------------------

    check_bash_version

    detect_operating_system

    check_current_user

    check_package_manager


    # --------------------------------------------------------------------------
    # Git.
    # --------------------------------------------------------------------------

    install_git_if_required


    # --------------------------------------------------------------------------
    # Configuration.
    # --------------------------------------------------------------------------

    collect_configuration


    # --------------------------------------------------------------------------
    # Git identity.
    # --------------------------------------------------------------------------

    configure_git_identity

    verify_git_configuration


    # --------------------------------------------------------------------------
    # SSH.
    # --------------------------------------------------------------------------

    prepare_ssh_directory

    generate_ssh_key_if_required

    fix_ssh_permissions

    configure_github_ssh

    configure_github_known_hosts

    start_ssh_agent


    # --------------------------------------------------------------------------
    # Public key.
    # --------------------------------------------------------------------------

    display_public_key


    # --------------------------------------------------------------------------
    # Network.
    #
    # Network failure is handled explicitly.
    # --------------------------------------------------------------------------

    if ! test_github_network; then

        log_error "GitHub network connectivity failed."

        SSH_TEST_RESULT="FAIL"

        REPOSITORY_TEST_RESULT="NOT TESTED"

        CLONE_PULL_RESULT="NOT TESTED"


        generate_report

        final_summary

        return 1

    fi


    # --------------------------------------------------------------------------
    # GitHub SSH authentication.
    # --------------------------------------------------------------------------
    #
    # FIRST TEST
    # --------------------------------------------------------------------------

    if ! test_github_ssh; then

        # ----------------------------------------------------------------------
        # Authentication failed.
        #
        # This is NOT an unexpected script crash.
        #
        # The public key simply may not have been registered with GitHub yet.
        # ----------------------------------------------------------------------

        if ! setup_github_key_interactively; then

            display_ssh_diagnostics


            log_error "GitHub SSH authentication is still not working."

            log_error "Repository clone cannot continue until SSH authentication succeeds."


            REPOSITORY_TEST_RESULT="NOT TESTED"

            CLONE_PULL_RESULT="NOT TESTED"


            generate_report

            final_summary


            return 1

        fi

    fi


    # --------------------------------------------------------------------------
    # Repository access.
    # --------------------------------------------------------------------------

    if ! test_repository_access; then

        display_ssh_diagnostics


        log_error "GitHub SSH authentication succeeded, but repository access failed."

        log_error "Verify that this GitHub account has access to the repository."


        CLONE_PULL_RESULT="NOT TESTED"


        generate_report

        final_summary


        return 1

    fi


    # --------------------------------------------------------------------------
    # Clone or update repository.
    # --------------------------------------------------------------------------

    if ! clone_repository; then

        log_error "Repository clone/update failed."


        generate_report

        final_summary


        return 1

    fi


    # --------------------------------------------------------------------------
    # Repository verification.
    # --------------------------------------------------------------------------

    if [[ -d "$REPOSITORY_DIR/.git" ]]; then

        verify_git_remote || true

        verify_git_branch || true

        verify_git_status || true

        display_recent_commits

        check_devops_files

        check_disk_space

    fi


    # --------------------------------------------------------------------------
    # AWS/EC2 information.
    # --------------------------------------------------------------------------

    collect_ec2_information

    check_aws_cli

    check_aws_identity


    # --------------------------------------------------------------------------
    # Final report.
    # --------------------------------------------------------------------------

    generate_report

    final_summary


    # --------------------------------------------------------------------------
    # Final exit code.
    # --------------------------------------------------------------------------

    if [[ "$OVERALL_STATUS" == "SUCCESS" ]]; then

        return 0

    fi


    return 1

}


# ==============================================================================
# 44. SCRIPT ENTRY POINT
# ==============================================================================

main "$@"
