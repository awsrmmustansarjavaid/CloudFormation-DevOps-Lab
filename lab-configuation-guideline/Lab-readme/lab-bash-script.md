# 1. git-commit-push.sh

```
#!/bin/bash

###############################################################################
# Script Name : git-workflow.sh
# Description : Standard Git workflow for updating a local repository
# Author      : Raja Muhammad Mustansar Javaid
###############################################################################

###############################################################################
# STEP 1 - Check Repository Status
###############################################################################

# Display the current status of the Git repository.
# This shows:
#   - Modified files
#   - New (untracked) files
#   - Deleted files
#   - Files already staged for commit
echo "==============================="
echo "Step 1 - Checking Git Status"
echo "==============================="

git status

###############################################################################
# STEP 2 - Stage Changes
###############################################################################

# Option 1
# Stage a single file.
# Uncomment this line if you only want to commit one file.

# git add README.md

# Option 2
# Stage every modified, new, and deleted file.

echo ""
echo "==============================="
echo "Step 2 - Staging Files"
echo "==============================="

git add .

###############################################################################
# STEP 3 - Verify Staged Changes
###############################################################################

# Verify which files are staged and ready to be committed.

echo ""
echo "==============================="
echo "Step 3 - Verify Staged Files"
echo "==============================="

git status

###############################################################################
# STEP 4 - Commit Changes
###############################################################################

# Save the staged files to the local Git history.
# Replace the commit message with a meaningful description.

echo ""
echo "==============================="
echo "Step 4 - Creating Commit"
echo "==============================="

git commit -m "Describe your changes"

###############################################################################
# Examples of Good Commit Messages
###############################################################################

# git commit -m "Add VPC CloudFormation template"
# git commit -m "Update Docker configuration"
# git commit -m "Fix EC2 deployment script"
# git commit -m "Add GitHub Actions workflow"
# git commit -m "Improve project documentation"

###############################################################################
# STEP 5 - Push Changes to GitHub
###############################################################################

# Upload the latest commit to the remote GitHub repository.
# Since the local 'main' branch already tracks 'origin/main',
# you only need the following command.

echo ""
echo "==============================="
echo "Step 5 - Pushing to GitHub"
echo "==============================="

git push

###############################################################################
# Git Workflow Complete
###############################################################################

echo ""
echo "=============================================="
echo " Git workflow completed successfully!"
echo "=============================================="
```

---
# 2. ec2-userdata.sh

```
#!/bin/bash
# =========================================================
# ☕ Charlie Cafe — EC2 Bootstrap Script (Production Ready)
# Amazon Linux 2023
# LAMP + Docker + DevOps Tools
# =========================================================

set -e  # Stop on error

echo "🚀 Starting EC2 Setup..."

# ---------------------------------------------------------
# 1️⃣ Update OS (MANDATORY)
# ---------------------------------------------------------
dnf update -y

# ---------------------------------------------------------
# 2️⃣ Install Apache (httpd)
# ---------------------------------------------------------
dnf install -y httpd
systemctl enable httpd
systemctl start httpd

# ---------------------------------------------------------
# 3️⃣ Install PHP + MySQL Support
# ---------------------------------------------------------
dnf install -y \
php \
php-mysqlnd \
php-cli \
php-common \
php-mbstring \
php-xml

# ---------------------------------------------------------
# 4️⃣ Fix Web Directory Permissions
# ---------------------------------------------------------
chown -R apache:apache /var/www
chmod -R 755 /var/www

# ---------------------------------------------------------
# 5️⃣ Install MySQL Client (MariaDB)
# ---------------------------------------------------------
dnf install -y mariadb105

# ---------------------------------------------------------
# 6️⃣ Install Docker
# ---------------------------------------------------------
dnf install -y docker

systemctl enable docker
systemctl start docker

# Allow ec2-user to run docker without sudo
usermod -aG docker ec2-user

# ---------------------------------------------------------
# 7️⃣ Install Docker Compose (v2)
# ---------------------------------------------------------
mkdir -p /usr/local/lib/docker/cli-plugins/

curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
-o /usr/local/lib/docker/cli-plugins/docker-compose

chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Verify
docker compose version

# ---------------------------------------------------------
# 8️⃣ Install Git
# ---------------------------------------------------------
dnf install -y git

# ---------------------------------------------------------
# 9️⃣ Install Useful DevOps Tools
# ---------------------------------------------------------
dnf install -y \
htop \
unzip \
curl \
wget \
nano \
vim \
tar

# ---------------------------------------------------------
# 🔟 Install AWS CLI (already included in AL2023 but ensure)
# ---------------------------------------------------------
dnf install -y awscli

# ---------------------------------------------------------
# 1️⃣1️⃣ Create PHP Info Page (Optional)
# ---------------------------------------------------------
echo "<?php phpinfo(); ?>" > /var/www/html/info.php

# ---------------------------------------------------------
# 1️⃣2️⃣ Restart Apache
# ---------------------------------------------------------
systemctl restart httpd

# ---------------------------------------------------------
# ✅ Done
# ---------------------------------------------------------
echo "✅ EC2 Setup Completed Successfully!"
```

---
# 3. verify-docker.sh

```
#!/bin/bash

# ==========================================================
# verify-docker.sh
# ==========================================================
#
# Purpose:
# Verify that the Docker container is running and that
# the required development tools are installed correctly.
#
# This script checks:
# - AWS CLI
# - Git
# - Python 3
# - Bash
# - Current working directory
# - Project files
#
# ==========================================================

echo "==========================================="
echo " AWS DevOps CloudFormation Lab Verification"
echo "==========================================="
echo

# Verify container is running
echo "Checking Docker container..."
docker ps --filter "name=aws-cloudformation-lab"

echo
echo "==========================================="
echo "Verifying installed tools..."
echo "==========================================="
echo

docker exec aws-cloudformation-lab aws --version
echo

docker exec aws-cloudformation-lab git --version
echo

docker exec aws-cloudformation-lab python3 --version
echo

docker exec aws-cloudformation-lab bash --version | head -n 1
echo

echo "==========================================="
echo "Current Working Directory"
echo "==========================================="
docker exec aws-cloudformation-lab pwd
echo

echo "==========================================="
echo "Project Files"
echo "==========================================="
docker exec aws-cloudformation-lab ls -la /workspace
echo

echo "==========================================="
echo "Verification Complete"
echo "==========================================="
```

---
# 4. verify-lab.sh

```
#!/usr/bin/env bash

# ==========================================================
# Charlie Cafe - AWS CloudFormation + Docker Verification
# ==========================================================
#
# File:
#   scripts/verify-lab.sh
#
# Purpose:
#   Verify the important resources created by the lab.
#
# This script checks:
#
#   1. AWS CLI
#   2. AWS authentication
#   3. CloudFormation Template Bucket stack
#   4. Main CloudFormation stack
#   5. CloudFormation resources
#   6. VPC
#   7. Subnets
#   8. EC2
#   9. S3
#  10. RDS
#  11. Secrets Manager
#  12. ECR
#  13. ECS
#  14. ALB
#  15. Docker
#  16. Docker Compose
#  17. Docker image
#  18. Docker container
#  19. HTTP application test
#  20. Docker logs
#
# IMPORTANT:
#
# This script DOES NOT display:
#
#   - RDS passwords
#   - Secrets Manager secret values
#   - AWS access keys
#
# ==========================================================


# ==========================================================
# 1. SCRIPT SAFETY
# ==========================================================

# Exit when a command fails.
#
# We do NOT use "set -e" because this verification script
# needs to continue checking other resources even when one
# verification test fails.
#
set -u


# ==========================================================
# 2. LAB CONFIGURATION
# ==========================================================
#
# Change these values if your lab uses different names.
#
# ==========================================================

AWS_REGION="us-east-1"

# Main CloudFormation stack.
STACK_NAME="Lab01-CloudFormation"

# Template bucket CloudFormation stack.
TEMPLATE_BUCKET_STACK="Lab01-CloudFormation-TemplateBucket"

# Docker image name.
DOCKER_IMAGE="charlie-cafe:latest"

# Docker container name.
DOCKER_CONTAINER="charlie-cafe-container"

# Local application URL.
APPLICATION_URL="http://localhost:8080"


# ==========================================================
# 3. VERIFICATION COUNTERS
# ==========================================================

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0


# ==========================================================
# 4. COLOUR / OUTPUT FUNCTIONS
# ==========================================================
#
# These functions make the verification report easier to
# read.
#
# ==========================================================

pass_test() {

    echo "  [PASS] $1"

    PASS_COUNT=$((PASS_COUNT + 1))
}


fail_test() {

    echo "  [FAIL] $1"

    FAIL_COUNT=$((FAIL_COUNT + 1))
}


skip_test() {

    echo "  [SKIP] $1"

    SKIP_COUNT=$((SKIP_COUNT + 1))
}


section() {

    echo ""
    echo "=========================================================="
    echo "$1"
    echo "=========================================================="
}


# ==========================================================
# 5. START VERIFICATION
# ==========================================================

clear 2>/dev/null || true

echo ""
echo "=========================================================="
echo " Charlie Cafe AWS + Docker Lab Verification"
echo "=========================================================="
echo ""
echo "AWS Region       : $AWS_REGION"
echo "Main Stack       : $STACK_NAME"
echo "Docker Image     : $DOCKER_IMAGE"
echo "Docker Container : $DOCKER_CONTAINER"
echo "Application URL  : $APPLICATION_URL"
echo ""


# ==========================================================
# 6. VERIFY AWS CLI
# ==========================================================

section "1. AWS CLI Verification"

if command -v aws >/dev/null 2>&1; then

    AWS_VERSION=$(aws --version 2>&1)

    echo "AWS CLI:"
    echo "$AWS_VERSION"

    pass_test "AWS CLI is installed."

else

    fail_test "AWS CLI is not installed."

fi


# ==========================================================
# 7. VERIFY AWS AUTHENTICATION
# ==========================================================

section "2. AWS Authentication Verification"

if aws sts get-caller-identity \
    --region "$AWS_REGION" \
    --no-cli-pager >/tmp/charlie-cafe-identity.json 2>/dev/null
then

    echo "AWS Account Information:"

    cat /tmp/charlie-cafe-identity.json

    pass_test "AWS authentication is working."

else

    fail_test "AWS authentication failed."

fi


# ==========================================================
# 8. VERIFY TEMPLATE BUCKET STACK
# ==========================================================

section "3. Template Bucket CloudFormation Stack"

TEMPLATE_BUCKET_STATUS=$(

    aws cloudformation describe-stacks \
        --stack-name "$TEMPLATE_BUCKET_STACK" \
        --region "$AWS_REGION" \
        --query "Stacks[0].StackStatus" \
        --output text \
        --no-cli-pager 2>/dev/null

)

if [ "$TEMPLATE_BUCKET_STATUS" = "CREATE_COMPLETE" ] ||
   [ "$TEMPLATE_BUCKET_STATUS" = "UPDATE_COMPLETE" ]
then

    echo "Stack Status: $TEMPLATE_BUCKET_STATUS"

    pass_test "Template bucket CloudFormation stack is healthy."

else

    if [ -z "$TEMPLATE_BUCKET_STATUS" ] ||
       [ "$TEMPLATE_BUCKET_STATUS" = "None" ]
    then

        fail_test "Template bucket stack was not found."

    else

        fail_test "Template bucket stack status is $TEMPLATE_BUCKET_STATUS."

    fi

fi


# ==========================================================
# 9. GET TEMPLATE BUCKET NAME
# ==========================================================

section "4. Template S3 Bucket"

TEMPLATE_BUCKET=$(

    aws cloudformation describe-stacks \
        --stack-name "$TEMPLATE_BUCKET_STACK" \
        --region "$AWS_REGION" \
        --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" \
        --output text \
        --no-cli-pager 2>/dev/null

)

if [ -n "$TEMPLATE_BUCKET" ] &&
   [ "$TEMPLATE_BUCKET" != "None" ]
then

    echo "Template Bucket: $TEMPLATE_BUCKET"

    if aws s3api head-bucket \
        --bucket "$TEMPLATE_BUCKET" \
        --region "$AWS_REGION" \
        >/dev/null 2>&1
    then

        pass_test "Template S3 bucket exists."

    else

        fail_test "Template S3 bucket cannot be accessed."

    fi

else

    fail_test "Template bucket name could not be retrieved."

fi


# ==========================================================
# 10. VERIFY MAIN CLOUDFORMATION STACK
# ==========================================================

section "5. Main CloudFormation Stack"

MAIN_STACK_STATUS=$(

    aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query "Stacks[0].StackStatus" \
        --output text \
        --no-cli-pager 2>/dev/null

)

echo "Stack Status: $MAIN_STACK_STATUS"

case "$MAIN_STACK_STATUS" in

    CREATE_COMPLETE|UPDATE_COMPLETE)

        pass_test "Main CloudFormation stack is healthy."

        ;;

    *)

        fail_test "Main CloudFormation stack is not in a successful state."

        ;;

esac


# ==========================================================
# 11. DISPLAY MAIN STACK RESOURCES
# ==========================================================

section "6. CloudFormation Resources"

if [ "$MAIN_STACK_STATUS" = "CREATE_COMPLETE" ] ||
   [ "$MAIN_STACK_STATUS" = "UPDATE_COMPLETE" ]
then

    echo "Resources created by the main stack:"
    echo ""

    aws cloudformation list-stack-resources \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --no-cli-pager

    pass_test "CloudFormation resources were successfully retrieved."

else

    skip_test "CloudFormation resources because the main stack is unhealthy."

fi


# ==========================================================
# 12. VERIFY VPC
# ==========================================================

section "7. VPC Verification"

VPC_ID=$(

    aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query "Stacks[0].Outputs[?OutputKey=='VPCId'].OutputValue" \
        --output text \
        --no-cli-pager 2>/dev/null

)

if [ -n "$VPC_ID" ] &&
   [ "$VPC_ID" != "None" ]
then

    echo "VPC ID: $VPC_ID"

    VPC_STATE=$(

        aws ec2 describe-vpcs \
            --vpc-ids "$VPC_ID" \
            --region "$AWS_REGION" \
            --query "Vpcs[0].State" \
            --output text \
            --no-cli-pager

    )

    echo "VPC State: $VPC_STATE"

    if [ "$VPC_STATE" = "available" ]; then

        pass_test "VPC is available."

    else

        fail_test "VPC is not available."

    fi

else

    fail_test "VPC ID could not be retrieved."

fi


# ==========================================================
# 13. VERIFY SUBNETS
# ==========================================================

section "8. Subnet Verification"

SUBNET_COUNT=$(

    aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --region "$AWS_REGION" \
        --query "length(Subnets)" \
        --output text \
        --no-cli-pager 2>/dev/null

)

echo "Subnets found: $SUBNET_COUNT"

if [ "$SUBNET_COUNT" -ge 4 ]; then

    pass_test "Expected public/private subnet architecture exists."

else

    fail_test "Expected subnet count was not found."

fi


# ==========================================================
# 14. VERIFY EC2
# ==========================================================

section "9. EC2 Verification"

EC2_ID=$(

    aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query "Stacks[0].Outputs[?OutputKey=='EC2InstanceId'].OutputValue" \
        --output text \
        --no-cli-pager 2>/dev/null

)

if [ -n "$EC2_ID" ] &&
   [ "$EC2_ID" != "None" ]
then

    EC2_STATE=$(

        aws ec2 describe-instances \
            --instance-ids "$EC2_ID" \
            --region "$AWS_REGION" \
            --query "Reservations[0].Instances[0].State.Name" \
            --output text \
            --no-cli-pager

    )

    echo "EC2 Instance: $EC2_ID"
    echo "EC2 State:    $EC2_STATE"

    if [ "$EC2_STATE" = "running" ]; then

        pass_test "EC2 instance is running."

    else

        fail_test "EC2 instance is not running."

    fi

else

    fail_test "EC2 instance ID could not be retrieved."

fi


# ==========================================================
# 15. VERIFY S3
# ==========================================================

section "10. S3 Verification"

if [ -n "${TEMPLATE_BUCKET:-}" ] &&
   [ "$TEMPLATE_BUCKET" != "None" ]
then

    if aws s3 ls "s3://$TEMPLATE_BUCKET/templates/" \
        --region "$AWS_REGION" \
        >/dev/null 2>&1
    then

        echo "CloudFormation templates found in S3."

        aws s3 ls \
            "s3://$TEMPLATE_BUCKET/templates/" \
            --region "$AWS_REGION"

        pass_test "S3 template bucket is accessible."

    else

        fail_test "S3 template directory could not be accessed."

    fi

else

    skip_test "S3 verification because bucket name was unavailable."

fi


# ==========================================================
# 16. VERIFY RDS
# ==========================================================

section "11. RDS Verification"

RDS_ID=$(

    aws rds describe-db-instances \
        --region "$AWS_REGION" \
        --query "DBInstances[0].DBInstanceIdentifier" \
        --output text \
        --no-cli-pager 2>/dev/null

)

if [ -n "$RDS_ID" ] &&
   [ "$RDS_ID" != "None" ]
then

    RDS_STATUS=$(

        aws rds describe-db-instances \
            --db-instance-identifier "$RDS_ID" \
            --region "$AWS_REGION" \
            --query "DBInstances[0].DBInstanceStatus" \
            --output text \
            --no-cli-pager

    )

    echo "RDS Instance: $RDS_ID"
    echo "RDS Status:   $RDS_STATUS"

    if [ "$RDS_STATUS" = "available" ]; then

        pass_test "RDS database is available."

    else

        fail_test "RDS database is not available."

    fi

else

    fail_test "RDS database was not found."

fi


# ==========================================================
# 17. VERIFY SECRETS MANAGER
# ==========================================================
#
# We ONLY verify that the secret exists.
#
# We NEVER retrieve SecretString.
#
# ==========================================================

section "12. Secrets Manager Verification"

SECRET_COUNT=$(

    aws secretsmanager list-secrets \
        --region "$AWS_REGION" \
        --query "length(SecretList)" \
        --output text \
        --no-cli-pager 2>/dev/null

)

echo "Secrets found: $SECRET_COUNT"

if [ "$SECRET_COUNT" -gt 0 ]; then

    pass_test "Secrets Manager contains secrets."

else

    fail_test "No Secrets Manager secrets were found."

fi


# ==========================================================
# 18. VERIFY ECR
# ==========================================================

section "13. ECR Verification"

ECR_REPOSITORIES=$(

    aws ecr describe-repositories \
        --region "$AWS_REGION" \
        --query "repositories[].repositoryName" \
        --output text \
        --no-cli-pager 2>/dev/null

)

if [ -n "$ECR_REPOSITORIES" ]; then

    echo "ECR repositories:"
    echo "$ECR_REPOSITORIES"

    pass_test "ECR repository exists."

else

    fail_test "No ECR repository was found."

fi


# ==========================================================
# 19. VERIFY ECS
# ==========================================================

section "14. ECS Verification"

ECS_CLUSTERS=$(

    aws ecs list-clusters \
        --region "$AWS_REGION" \
        --query "clusterArns[]" \
        --output text \
        --no-cli-pager 2>/dev/null

)

if [ -n "$ECS_CLUSTERS" ]; then

    echo "ECS clusters:"
    echo "$ECS_CLUSTERS"

    pass_test "ECS cluster exists."

else

    fail_test "No ECS cluster was found."

fi


# ==========================================================
# 20. VERIFY ALB
# ==========================================================

section "15. Application Load Balancer Verification"

ALB_COUNT=$(

    aws elbv2 describe-load-balancers \
        --region "$AWS_REGION" \
        --query "length(LoadBalancers)" \
        --output text \
        --no-cli-pager 2>/dev/null

)

echo "ALB count: $ALB_COUNT"

if [ "$ALB_COUNT" -gt 0 ]; then

    pass_test "Application Load Balancer exists."

else

    fail_test "Application Load Balancer was not found."

fi


# ==========================================================
# 21. VERIFY DOCKER
# ==========================================================

section "16. Docker Verification"

if command -v docker >/dev/null 2>&1; then

    docker --version

    pass_test "Docker is installed."

else

    fail_test "Docker is not installed."

fi


# ==========================================================
# 22. VERIFY DOCKER COMPOSE
# ==========================================================

section "17. Docker Compose Verification"

if docker compose version >/dev/null 2>&1; then

    docker compose version

    pass_test "Docker Compose is available."

else

    fail_test "Docker Compose is not available."

fi


# ==========================================================
# 23. VERIFY DOCKER IMAGE
# ==========================================================

section "18. Docker Image Verification"

if docker image inspect "$DOCKER_IMAGE" \
    >/dev/null 2>&1
then

    echo "Docker Image:"
    docker image inspect "$DOCKER_IMAGE" \
        --format='Repository={{.RepoTags}} ImageID={{.Id}}'

    pass_test "Charlie Cafe Docker image exists."

else

    fail_test "Charlie Cafe Docker image does not exist."

fi


# ==========================================================
# 24. VERIFY DOCKER CONTAINER
# ==========================================================

section "19. Docker Container Verification"

if docker inspect "$DOCKER_CONTAINER" \
    >/dev/null 2>&1
then

    CONTAINER_STATUS=$(

        docker inspect \
            --format='{{.State.Status}}' \
            "$DOCKER_CONTAINER"

    )

    echo "Container: $DOCKER_CONTAINER"
    echo "Status:    $CONTAINER_STATUS"

    if [ "$CONTAINER_STATUS" = "running" ]; then

        pass_test "Docker container is running."

    else

        fail_test "Docker container exists but is not running."

    fi

else

    fail_test "Docker container does not exist."

fi


# ==========================================================
# 25. VERIFY HTTP APPLICATION
# ==========================================================

section "20. HTTP Application Verification"

echo "Testing:"
echo "$APPLICATION_URL"
echo ""

if curl \
    --fail \
    --silent \
    --show-error \
    --max-time 10 \
    "$APPLICATION_URL" \
    >/tmp/charlie-cafe-response.html
then

    pass_test "Charlie Cafe application returned HTTP response."

    echo ""
    echo "Application response preview:"
    echo ""

    head -n 20 /tmp/charlie-cafe-response.html

else

    fail_test "Charlie Cafe application did not respond successfully."

fi


# ==========================================================
# 26. VERIFY HTTP STATUS CODE
# ==========================================================

section "21. HTTP Status Code Verification"

HTTP_STATUS=$(

    curl \
        --silent \
        --output /dev/null \
        --write-out "%{http_code}" \
        --max-time 10 \
        "$APPLICATION_URL"

)

echo "HTTP Status: $HTTP_STATUS"

if [ "$HTTP_STATUS" = "200" ]; then

    pass_test "Application returned HTTP 200 OK."

else

    fail_test "Application returned HTTP status $HTTP_STATUS."

fi


# ==========================================================
# 27. DISPLAY DOCKER LOGS
# ==========================================================

section "22. Docker Container Logs"

if docker inspect "$DOCKER_CONTAINER" \
    >/dev/null 2>&1
then

    echo "Recent container logs:"
    echo ""

    docker logs \
        --tail 50 \
        "$DOCKER_CONTAINER" \
        2>&1 || true

    pass_test "Docker container logs retrieved."

else

    skip_test "Docker logs because container does not exist."

fi


# ==========================================================
# 28. FINAL VERIFICATION REPORT
# ==========================================================

section "FINAL VERIFICATION REPORT"

echo ""
echo "PASS : $PASS_COUNT"
echo "FAIL : $FAIL_COUNT"
echo "SKIP : $SKIP_COUNT"
echo ""

echo "=========================================================="

if [ "$FAIL_COUNT" -eq 0 ]; then

    echo "RESULT: VERIFICATION SUCCESSFUL"
    echo "=========================================================="
    echo ""
    echo "Charlie Cafe lab verification completed successfully."
    echo ""
    echo "CloudFormation resources were verified."
    echo "Docker image was verified."
    echo "Docker container was verified."
    echo "Application HTTP endpoint was tested."
    echo ""

else

    echo "RESULT: VERIFICATION FAILED"
    echo "=========================================================="
    echo ""
    echo "One or more verification tests failed."
    echo ""
    echo "Review the [FAIL] messages above."
    echo ""

fi


# ==========================================================
# 29. CLEAN TEMPORARY FILES
# ==========================================================

rm -f /tmp/charlie-cafe-identity.json
rm -f /tmp/charlie-cafe-response.html


# ==========================================================
# 30. EXIT CODE
# ==========================================================
#
# Exit 0 = all tests passed.
#
# Exit 1 = at least one test failed.
#
# This is useful for GitHub Actions because the workflow can
# automatically mark the verification stage as failed.
#
# ==========================================================

if [ "$FAIL_COUNT" -eq 0 ]; then

    exit 0

else

    exit 1

fi
```

---
# 5. delete-stack.sh

```
#!/bin/bash

# ==========================================
# AWS CloudFormation Stack Deletion Script
# Purpose:
#   Deletes an existing CloudFormation stack
#   and waits until the deletion is complete.
#
# Prerequisites:
#   - AWS CLI installed
#   - AWS CLI configured (aws configure)
#   - IAM user/role with CloudFormation permissions
# ==========================================

# Name of the CloudFormation stack to delete
STACK_NAME="Lab01-CloudFormation"

# AWS Region where the stack exists
REGION="us-east-1"

# Display a message to the user
echo "Deleting CloudFormation stack: $STACK_NAME"

# Delete the CloudFormation stack
aws cloudformation delete-stack \
  --stack-name "$STACK_NAME" \
  --region "$REGION"

# Inform the user that the script is waiting
echo "Waiting for stack deletion..."

# Wait until AWS confirms the stack has been deleted
aws cloudformation wait stack-delete-complete \
  --stack-name "$STACK_NAME" \
  --region "$REGION"

# Display a success message
echo "========================================="
echo "CloudFormation stack deleted successfully!"
echo "========================================="
```

---
# 6. verify-cloudformation-lab.sh

```
#!/bin/bash

# ================================================================
# AWS CloudFormation DevOps Lab - Complete Verification Script
# ================================================================
#
# Purpose:
#   Verify the AWS CloudFormation DevOps Lab from inside EC2.
#
# This script performs READ-ONLY checks.
# It does NOT create, update, or delete AWS resources.
#
# Main areas tested:
#   1. AWS CLI
#   2. AWS Identity / IAM
#   3. CloudFormation Main Stack
#   4. Nested Stacks
#   5. VPC
#   6. Subnets
#   7. Route Tables
#   8. Internet Gateway
#   9. Security Groups
#  10. EC2
#  11. UserData / Cloud-Init
#  12. Apache
#  13. PHP
#  14. Docker
#  15. Git
#  16. S3
#  17. RDS
#  18. Secrets Manager
#  19. ECS
#  20. ECR
#  21. VPC Endpoints
#  22. ALB
#  23. Target Health
#  24. CloudWatch Logs
#  25. End-to-End Connectivity
#
# ================================================================


# ================================================================
# 1. Configuration
# ================================================================

# Change these values if your stack/resource names are different.

MAIN_STACK="CloudFormation-DevOps-Lab"
ECS_STACK="CharlieCafe-ECS-Stack"

ECR_REPOSITORY="charlie-cafe"
ECS_CLUSTER="CharlieCafe-Cluster"
ECS_SERVICE="CharlieCafe-Service"

# AWS region.
# If AWS_DEFAULT_REGION is already configured, use that.
AWS_REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"

# Counter for failed tests.
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0


# ================================================================
# 2. Output Functions
# ================================================================

print_header() {
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


# ================================================================
# 3. Verify AWS CLI
# ================================================================

print_header "1. AWS CLI Verification"

if command -v aws >/dev/null 2>&1; then
    pass "AWS CLI is installed."
    aws --version
else
    fail "AWS CLI is not installed."
fi


# ================================================================
# 4. Verify AWS Region
# ================================================================

print_header "2. AWS Region"

echo "AWS Region: $AWS_REGION"

export AWS_DEFAULT_REGION="$AWS_REGION"

pass "AWS region configured."


# ================================================================
# 5. Verify AWS Identity
# ================================================================

print_header "3. AWS Identity / IAM Verification"

IDENTITY=$(aws sts get-caller-identity 2>/dev/null)

if [ $? -eq 0 ]; then
    pass "AWS credentials are working."

    echo "$IDENTITY" \
        --output json 2>/dev/null || echo "$IDENTITY"
else
    fail "AWS credentials are not working."
fi


# ================================================================
# 6. CloudFormation Main Stack
# ================================================================

print_header "4. Main CloudFormation Stack"

MAIN_STACK_STATUS=$(aws cloudformation describe-stacks \
    --stack-name "$MAIN_STACK" \
    --query "Stacks[0].StackStatus" \
    --output text 2>/dev/null)

if [ "$MAIN_STACK_STATUS" = "CREATE_COMPLETE" ] || \
   [ "$MAIN_STACK_STATUS" = "UPDATE_COMPLETE" ]; then

    pass "Main CloudFormation stack status: $MAIN_STACK_STATUS"

else

    if [ -z "$MAIN_STACK_STATUS" ] || [ "$MAIN_STACK_STATUS" = "None" ]; then
        fail "Main CloudFormation stack was not found."
    else
        fail "Main CloudFormation stack status: $MAIN_STACK_STATUS"
    fi
fi


# ================================================================
# 7. Main Stack Outputs
# ================================================================

print_header "5. Main Stack Outputs"

aws cloudformation describe-stacks \
    --stack-name "$MAIN_STACK" \
    --query "Stacks[0].Outputs[*].[OutputKey,OutputValue]" \
    --output table 2>/dev/null

if [ $? -eq 0 ]; then
    pass "Main stack outputs retrieved."
else
    fail "Unable to retrieve main stack outputs."
fi


# ================================================================
# 8. Main Stack Resources
# ================================================================

print_header "6. Main Stack Resources"

aws cloudformation list-stack-resources \
    --stack-name "$MAIN_STACK" \
    --query "StackResourceSummaries[*].[LogicalResourceId,ResourceType,ResourceStatus]" \
    --output table 2>/dev/null

if [ $? -eq 0 ]; then
    pass "Main stack resources retrieved."
else
    fail "Unable to retrieve main stack resources."
fi


# ================================================================
# 9. Nested Stack Verification
# ================================================================

print_header "7. Nested CloudFormation Stacks"

NESTED_STACKS=$(aws cloudformation list-stack-resources \
    --stack-name "$MAIN_STACK" \
    --query "StackResourceSummaries[?ResourceType=='AWS::CloudFormation::Stack'].[LogicalResourceId,PhysicalResourceId,ResourceStatus]" \
    --output text 2>/dev/null)

if [ -n "$NESTED_STACKS" ]; then

    echo "$NESTED_STACKS"

    pass "Nested CloudFormation stacks were found."

else

    warn "No nested stacks were detected."
fi


# ================================================================
# 10. Retrieve VPC ID
# ================================================================

print_header "8. VPC Verification"

VPC_ID=$(aws cloudformation describe-stacks \
    --stack-name "$MAIN_STACK" \
    --query "Stacks[0].Outputs[?contains(OutputKey, 'Vpc') || contains(OutputKey, 'VPC')].OutputValue | [0]" \
    --output text 2>/dev/null)

# If the CloudFormation output does not contain the VPC ID,
# try to discover the VPC using the expected CIDR.

if [ -z "$VPC_ID" ] || [ "$VPC_ID" = "None" ]; then

    info "VPC ID was not found in stack outputs."
    info "Searching for VPC with CIDR 10.0.0.0/16..."

    VPC_ID=$(aws ec2 describe-vpcs \
        --filters "Name=cidr-block,Values=10.0.0.0/16" \
        --query "Vpcs[0].VpcId" \
        --output text)
fi

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then

    pass "VPC found: $VPC_ID"

    aws ec2 describe-vpcs \
        --vpc-ids "$VPC_ID" \
        --query "Vpcs[0].[VpcId,CidrBlock,State]" \
        --output table

else

    fail "VPC could not be identified."
fi


# ================================================================
# 11. VPC DNS Support
# ================================================================

print_header "9. VPC DNS Support"

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then

    DNS_SUPPORT=$(aws ec2 describe-vpc-attribute \
        --vpc-id "$VPC_ID" \
        --attribute enableDnsSupport \
        --query "EnableDnsSupport.Value" \
        --output text)

    if [ "$DNS_SUPPORT" = "True" ]; then
        pass "VPC DNS support is enabled."
    else
        fail "VPC DNS support is not enabled."
    fi

    DNS_HOSTNAMES=$(aws ec2 describe-vpc-attribute \
        --vpc-id "$VPC_ID" \
        --attribute enableDnsHostnames \
        --query "EnableDnsHostnames.Value" \
        --output text)

    if [ "$DNS_HOSTNAMES" = "True" ]; then
        pass "VPC DNS hostnames are enabled."
    else
        fail "VPC DNS hostnames are not enabled."
    fi

fi


# ================================================================
# 12. Internet Gateway
# ================================================================

print_header "10. Internet Gateway"

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then

    IGW_ID=$(aws ec2 describe-internet-gateways \
        --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
        --query "InternetGateways[0].InternetGatewayId" \
        --output text)

    if [ -n "$IGW_ID" ] && [ "$IGW_ID" != "None" ]; then
        pass "Internet Gateway is attached: $IGW_ID"
    else
        fail "No Internet Gateway is attached to the VPC."
    fi

fi


# ================================================================
# 13. Subnets
# ================================================================

print_header "11. VPC Subnets"

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then

    aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "Subnets[*].[SubnetId,AvailabilityZone,CidrBlock,MapPublicIpOnLaunch,Tags[?Key=='Name'].Value|[0]]" \
        --output table

    SUBNET_COUNT=$(aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "length(Subnets)" \
        --output text)

    if [ "$SUBNET_COUNT" -ge 4 ]; then
        pass "At least four VPC subnets were found."
    else
        warn "Expected approximately four subnets, found $SUBNET_COUNT."
    fi

fi


# ================================================================
# 14. Route Tables
# ================================================================

print_header "12. Route Tables"

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then

    aws ec2 describe-route-tables \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "RouteTables[*].[RouteTableId,Routes[*].[DestinationCidrBlock,GatewayId,NatGatewayId],Tags[?Key=='Name'].Value|[0]]" \
        --output table

    pass "VPC route tables retrieved."

fi


# ================================================================
# 15. Security Groups
# ================================================================

print_header "13. Security Groups"

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then

    aws ec2 describe-security-groups \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "SecurityGroups[*].[GroupId,GroupName,Description]" \
        --output table

    pass "Security groups retrieved."

fi


# ================================================================
# 16. EC2 Verification
# ================================================================

print_header "14. EC2 Verification"

INSTANCE_ID=$(aws ec2 describe-instances \
    --filters \
        "Name=vpc-id,Values=$VPC_ID" \
        "Name=instance-state-name,Values=running" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text 2>/dev/null)

if [ -n "$INSTANCE_ID" ] && [ "$INSTANCE_ID" != "None" ]; then

    pass "Running EC2 instance found: $INSTANCE_ID"

    aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --query "Reservations[0].Instances[0].[InstanceId,InstanceType,State.Name,SubnetId,PrivateIpAddress,PublicIpAddress]" \
        --output table

else

    warn "No running EC2 instance found in the VPC."
fi


# ================================================================
# 17. EC2 System Status
# ================================================================

print_header "15. EC2 System Health"

if [ -n "$INSTANCE_ID" ] && [ "$INSTANCE_ID" != "None" ]; then

    INSTANCE_STATUS=$(aws ec2 describe-instance-status \
        --instance-ids "$INSTANCE_ID" \
        --include-all-instances \
        --query "InstanceStatuses[0].[SystemStatus.Status,InstanceStatus.Status]" \
        --output text)

    echo "$INSTANCE_STATUS"

    if echo "$INSTANCE_STATUS" | grep -q "ok"; then
        pass "EC2 system and instance status checks are healthy."
    else
        warn "EC2 health checks are not both showing OK."
    fi

fi


# ================================================================
# 18. EC2 UserData / Cloud-Init
# ================================================================

print_header "16. EC2 UserData / Cloud-Init"

if [ -f "/var/log/cloud-init.log" ]; then
    pass "cloud-init.log exists."
else
    warn "cloud-init.log was not found."
fi

if [ -f "/var/log/cloud-init-output.log" ]; then
    pass "cloud-init-output.log exists."
else
    warn "cloud-init-output.log was not found."
fi

if [ -f "/var/log/bootstrap.log" ]; then
    pass "bootstrap.log exists."

    echo
    echo "--- Last 20 bootstrap.log lines ---"
    sudo tail -n 20 /var/log/bootstrap.log

else
    warn "bootstrap.log was not found."
fi

if [ -f "/var/log/bootstrap-status.log" ]; then
    pass "bootstrap-status.log exists."

    echo
    cat /var/log/bootstrap-status.log
else
    warn "bootstrap-status.log was not found."
fi


# ================================================================
# 19. EC2 Internet Connectivity
# ================================================================

print_header "17. EC2 Internet Connectivity"

if curl -Is --connect-timeout 5 https://www.google.com >/dev/null 2>&1; then
    pass "EC2 HTTPS Internet connectivity works."
else
    fail "EC2 cannot reach Google over HTTPS."
fi

if curl -Is --connect-timeout 5 https://github.com >/dev/null 2>&1; then
    pass "EC2 can reach GitHub."
else
    fail "EC2 cannot reach GitHub."
fi


# ================================================================
# 20. DNS
# ================================================================

print_header "18. EC2 DNS Verification"

if getent hosts github.com >/dev/null 2>&1; then
    pass "DNS resolution for github.com works."
else
    fail "DNS resolution for github.com failed."
fi

if getent hosts amazonaws.com >/dev/null 2>&1; then
    pass "DNS resolution for amazonaws.com works."
else
    fail "DNS resolution for amazonaws.com failed."
fi


# ================================================================
# 21. Apache
# ================================================================

print_header "19. Apache Verification"

if command -v httpd >/dev/null 2>&1; then

    pass "Apache/httpd is installed."

    if systemctl is-active --quiet httpd; then
        pass "Apache is running."
    else
        fail "Apache is installed but not running."
    fi

    if curl -Is http://localhost >/dev/null 2>&1; then
        pass "Apache responds on localhost."
    else
        fail "Apache does not respond on localhost."
    fi

else

    warn "Apache/httpd is not installed."

fi


# ================================================================
# 22. PHP
# ================================================================

print_header "20. PHP Verification"

if command -v php >/dev/null 2>&1; then

    pass "PHP is installed."

    php --version | head -n 1

else

    warn "PHP is not installed."

fi


# ================================================================
# 23. Docker
# ================================================================

print_header "21. Docker Verification"

if command -v docker >/dev/null 2>&1; then

    pass "Docker is installed."

    docker --version

    if systemctl is-active --quiet docker; then
        pass "Docker service is running."
    else
        fail "Docker service is not running."
    fi

    DOCKER_ENABLED=$(systemctl is-enabled docker 2>/dev/null)

    if [ "$DOCKER_ENABLED" = "enabled" ]; then
        pass "Docker is enabled at boot."
    else
        warn "Docker is not enabled at boot."
    fi

    echo
    echo "--- Docker Containers ---"
    sudo docker ps -a

    echo
    echo "--- Docker Images ---"
    sudo docker images

else

    warn "Docker is not installed."

fi


# ================================================================
# 24. Docker Compose
# ================================================================

print_header "22. Docker Compose Verification"

if docker compose version >/dev/null 2>&1; then

    pass "Docker Compose plugin is installed."
    docker compose version

elif command -v docker-compose >/dev/null 2>&1; then

    pass "Standalone docker-compose is installed."
    docker-compose --version

else

    warn "Docker Compose was not found."
fi


# ================================================================
# 25. Git
# ================================================================

print_header "23. Git Verification"

if command -v git >/dev/null 2>&1; then

    pass "Git is installed."
    git --version

else

    warn "Git is not installed."

fi


# ================================================================
# 26. AWS CLI Identity From EC2
# ================================================================

print_header "24. AWS CLI Authentication From EC2"

if aws sts get-caller-identity >/dev/null 2>&1; then

    pass "EC2 can authenticate to AWS."

    aws sts get-caller-identity \
        --query "[Account,Arn]" \
        --output table

else

    fail "EC2 cannot authenticate to AWS."
fi


# ================================================================
# 27. S3
# ================================================================

print_header "25. S3 Verification"

S3_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "$MAIN_STACK" \
    --query "Stacks[0].Outputs[?contains(OutputKey, 'S3') && contains(OutputKey, 'Bucket')].OutputValue | [0]" \
    --output text 2>/dev/null)

if [ -n "$S3_BUCKET" ] && [ "$S3_BUCKET" != "None" ]; then

    pass "S3 bucket found: $S3_BUCKET"

    if aws s3api head-bucket --bucket "$S3_BUCKET" 2>/dev/null; then
        pass "S3 bucket is accessible."
    else
        fail "S3 bucket cannot be accessed."
    fi

    echo
    echo "--- S3 Versioning ---"

    aws s3api get-bucket-versioning \
        --bucket "$S3_BUCKET"

else

    warn "S3 bucket could not be found from CloudFormation outputs."
fi


# ================================================================
# 28. RDS
# ================================================================

print_header "26. RDS MySQL Verification"

RDS_IDENTIFIER=$(aws rds describe-db-instances \
    --query "DBInstances[?Engine=='mysql'].DBInstanceIdentifier | [0]" \
    --output text 2>/dev/null)

if [ -n "$RDS_IDENTIFIER" ] && [ "$RDS_IDENTIFIER" != "None" ]; then

    pass "RDS MySQL instance found: $RDS_IDENTIFIER"

    aws rds describe-db-instances \
        --db-instance-identifier "$RDS_IDENTIFIER" \
        --query "DBInstances[0].[DBInstanceIdentifier,Engine,DBInstanceStatus,PubliclyAccessible,Endpoint.Address,Endpoint.Port]" \
        --output table

    RDS_ENDPOINT=$(aws rds describe-db-instances \
        --db-instance-identifier "$RDS_IDENTIFIER" \
        --query "DBInstances[0].Endpoint.Address" \
        --output text)

    RDS_PORT=$(aws rds describe-db-instances \
        --db-instance-identifier "$RDS_IDENTIFIER" \
        --query "DBInstances[0].Endpoint.Port" \
        --output text)

    RDS_PUBLIC=$(aws rds describe-db-instances \
        --db-instance-identifier "$RDS_IDENTIFIER" \
        --query "DBInstances[0].PubliclyAccessible" \
        --output text)

    if [ "$RDS_PUBLIC" = "False" ]; then
        pass "RDS is not publicly accessible."
    else
        warn "RDS is publicly accessible."
    fi

else

    warn "No MySQL RDS instance was found."

fi


# ================================================================
# 29. RDS Network Connectivity
# ================================================================

print_header "27. RDS Network Connectivity"

if [ -n "$RDS_ENDPOINT" ] && [ "$RDS_ENDPOINT" != "None" ]; then

    if getent hosts "$RDS_ENDPOINT" >/dev/null 2>&1; then
        pass "RDS endpoint resolves from EC2."
    else
        fail "RDS endpoint does not resolve from EC2."
    fi

    if command -v nc >/dev/null 2>&1; then

        if nc -z -w 5 "$RDS_ENDPOINT" "$RDS_PORT" >/dev/null 2>&1; then
            pass "EC2 can reach RDS port $RDS_PORT."
        else
            fail "EC2 cannot reach RDS port $RDS_PORT."
        fi

    else

        warn "netcat (nc) is not installed; RDS TCP test skipped."

    fi

fi


# ================================================================
# 30. Secrets Manager
# ================================================================

print_header "28. Secrets Manager Verification"

SECRET_COUNT=$(aws secretsmanager list-secrets \
    --query "length(SecretList)" \
    --output text 2>/dev/null)

if [ "$SECRET_COUNT" -gt 0 ]; then

    pass "Secrets Manager contains $SECRET_COUNT secret(s)."

    # Only display metadata.
    # Never print secret values or passwords.
    aws secretsmanager list-secrets \
        --query "SecretList[*].[Name,ARN]" \
        --output table

else

    warn "No Secrets Manager secrets were found."
fi


# ================================================================
# 31. ECS CloudFormation Stack
# ================================================================

print_header "29. ECS CloudFormation Stack"

ECS_STACK_STATUS=$(aws cloudformation describe-stacks \
    --stack-name "$ECS_STACK" \
    --query "Stacks[0].StackStatus" \
    --output text 2>/dev/null)

if [ "$ECS_STACK_STATUS" = "CREATE_COMPLETE" ] || \
   [ "$ECS_STACK_STATUS" = "UPDATE_COMPLETE" ]; then

    pass "ECS stack status: $ECS_STACK_STATUS"

else

    fail "ECS stack status: ${ECS_STACK_STATUS:-NOT_FOUND}"
fi


# ================================================================
# 32. ECR Repository
# ================================================================

print_header "30. ECR Verification"

if aws ecr describe-repositories \
    --repository-names "$ECR_REPOSITORY" >/dev/null 2>&1; then

    pass "ECR repository exists: $ECR_REPOSITORY"

    aws ecr describe-images \
        --repository-name "$ECR_REPOSITORY" \
        --query "imageDetails[*].[imageTags,imageDigest,imagePushedAt]" \
        --output table 2>/dev/null

else

    fail "ECR repository does not exist: $ECR_REPOSITORY"
fi


# ================================================================
# 33. ECS Cluster
# ================================================================

print_header "31. ECS Cluster"

ECS_CLUSTER_STATUS=$(aws ecs describe-clusters \
    --clusters "$ECS_CLUSTER" \
    --query "clusters[0].status" \
    --output text 2>/dev/null)

if [ "$ECS_CLUSTER_STATUS" = "ACTIVE" ]; then
    pass "ECS cluster is ACTIVE."
else
    fail "ECS cluster status: ${ECS_CLUSTER_STATUS:-NOT_FOUND}"
fi


# ================================================================
# 34. ECS Service
# ================================================================

print_header "32. ECS Service"

ECS_SERVICE_STATUS=$(aws ecs describe-services \
    --cluster "$ECS_CLUSTER" \
    --services "$ECS_SERVICE" \
    --query "services[0].status" \
    --output text 2>/dev/null)

if [ "$ECS_SERVICE_STATUS" = "ACTIVE" ]; then

    pass "ECS service is ACTIVE."

    aws ecs describe-services \
        --cluster "$ECS_CLUSTER" \
        --services "$ECS_SERVICE" \
        --query "services[0].[serviceName,status,desiredCount,runningCount,pendingCount]" \
        --output table

else

    fail "ECS service status: ${ECS_SERVICE_STATUS:-NOT_FOUND}"
fi


# ================================================================
# 35. ECS Running Tasks
# ================================================================

print_header "33. ECS Running Tasks"

TASK_ARNS=$(aws ecs list-tasks \
    --cluster "$ECS_CLUSTER" \
    --service-name "$ECS_SERVICE" \
    --desired-status RUNNING \
    --query "taskArns[]" \
    --output text 2>/dev/null)

if [ -n "$TASK_ARNS" ]; then

    pass "Running ECS task(s) found."

    aws ecs describe-tasks \
        --cluster "$ECS_CLUSTER" \
        --tasks $TASK_ARNS \
        --query "tasks[*].[taskArn,lastStatus,healthStatus,launchType]" \
        --output table

else

    warn "No running ECS task was found."
fi


# ================================================================
# 36. VPC Endpoints
# ================================================================

print_header "34. VPC Endpoints"

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then

    aws ec2 describe-vpc-endpoints \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "VpcEndpoints[*].[VpcEndpointId,ServiceName,VpcEndpointType,State]" \
        --output table

    ENDPOINT_COUNT=$(aws ec2 describe-vpc-endpoints \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "length(VpcEndpoints)" \
        --output text)

    if [ "$ENDPOINT_COUNT" -ge 3 ]; then
        pass "At least three VPC endpoints were found."
    else
        warn "Only $ENDPOINT_COUNT VPC endpoint(s) were found."
    fi

fi


# ================================================================
# 37. Application Load Balancer
# ================================================================

print_header "35. Application Load Balancer"

ALB_ARN=$(aws elbv2 describe-load-balancers \
    --query "LoadBalancers[?Type=='application'].LoadBalancerArn | [0]" \
    --output text 2>/dev/null)

if [ -n "$ALB_ARN" ] && [ "$ALB_ARN" != "None" ]; then

    pass "Application Load Balancer found."

    aws elbv2 describe-load-balancers \
        --load-balancer-arns "$ALB_ARN" \
        --query "LoadBalancers[0].[LoadBalancerName,DNSName,Scheme,Type,State.Code]" \
        --output table

    ALB_DNS=$(aws elbv2 describe-load-balancers \
        --load-balancer-arns "$ALB_ARN" \
        --query "LoadBalancers[0].DNSName" \
        --output text)

else

    warn "No Application Load Balancer found."
fi


# ================================================================
# 38. Target Groups
# ================================================================

print_header "36. ALB Target Groups"

if [ -n "$ALB_ARN" ] && [ "$ALB_ARN" != "None" ]; then

    TARGET_GROUPS=$(aws elbv2 describe-target-groups \
        --load-balancer-arn "$ALB_ARN" \
        --query "TargetGroups[*].TargetGroupArn" \
        --output text 2>/dev/null)

    if [ -n "$TARGET_GROUPS" ]; then

        pass "ALB target group(s) found."

        for TG in $TARGET_GROUPS; do

            aws elbv2 describe-target-health \
                --target-group-arn "$TG" \
                --query "TargetHealthDescriptions[*].[Target.Id,Target.Port,TargetHealth.State,TargetHealth.Reason]" \
                --output table

        done

    else

        warn "No ALB target groups were found."

    fi

fi


# ================================================================
# 39. Application HTTP Test
# ================================================================

print_header "37. Application HTTP Test"

if [ -n "$ALB_DNS" ] && [ "$ALB_DNS" != "None" ]; then

    HTTP_STATUS=$(curl -s -o /dev/null \
        -w "%{http_code}" \
        --connect-timeout 10 \
        "http://$ALB_DNS")

    echo "HTTP Status: $HTTP_STATUS"

    if [[ "$HTTP_STATUS" =~ ^2|3 ]]; then
        pass "Application responded through the ALB."
    else
        fail "Application did not return a successful HTTP response."
    fi

else

    warn "ALB DNS name unavailable; application test skipped."
fi


# ================================================================
# 40. CloudWatch Logs
# ================================================================

print_header "38. CloudWatch Logs"

LOG_GROUP="/ecs/charlie-cafe"

if aws logs describe-log-groups \
    --log-group-name-prefix "$LOG_GROUP" \
    --query "logGroups[?logGroupName=='$LOG_GROUP'].logGroupName" \
    --output text 2>/dev/null | grep -q "$LOG_GROUP"; then

    pass "CloudWatch log group exists: $LOG_GROUP"

    echo
    echo "--- Recent ECS Logs ---"

    aws logs tail "$LOG_GROUP" \
        --since 10m \
        --format short 2>/dev/null || \
        warn "Unable to retrieve recent CloudWatch logs."

else

    warn "CloudWatch log group was not found: $LOG_GROUP"
fi


# ================================================================
# 41. Local RDS Port Test
# ================================================================

print_header "39. Final EC2-to-RDS Connectivity"

if [ -n "$RDS_ENDPOINT" ] && [ "$RDS_ENDPOINT" != "None" ]; then

    if command -v nc >/dev/null 2>&1; then

        nc -z -w 5 "$RDS_ENDPOINT" "$RDS_PORT" >/dev/null 2>&1

        if [ $? -eq 0 ]; then
            pass "EC2 -> RDS connectivity verified."
        else
            fail "EC2 -> RDS connectivity failed."
        fi

    else

        warn "nc not installed. EC2 -> RDS TCP test skipped."

    fi

fi


# ================================================================
# 42. Final Summary
# ================================================================

print_header "FINAL VERIFICATION SUMMARY"

echo "Passed Tests : $PASS_COUNT"
echo "Failed Tests : $FAIL_COUNT"
echo "Warnings     : $WARN_COUNT"

echo

if [ "$FAIL_COUNT" -eq 0 ]; then

    echo "==============================================================="
    echo "RESULT: AWS CLOUDFORMATION LAB VERIFICATION PASSED"
    echo "==============================================================="

else

    echo "==============================================================="
    echo "RESULT: AWS CLOUDFORMATION LAB HAS FAILURES"
    echo "==============================================================="

    echo
    echo "Review the [FAIL] messages above."

fi

echo
echo "Verification completed."
echo "This script did not intentionally modify or delete AWS resources."
```

### How to Run the Bash Script on EC2

Create the file:

```
nano verify-cloudformation-lab.sh
```

Paste the script.

Save it and make it executable:

```
chmod +x verify-cloudformation-lab.sh
```

Run:

```
./verify-cloudformation-lab.sh
```

Or:

```
bash verify-cloudformation-lab.sh
```

If your AWS region is different:

```
AWS_REGION=ap-southeast-1 ./verify-cloudformation-lab.sh
```

For your lab, you can also export it first:

```
export AWS_REGION=us-east-1
```

Then:

```
./verify-cloudformation-lab.sh
```

### Create an IAM role for the EC2 lab

For your learning lab, the simplest initial approach is to create a role with read-only access.

You can create the role from the AWS Console:

IAM → Roles → Create role

Select:

```
Trusted entity type:
AWS service
```

Then:

```
Use case:
EC2
```

Create something like:

```
CharlieCafe-EC2-Verification-Role
```


For your first verification phase, you can attach:

```
ReadOnlyAccess
```

This is convenient for a lab because your verification script examines many AWS services.

Important

I would not use AdministratorAccess just to make the script work.

Your verification script only needs to inspect resources, so read-only permissions are much more appropriate.

### Attach the role to the existing EC2

After creating the role, go to:

EC2 → Instances → your instance

Then:

Actions → Security → Modify IAM role

Select:

```
CharlieCafe-EC2-Verification-Role
```

and save.

You do not need to recreate the EC2 instance.

### Test the role from EC2

After attaching the role, wait a few seconds and run:

```
TOKEN=$(curl -sX PUT \
  "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

curl -s \
  -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/iam/security-credentials/
```

Now you should get a role name, for example:

```
CharlieCafe-EC2-Verification-Role
```

Then:

```
aws sts get-caller-identity
```

You should get something similar to:

```
{
    "UserId": "AROAEXAMPLE:i-0123456789abcdef0",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:assumed-role/CharlieCafe-EC2-Verification-Role/i-0123456789abcdef0"
}
```

That is the result we want.

### 1. Verify CloudFormation

Once sts get-caller-identity works, test your main stack:

```
aws cloudformation list-stacks \
  --region us-east-1 \
  --stack-status-filter \
    CREATE_COMPLETE \
    UPDATE_COMPLETE \
    UPDATE_ROLLBACK_COMPLETE
```

If you know your stack name, even better:

```
aws cloudformation describe-stacks \
  --stack-name YOUR_MAIN_STACK_NAME \
  --region us-east-1
```

### 2. Verify your VPC

Your lab is using:

```
10.0.0.0/16
```

so test:

```
aws ec2 describe-vpcs \
  --filters "Name=cidr-block,Values=10.0.0.0/16" \
  --region us-east-1
```

You should now receive actual VPC information.

### 3. Verify ECS/ECR

Then:

```
aws ecs list-clusters \
  --region us-east-1
```

And:

```
aws ecr describe-repositories \
  --repository-names charlie-cafe \
  --region us-east-1
```

And:

```
aws ecs describe-services \
  --cluster CharlieCafe-Cluster \
  --services CharlieCafe-Service \
  --region us-east-1
```

These commands will tell us whether the resources actually exist.









---
# 7. Verify-CloudFormationLab.ps1

#### PowerShell Script — Run From Windows


```
# =================================================================
# AWS CloudFormation DevOps Lab - Complete Verification Script
# =================================================================
#
# Purpose:
#   Verify the AWS CloudFormation DevOps Lab from Windows PowerShell.
#
# This script performs READ-ONLY verification.
# It does NOT create, update, or delete AWS resources.
#
# Main areas tested:
#   CloudFormation
#   Nested Stacks
#   VPC
#   Subnets
#   Route Tables
#   Internet Gateway
#   Security Groups
#   EC2
#   S3
#   RDS
#   Secrets Manager
#   ECR
#   ECS
#   VPC Endpoints
#   Application Load Balancer
#   CloudWatch Logs
#   End-to-End Application
#
# =================================================================


# =================================================================
# 1. Configuration
# =================================================================

$MainStack = "CloudFormation-DevOps-Lab"
$EcsStack = "CharlieCafe-ECS-Stack"

$EcrRepository = "charlie-cafe"
$EcsCluster = "CharlieCafe-Cluster"
$EcsService = "CharlieCafe-Service"

# Change this if your AWS region is different.
$AwsRegion = if ($env:AWS_REGION) {
    $env:AWS_REGION
}
elseif ($env:AWS_DEFAULT_REGION) {
    $env:AWS_DEFAULT_REGION
}
else {
    "us-east-1"
}


# =================================================================
# 2. Test Counters
# =================================================================

$PassCount = 0
$FailCount = 0
$WarnCount = 0


# =================================================================
# 3. Output Functions
# =================================================================

function Write-Header {
    param (
        [string]$Message
    )

    Write-Host ""
    Write-Host "==============================================================="
    Write-Host $Message
    Write-Host "==============================================================="
}

function Write-Pass {
    param (
        [string]$Message
    )

    Write-Host "[PASS] $Message"
    $script:PassCount++
}

function Write-Fail {
    param (
        [string]$Message
    )

    Write-Host "[FAIL] $Message"
    $script:FailCount++
}

function Write-Warn {
    param (
        [string]$Message
    )

    Write-Host "[WARN] $Message"
    $script:WarnCount++
}

function Write-Info {
    param (
        [string]$Message
    )

    Write-Host "[INFO] $Message"
}


# =================================================================
# 4. AWS CLI Verification
# =================================================================

Write-Header "1. AWS CLI Verification"

$AwsCli = Get-Command aws -ErrorAction SilentlyContinue

if ($AwsCli) {

    Write-Pass "AWS CLI is installed."

    aws --version

}
else {

    Write-Fail "AWS CLI is not installed."

}


# =================================================================
# 5. AWS Region
# =================================================================

Write-Header "2. AWS Region"

Write-Host "AWS Region: $AwsRegion"

$env:AWS_DEFAULT_REGION = $AwsRegion

Write-Pass "AWS region configured."


# =================================================================
# 6. AWS Identity
# =================================================================

Write-Header "3. AWS Identity / IAM Verification"

$Identity = aws sts get-caller-identity 2>$null

if ($LASTEXITCODE -eq 0) {

    Write-Pass "AWS credentials are working."

    $Identity | ConvertFrom-Json |
        Select-Object Account, Arn |
        Format-Table -AutoSize

}
else {

    Write-Fail "AWS credentials are not working."

}


# =================================================================
# 7. Main CloudFormation Stack
# =================================================================

Write-Header "4. Main CloudFormation Stack"

$MainStackStatus = aws cloudformation describe-stacks `
    --stack-name $MainStack `
    --query "Stacks[0].StackStatus" `
    --output text 2>$null

if (
    $MainStackStatus -eq "CREATE_COMPLETE" -or
    $MainStackStatus -eq "UPDATE_COMPLETE"
) {

    Write-Pass "Main stack status: $MainStackStatus"

}
else {

    if ([string]::IsNullOrWhiteSpace($MainStackStatus)) {
        Write-Fail "Main CloudFormation stack was not found."
    }
    else {
        Write-Fail "Main CloudFormation stack status: $MainStackStatus"
    }

}


# =================================================================
# 8. Main Stack Outputs
# =================================================================

Write-Header "5. Main Stack Outputs"

aws cloudformation describe-stacks `
    --stack-name $MainStack `
    --query "Stacks[0].Outputs[*].[OutputKey,OutputValue]" `
    --output table

if ($LASTEXITCODE -eq 0) {
    Write-Pass "Main stack outputs retrieved."
}
else {
    Write-Fail "Unable to retrieve main stack outputs."
}


# =================================================================
# 9. Main Stack Resources
# =================================================================

Write-Header "6. Main Stack Resources"

aws cloudformation list-stack-resources `
    --stack-name $MainStack `
    --query "StackResourceSummaries[*].[LogicalResourceId,ResourceType,ResourceStatus]" `
    --output table

if ($LASTEXITCODE -eq 0) {
    Write-Pass "Main stack resources retrieved."
}
else {
    Write-Fail "Unable to retrieve main stack resources."
}


# =================================================================
# 10. Nested Stacks
# =================================================================

Write-Header "7. Nested CloudFormation Stacks"

$NestedStacks = aws cloudformation list-stack-resources `
    --stack-name $MainStack `
    --query "StackResourceSummaries[?ResourceType=='AWS::CloudFormation::Stack'].[LogicalResourceId,PhysicalResourceId,ResourceStatus]" `
    --output table 2>$null

if ($LASTEXITCODE -eq 0 -and $NestedStacks) {

    $NestedStacks

    Write-Pass "Nested CloudFormation stacks were found."

}
else {

    Write-Warn "No nested stacks were detected."

}


# =================================================================
# 11. Find VPC
# =================================================================

Write-Header "8. VPC Verification"

$VpcId = aws ec2 describe-vpcs `
    --filters "Name=cidr-block,Values=10.0.0.0/16" `
    --query "Vpcs[0].VpcId" `
    --output text 2>$null

if ($VpcId -and $VpcId -ne "None") {

    Write-Pass "VPC found: $VpcId"

    aws ec2 describe-vpcs `
        --vpc-ids $VpcId `
        --query "Vpcs[0].[VpcId,CidrBlock,State]" `
        --output table

}
else {

    Write-Fail "VPC with CIDR 10.0.0.0/16 was not found."

}


# =================================================================
# 12. VPC DNS Support
# =================================================================

Write-Header "9. VPC DNS Support"

if ($VpcId -and $VpcId -ne "None") {

    $DnsSupport = aws ec2 describe-vpc-attribute `
        --vpc-id $VpcId `
        --attribute enableDnsSupport `
        --query "EnableDnsSupport.Value" `
        --output text

    if ($DnsSupport -eq "True") {
        Write-Pass "VPC DNS support is enabled."
    }
    else {
        Write-Fail "VPC DNS support is not enabled."
    }


    $DnsHostnames = aws ec2 describe-vpc-attribute `
        --vpc-id $VpcId `
        --attribute enableDnsHostnames `
        --query "EnableDnsHostnames.Value" `
        --output text

    if ($DnsHostnames -eq "True") {
        Write-Pass "VPC DNS hostnames are enabled."
    }
    else {
        Write-Fail "VPC DNS hostnames are not enabled."
    }

}


# =================================================================
# 13. Internet Gateway
# =================================================================

Write-Header "10. Internet Gateway"

if ($VpcId -and $VpcId -ne "None") {

    $IgwId = aws ec2 describe-internet-gateways `
        --filters "Name=attachment.vpc-id,Values=$VpcId" `
        --query "InternetGateways[0].InternetGatewayId" `
        --output text 2>$null

    if ($IgwId -and $IgwId -ne "None") {
        Write-Pass "Internet Gateway attached: $IgwId"
    }
    else {
        Write-Fail "Internet Gateway is not attached to the VPC."
    }

}


# =================================================================
# 14. Subnets
# =================================================================

Write-Header "11. VPC Subnets"

if ($VpcId -and $VpcId -ne "None") {

    aws ec2 describe-subnets `
        --filters "Name=vpc-id,Values=$VpcId" `
        --query "Subnets[*].[SubnetId,AvailabilityZone,CidrBlock,MapPublicIpOnLaunch,Tags[?Key=='Name'].Value|[0]]" `
        --output table

    $SubnetCount = aws ec2 describe-subnets `
        --filters "Name=vpc-id,Values=$VpcId" `
        --query "length(Subnets)" `
        --output text

    if ([int]$SubnetCount -ge 4) {
        Write-Pass "At least four subnets were found."
    }
    else {
        Write-Warn "Expected approximately four subnets, found $SubnetCount."
    }

}


# =================================================================
# 15. Route Tables
# =================================================================

Write-Header "12. Route Tables"

if ($VpcId -and $VpcId -ne "None") {

    aws ec2 describe-route-tables `
        --filters "Name=vpc-id,Values=$VpcId" `
        --query "RouteTables[*].[RouteTableId,Routes[*].[DestinationCidrBlock,GatewayId,NatGatewayId],Tags[?Key=='Name'].Value|[0]]" `
        --output table

    Write-Pass "Route tables retrieved."

}


# =================================================================
# 16. Security Groups
# =================================================================

Write-Header "13. Security Groups"

if ($VpcId -and $VpcId -ne "None") {

    aws ec2 describe-security-groups `
        --filters "Name=vpc-id,Values=$VpcId" `
        --query "SecurityGroups[*].[GroupId,GroupName,Description]" `
        --output table

    Write-Pass "Security groups retrieved."

}


# =================================================================
# 17. EC2 Verification
# =================================================================

Write-Header "14. EC2 Verification"

$InstanceId = aws ec2 describe-instances `
    --filters `
        "Name=vpc-id,Values=$VpcId" `
        "Name=instance-state-name,Values=running" `
    --query "Reservations[0].Instances[0].InstanceId" `
    --output text 2>$null

if ($InstanceId -and $InstanceId -ne "None") {

    Write-Pass "Running EC2 instance found: $InstanceId"

    aws ec2 describe-instances `
        --instance-ids $InstanceId `
        --query "Reservations[0].Instances[0].[InstanceId,InstanceType,State.Name,SubnetId,PrivateIpAddress,PublicIpAddress]" `
        --output table

}
else {

    Write-Warn "No running EC2 instance was found."

}


# =================================================================
# 18. EC2 Health
# =================================================================

Write-Header "15. EC2 System Health"

if ($InstanceId -and $InstanceId -ne "None") {

    $Health = aws ec2 describe-instance-status `
        --instance-ids $InstanceId `
        --include-all-instances `
        --query "InstanceStatuses[0].[SystemStatus.Status,InstanceStatus.Status]" `
        --output text

    Write-Host $Health

    if ($Health -match "ok") {
        Write-Pass "EC2 health checks are healthy."
    }
    else {
        Write-Warn "EC2 health checks are not both OK."
    }

}


# =================================================================
# 19. S3
# =================================================================

Write-Header "16. S3 Verification"

$S3Buckets = aws s3api list-buckets `
    --query "Buckets[].Name" `
    --output text 2>$null

if ($S3Buckets) {

    Write-Pass "S3 bucket(s) found."

    aws s3api list-buckets `
        --query "Buckets[*].[Name,CreationDate]" `
        --output table

}
else {

    Write-Warn "No S3 buckets were found."

}


# =================================================================
# 20. S3 Versioning
# =================================================================

Write-Header "17. S3 Versioning"

if ($S3Buckets) {

    foreach ($Bucket in ($S3Buckets -split "\s+")) {

        if ($Bucket) {

            Write-Host ""
            Write-Host "Bucket: $Bucket"

            aws s3api get-bucket-versioning `
                --bucket $Bucket `
                --output json

        }

    }

    Write-Pass "S3 versioning information retrieved."

}


# =================================================================
# 21. RDS
# =================================================================

Write-Header "18. RDS MySQL Verification"

$RdsIdentifier = aws rds describe-db-instances `
    --query "DBInstances[?Engine=='mysql'].DBInstanceIdentifier | [0]" `
    --output text 2>$null

if ($RdsIdentifier -and $RdsIdentifier -ne "None") {

    Write-Pass "RDS MySQL instance found: $RdsIdentifier"

    aws rds describe-db-instances `
        --db-instance-identifier $RdsIdentifier `
        --query "DBInstances[0].[DBInstanceIdentifier,Engine,DBInstanceStatus,PubliclyAccessible,Endpoint.Address,Endpoint.Port]" `
        --output table

    $RdsEndpoint = aws rds describe-db-instances `
        --db-instance-identifier $RdsIdentifier `
        --query "DBInstances[0].Endpoint.Address" `
        --output text

    $RdsPort = aws rds describe-db-instances `
        --db-instance-identifier $RdsIdentifier `
        --query "DBInstances[0].Endpoint.Port" `
        --output text

    $RdsPublic = aws rds describe-db-instances `
        --db-instance-identifier $RdsIdentifier `
        --query "DBInstances[0].PubliclyAccessible" `
        --output text

    if ($RdsPublic -eq "False") {
        Write-Pass "RDS is private."
    }
    else {
        Write-Warn "RDS is publicly accessible."
    }

}
else {

    Write-Warn "No MySQL RDS instance found."

}


# =================================================================
# 22. Secrets Manager
# =================================================================

Write-Header "19. Secrets Manager"

$Secrets = aws secretsmanager list-secrets `
    --query "SecretList[*].[Name,ARN]" `
    --output table 2>$null

if ($Secrets) {

    Write-Pass "Secrets Manager secrets were found."

    # Only display secret metadata.
    # NEVER print secret values/passwords.
    $Secrets

}
else {

    Write-Warn "No Secrets Manager secrets were found."

}


# =================================================================
# 23. ECS CloudFormation Stack
# =================================================================

Write-Header "20. ECS CloudFormation Stack"

$EcsStackStatus = aws cloudformation describe-stacks `
    --stack-name $EcsStack `
    --query "Stacks[0].StackStatus" `
    --output text 2>$null

if (
    $EcsStackStatus -eq "CREATE_COMPLETE" -or
    $EcsStackStatus -eq "UPDATE_COMPLETE"
) {

    Write-Pass "ECS stack status: $EcsStackStatus"

}
else {

    Write-Fail "ECS stack status: $EcsStackStatus"

}


# =================================================================
# 24. ECR
# =================================================================

Write-Header "21. ECR Verification"

aws ecr describe-repositories `
    --repository-names $EcrRepository `
    --query "repositories[*].[repositoryName,repositoryUri]" `
    --output table 2>$null

if ($LASTEXITCODE -eq 0) {

    Write-Pass "ECR repository exists."

    aws ecr describe-images `
        --repository-name $EcrRepository `
        --query "imageDetails[*].[imageTags,imageDigest,imagePushedAt]" `
        --output table

}
else {

    Write-Fail "ECR repository does not exist."

}


# =================================================================
# 25. ECS Cluster
# =================================================================

Write-Header "22. ECS Cluster"

$ClusterStatus = aws ecs describe-clusters `
    --clusters $EcsCluster `
    --query "clusters[0].status" `
    --output text 2>$null

if ($ClusterStatus -eq "ACTIVE") {

    Write-Pass "ECS cluster is ACTIVE."

}
else {

    Write-Fail "ECS cluster status: $ClusterStatus"

}


# =================================================================
# 26. ECS Service
# =================================================================

Write-Header "23. ECS Service"

$ServiceStatus = aws ecs describe-services `
    --cluster $EcsCluster `
    --services $EcsService `
    --query "services[0].status" `
    --output text 2>$null

if ($ServiceStatus -eq "ACTIVE") {

    Write-Pass "ECS service is ACTIVE."

    aws ecs describe-services `
        --cluster $EcsCluster `
        --services $EcsService `
        --query "services[0].[serviceName,status,desiredCount,runningCount,pendingCount]" `
        --output table

}
else {

    Write-Fail "ECS service status: $ServiceStatus"

}


# =================================================================
# 27. ECS Running Tasks
# =================================================================

Write-Header "24. ECS Running Tasks"

$TaskArns = aws ecs list-tasks `
    --cluster $EcsCluster `
    --service-name $EcsService `
    --desired-status RUNNING `
    --query "taskArns[]" `
    --output text 2>$null

if ($TaskArns) {

    Write-Pass "Running ECS task(s) found."

    aws ecs describe-tasks `
        --cluster $EcsCluster `
        --tasks $TaskArns `
        --query "tasks[*].[taskArn,lastStatus,healthStatus,launchType]" `
        --output table

}
else {

    Write-Warn "No running ECS task was found."

}


# =================================================================
# 28. VPC Endpoints
# =================================================================

Write-Header "25. VPC Endpoints"

if ($VpcId -and $VpcId -ne "None") {

    aws ec2 describe-vpc-endpoints `
        --filters "Name=vpc-id,Values=$VpcId" `
        --query "VpcEndpoints[*].[VpcEndpointId,ServiceName,VpcEndpointType,State]" `
        --output table

    $EndpointCount = aws ec2 describe-vpc-endpoints `
        --filters "Name=vpc-id,Values=$VpcId" `
        --query "length(VpcEndpoints)" `
        --output text

    if ([int]$EndpointCount -ge 3) {
        Write-Pass "At least three VPC endpoints were found."
    }
    else {
        Write-Warn "Only $EndpointCount VPC endpoint(s) were found."
    }

}


# =================================================================
# 29. Application Load Balancer
# =================================================================

Write-Header "26. Application Load Balancer"

$AlbArn = aws elbv2 describe-load-balancers `
    --query "LoadBalancers[?Type=='application'].LoadBalancerArn | [0]" `
    --output text 2>$null

if ($AlbArn -and $AlbArn -ne "None") {

    Write-Pass "Application Load Balancer found."

    aws elbv2 describe-load-balancers `
        --load-balancer-arns $AlbArn `
        --query "LoadBalancers[0].[LoadBalancerName,DNSName,Scheme,Type,State.Code]" `
        --output table

    $AlbDns = aws elbv2 describe-load-balancers `
        --load-balancer-arns $AlbArn `
        --query "LoadBalancers[0].DNSName" `
        --output text

}
else {

    Write-Warn "Application Load Balancer was not found."

}


# =================================================================
# 30. ALB Target Health
# =================================================================

Write-Header "27. ALB Target Health"

if ($AlbArn -and $AlbArn -ne "None") {

    $TargetGroups = aws elbv2 describe-target-groups `
        --load-balancer-arn $AlbArn `
        --query "TargetGroups[*].TargetGroupArn" `
        --output text 2>$null

    if ($TargetGroups) {

        foreach ($TargetGroup in ($TargetGroups -split "\s+")) {

            if ($TargetGroup) {

                Write-Host ""
                Write-Host "Target Group: $TargetGroup"

                aws elbv2 describe-target-health `
                    --target-group-arn $TargetGroup `
                    --query "TargetHealthDescriptions[*].[Target.Id,Target.Port,TargetHealth.State,TargetHealth.Reason]" `
                    --output table

            }

        }

        Write-Pass "ALB target health information retrieved."

    }
    else {

        Write-Warn "No target groups found."

    }

}


# =================================================================
# 31. Application HTTP Test
# =================================================================

Write-Header "28. Application HTTP Test"

if ($AlbDns -and $AlbDns -ne "None") {

    $ApplicationUrl = "http://$AlbDns"

    Write-Host "Testing: $ApplicationUrl"

    try {

        $Response = Invoke-WebRequest `
            -Uri $ApplicationUrl `
            -UseBasicParsing `
            -TimeoutSec 15

        Write-Host "HTTP Status: $($Response.StatusCode)"

        if ($Response.StatusCode -ge 200 -and $Response.StatusCode -lt 400) {

            Write-Pass "Application responded successfully through ALB."

        }
        else {

            Write-Fail "Application returned an unexpected HTTP status."

        }

    }
    catch {

        Write-Fail "Application HTTP request failed."
        Write-Host $_.Exception.Message

    }

}
else {

    Write-Warn "ALB DNS name unavailable."

}


# =================================================================
# 32. CloudWatch Logs
# =================================================================

Write-Header "29. CloudWatch Logs"

$LogGroup = "/ecs/charlie-cafe"

aws logs describe-log-groups `
    --log-group-name-prefix $LogGroup `
    --query "logGroups[*].[logGroupName,storedBytes]" `
    --output table 2>$null

if ($LASTEXITCODE -eq 0) {

    Write-Pass "CloudWatch log group information retrieved."

}
else {

    Write-Warn "Unable to retrieve CloudWatch log group."

}


# =================================================================
# 33. RDS DNS Test
# =================================================================

Write-Header "30. RDS DNS Verification"

if ($RdsEndpoint -and $RdsEndpoint -ne "None") {

    Write-Host "RDS Endpoint: $RdsEndpoint"

    try {

        $DnsResult = Resolve-DnsName `
            -Name $RdsEndpoint `
            -ErrorAction Stop

        Write-Pass "RDS endpoint resolves through DNS."

        $DnsResult |
            Select-Object Name, Type, IPAddress |
            Format-Table -AutoSize

    }
    catch {

        Write-Fail "RDS endpoint DNS resolution failed."

    }

}


# =================================================================
# 34. Final Summary
# =================================================================

Write-Header "FINAL VERIFICATION SUMMARY"

Write-Host "Passed Tests : $PassCount"
Write-Host "Failed Tests : $FailCount"
Write-Host "Warnings     : $WarnCount"

Write-Host ""

if ($FailCount -eq 0) {

    Write-Host "==============================================================="
    Write-Host "RESULT: AWS CLOUDFORMATION LAB VERIFICATION PASSED"
    Write-Host "==============================================================="

}
else {

    Write-Host "==============================================================="
    Write-Host "RESULT: AWS CLOUDFORMATION LAB HAS FAILURES"
    Write-Host "==============================================================="

    Write-Host ""
    Write-Host "Review the [FAIL] messages above."

}

Write-Host ""
Write-Host "Verification completed."
Write-Host "This script does not intentionally modify or delete AWS resources."
```

### Run the PowerShell Script

Open PowerShell in the directory containing the file:

```
cd C:\Users\YourName\Documents\CloudFormation-DevOps-Lab
```

Check AWS CLI:

```
aws --version
```

Check your identity:

```
aws sts get-caller-identity
```

Set your region:

```
$env:AWS_REGION="us-east-1"
```

Then run:

```
.\Verify-CloudFormationLab.ps1
```

If PowerShell blocks the script because of execution policy, you can run it for the current PowerShell process:

```
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Then:

```
.\Verify-CloudFormationLab.ps1
```

## One Important Difference Between the Two Scripts "Verify-CloudFormationLab.ps1" & "verify-cloudformation-lab.sh"

There is an important architectural difference.

### EC2 Bash script

The Bash script can test things that only make sense from inside your VPC, for example:

```
EC2
 |
 +-- DNS
 |
 +-- Internet
 |
 +-- GitHub
 |
 +-- RDS endpoint
 |
 +-- RDS port 3306
 |
 +-- Local Apache
 |
 +-- Docker
 |
 +-- UserData
 |
 +-- AWS CLI
```

So the EC2 script is your inside-the-network verification.

### PowerShell script

The PowerShell script is better for testing:

```
CloudFormation
VPC
Subnets
Route Tables
Security Groups
EC2
S3
RDS
ECR
ECS
ALB
VPC Endpoints
CloudWatch
```

and then testing the application externally:

```
Windows
   |
   v
Internet
   |
   v
ALB
   |
   v
ECS
```

So together:

```
                  AWS CloudFormation Lab
                           |
              +------------+------------+
              |                         |
              v                         v
       Windows PowerShell          EC2 Bash
       External Testing            Internal Testing
              |                         |
              |                         |
              v                         v
       AWS Resources              VPC Connectivity
       CloudFormation             RDS Connectivity
       ECS                        DNS
       ECR                        Docker
       ALB                        Apache
       S3                         UserData
       VPC                        AWS CLI
       RDS                        GitHub
       CloudWatch                 Application
```

### Recommended professional repository structure

Since you're also organizing the repository around CloudFormation and Terraform, I would keep these verification scripts with the corresponding infrastructure:

```
CloudFormation-DevOps-Lab/
│
├── infrastructure/
│   │
│   ├── aws-cloudformation/
│   │   │
│   │   ├── templates/
│   │   │   ├── main.yaml
│   │   │   ├── aws-ecs-ecr.yaml
│   │   │   ├── aws-rds.yaml
│   │   │   ├── ec2-webserver.yaml
│   │   │   ├── s3.yaml
│   │   │   └── template-bucket.yaml
│   │   │
│   │   ├── scripts/
│   │   │   ├── verify-cloudformation-lab.sh
│   │   │   └── Verify-CloudFormationLab.ps1
│   │   │
│   │   └── README.md
│   │
│   └── terraform/
│       ├── modules/
│       ├── environments/
│       ├── scripts/
│       └── README.md
│
├── .github/
│   └── workflows/
│
├── application/
│
└── README.md
```

That gives you a very clean separation:

```
CloudFormation
      |
      +-- templates
      +-- scripts
      +-- documentation

Terraform
      |
      +-- modules
      +-- environments
      +-- scripts
      +-- documentation
```

One recommendation: before putting these scripts into your final GitHub repository, I would adjust the resource discovery to use your actual CloudFormation Outputs and resource logical IDs instead of generic discovery for things like the VPC, RDS, S3 bucket, and ALB. That will make the verification much more deterministic and professional for your specific lab.

---
# 8. verify-cloudformation-lab.sh

```

```

---
