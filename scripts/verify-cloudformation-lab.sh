#!/bin/bash

# ================================================================
# AWS CloudFormation DevOps Lab
# Complete Read-Only Verification Script
# ================================================================
#
# Purpose:
#   Verify the Charlie Cafe AWS CloudFormation / DevOps lab
#   from inside an EC2 instance.
#
# IMPORTANT:
#   This script performs READ-ONLY verification.
#
#   It does NOT intentionally:
#       - Create AWS resources
#       - Update AWS resources
#       - Delete AWS resources
#       - Start/stop EC2 instances
#       - Change ECS desired count
#       - Push Docker images
#       - Modify IAM permissions
#
# ================================================================
#
# Main areas tested:
#
#   1.  AWS CLI
#   2.  AWS Region
#   3.  AWS Identity / IAM
#   4.  CloudFormation Main Stack
#   5.  CloudFormation Outputs
#   6.  CloudFormation Resources
#   7.  Nested Stacks
#   8.  VPC
#   9.  VPC DNS
#   10. Internet Gateway
#   11. Subnets
#   12. Route Tables
#   13. Security Groups
#   14. EC2
#   15. EC2 System Health
#   16. UserData / Cloud-Init
#   17. Internet Connectivity
#   18. DNS
#   19. Apache
#   20. PHP
#   21. Docker
#   22. Docker Compose
#   23. Git
#   24. AWS Authentication
#   25. S3
#   26. RDS
#   27. RDS Network Connectivity
#   28. Secrets Manager
#   29. ECS CloudFormation Stack
#   30. ECR
#   31. ECS Cluster
#   32. ECS Service
#   33. ECS Running Tasks
#   34. VPC Endpoints
#   35. Application Load Balancer
#   36. ALB Target Groups
#   37. Application HTTP Test
#   38. CloudWatch Logs
#   39. Final EC2-to-RDS Connectivity
#
# ================================================================


# ================================================================
# 1. CONFIGURATION
# ================================================================
#
# CHANGE YOUR AWS REGION HERE.
#
# Examples:
#
#   AWS_REGION="us-east-1"
#   AWS_REGION="us-east-2"
#   AWS_REGION="eu-west-1"
#   AWS_REGION="ap-southeast-1"
#
# Do NOT hardcode the region throughout the script.
# All AWS CLI commands below use this variable.
#
# ================================================================

AWS_REGION="us-east-1"

# Optional AWS CLI profile.
#
# Leave empty when using the EC2 IAM Role:
#
#     AWS_PROFILE=""
#
# Example when using a configured local AWS profile:
#
#     AWS_PROFILE="default"
#
AWS_PROFILE=""

# ================================================================
# CloudFormation Stack Names
# ================================================================

MAIN_STACK="Main-CloudFormation"
ECS_STACK="CharlieCafe-ECS-Stack"


# ================================================================
# ECS / ECR Configuration
# ================================================================

ECR_REPOSITORY="charlie-cafe"

ECS_CLUSTER="CharlieCafe-Cluster"

ECS_SERVICE="CharlieCafe-Service"

CONTAINER_PORT="80"


# ================================================================
# CloudWatch Configuration
# ================================================================

LOG_GROUP="/ecs/charlie-cafe"


# ================================================================
# Expected VPC CIDR
# ================================================================
#
# Used only as a fallback if the VPC ID cannot be obtained
# from CloudFormation outputs.
#
# Change this if your lab uses another CIDR.
#
# ================================================================

EXPECTED_VPC_CIDR="10.0.0.0/16"


# ================================================================
# Verification Counters
# ================================================================

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0


# ================================================================
# AWS CLI Configuration
# ================================================================

# Disable AWS CLI pagination.
#
# This prevents commands such as:
#
#     aws cloudformation describe-stacks
#
# from opening a pager such as "less".
#
export AWS_PAGER=""

# Export the region so commands/tools that use
# AWS_DEFAULT_REGION can also see it.
export AWS_DEFAULT_REGION="$AWS_REGION"


# ================================================================
# Optional AWS Profile
# ================================================================

if [ -n "$AWS_PROFILE" ]; then

    export AWS_PROFILE

fi


# ================================================================
# Helper: AWS CLI Base Command
# ================================================================
#
# Every AWS command should use:
#
#     aws ... --region "$AWS_REGION"
#
# This guarantees that the verification script checks
# the region configured at the top of this file.
#
# ================================================================


# ================================================================
# 2. OUTPUT FUNCTIONS
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
# 3. VERIFY AWS CLI
# ================================================================

print_header "1. AWS CLI Verification"

if command -v aws >/dev/null 2>&1; then

    pass "AWS CLI is installed."

    aws --version

else

    fail "AWS CLI is not installed."

fi


# ================================================================
# 4. VERIFY CONFIGURATION
# ================================================================

print_header "2. Verification Configuration"

echo "AWS Region          : $AWS_REGION"
echo "AWS Profile         : ${AWS_PROFILE:-EC2 IAM Role / Default Credentials}"
echo "Main Stack          : $MAIN_STACK"
echo "ECS Stack           : $ECS_STACK"
echo "ECR Repository      : $ECR_REPOSITORY"
echo "ECS Cluster         : $ECS_CLUSTER"
echo "ECS Service         : $ECS_SERVICE"
echo "CloudWatch Log Group: $LOG_GROUP"
echo "Expected VPC CIDR   : $EXPECTED_VPC_CIDR"

pass "Verification configuration loaded."


# ================================================================
# 5. VERIFY AWS IDENTITY
# ================================================================

print_header "3. AWS Identity / IAM Verification"

IDENTITY=$(aws sts get-caller-identity \
    --region "$AWS_REGION" \
    2>/dev/null)

if [ $? -eq 0 ]; then

    pass "AWS credentials are working."

    echo
    echo "--- AWS Caller Identity ---"

    aws sts get-caller-identity \
        --region "$AWS_REGION" \
        --query "[Account,Arn]" \
        --output table

    AWS_ACCOUNT_ID=$(aws sts get-caller-identity \
        --region "$AWS_REGION" \
        --query "Account" \
        --output text)

    AWS_CALLER_ARN=$(aws sts get-caller-identity \
        --region "$AWS_REGION" \
        --query "Arn" \
        --output text)

    echo
    echo "AWS Account ID : $AWS_ACCOUNT_ID"
    echo "Caller ARN     : $AWS_CALLER_ARN"

else

    fail "AWS credentials are not working."

    echo
    echo "Possible causes:"
    echo "  1. EC2 does not have an IAM role."
    echo "  2. IAM role is not attached to the instance."
    echo "  3. AWS CLI credentials are invalid."
    echo "  4. AWS metadata credentials are unavailable."

fi


# ================================================================
# 6. MAIN CLOUDFORMATION STACK
# ================================================================

print_header "4. Main CloudFormation Stack"

MAIN_STACK_STATUS=$(aws cloudformation describe-stacks \
    --stack-name "$MAIN_STACK" \
    --region "$AWS_REGION" \
    --query "Stacks[0].StackStatus" \
    --output text \
    2>/dev/null)

if [ "$MAIN_STACK_STATUS" = "CREATE_COMPLETE" ] || \
   [ "$MAIN_STACK_STATUS" = "UPDATE_COMPLETE" ]; then

    pass "Main CloudFormation stack status: $MAIN_STACK_STATUS"

else

    if [ -z "$MAIN_STACK_STATUS" ] || \
       [ "$MAIN_STACK_STATUS" = "None" ]; then

        fail "Main CloudFormation stack was not found."

    else

        fail "Main CloudFormation stack status: $MAIN_STACK_STATUS"

    fi

fi


# ================================================================
# 7. MAIN STACK OUTPUTS
# ================================================================

print_header "5. Main Stack Outputs"

aws cloudformation describe-stacks \
    --stack-name "$MAIN_STACK" \
    --region "$AWS_REGION" \
    --query "Stacks[0].Outputs[*].[OutputKey,OutputValue]" \
    --output table \
    2>/dev/null

if [ $? -eq 0 ]; then

    pass "Main stack outputs retrieved."

else

    fail "Unable to retrieve main stack outputs."

fi


# ================================================================
# 8. MAIN STACK RESOURCES
# ================================================================

print_header "6. Main Stack Resources"

aws cloudformation list-stack-resources \
    --stack-name "$MAIN_STACK" \
    --region "$AWS_REGION" \
    --query "StackResourceSummaries[*].[LogicalResourceId,ResourceType,ResourceStatus]" \
    --output table \
    2>/dev/null

if [ $? -eq 0 ]; then

    pass "Main stack resources retrieved."

else

    fail "Unable to retrieve main stack resources."

fi


# ================================================================
# 9. NESTED STACKS
# ================================================================

print_header "7. Nested CloudFormation Stacks"

NESTED_STACKS=$(aws cloudformation list-stack-resources \
    --stack-name "$MAIN_STACK" \
    --region "$AWS_REGION" \
    --query "StackResourceSummaries[?ResourceType=='AWS::CloudFormation::Stack'].[LogicalResourceId,PhysicalResourceId,ResourceStatus]" \
    --output text \
    2>/dev/null)

if [ -n "$NESTED_STACKS" ]; then

    echo "$NESTED_STACKS"

    pass "Nested CloudFormation stacks were found."

else

    warn "No nested stacks were detected."

fi


# ================================================================
# 10. RETRIEVE VPC ID
# ================================================================

print_header "8. VPC Verification"

VPC_ID=$(aws cloudformation describe-stacks \
    --stack-name "$MAIN_STACK" \
    --region "$AWS_REGION" \
    --query "Stacks[0].Outputs[?contains(OutputKey, 'Vpc') || contains(OutputKey, 'VPC')].OutputValue | [0]" \
    --output text \
    2>/dev/null)

# ------------------------------------------------
# Fallback VPC discovery
# ------------------------------------------------

if [ -z "$VPC_ID" ] || [ "$VPC_ID" = "None" ]; then

    info "VPC ID was not found in CloudFormation outputs."

    info "Searching for VPC with CIDR $EXPECTED_VPC_CIDR..."

    VPC_ID=$(aws ec2 describe-vpcs \
        --region "$AWS_REGION" \
        --filters "Name=cidr-block,Values=$EXPECTED_VPC_CIDR" \
        --query "Vpcs[0].VpcId" \
        --output text \
        2>/dev/null)

fi


if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then

    pass "VPC found: $VPC_ID"

    aws ec2 describe-vpcs \
        --vpc-ids "$VPC_ID" \
        --region "$AWS_REGION" \
        --query "Vpcs[0].[VpcId,CidrBlock,State]" \
        --output table

else

    fail "VPC could not be identified."

fi


# ================================================================
# 11. VPC DNS SUPPORT
# ================================================================

print_header "9. VPC DNS Support"

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then

    DNS_SUPPORT=$(aws ec2 describe-vpc-attribute \
        --vpc-id "$VPC_ID" \
        --attribute enableDnsSupport \
        --region "$AWS_REGION" \
        --query "EnableDnsSupport.Value" \
        --output text \
        2>/dev/null)

    if [ "$DNS_SUPPORT" = "True" ]; then

        pass "VPC DNS support is enabled."

    else

        fail "VPC DNS support is not enabled."

    fi


    DNS_HOSTNAMES=$(aws ec2 describe-vpc-attribute \
        --vpc-id "$VPC_ID" \
        --attribute enableDnsHostnames \
        --region "$AWS_REGION" \
        --query "EnableDnsHostnames.Value" \
        --output text \
        2>/dev/null)

    if [ "$DNS_HOSTNAMES" = "True" ]; then

        pass "VPC DNS hostnames are enabled."

    else

        fail "VPC DNS hostnames are not enabled."

    fi

fi


# ================================================================
# 12. INTERNET GATEWAY
# ================================================================

print_header "10. Internet Gateway"

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then

    IGW_ID=$(aws ec2 describe-internet-gateways \
        --region "$AWS_REGION" \
        --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
        --query "InternetGateways[0].InternetGatewayId" \
        --output text \
        2>/dev/null)

    if [ -n "$IGW_ID" ] && [ "$IGW_ID" != "None" ]; then

        pass "Internet Gateway is attached: $IGW_ID"

    else

        fail "No Internet Gateway is attached to the VPC."

    fi

fi


# ================================================================
# 13. SUBNETS
# ================================================================

print_header "11. VPC Subnets"

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then

    aws ec2 describe-subnets \
        --region "$AWS_REGION" \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "Subnets[*].[SubnetId,AvailabilityZone,CidrBlock,MapPublicIpOnLaunch,Tags[?Key=='Name'].Value|[0]]" \
        --output table

    SUBNET_COUNT=$(aws ec2 describe-subnets \
        --region "$AWS_REGION" \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "length(Subnets)" \
        --output text \
        2>/dev/null)

    if [ "$SUBNET_COUNT" -ge 4 ]; then

        pass "At least four VPC subnets were found."

    else

        warn "Expected approximately four subnets, found $SUBNET_COUNT."

    fi

fi


# ================================================================
# 14. ROUTE TABLES
# ================================================================

print_header "12. Route Tables"

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then

    aws ec2 describe-route-tables \
        --region "$AWS_REGION" \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "RouteTables[*].[RouteTableId,Routes[*].[DestinationCidrBlock,GatewayId,NatGatewayId],Tags[?Key=='Name'].Value|[0]]" \
        --output table

    pass "VPC route tables retrieved."

fi


# ================================================================
# 15. SECURITY GROUPS
# ================================================================

print_header "13. Security Groups"

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then

    aws ec2 describe-security-groups \
        --region "$AWS_REGION" \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "SecurityGroups[*].[GroupId,GroupName,Description]" \
        --output table

    pass "Security groups retrieved."

fi


# ================================================================
# 16. EC2 VERIFICATION
# ================================================================

print_header "14. EC2 Verification"

INSTANCE_ID=$(aws ec2 describe-instances \
    --region "$AWS_REGION" \
    --filters \
        "Name=vpc-id,Values=$VPC_ID" \
        "Name=instance-state-name,Values=running" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text \
    2>/dev/null)

if [ -n "$INSTANCE_ID" ] && [ "$INSTANCE_ID" != "None" ]; then

    pass "Running EC2 instance found: $INSTANCE_ID"

    aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --region "$AWS_REGION" \
        --query "Reservations[0].Instances[0].[InstanceId,InstanceType,State.Name,SubnetId,PrivateIpAddress,PublicIpAddress]" \
        --output table

else

    warn "No running EC2 instance found in the VPC."

fi


# ================================================================
# 17. EC2 SYSTEM HEALTH
# ================================================================

print_header "15. EC2 System Health"

if [ -n "$INSTANCE_ID" ] && [ "$INSTANCE_ID" != "None" ]; then

    INSTANCE_STATUS=$(aws ec2 describe-instance-status \
        --instance-ids "$INSTANCE_ID" \
        --include-all-instances \
        --region "$AWS_REGION" \
        --query "InstanceStatuses[0].[SystemStatus.Status,InstanceStatus.Status]" \
        --output text \
        2>/dev/null)

    echo "$INSTANCE_STATUS"

    if echo "$INSTANCE_STATUS" | grep -q "ok"; then

        pass "EC2 system and instance status checks are healthy."

    else

        warn "EC2 health checks are not both showing OK."

    fi

fi


# ================================================================
# 18. USERDATA / CLOUD-INIT
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
# 19. EC2 INTERNET CONNECTIVITY
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
# 21. APACHE
# ================================================================

print_header "19. Apache Verification"

if command -v httpd >/dev/null 2>&1; then

    pass "Apache/httpd is installed."

    if systemctl is-active --quiet httpd; then

        pass "Apache is running."

    else

        fail "Apache is installed but not running."

    fi


    if curl -Is --connect-timeout 5 http://localhost >/dev/null 2>&1; then

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
# 23. DOCKER
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
# 24. DOCKER COMPOSE
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
# 25. GIT
# ================================================================

print_header "23. Git Verification"

if command -v git >/dev/null 2>&1; then

    pass "Git is installed."

    git --version

else

    warn "Git is not installed."

fi


# ================================================================
# 26. AWS AUTHENTICATION FROM EC2
# ================================================================

print_header "24. AWS CLI Authentication From EC2"

if aws sts get-caller-identity \
    --region "$AWS_REGION" \
    >/dev/null 2>&1; then

    pass "EC2 can authenticate to AWS."

    aws sts get-caller-identity \
        --region "$AWS_REGION" \
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
    --region "$AWS_REGION" \
    --query "Stacks[0].Outputs[?contains(OutputKey, 'S3') && contains(OutputKey, 'Bucket')].OutputValue | [0]" \
    --output text \
    2>/dev/null)


if [ -n "$S3_BUCKET" ] && [ "$S3_BUCKET" != "None" ]; then

    pass "S3 bucket found: $S3_BUCKET"


    if aws s3api head-bucket \
        --bucket "$S3_BUCKET" \
        --region "$AWS_REGION" \
        2>/dev/null; then

        pass "S3 bucket is accessible."

    else

        fail "S3 bucket cannot be accessed."

    fi


    echo
    echo "--- S3 Versioning ---"

    aws s3api get-bucket-versioning \
        --bucket "$S3_BUCKET" \
        --region "$AWS_REGION"

else

    warn "S3 bucket could not be found from CloudFormation outputs."

fi


# ================================================================
# 28. RDS MYSQL
# ================================================================

print_header "26. RDS MySQL Verification"

RDS_IDENTIFIER=$(aws rds describe-db-instances \
    --region "$AWS_REGION" \
    --query "DBInstances[?Engine=='mysql'].DBInstanceIdentifier | [0]" \
    --output text \
    2>/dev/null)


if [ -n "$RDS_IDENTIFIER" ] && [ "$RDS_IDENTIFIER" != "None" ]; then

    pass "RDS MySQL instance found: $RDS_IDENTIFIER"


    aws rds describe-db-instances \
        --db-instance-identifier "$RDS_IDENTIFIER" \
        --region "$AWS_REGION" \
        --query "DBInstances[0].[DBInstanceIdentifier,Engine,DBInstanceStatus,PubliclyAccessible,Endpoint.Address,Endpoint.Port]" \
        --output table


    RDS_ENDPOINT=$(aws rds describe-db-instances \
        --db-instance-identifier "$RDS_IDENTIFIER" \
        --region "$AWS_REGION" \
        --query "DBInstances[0].Endpoint.Address" \
        --output text)


    RDS_PORT=$(aws rds describe-db-instances \
        --db-instance-identifier "$RDS_IDENTIFIER" \
        --region "$AWS_REGION" \
        --query "DBInstances[0].Endpoint.Port" \
        --output text)


    RDS_PUBLIC=$(aws rds describe-db-instances \
        --db-instance-identifier "$RDS_IDENTIFIER" \
        --region "$AWS_REGION" \
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
# 29. RDS NETWORK CONNECTIVITY
# ================================================================

print_header "27. RDS Network Connectivity"

if [ -n "$RDS_ENDPOINT" ] && \
   [ "$RDS_ENDPOINT" != "None" ]; then


    if getent hosts "$RDS_ENDPOINT" >/dev/null 2>&1; then

        pass "RDS endpoint resolves from EC2."

    else

        fail "RDS endpoint does not resolve from EC2."

    fi


    if command -v nc >/dev/null 2>&1; then

        if nc -z -w 5 "$RDS_ENDPOINT" "$RDS_PORT" \
            >/dev/null 2>&1; then

            pass "EC2 can reach RDS port $RDS_PORT."

        else

            fail "EC2 cannot reach RDS port $RDS_PORT."

        fi

    else

        warn "netcat (nc) is not installed; RDS TCP test skipped."

    fi

fi


# ================================================================
# 30. SECRETS MANAGER
# ================================================================

print_header "28. Secrets Manager Verification"

SECRET_COUNT=$(aws secretsmanager list-secrets \
    --region "$AWS_REGION" \
    --query "length(SecretList)" \
    --output text \
    2>/dev/null)


if [ "$SECRET_COUNT" -gt 0 ]; then

    pass "Secrets Manager contains $SECRET_COUNT secret(s)."

    echo
    echo "--- Secret Metadata ---"

    # IMPORTANT:
    # Secret values are NEVER displayed.

    aws secretsmanager list-secrets \
        --region "$AWS_REGION" \
        --query "SecretList[*].[Name,ARN]" \
        --output table

else

    warn "No Secrets Manager secrets were found."

fi


# ================================================================
# 31. ECS CLOUDFORMATION STACK
# ================================================================

print_header "29. ECS CloudFormation Stack"

ECS_STACK_STATUS=$(aws cloudformation describe-stacks \
    --stack-name "$ECS_STACK" \
    --region "$AWS_REGION" \
    --query "Stacks[0].StackStatus" \
    --output text \
    2>/dev/null)


if [ "$ECS_STACK_STATUS" = "CREATE_COMPLETE" ] || \
   [ "$ECS_STACK_STATUS" = "UPDATE_COMPLETE" ]; then

    pass "ECS stack status: $ECS_STACK_STATUS"

else

    fail "ECS stack status: ${ECS_STACK_STATUS:-NOT_FOUND}"

fi


# ================================================================
# 32. ECR VERIFICATION
# ================================================================
#
# IMPORTANT:
#
# Do NOT hide all errors behind:
#
#     >/dev/null 2>&1
#
# because:
#
#     AccessDenied
#
# and:
#
#     RepositoryNotFound
#
# are completely different problems.
#
# We capture the AWS CLI error and display it.
#
# ================================================================

print_header "30. ECR Verification"

info "Checking ECR repository:"
info "Repository : $ECR_REPOSITORY"
info "Region     : $AWS_REGION"
info "Account    : ${AWS_ACCOUNT_ID:-Unknown}"

ECR_ERROR_FILE="/tmp/charlie-cafe-ecr-error.txt"

rm -f "$ECR_ERROR_FILE"


if aws ecr describe-repositories \
    --repository-names "$ECR_REPOSITORY" \
    --region "$AWS_REGION" \
    >/dev/null 2>"$ECR_ERROR_FILE"; then


    pass "ECR repository exists: $ECR_REPOSITORY"


    echo
    echo "--- ECR Repository Details ---"

    aws ecr describe-repositories \
        --repository-names "$ECR_REPOSITORY" \
        --region "$AWS_REGION" \
        --query "repositories[0].[repositoryName,repositoryUri,registryId,repositoryArn]" \
        --output table


    echo
    echo "--- ECR Images ---"

    if aws ecr describe-images \
        --repository-name "$ECR_REPOSITORY" \
        --region "$AWS_REGION" \
        --query "imageDetails[*].[imageTags,imageDigest,imagePushedAt]" \
        --output table \
        2>/dev/null; then

        pass "ECR image information retrieved."

    else

        warn "ECR repository exists, but image information could not be retrieved."

    fi


else

    ECR_ERROR=$(cat "$ECR_ERROR_FILE")

    echo
    echo "--- AWS ECR Error ---"
    echo "$ECR_ERROR"
    echo


    if echo "$ECR_ERROR" | grep -qi "RepositoryNotFoundException"; then

        fail "ECR repository does not exist in region $AWS_REGION: $ECR_REPOSITORY"

        echo
        echo "Troubleshooting:"
        echo "  Check AWS Console -> ECR -> Repositories"
        echo "  Region must be: $AWS_REGION"
        echo "  Repository must be: $ECR_REPOSITORY"


    elif echo "$ECR_ERROR" | grep -qi "AccessDenied"; then

        fail "IAM permission denied while accessing ECR."

        echo
        echo "Required read permissions normally include:"
        echo "  ecr:DescribeRepositories"
        echo "  ecr:DescribeImages"


    elif echo "$ECR_ERROR" | grep -qi "UnrecognizedClientException"; then

        fail "AWS credentials are invalid or unavailable."


    else

        fail "ECR verification failed."

        echo
        echo "AWS returned:"
        echo "$ECR_ERROR"

    fi

fi


rm -f "$ECR_ERROR_FILE"


# ================================================================
# 33. ECS CLUSTER
# ================================================================

print_header "31. ECS Cluster"

ECS_CLUSTER_STATUS=$(aws ecs describe-clusters \
    --clusters "$ECS_CLUSTER" \
    --region "$AWS_REGION" \
    --query "clusters[0].status" \
    --output text \
    2>/dev/null)


if [ "$ECS_CLUSTER_STATUS" = "ACTIVE" ]; then

    pass "ECS cluster is ACTIVE."

else

    fail "ECS cluster status: ${ECS_CLUSTER_STATUS:-NOT_FOUND}"

fi


# ================================================================
# 34. ECS SERVICE
# ================================================================

print_header "32. ECS Service"

ECS_SERVICE_STATUS=$(aws ecs describe-services \
    --cluster "$ECS_CLUSTER" \
    --services "$ECS_SERVICE" \
    --region "$AWS_REGION" \
    --query "services[0].status" \
    --output text \
    2>/dev/null)


if [ "$ECS_SERVICE_STATUS" = "ACTIVE" ]; then

    pass "ECS service is ACTIVE."


    aws ecs describe-services \
        --cluster "$ECS_CLUSTER" \
        --services "$ECS_SERVICE" \
        --region "$AWS_REGION" \
        --query "services[0].[serviceName,status,desiredCount,runningCount,pendingCount]" \
        --output table

else

    fail "ECS service status: ${ECS_SERVICE_STATUS:-NOT_FOUND}"

fi


# ================================================================
# 35. ECS RUNNING TASKS
# ================================================================

print_header "33. ECS Running Tasks"

TASK_ARNS=$(aws ecs list-tasks \
    --cluster "$ECS_CLUSTER" \
    --service-name "$ECS_SERVICE" \
    --desired-status RUNNING \
    --region "$AWS_REGION" \
    --query "taskArns[]" \
    --output text \
    2>/dev/null)


if [ -n "$TASK_ARNS" ] && \
   [ "$TASK_ARNS" != "None" ]; then

    pass "Running ECS task(s) found."


    aws ecs describe-tasks \
        --cluster "$ECS_CLUSTER" \
        --tasks $TASK_ARNS \
        --region "$AWS_REGION" \
        --query "tasks[*].[taskArn,lastStatus,healthStatus,launchType]" \
        --output table

else

    warn "No running ECS task was found."

fi


# ================================================================
# 36. VPC ENDPOINTS
# ================================================================

print_header "34. VPC Endpoints"

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then

    aws ec2 describe-vpc-endpoints \
        --region "$AWS_REGION" \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "VpcEndpoints[*].[VpcEndpointId,ServiceName,VpcEndpointType,State]" \
        --output table


    ENDPOINT_COUNT=$(aws ec2 describe-vpc-endpoints \
        --region "$AWS_REGION" \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "length(VpcEndpoints)" \
        --output text \
        2>/dev/null)


    if [ "$ENDPOINT_COUNT" -ge 3 ]; then

        pass "At least three VPC endpoints were found."

    else

        warn "Only $ENDPOINT_COUNT VPC endpoint(s) were found."

    fi

fi


# ================================================================
# 37. APPLICATION LOAD BALANCER
# ================================================================

print_header "35. Application Load Balancer"

ALB_ARN=$(aws elbv2 describe-load-balancers \
    --region "$AWS_REGION" \
    --query "LoadBalancers[?Type=='application'].LoadBalancerArn | [0]" \
    --output text \
    2>/dev/null)


if [ -n "$ALB_ARN" ] && \
   [ "$ALB_ARN" != "None" ]; then

    pass "Application Load Balancer found."


    aws elbv2 describe-load-balancers \
        --load-balancer-arns "$ALB_ARN" \
        --region "$AWS_REGION" \
        --query "LoadBalancers[0].[LoadBalancerName,DNSName,Scheme,Type,State.Code]" \
        --output table


    ALB_DNS=$(aws elbv2 describe-load-balancers \
        --load-balancer-arns "$ALB_ARN" \
        --region "$AWS_REGION" \
        --query "LoadBalancers[0].DNSName" \
        --output text)

else

    warn "No Application Load Balancer found."

fi


# ================================================================
# 38. ALB TARGET GROUPS
# ================================================================

print_header "36. ALB Target Groups"

if [ -n "$ALB_ARN" ] && \
   [ "$ALB_ARN" != "None" ]; then


    TARGET_GROUPS=$(aws elbv2 describe-target-groups \
        --load-balancer-arn "$ALB_ARN" \
        --region "$AWS_REGION" \
        --query "TargetGroups[*].TargetGroupArn" \
        --output text \
        2>/dev/null)


    if [ -n "$TARGET_GROUPS" ] && \
       [ "$TARGET_GROUPS" != "None" ]; then

        pass "ALB target group(s) found."


        for TG in $TARGET_GROUPS; do

            echo
            echo "--- Target Group: $TG ---"

            aws elbv2 describe-target-health \
                --target-group-arn "$TG" \
                --region "$AWS_REGION" \
                --query "TargetHealthDescriptions[*].[Target.Id,Target.Port,TargetHealth.State,TargetHealth.Reason]" \
                --output table

        done

    else

        warn "No ALB target groups were found."

    fi

fi


# ================================================================
# 39. APPLICATION HTTP TEST
# ================================================================

print_header "37. Application HTTP Test"

if [ -n "$ALB_DNS" ] && \
   [ "$ALB_DNS" != "None" ]; then


    HTTP_STATUS=$(curl -s -o /dev/null \
        -w "%{http_code}" \
        --connect-timeout 10 \
        "http://$ALB_DNS")


    echo "ALB DNS    : $ALB_DNS"
    echo "HTTP Status: $HTTP_STATUS"


    # Correct HTTP success range:
    #
    #   200-299 = successful
    #   300-399 = redirect
    #
    if [[ "$HTTP_STATUS" =~ ^[23][0-9][0-9]$ ]]; then

        pass "Application responded through the ALB."

    else

        fail "Application did not return a successful HTTP response."

    fi

else

    warn "ALB DNS name unavailable; application test skipped."

fi


# ================================================================
# 40. CLOUDWATCH LOGS
# ================================================================

print_header "38. CloudWatch Logs"

if aws logs describe-log-groups \
    --log-group-name-prefix "$LOG_GROUP" \
    --region "$AWS_REGION" \
    --query "logGroups[?logGroupName=='$LOG_GROUP'].logGroupName" \
    --output text \
    2>/dev/null | grep -q "$LOG_GROUP"; then


    pass "CloudWatch log group exists: $LOG_GROUP"


    echo
    echo "--- Recent ECS Logs ---"


    if aws logs tail "$LOG_GROUP" \
        --since 10m \
        --format short \
        --region "$AWS_REGION" \
        2>/dev/null; then

        pass "Recent CloudWatch logs retrieved."

    else

        warn "Unable to retrieve recent CloudWatch logs."

    fi

else

    warn "CloudWatch log group was not found: $LOG_GROUP"

fi


# ================================================================
# 41. FINAL EC2 -> RDS CONNECTIVITY
# ================================================================
#
# This is intentionally kept as a final summary test.
#
# The same RDS connectivity was already checked in section 27.
#
# Therefore we do not run another network test here.
#
# ================================================================

print_header "39. Final EC2-to-RDS Connectivity"

if [ -n "$RDS_ENDPOINT" ] && \
   [ "$RDS_ENDPOINT" != "None" ]; then

    if command -v nc >/dev/null 2>&1; then

        if nc -z -w 5 "$RDS_ENDPOINT" "$RDS_PORT" \
            >/dev/null 2>&1; then

            pass "Final EC2 -> RDS connectivity verified."

        else

            fail "Final EC2 -> RDS connectivity failed."

        fi

    else

        warn "nc not installed. EC2 -> RDS TCP test skipped."

    fi

else

    warn "RDS endpoint unavailable; final connectivity test skipped."

fi


# ================================================================
# 42. FINAL SUMMARY
# ================================================================

print_header "FINAL VERIFICATION SUMMARY"

echo
echo "AWS Region   : $AWS_REGION"
echo "AWS Account  : ${AWS_ACCOUNT_ID:-Unknown}"
echo "AWS Identity : ${AWS_CALLER_ARN:-Unknown}"
echo

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
    echo
    echo "IMPORTANT:"
    echo "The ECR verification now displays the actual AWS error."
    echo "This helps distinguish IAM permission problems from"
    echo "RepositoryNotFound problems."

fi


echo
echo "Verification completed."
echo "This script performs read-only verification."
echo "It does not intentionally modify or delete AWS resources."
echo
echo "Configured AWS Region: $AWS_REGION"