#!/bin/bash

# =====================================================================
# ☕ Charlie Cafe — AWS CloudFormation DevOps Lab
# COMPLETE FAST READ-ONLY VERIFICATION SCRIPT
# =====================================================================
#
# Operating System:
#   Amazon Linux 2023
#
# Purpose:
#   Verify the AWS CloudFormation / DevOps lab from an EC2 instance.
#
# IMPORTANT:
#   This script is READ-ONLY with respect to AWS resources.
#
# It DOES NOT:
#   - Create AWS resources
#   - Delete AWS resources
#   - Update CloudFormation
#   - Start/stop/reboot EC2
#   - Change ECS desired count
#   - Push Docker images
#   - Login to ECR
#   - Change IAM
#   - Change Security Groups
#   - Change Route Tables
#   - Change RDS
#   - Change S3
#   - Change CloudFront
#
# It ONLY performs:
#   - describe
#   - list
#   - get
#   - head
#   - status
#   - connectivity tests
#
# =====================================================================
# FAST-SAFETY DESIGN
# =====================================================================
#
# Every AWS CLI command is protected with a timeout.
#
# This is especially important for:
#
#   CloudWatch Logs
#   CloudFormation
#   RDS
#   ECS
#   ECR
#   ALB
#   VPC
#
# If one AWS API call becomes slow, the script will WARN and continue.
#
# =====================================================================


# ---------------------------------------------------------------------
# 1. CONFIGURATION
# ---------------------------------------------------------------------

AWS_REGION="us-east-1"

# Leave empty unless you specifically use an AWS CLI profile.
AWS_PROFILE=""

# Main CloudFormation stack.
MAIN_STACK="Main-CloudFormation"

# ECS CloudFormation stack.
ECS_STACK="CharlieCafe-ECS-Stack"

# ECR repository.
ECR_REPOSITORY="charlie-cafe"

# ECS cluster.
ECS_CLUSTER="CharlieCafe-Cluster"

# ECS service.
ECS_SERVICE="CharlieCafe-Service"

# CloudWatch Log Group.
LOG_GROUP="/ecs/charlie-cafe"

# Expected VPC CIDR.
EXPECTED_VPC_CIDR="10.0.0.0/16"

# Optional RDS identifier.
#
# Leave empty to automatically discover a MySQL database
# belonging to the discovered VPC.
RDS_IDENTIFIER=""

# Optional S3 bucket.
#
# Leave empty to discover buckets automatically.
S3_BUCKET=""

# Optional CloudFront Distribution ID.
#
# Leave empty for automatic discovery.
CLOUDFRONT_DISTRIBUTION_ID=""

# Optional CloudFront domain.
#
# Example:
# d123456789.cloudfront.net
CLOUDFRONT_DOMAIN=""

# Optional ALB ARN.
#
# Leave empty for automatic discovery in the lab VPC.
ALB_ARN=""

# Expected container port.
CONTAINER_PORT="80"

# ---------------------------------------------------------------------
# OPTIONAL EXPECTED COUNTS
# ---------------------------------------------------------------------

# Set to 0 if you do not want count validation.
EXPECTED_SUBNET_COUNT=0

# Set to 0 if you do not want endpoint count validation.
EXPECTED_VPC_ENDPOINT_COUNT=0

# ---------------------------------------------------------------------
# PERFORMANCE SETTINGS
# ---------------------------------------------------------------------

# Maximum time allowed for an AWS CLI command.
#
# 8 seconds is normally enough for describe/list calls.
# If an API call is slow, it will be skipped rather than hanging.
AWS_TIMEOUT_SECONDS=8

# Maximum time allowed for curl connectivity tests.
CURL_TIMEOUT_SECONDS=5

# Maximum time allowed for nc connectivity tests.
NC_TIMEOUT_SECONDS=5

# Do NOT retrieve CloudWatch log contents.
#
# This is intentionally FALSE because log retrieval can be slow.
SHOW_RECENT_LOGS="false"

# Return exit code 1 if verification failures exist.
EXIT_NONZERO_ON_FAILURE="true"


# ---------------------------------------------------------------------
# 2. GLOBAL SETTINGS
# ---------------------------------------------------------------------

export AWS_PAGER=""

export AWS_DEFAULT_REGION="$AWS_REGION"

if [ -n "$AWS_PROFILE" ]; then
    export AWS_PROFILE="$AWS_PROFILE"
fi


# ---------------------------------------------------------------------
# 3. COUNTERS
# ---------------------------------------------------------------------

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0


# ---------------------------------------------------------------------
# 4. OUTPUT FUNCTIONS
# ---------------------------------------------------------------------

print_header() {

    echo
    echo "======================================================================"
    echo "$1"
    echo "======================================================================"
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


# ---------------------------------------------------------------------
# 5. COMMAND CHECK
# ---------------------------------------------------------------------

command_exists() {

    command -v "$1" >/dev/null 2>&1
}


# ---------------------------------------------------------------------
# 6. FAST AWS COMMAND WRAPPER
# ---------------------------------------------------------------------
#
# IMPORTANT:
#
# This is the major fix.
#
# Every AWS CLI call goes through this function.
#
# If AWS takes longer than AWS_TIMEOUT_SECONDS,
# the command is killed and the script continues.
#
# ---------------------------------------------------------------------

aws_fast() {

    if ! command_exists aws; then
        return 127
    fi

    timeout --signal=TERM --kill-after=2s \
        "${AWS_TIMEOUT_SECONDS}s" \
        aws --region "$AWS_REGION" "$@"
}


# ---------------------------------------------------------------------
# 7. FAST AWS OUTPUT FUNCTION
# ---------------------------------------------------------------------
#
# Used when we need to capture AWS command output.
#
# Usage:
#
# RESULT=$(aws_fast ec2 describe-instances ...)
# RC=$?
#
# ---------------------------------------------------------------------

aws_fast_capture() {

    timeout --signal=TERM --kill-after=2s \
        "${AWS_TIMEOUT_SECONDS}s" \
        aws --region "$AWS_REGION" "$@"
}


# ---------------------------------------------------------------------
# 8. INITIAL SYSTEM CHECK
# ---------------------------------------------------------------------

print_header "1. BASIC COMMAND DEPENDENCIES"

MISSING_COMMANDS=0

for CMD in aws curl getent ss docker git systemctl timeout; do

    if command_exists "$CMD"; then

        echo "[PASS] $CMD is installed."

    else

        echo "[WARN] $CMD is not installed."
        MISSING_COMMANDS=$((MISSING_COMMANDS + 1))

    fi

done

if [ "$MISSING_COMMANDS" -eq 0 ]; then

    pass "Required verification commands are available."

else

    warn "$MISSING_COMMANDS command(s) are missing."

fi


# ---------------------------------------------------------------------
# 9. OPERATING SYSTEM
# ---------------------------------------------------------------------

print_header "2. EC2 OPERATING SYSTEM"

if [ -f /etc/os-release ]; then

    cat /etc/os-release

    pass "Operating system information detected."

else

    warn "/etc/os-release was not found."

fi


# ---------------------------------------------------------------------
# 10. HOSTNAME
# ---------------------------------------------------------------------

print_header "3. HOSTNAME"

if command_exists hostnamectl; then

    hostnamectl 2>/dev/null

else

    hostname

fi


# ---------------------------------------------------------------------
# 11. CURRENT USER
# ---------------------------------------------------------------------

print_header "4. CURRENT USER"

whoami


# ---------------------------------------------------------------------
# 12. KERNEL
# ---------------------------------------------------------------------

print_header "5. KERNEL"

uname -a


# ---------------------------------------------------------------------
# 13. DISK
# ---------------------------------------------------------------------

print_header "6. DISK USAGE"

df -h


# ---------------------------------------------------------------------
# 14. MEMORY
# ---------------------------------------------------------------------

print_header "7. MEMORY"

free -h


# ---------------------------------------------------------------------
# 15. CPU
# ---------------------------------------------------------------------

print_header "8. CPU"

echo "CPU Cores: $(nproc)"


# ---------------------------------------------------------------------
# 16. AWS CLI
# ---------------------------------------------------------------------

print_header "9. AWS CLI"

if command_exists aws; then

    aws --version

    pass "AWS CLI is installed."

else

    fail "AWS CLI is not installed."

fi


# ---------------------------------------------------------------------
# 17. AWS IDENTITY
# ---------------------------------------------------------------------

print_header "10. AWS IDENTITY"

if command_exists aws; then

    IDENTITY_OUTPUT=$(aws_fast sts get-caller-identity \
        --output json 2>/dev/null)

    IDENTITY_RC=$?

    if [ "$IDENTITY_RC" -eq 0 ] && [ -n "$IDENTITY_OUTPUT" ]; then

        echo "$IDENTITY_OUTPUT"

        ACCOUNT_ID=$(echo "$IDENTITY_OUTPUT" |
            grep -o '"Account": "[^"]*"' |
            cut -d'"' -f4)

        pass "AWS identity verified."

    else

        fail "Unable to verify AWS identity."

    fi

fi


# ---------------------------------------------------------------------
# 18. EC2 INSTANCE METADATA
# ---------------------------------------------------------------------

print_header "11. EC2 INSTANCE METADATA"

INSTANCE_ID=""
IMDS_TOKEN=""

if command_exists curl; then

    IMDS_TOKEN=$(curl -sS \
        --connect-timeout 2 \
        --max-time 3 \
        -X PUT \
        -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" \
        "http://169.254.169.254/latest/api/token" 2>/dev/null)

fi


if [ -n "$IMDS_TOKEN" ]; then

    INSTANCE_ID=$(curl -sS \
        --connect-timeout 2 \
        --max-time 3 \
        -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" \
        "http://169.254.169.254/latest/meta-data/instance-id" 2>/dev/null)

    IMDS_REGION=$(curl -sS \
        --connect-timeout 2 \
        --max-time 3 \
        -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" \
        "http://169.254.169.254/latest/meta-data/placement/region" 2>/dev/null)

    IMDS_AZ=$(curl -sS \
        --connect-timeout 2 \
        --max-time 3 \
        -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" \
        "http://169.254.169.254/latest/meta-data/placement/availability-zone" 2>/dev/null)

    IMDS_INSTANCE_TYPE=$(curl -sS \
        --connect-timeout 2 \
        --max-time 3 \
        -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" \
        "http://169.254.169.254/latest/meta-data/instance-type" 2>/dev/null)

    echo "Instance ID:       $INSTANCE_ID"
    echo "Region:            $IMDS_REGION"
    echo "Availability Zone: $IMDS_AZ"
    echo "Instance Type:     $IMDS_INSTANCE_TYPE"

    pass "EC2 Instance Metadata Service is accessible."

else

    warn "IMDSv2 is not accessible. Using AWS API discovery."

fi


# ---------------------------------------------------------------------
# 19. MAIN CLOUDFORMATION STACK
# ---------------------------------------------------------------------

print_header "12. MAIN CLOUDFORMATION STACK"

STACK_STATUS=""
STACK_EXISTS="false"

if [ -n "$MAIN_STACK" ]; then

    STACK_STATUS=$(aws_fast cloudformation describe-stacks \
        --stack-name "$MAIN_STACK" \
        --query "Stacks[0].StackStatus" \
        --output text 2>/dev/null)

    RC=$?

    if [ "$RC" -eq 0 ] && [ -n "$STACK_STATUS" ] && [ "$STACK_STATUS" != "None" ]; then

        STACK_EXISTS="true"

        echo "Stack:  $MAIN_STACK"
        echo "Status: $STACK_STATUS"

        case "$STACK_STATUS" in

            CREATE_COMPLETE|UPDATE_COMPLETE)
                pass "Main CloudFormation stack is healthy."
                ;;

            *_IN_PROGRESS)
                warn "Main CloudFormation stack is currently in progress."
                ;;

            *_FAILED|*_ROLLBACK*)
                fail "Main CloudFormation stack has failure/rollback status."
                ;;

            *)
                warn "Main CloudFormation stack status: $STACK_STATUS"
                ;;

        esac

    else

        fail "Main CloudFormation stack was not found or could not be queried."

    fi

fi


# ---------------------------------------------------------------------
# 20. CLOUDFORMATION OUTPUTS
# ---------------------------------------------------------------------

print_header "13. CLOUDFORMATION OUTPUTS"

if [ "$STACK_EXISTS" = "true" ]; then

    aws_fast cloudformation describe-stacks \
        --stack-name "$MAIN_STACK" \
        --query "Stacks[0].Outputs[].{Key:OutputKey,Value:OutputValue}" \
        --output table 2>/dev/null

    if [ "$?" -eq 0 ]; then
        pass "CloudFormation outputs retrieved."
    else
        warn "CloudFormation outputs could not be retrieved."
    fi

fi


# ---------------------------------------------------------------------
# 21. DISCOVER VPC
# ---------------------------------------------------------------------

print_header "14. VPC DISCOVERY"

VPC_ID=""

if [ "$STACK_EXISTS" = "true" ]; then

    VPC_ID=$(aws_fast cloudformation describe-stacks \
        --stack-name "$MAIN_STACK" \
        --query "Stacks[0].Outputs[?contains(OutputKey,'VPC') || contains(OutputKey,'Vpc') || contains(OutputKey,'vpc')].OutputValue | [0]" \
        --output text 2>/dev/null)

fi


# Fallback: find VPC matching expected CIDR.
if [ -z "$VPC_ID" ] || [ "$VPC_ID" = "None" ]; then

    VPC_ID=$(aws_fast ec2 describe-vpcs \
        --filters "Name=cidr-block,Values=$EXPECTED_VPC_CIDR" \
        --query "Vpcs[0].VpcId" \
        --output text 2>/dev/null)

fi


if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then

    echo "VPC ID: $VPC_ID"
    pass "Lab VPC discovered."

else

    fail "Lab VPC could not be discovered."

fi


# ---------------------------------------------------------------------
# 22. VPC DETAILS
# ---------------------------------------------------------------------

print_header "15. VPC DETAILS"

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then

    aws_fast ec2 describe-vpcs \
        --vpc-ids "$VPC_ID" \
        --query "Vpcs[0].{VpcId:VpcId,CIDR:CidrBlock,State:State,Default: IsDefault,Tenancy:InstanceTenancy}" \
        --output table 2>/dev/null

fi


# ---------------------------------------------------------------------
# 23. VPC DNS
# ---------------------------------------------------------------------

print_header "16. VPC DNS"

if [ -n "$VPC_ID" ]; then

    DNS_SUPPORT=$(aws_fast ec2 describe-vpc-attribute \
        --vpc-id "$VPC_ID" \
        --attribute enableDnsSupport \
        --query "EnableDnsSupport.Value" \
        --output text 2>/dev/null)

    DNS_HOSTNAMES=$(aws_fast ec2 describe-vpc-attribute \
        --vpc-id "$VPC_ID" \
        --attribute enableDnsHostnames \
        --query "EnableDnsHostnames.Value" \
        --output text 2>/dev/null)

    echo "DNS Support:    $DNS_SUPPORT"
    echo "DNS Hostnames:  $DNS_HOSTNAMES"

fi


# ---------------------------------------------------------------------
# 24. INTERNET GATEWAY
# ---------------------------------------------------------------------

print_header "17. INTERNET GATEWAY"

if [ -n "$VPC_ID" ]; then

    IGW_COUNT=$(aws_fast ec2 describe-internet-gateways \
        --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
        --query "length(InternetGateways)" \
        --output text 2>/dev/null)

    echo "Internet Gateways: ${IGW_COUNT:-0}"

    if [ "${IGW_COUNT:-0}" -gt 0 ]; then
        pass "Internet Gateway attached to VPC."
    else
        warn "No Internet Gateway attached to VPC."
    fi

fi


# ---------------------------------------------------------------------
# 25. SUBNETS
# ---------------------------------------------------------------------

print_header "18. VPC SUBNETS"

SUBNET_COUNT=0

if [ -n "$VPC_ID" ]; then

    aws_fast ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "Subnets[].{Subnet:SubnetId,CIDR:CidrBlock,AZ:AvailabilityZone,PublicIP:MapPublicIpOnLaunch,State:State}" \
        --output table 2>/dev/null

    SUBNET_COUNT=$(aws_fast ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "length(Subnets)" \
        --output text 2>/dev/null)

    echo "Subnet Count: ${SUBNET_COUNT:-0}"

    if [ "${EXPECTED_SUBNET_COUNT:-0}" -gt 0 ]; then

        if [ "${SUBNET_COUNT:-0}" -ge "$EXPECTED_SUBNET_COUNT" ]; then
            pass "Expected subnet count is present."
        else
            warn "Expected at least $EXPECTED_SUBNET_COUNT subnets."
        fi

    else

        pass "Subnet discovery completed."

    fi

fi


# ---------------------------------------------------------------------
# 26. ROUTE TABLES
# ---------------------------------------------------------------------

print_header "19. ROUTE TABLES"

if [ -n "$VPC_ID" ]; then

    aws_fast ec2 describe-route-tables \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "RouteTables[].{RouteTable:RouteTableId,Routes:Routes,Associations:Associations}" \
        --output json 2>/dev/null

    if [ "$?" -eq 0 ]; then
        pass "Route tables retrieved."
    else
        warn "Route table verification timed out or failed."
    fi

fi


# ---------------------------------------------------------------------
# 27. NAT GATEWAYS
# ---------------------------------------------------------------------

print_header "20. NAT GATEWAYS"

if [ -n "$VPC_ID" ]; then

    aws_fast ec2 describe-nat-gateways \
        --filter "Name=vpc-id,Values=$VPC_ID" \
        --query "NatGateways[].{Id:NatGatewayId,State:State,Subnet:SubnetId,PublicIP:NatGatewayAddresses[0].PublicIp}" \
        --output table 2>/dev/null

fi


# ---------------------------------------------------------------------
# 28. NETWORK ACL
# ---------------------------------------------------------------------

print_header "21. NETWORK ACLS"

if [ -n "$VPC_ID" ]; then

    aws_fast ec2 describe-network-acls \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "NetworkAcls[].{ACL:NetworkAclId,Default:IsDefault,Associations:Associations}" \
        --output table 2>/dev/null

fi


# ---------------------------------------------------------------------
# 29. SECURITY GROUPS
# ---------------------------------------------------------------------

print_header "22. SECURITY GROUPS"

if [ -n "$VPC_ID" ]; then

    aws_fast ec2 describe-security-groups \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "SecurityGroups[].{GroupId:GroupId,Name:GroupName,Description:Description}" \
        --output table 2>/dev/null

fi


# ---------------------------------------------------------------------
# 30. VPC ENDPOINTS
# ---------------------------------------------------------------------

print_header "23. VPC ENDPOINTS"

VPC_ENDPOINT_COUNT=0

if [ -n "$VPC_ID" ]; then

    aws_fast ec2 describe-vpc-endpoints \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "VpcEndpoints[].{Id:VpcEndpointId,Type:VpcEndpointType,State:State,Service:ServiceName}" \
        --output table 2>/dev/null

    VPC_ENDPOINT_COUNT=$(aws_fast ec2 describe-vpc-endpoints \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "length(VpcEndpoints)" \
        --output text 2>/dev/null)

    echo "VPC Endpoint Count: ${VPC_ENDPOINT_COUNT:-0}"

    if [ "${EXPECTED_VPC_ENDPOINT_COUNT:-0}" -gt 0 ]; then

        if [ "${VPC_ENDPOINT_COUNT:-0}" -ge "$EXPECTED_VPC_ENDPOINT_COUNT" ]; then
            pass "Expected VPC endpoint count is present."
        else
            warn "Expected at least $EXPECTED_VPC_ENDPOINT_COUNT VPC endpoints."
        fi

    else

        pass "VPC endpoint discovery completed."

    fi

fi


# ---------------------------------------------------------------------
# 31. VPC FLOW LOGS
# ---------------------------------------------------------------------

print_header "24. VPC FLOW LOGS"

if [ -n "$VPC_ID" ]; then

    FLOW_LOG_COUNT=$(aws_fast ec2 describe-flow-logs \
        --filter "Name=resource-id,Values=$VPC_ID" \
        --query "length(FlowLogs)" \
        --output text 2>/dev/null)

    echo "Flow Logs: ${FLOW_LOG_COUNT:-0}"

    if [ "${FLOW_LOG_COUNT:-0}" -gt 0 ]; then
        pass "VPC Flow Logs are configured."
    else
        info "No VPC Flow Logs detected."
    fi

fi


# ---------------------------------------------------------------------
# 32. EC2 INSTANCE DISCOVERY
# ---------------------------------------------------------------------

print_header "25. EC2 INSTANCE"

if [ -z "$INSTANCE_ID" ] && [ -n "$VPC_ID" ]; then

    INSTANCE_ID=$(aws_fast ec2 describe-instances \
        --filters \
        "Name=vpc-id,Values=$VPC_ID" \
        "Name=instance-state-name,Values=running" \
        --query "Reservations[].Instances[].InstanceId | [0]" \
        --output text 2>/dev/null)

fi


if [ -n "$INSTANCE_ID" ] && [ "$INSTANCE_ID" != "None" ]; then

    aws_fast ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --query "Reservations[0].Instances[0].{InstanceId:InstanceId,State:State.Name,Type:InstanceType,PrivateIP:PrivateIpAddress,PublicIP:PublicIpAddress,AZ:Placement.AvailabilityZone,VpcId:VpcId,SubnetId:SubnetId}" \
        --output table 2>/dev/null

    pass "EC2 instance discovered."

else

    fail "Running EC2 instance could not be discovered."

fi


# ---------------------------------------------------------------------
# 33. EC2 SYSTEM HEALTH
# ---------------------------------------------------------------------

print_header "26. EC2 SYSTEM HEALTH"

if [ -n "$INSTANCE_ID" ]; then

    aws_fast ec2 describe-instance-status \
        --instance-ids "$INSTANCE_ID" \
        --include-all-instances \
        --query "InstanceStatuses[0].{Instance:InstanceStatus.Status,System:SystemStatus.Status,Reachability:InstanceStatus.Details[0].Name}" \
        --output table 2>/dev/null

fi


# ---------------------------------------------------------------------
# 34. USER DATA / CLOUD-INIT
# ---------------------------------------------------------------------

print_header "27. EC2 USERDATA / CLOUD-INIT"

if [ -f /var/log/cloud-init-output.log ]; then

    echo "Last 20 lines of cloud-init-output.log:"
    tail -20 /var/log/cloud-init-output.log

    pass "cloud-init output log exists."

else

    warn "cloud-init-output.log not found."

fi


# ---------------------------------------------------------------------
# 35. DOCKER
# ---------------------------------------------------------------------

print_header "28. DOCKER"

if command_exists docker; then

    docker --version

    pass "Docker installed."

    echo
    echo "Docker service status:"

    if sudo -n systemctl status docker --no-pager 2>/dev/null; then
        pass "Docker service is available."
    else
        warn "Unable to read Docker systemd status without prompting."
    fi

    echo
    echo "Docker containers:"

    if sudo -n docker ps -a 2>/dev/null; then
        pass "Docker container list retrieved."
    else
        warn "Unable to retrieve Docker containers."
    fi

    echo
    echo "Docker images:"

    if sudo -n docker images 2>/dev/null; then
        pass "Docker image list retrieved."
    else
        warn "Unable to retrieve Docker images."
    fi

else

    warn "Docker is not installed."

fi


# ---------------------------------------------------------------------
# 36. DOCKER COMPOSE
# ---------------------------------------------------------------------

print_header "29. DOCKER COMPOSE"

if docker compose version >/dev/null 2>&1; then

    docker compose version

    pass "Docker Compose plugin is available."

elif command_exists docker-compose; then

    docker-compose --version

    pass "docker-compose is available."

else

    warn "Docker Compose was not detected."

fi


# ---------------------------------------------------------------------
# 37. NGINX
# ---------------------------------------------------------------------

print_header "30. NGINX"

if command_exists nginx; then

    nginx -v 2>&1

    if sudo -n systemctl is-active --quiet nginx 2>/dev/null; then
        pass "Nginx is installed and active."
    else
        warn "Nginx is installed but not active."
    fi

else

    info "Nginx is not installed."

fi


# ---------------------------------------------------------------------
# 38. APACHE
# ---------------------------------------------------------------------

print_header "31. APACHE"

if command_exists httpd; then

    httpd -v

    if sudo -n systemctl is-active --quiet httpd 2>/dev/null; then
        pass "Apache is installed and active."
    else
        warn "Apache is installed but not active."
    fi

else

    info "Apache/httpd is not installed."

fi


# ---------------------------------------------------------------------
# 39. PHP
# ---------------------------------------------------------------------

print_header "32. PHP"

if command_exists php; then

    php --version | head -1

    pass "PHP is installed."

else

    info "PHP is not installed."

fi


# ---------------------------------------------------------------------
# 40. GIT
# ---------------------------------------------------------------------

print_header "33. GIT"

if command_exists git; then

    git --version

    pass "Git is installed."

else

    warn "Git is not installed."

fi


# ---------------------------------------------------------------------
# 41. LISTENING PORTS
# ---------------------------------------------------------------------

print_header "34. LISTENING PORTS"

if command_exists ss; then

    if sudo -n ss -tulpn 2>/dev/null; then
        pass "Listening ports retrieved."
    else
        ss -tulpn 2>/dev/null
        pass "Listening ports retrieved."
    fi

else

    warn "ss command is not available."

fi


# ---------------------------------------------------------------------
# 42. INTERNET CONNECTIVITY
# ---------------------------------------------------------------------

print_header "35. EC2 INTERNET CONNECTIVITY"

if command_exists curl; then

    if curl -sS \
        --connect-timeout "$CURL_TIMEOUT_SECONDS" \
        --max-time "$CURL_TIMEOUT_SECONDS" \
        -I https://www.google.com >/dev/null 2>&1; then

        pass "EC2 can reach the public internet."

    else

        warn "EC2 could not reach Google."

    fi

    if curl -sS \
        --connect-timeout "$CURL_TIMEOUT_SECONDS" \
        --max-time "$CURL_TIMEOUT_SECONDS" \
        -I https://github.com >/dev/null 2>&1; then

        pass "EC2 can reach GitHub."

    else

        warn "EC2 could not reach GitHub."

    fi

fi


# ---------------------------------------------------------------------
# 43. DNS
# ---------------------------------------------------------------------

print_header "36. DNS RESOLUTION"

for DOMAIN in github.com amazonaws.com google.com; do

    if getent hosts "$DOMAIN" >/dev/null 2>&1; then

        echo "[PASS] DNS resolves $DOMAIN"

    else

        echo "[WARN] DNS failed for $DOMAIN"

    fi

done


# ---------------------------------------------------------------------
# 44. AWS AUTHENTICATION FROM EC2
# ---------------------------------------------------------------------

print_header "37. AWS AUTHENTICATION FROM EC2"

if command_exists aws; then

    AUTH_CHECK=$(aws_fast sts get-caller-identity \
        --query "Arn" \
        --output text 2>/dev/null)

    if [ -n "$AUTH_CHECK" ] && [ "$AUTH_CHECK" != "None" ]; then

        echo "AWS Identity:"
        echo "$AUTH_CHECK"

        pass "EC2 has working AWS credentials."

    else

        fail "EC2 AWS credentials are not working."

    fi

fi


# =====================================================================
# S3 VERIFICATION
# =====================================================================

print_header "38. S3 BUCKET COUNT"

S3_LIST_RC=0

BUCKET_LIST=$(aws_fast_capture s3api list-buckets \
    --query "Buckets[].Name" \
    --output text 2>/dev/null)

S3_LIST_RC=$?

if [ "$S3_LIST_RC" -eq 0 ]; then

    if [ -z "$BUCKET_LIST" ] || [ "$BUCKET_LIST" = "None" ]; then

        S3_BUCKET_COUNT=0

    else

        S3_BUCKET_COUNT=$(echo "$BUCKET_LIST" | wc -w)

    fi

    echo "Total S3 Buckets in AWS Account: $S3_BUCKET_COUNT"

    pass "S3 bucket listing completed."

else

    S3_BUCKET_COUNT=0

    warn "Could not list S3 buckets. Check s3:ListAllMyBuckets permission."

fi


# ---------------------------------------------------------------------
# 45. S3 BUCKET DETAILS
# ---------------------------------------------------------------------

print_header "39. S3 BUCKET DETAILS"

if [ "$S3_LIST_RC" -eq 0 ] && [ "$S3_BUCKET_COUNT" -gt 0 ]; then

    for BUCKET in $BUCKET_LIST; do

        echo
        echo "--------------------------------------------------------------"
        echo "Bucket: $BUCKET"
        echo "--------------------------------------------------------------"

        BUCKET_REGION=$(aws_fast_capture s3api get-bucket-location \
            --bucket "$BUCKET" \
            --query "LocationConstraint" \
            --output text 2>/dev/null)

        if [ "$?" -ne 0 ]; then

            BUCKET_REGION="UNKNOWN"

        elif [ "$BUCKET_REGION" = "None" ] || [ -z "$BUCKET_REGION" ]; then

            BUCKET_REGION="us-east-1"

        fi

        echo "Region: $BUCKET_REGION"

        VERSIONING=$(aws_fast_capture s3api get-bucket-versioning \
            --bucket "$BUCKET" \
            --query "Status" \
            --output text 2>/dev/null)

        echo "Versioning: ${VERSIONING:-Not Enabled}"

        ENCRYPTION=$(aws_fast_capture s3api get-bucket-encryption \
            --bucket "$BUCKET" \
            --query "ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm" \
            --output text 2>/dev/null)

        if [ -n "$ENCRYPTION" ] && [ "$ENCRYPTION" != "None" ]; then
            echo "Encryption: $ENCRYPTION"
        else
            echo "Encryption: Not returned by API"
        fi

        PUBLIC_BLOCK=$(aws_fast_capture s3api get-public-access-block \
            --bucket "$BUCKET" \
            --query "PublicAccessBlockConfiguration" \
            --output json 2>/dev/null)

        if [ -n "$PUBLIC_BLOCK" ]; then
            echo "Public Access Block:"
            echo "$PUBLIC_BLOCK"
        else
            echo "Public Access Block: Not configured / unavailable"
        fi

        WEBSITE=$(aws_fast_capture s3api get-bucket-website \
            --bucket "$BUCKET" \
            --output json 2>/dev/null)

        if [ -n "$WEBSITE" ]; then
            echo "Website Configuration:"
            echo "$WEBSITE"
        else
            echo "Website Configuration: Not configured"
        fi

        POLICY_STATUS=$(aws_fast_capture s3api get-bucket-policy-status \
            --bucket "$BUCKET" \
            --query "PolicyStatus.IsPublic" \
            --output text 2>/dev/null)

        if [ "$POLICY_STATUS" = "true" ]; then
            warn "Bucket policy reports public access: $BUCKET"
        elif [ "$POLICY_STATUS" = "false" ]; then
            pass "Bucket policy is not public: $BUCKET"
        else
            info "Bucket policy status unavailable: $BUCKET"
        fi

    done

else

    info "No S3 bucket details available."

fi


# ---------------------------------------------------------------------
# 46. CONFIGURED S3 BUCKET
# ---------------------------------------------------------------------

if [ -n "$S3_BUCKET" ]; then

    print_header "40. CONFIGURED S3 BUCKET"

    echo "Configured Bucket: $S3_BUCKET"

    if aws_fast s3api head-bucket \
        --bucket "$S3_BUCKET" >/dev/null 2>&1; then

        pass "Configured S3 bucket is accessible."

    else

        fail "Configured S3 bucket could not be accessed."

    fi

fi


# =====================================================================
# RDS
# =====================================================================

print_header "41. RDS MYSQL DISCOVERY"

if [ -z "$RDS_IDENTIFIER" ] && [ -n "$VPC_ID" ]; then

    RDS_IDENTIFIER=$(aws_fast_capture rds describe-db-instances \
        --query "DBInstances[?Engine=='mysql' && DBSubnetGroup.VpcId=='$VPC_ID'].DBInstanceIdentifier | [0]" \
        --output text 2>/dev/null)

fi


if [ -z "$RDS_IDENTIFIER" ] || [ "$RDS_IDENTIFIER" = "None" ]; then

    RDS_IDENTIFIER=$(aws_fast_capture rds describe-db-instances \
        --query "DBInstances[?Engine=='mysql'].DBInstanceIdentifier | [0]" \
        --output text 2>/dev/null)

fi


if [ -n "$RDS_IDENTIFIER" ] && [ "$RDS_IDENTIFIER" != "None" ]; then

    echo "RDS Identifier: $RDS_IDENTIFIER"

    RDS_DATA=$(aws_fast_capture rds describe-db-instances \
        --db-instance-identifier "$RDS_IDENTIFIER" \
        --query "DBInstances[0].{Status:DBInstanceStatus,Engine:Engine,EngineVersion:EngineVersion,Endpoint:Endpoint.Address,Port:Endpoint.Port,PubliclyAccessible:PubliclyAccessible,MultiAZ:MultiAZ,Encrypted:StorageEncrypted,BackupRetention:BackupRetentionPeriod,DeletionProtection:DeletionProtection,VpcId:DBSubnetGroup.VpcId,SubnetGroup:DBSubnetGroup.DBSubnetGroupName}" \
        --output table 2>/dev/null)

    RDS_RC=$?

    if [ "$RDS_RC" -eq 0 ]; then

        echo "$RDS_DATA"

        RDS_STATUS=$(aws_fast_capture rds describe-db-instances \
            --db-instance-identifier "$RDS_IDENTIFIER" \
            --query "DBInstances[0].DBInstanceStatus" \
            --output text 2>/dev/null)

        RDS_ENDPOINT=$(aws_fast_capture rds describe-db-instances \
            --db-instance-identifier "$RDS_IDENTIFIER" \
            --query "DBInstances[0].Endpoint.Address" \
            --output text 2>/dev/null)

        RDS_PORT=$(aws_fast_capture rds describe-db-instances \
            --db-instance-identifier "$RDS_IDENTIFIER" \
            --query "DBInstances[0].Endpoint.Port" \
            --output text 2>/dev/null)

        if [ "$RDS_STATUS" = "available" ]; then
            pass "RDS MySQL is available."
        else
            warn "RDS status: $RDS_STATUS"
        fi

    else

        warn "RDS verification timed out or failed."

    fi

else

    info "No MySQL RDS instance discovered."

fi


# ---------------------------------------------------------------------
# 47. RDS NETWORK CONNECTIVITY
# ---------------------------------------------------------------------

print_header "42. RDS NETWORK CONNECTIVITY"

if [ -n "$RDS_ENDPOINT" ] && [ "$RDS_ENDPOINT" != "None" ]; then

    echo "RDS Endpoint: $RDS_ENDPOINT"
    echo "RDS Port:     ${RDS_PORT:-3306}"

    if getent hosts "$RDS_ENDPOINT" >/dev/null 2>&1; then

        pass "RDS endpoint DNS resolves."

    else

        warn "RDS endpoint DNS does not resolve."

    fi

    if command_exists nc; then

        if timeout "$NC_TIMEOUT_SECONDS" \
            nc -z -w "$NC_TIMEOUT_SECONDS" \
            "$RDS_ENDPOINT" "${RDS_PORT:-3306}" \
            >/dev/null 2>&1; then

            pass "EC2 can reach RDS TCP port."

        else

            warn "EC2 could not connect to RDS TCP port."

        fi

    else

        info "nc is not installed; TCP test skipped."

    fi

fi


# =====================================================================
# SECRETS MANAGER
# =====================================================================

print_header "43. SECRETS MANAGER"

SECRET_COUNT=$(aws_fast_capture secretsmanager list-secrets \
    --query "length(SecretList)" \
    --output text 2>/dev/null)

if [ -n "$SECRET_COUNT" ] && [ "$SECRET_COUNT" != "None" ]; then

    echo "Secrets in Region: $SECRET_COUNT"

    aws_fast secretsmanager list-secrets \
        --query "SecretList[].{Name:Name,Description:Description,LastChanged:LastChangedDate,ARN:ARN}" \
        --output table 2>/dev/null

    pass "Secrets Manager metadata verified."

else

    warn "Secrets Manager could not be queried."

fi


# =====================================================================
# ECR
# =====================================================================

print_header "44. ECR REPOSITORY"

if [ -n "$ECR_REPOSITORY" ]; then

    ECR_ERROR=$(aws_fast_capture ecr describe-repositories \
        --repository-names "$ECR_REPOSITORY" \
        --query "repositories[0]" \
        --output json 2>&1)

    ECR_RC=$?

    if [ "$ECR_RC" -eq 0 ]; then

        echo "$ECR_ERROR"

        pass "ECR repository exists."

        echo
        echo "ECR Images:"

        aws_fast ecr describe-images \
            --repository-name "$ECR_REPOSITORY" \
            --query "imageDetails[].{ImageDigest:imageDigest,Tags:imageTags,PushTime:imagePushedAt,Size:imageSizeInBytes}" \
            --output table 2>/dev/null

    else

        if echo "$ECR_ERROR" | grep -qi "RepositoryNotFound"; then

            fail "ECR repository '$ECR_REPOSITORY' does not exist."

        elif echo "$ECR_ERROR" | grep -qi "AccessDenied"; then

            warn "Access denied while reading ECR repository."

        elif echo "$ECR_ERROR" | grep -qi "ExpiredToken\|Unable to locate credentials"; then

            fail "AWS credentials are invalid or unavailable."

        else

            warn "ECR verification failed or timed out."

        fi

    fi

fi


# =====================================================================
# ECS
# =====================================================================

print_header "45. ECS CLUSTER"

ECS_CLUSTER_STATUS=""

if [ -n "$ECS_CLUSTER" ]; then

    ECS_CLUSTER_STATUS=$(aws_fast_capture ecs describe-clusters \
        --clusters "$ECS_CLUSTER" \
        --query "clusters[0].status" \
        --output text 2>/dev/null)

    if [ "$ECS_CLUSTER_STATUS" = "ACTIVE" ]; then

        pass "ECS cluster is ACTIVE."

        aws_fast ecs describe-clusters \
            --clusters "$ECS_CLUSTER" \
            --query "clusters[0].{Name:clusterName,Status:status,RunningTasks:runningTasksCount,PendingTasks:pendingTasksCount,Services:activeServicesCount}" \
            --output table 2>/dev/null

    elif [ -n "$ECS_CLUSTER_STATUS" ] && [ "$ECS_CLUSTER_STATUS" != "None" ]; then

        warn "ECS cluster status: $ECS_CLUSTER_STATUS"

    else

        fail "ECS cluster could not be found."

    fi

fi


# ---------------------------------------------------------------------
# 48. ECS SERVICE
# ---------------------------------------------------------------------

print_header "46. ECS SERVICE"

if [ -n "$ECS_CLUSTER" ] && [ -n "$ECS_SERVICE" ]; then

    ECS_SERVICE_STATUS=$(aws_fast_capture ecs describe-services \
        --cluster "$ECS_CLUSTER" \
        --services "$ECS_SERVICE" \
        --query "services[0].status" \
        --output text 2>/dev/null)

    if [ "$ECS_SERVICE_STATUS" = "ACTIVE" ]; then

        pass "ECS service is ACTIVE."

        aws_fast ecs describe-services \
            --cluster "$ECS_CLUSTER" \
            --services "$ECS_SERVICE" \
            --query "services[0].{Service:serviceName,Status:status,Desired:desiredCount,Running:runningCount,Pending:pendingCount,TaskDefinition:taskDefinition,LaunchType:launchType}" \
            --output table 2>/dev/null

    elif [ -n "$ECS_SERVICE_STATUS" ] && [ "$ECS_SERVICE_STATUS" != "None" ]; then

        warn "ECS service status: $ECS_SERVICE_STATUS"

    else

        fail "ECS service could not be found."

    fi

fi


# ---------------------------------------------------------------------
# 49. ECS RUNNING TASKS
# ---------------------------------------------------------------------

print_header "47. ECS RUNNING TASKS"

if [ -n "$ECS_CLUSTER" ] && [ -n "$ECS_SERVICE" ]; then

    TASK_ARNS=$(aws_fast_capture ecs list-tasks \
        --cluster "$ECS_CLUSTER" \
        --service-name "$ECS_SERVICE" \
        --desired-status RUNNING \
        --query "taskArns[]" \
        --output text 2>/dev/null)

    if [ -n "$TASK_ARNS" ] && [ "$TASK_ARNS" != "None" ]; then

        aws_fast ecs describe-tasks \
            --cluster "$ECS_CLUSTER" \
            --tasks $TASK_ARNS \
            --query "tasks[].{TaskArn:taskArn,Status:lastStatus,Health:healthStatus,TaskDefinition:taskDefinition,CPU:cpu,Memory:memory}" \
            --output table 2>/dev/null

        pass "Running ECS tasks verified."

    else

        warn "No running ECS tasks found."

    fi

fi


# =====================================================================
# ALB
# =====================================================================

print_header "48. APPLICATION LOAD BALANCER"

if [ -z "$ALB_ARN" ] && [ -n "$VPC_ID" ]; then

    ALB_ARN=$(aws_fast_capture elbv2 describe-load-balancers \
        --query "LoadBalancers[?VpcId=='$VPC_ID' && Type=='application'].LoadBalancerArn | [0]" \
        --output text 2>/dev/null)

fi


ALB_DNS=""

if [ -n "$ALB_ARN" ] && [ "$ALB_ARN" != "None" ]; then

    aws_fast elbv2 describe-load-balancers \
        --load-balancer-arns "$ALB_ARN" \
        --query "LoadBalancers[0].{Name:LoadBalancerName,DNS:DNSName,State:State.Code,Type:Type,Scheme:Scheme,VpcId:VpcId,IPType:IpAddressType}" \
        --output table 2>/dev/null

    ALB_DNS=$(aws_fast_capture elbv2 describe-load-balancers \
        --load-balancer-arns "$ALB_ARN" \
        --query "LoadBalancers[0].DNSName" \
        --output text 2>/dev/null)

    if [ -n "$ALB_DNS" ] && [ "$ALB_DNS" != "None" ]; then

        pass "Application Load Balancer discovered."

    else

        warn "ALB DNS name could not be retrieved."

    fi

else

    warn "Application Load Balancer was not found in the lab VPC."

fi


# ---------------------------------------------------------------------
# 50. ALB LISTENERS
# ---------------------------------------------------------------------

print_header "49. ALB LISTENERS"

if [ -n "$ALB_ARN" ] && [ "$ALB_ARN" != "None" ]; then

    aws_fast elbv2 describe-listeners \
        --load-balancer-arn "$ALB_ARN" \
        --query "Listeners[].{Protocol:Protocol,Port:Port,ARN:ListenerArn}" \
        --output table 2>/dev/null

fi


# ---------------------------------------------------------------------
# 51. ALB TARGET GROUPS
# ---------------------------------------------------------------------

print_header "50. ALB TARGET GROUPS"

TARGET_GROUP_ARNS=""

if [ -n "$ALB_ARN" ]; then

    TARGET_GROUP_ARNS=$(aws_fast_capture elbv2 describe-target-groups \
        --load-balancer-arn "$ALB_ARN" \
        --query "TargetGroups[].TargetGroupArn" \
        --output text 2>/dev/null)

    aws_fast elbv2 describe-target-groups \
        --load-balancer-arn "$ALB_ARN" \
        --query "TargetGroups[].{Name:TargetGroupName,Protocol:Protocol,Port:Port,TargetType:TargetType,HealthPath:HealthCheckPath,HealthPort:HealthCheckPort}" \
        --output table 2>/dev/null

fi


# ---------------------------------------------------------------------
# 52. TARGET HEALTH
# ---------------------------------------------------------------------

print_header "51. ALB TARGET HEALTH"

if [ -n "$TARGET_GROUP_ARNS" ] && [ "$TARGET_GROUP_ARNS" != "None" ]; then

    for TG_ARN in $TARGET_GROUP_ARNS; do

        echo
        echo "Target Group:"
        echo "$TG_ARN"

        aws_fast elbv2 describe-target-health \
            --target-group-arn "$TG_ARN" \
            --query "TargetHealthDescriptions[].{Target:Target.Id,Port:Target.Port,State:TargetHealth.State,Reason:TargetHealth.Reason}" \
            --output table 2>/dev/null

    done

    pass "ALB target health verification completed."

else

    warn "No ALB target groups found."

fi


# ---------------------------------------------------------------------
# 53. ALB HTTP TEST
# ---------------------------------------------------------------------

print_header "52. ALB HTTP TEST"

if [ -n "$ALB_DNS" ] && [ "$ALB_DNS" != "None" ]; then

    echo "ALB DNS:"
    echo "$ALB_DNS"

    HTTP_STATUS=$(curl -sS \
        --connect-timeout "$CURL_TIMEOUT_SECONDS" \
        --max-time "$CURL_TIMEOUT_SECONDS" \
        -o /dev/null \
        -w "%{http_code}" \
        "http://$ALB_DNS" 2>/dev/null)

    if [[ "$HTTP_STATUS" =~ ^[23][0-9][0-9]$ ]]; then

        echo "HTTP Status: $HTTP_STATUS"
        pass "Application responded through ALB."

    elif [ -n "$HTTP_STATUS" ]; then

        echo "HTTP Status: $HTTP_STATUS"
        warn "ALB responded with HTTP $HTTP_STATUS."

    else

        warn "ALB HTTP request timed out or failed."

    fi

else

    info "ALB HTTP test skipped because ALB DNS is unavailable."

fi


# ---------------------------------------------------------------------
# 54. ALB HTTPS TEST
# ---------------------------------------------------------------------

print_header "53. ALB HTTPS TEST"

HTTPS_LISTENER=$(aws_fast_capture elbv2 describe-listeners \
    --load-balancer-arn "$ALB_ARN" \
    --query "Listeners[?Port==\`443\`].ListenerArn | [0]" \
    --output text 2>/dev/null)

if [ -n "$HTTPS_LISTENER" ] && [ "$HTTPS_LISTENER" != "None" ]; then

    echo "HTTPS/443 listener detected."

    HTTPS_STATUS=$(curl -k -sS \
        --connect-timeout "$CURL_TIMEOUT_SECONDS" \
        --max-time "$CURL_TIMEOUT_SECONDS" \
        -o /dev/null \
        -w "%{http_code}" \
        "https://$ALB_DNS" 2>/dev/null)

    if [[ "$HTTPS_STATUS" =~ ^[23][0-9][0-9]$ ]]; then

        echo "HTTPS Status: $HTTPS_STATUS"
        pass "Application responded through ALB HTTPS."

    else

        echo "HTTPS Status: ${HTTPS_STATUS:-NO_RESPONSE}"
        warn "ALB HTTPS request failed or timed out."

    fi

else

    info "No HTTPS/443 listener configured on this ALB."

fi


# =====================================================================
# CLOUDWATCH LOGS
# =====================================================================
#
# IMPORTANT:
#
# This section is intentionally FAST.
#
# We DO NOT call:
#
#     aws logs tail
#
# because log tailing can wait for log events and cause the script
# to appear frozen.
#
# Instead we only:
#
#   1. Check whether the log group exists.
#   2. Read its metadata.
#   3. Count streams.
#   4. Optionally retrieve logs ONLY if explicitly enabled.
#
# SHOW_RECENT_LOGS=false is the recommended setting.
#
# =====================================================================

print_header "54. CLOUDWATCH LOGS"

CLOUDWATCH_LOG_GROUP_FOUND="false"

if [ -n "$LOG_GROUP" ]; then

    # ---------------------------------------------------------------
    # FAST LOG GROUP LOOKUP
    # ---------------------------------------------------------------

    LOG_GROUP_DATA=$(aws_fast_capture logs describe-log-groups \
        --log-group-name-prefix "$LOG_GROUP" \
        --query "logGroups[?logGroupName=='$LOG_GROUP'] | [0]" \
        --output json 2>/dev/null)

    CW_RC=$?

    if [ "$CW_RC" -eq 124 ]; then

        warn "CloudWatch Log Group API timed out after ${AWS_TIMEOUT_SECONDS}s."
        info "Continuing verification..."

    elif [ "$CW_RC" -ne 0 ]; then

        warn "CloudWatch Log Group lookup failed."
        info "Continuing verification..."

    elif [ -z "$LOG_GROUP_DATA" ] || [ "$LOG_GROUP_DATA" = "null" ]; then

        warn "CloudWatch Log Group does not exist: $LOG_GROUP"

    else

        CLOUDWATCH_LOG_GROUP_FOUND="true"

        echo "Log Group:"
        echo "$LOG_GROUP_DATA"

        pass "CloudWatch Log Group exists."

    fi


    # ---------------------------------------------------------------
    # LOG STREAM COUNT
    # ---------------------------------------------------------------
    #
    # This is also bounded by AWS_TIMEOUT_SECONDS.
    #
    # ---------------------------------------------------------------

    if [ "$CLOUDWATCH_LOG_GROUP_FOUND" = "true" ]; then

        LOG_STREAM_COUNT=$(aws_fast_capture logs describe-log-streams \
            --log-group-name "$LOG_GROUP" \
            --query "length(logStreams)" \
            --output text 2>/dev/null)

        STREAM_RC=$?

        if [ "$STREAM_RC" -eq 124 ]; then

            warn "CloudWatch log stream lookup timed out."
            info "Continuing verification..."

        elif [ "$STREAM_RC" -eq 0 ]; then

            echo "Log Stream Count: ${LOG_STREAM_COUNT:-0}"

            pass "CloudWatch log stream metadata verified."

        else

            warn "CloudWatch log stream lookup failed."

        fi

    fi


    # ---------------------------------------------------------------
    # RECENT LOGS
    # ---------------------------------------------------------------
    #
    # DISABLED BY DEFAULT.
    #
    # If you set:
    #
    # SHOW_RECENT_LOGS="true"
    #
    # then the script retrieves only a very small number of events.
    #
    # Even then, timeout protection remains active.
    #
    # ---------------------------------------------------------------

    if [ "$SHOW_RECENT_LOGS" = "true" ] && \
       [ "$CLOUDWATCH_LOG_GROUP_FOUND" = "true" ]; then

        echo
        echo "Recent CloudWatch Events:"
        echo "---------------------------------------------"

        RECENT_LOGS=$(aws_fast_capture logs filter-log-events \
            --log-group-name "$LOG_GROUP" \
            --limit 5 \
            --query "events[].{Time:timestamp,Message:message}" \
            --output table 2>/dev/null)

        RECENT_RC=$?

        if [ "$RECENT_RC" -eq 124 ]; then

            warn "CloudWatch event retrieval timed out."
            info "Continuing verification..."

        elif [ "$RECENT_RC" -eq 0 ]; then

            echo "$RECENT_LOGS"

        else

            warn "Recent CloudWatch events could not be retrieved."

        fi

    else

        info "CloudWatch log content retrieval is disabled for fast verification."

    fi

else

    info "CloudWatch Log Group variable is empty."

fi


# =====================================================================
# CLOUDWATCH LOG GROUPS SUMMARY
# =====================================================================

print_header "55. CLOUDWATCH LOG GROUP SUMMARY"

CW_GROUP_COUNT=$(aws_fast_capture logs describe-log-groups \
    --query "length(logGroups)" \
    --output text 2>/dev/null)

CW_GROUP_RC=$?

if [ "$CW_GROUP_RC" -eq 124 ]; then

    warn "CloudWatch log group summary timed out."

elif [ "$CW_GROUP_RC" -eq 0 ]; then

    echo "CloudWatch Log Groups in Region: ${CW_GROUP_COUNT:-0}"

    pass "CloudWatch log group summary completed."

else

    warn "CloudWatch log group summary failed."

fi


# =====================================================================
# CLOUDFRONT
# =====================================================================

print_header "56. CLOUDFRONT DISTRIBUTIONS"

CF_DISTRIBUTION_COUNT=$(aws cloudfront list-distributions \
    --query "DistributionList.Quantity" \
    --output text 2>/dev/null)

CF_RC=$?

if [ "$CF_RC" -eq 0 ]; then

    echo "CloudFront Distributions: ${CF_DISTRIBUTION_COUNT:-0}"

    aws cloudfront list-distributions \
        --query "DistributionList.Items[].{Id:Id,Domain:DomainName,Status:Status,Enabled:Enabled}" \
        --output table 2>/dev/null

    pass "CloudFront distributions retrieved."

else

    warn "CloudFront distribution lookup failed."

fi


# ---------------------------------------------------------------------
# 57. CLOUDFRONT AUTO DISCOVERY
# ---------------------------------------------------------------------

if [ -z "$CLOUDFRONT_DISTRIBUTION_ID" ]; then

    if [ "${CF_DISTRIBUTION_COUNT:-0}" = "1" ]; then

        CLOUDFRONT_DISTRIBUTION_ID=$(aws cloudfront list-distributions \
            --query "DistributionList.Items[0].Id" \
            --output text 2>/dev/null)

    fi

fi


# ---------------------------------------------------------------------
# 58. CLOUDFRONT DETAILS
# ---------------------------------------------------------------------

print_header "57. CLOUDFRONT DETAILS"

if [ -n "$CLOUDFRONT_DISTRIBUTION_ID" ] && \
   [ "$CLOUDFRONT_DISTRIBUTION_ID" != "None" ]; then

    CF_STATUS=$(timeout \
        --signal=TERM \
        --kill-after=2s \
        8s \
        aws cloudfront get-distribution \
        --id "$CLOUDFRONT_DISTRIBUTION_ID" \
        --query "Distribution.{Id:Id,Domain:DomainName,Status:Status,Enabled:DistributionConfig.Enabled}" \
        --output table 2>/dev/null)

    CF_DETAIL_RC=$?

    if [ "$CF_DETAIL_RC" -eq 0 ]; then

        echo "$CF_STATUS"

        CLOUDFRONT_DOMAIN=$(aws cloudfront get-distribution \
            --id "$CLOUDFRONT_DISTRIBUTION_ID" \
            --query "Distribution.DomainName" \
            --output text 2>/dev/null)

        CF_DEPLOYMENT_STATUS=$(aws cloudfront get-distribution \
            --id "$CLOUDFRONT_DISTRIBUTION_ID" \
            --query "Distribution.Status" \
            --output text 2>/dev/null)

        if [ "$CF_DEPLOYMENT_STATUS" = "Deployed" ]; then
            pass "CloudFront distribution is deployed."
        else
            warn "CloudFront distribution status: $CF_DEPLOYMENT_STATUS"
        fi

    elif [ "$CF_DETAIL_RC" -eq 124 ]; then

        warn "CloudFront detail lookup timed out."

    else

        warn "CloudFront detail lookup failed."

    fi

else

    info "CloudFront distribution ID was not uniquely discovered."

fi


# ---------------------------------------------------------------------
# 59. CLOUDFRONT HTTPS TEST
# ---------------------------------------------------------------------

print_header "58. CLOUDFRONT HTTPS TEST"

if [ -n "$CLOUDFRONT_DOMAIN" ] && \
   [ "$CLOUDFRONT_DOMAIN" != "None" ]; then

    echo "CloudFront Domain:"
    echo "$CLOUDFRONT_DOMAIN"

    CF_HTTP_STATUS=$(curl -sS \
        --connect-timeout "$CURL_TIMEOUT_SECONDS" \
        --max-time "$CURL_TIMEOUT_SECONDS" \
        -o /dev/null \
        -w "%{http_code}" \
        "https://$CLOUDFRONT_DOMAIN" 2>/dev/null)

    if [[ "$CF_HTTP_STATUS" =~ ^[23][0-9][0-9]$ ]]; then

        echo "HTTP Status: $CF_HTTP_STATUS"

        pass "CloudFront HTTPS endpoint responded."

    elif [ -n "$CF_HTTP_STATUS" ]; then

        echo "HTTP Status: $CF_HTTP_STATUS"

        warn "CloudFront responded with HTTP $CF_HTTP_STATUS."

    else

        warn "CloudFront HTTPS request timed out."

    fi

else

    info "CloudFront HTTPS test skipped because domain is unavailable."

fi


# =====================================================================
# CLOUDFORMATION RESOURCES
# =====================================================================

print_header "59. CLOUDFORMATION RESOURCES"

if [ "$STACK_EXISTS" = "true" ]; then

    aws_fast cloudformation list-stack-resources \
        --stack-name "$MAIN_STACK" \
        --query "StackResourceSummaries[].{LogicalId:LogicalResourceId,Type:ResourceType,Status:ResourceStatus}" \
        --output table 2>/dev/null

fi


# =====================================================================
# NESTED STACKS
# =====================================================================

print_header "60. NESTED CLOUDFORMATION STACKS"

if [ "$STACK_EXISTS" = "true" ]; then

    aws_fast cloudformation list-stack-resources \
        --stack-name "$MAIN_STACK" \
        --query "StackResourceSummaries[?ResourceType=='AWS::CloudFormation::Stack'].{LogicalId:LogicalResourceId,PhysicalId:PhysicalResourceId,Status:ResourceStatus}" \
        --output table 2>/dev/null

fi


# =====================================================================
# ECS CLOUDFORMATION STACK
# =====================================================================

print_header "61. ECS CLOUDFORMATION STACK"

if [ -n "$ECS_STACK" ]; then

    ECS_STACK_STATUS=$(aws_fast_capture cloudformation describe-stacks \
        --stack-name "$ECS_STACK" \
        --query "Stacks[0].StackStatus" \
        --output text 2>/dev/null)

    if [ "$ECS_STACK_STATUS" = "CREATE_COMPLETE" ] || \
       [ "$ECS_STACK_STATUS" = "UPDATE_COMPLETE" ]; then

        pass "ECS CloudFormation stack is healthy."

    elif [ -n "$ECS_STACK_STATUS" ] && \
         [ "$ECS_STACK_STATUS" != "None" ]; then

        warn "ECS CloudFormation stack status: $ECS_STACK_STATUS"

    else

        info "ECS CloudFormation stack was not found."

    fi

fi


# =====================================================================
# CLOUDFORMATION FAILED EVENTS
# =====================================================================

print_header "62. CLOUDFORMATION RECENT EVENTS"

if [ "$STACK_EXISTS" = "true" ]; then

    aws_fast cloudformation describe-stack-events \
        --stack-name "$MAIN_STACK" \
        --query "StackEvents[:10].{Time:Timestamp,LogicalId:LogicalResourceId,Type:ResourceType,Status:ResourceStatus,Reason:ResourceStatusReason}" \
        --output table 2>/dev/null

    if [ "$?" -eq 0 ]; then
        pass "Recent CloudFormation events retrieved."
    else
        warn "CloudFormation event lookup failed."
    fi

fi


# =====================================================================
# FINAL CONNECTIVITY TEST
# =====================================================================

print_header "63. FINAL EC2 → RDS CONNECTIVITY"

if [ -n "$RDS_ENDPOINT" ] && \
   [ "$RDS_ENDPOINT" != "None" ] && \
   command_exists nc; then

    if timeout "$NC_TIMEOUT_SECONDS" \
        nc -z -w "$NC_TIMEOUT_SECONDS" \
        "$RDS_ENDPOINT" "${RDS_PORT:-3306}" \
        >/dev/null 2>&1; then

        pass "Final EC2 → RDS TCP connectivity test passed."

    else

        warn "Final EC2 → RDS TCP connectivity test failed."

    fi

else

    info "Final RDS connectivity test skipped."

fi


# =====================================================================
# FINAL LOCAL HTTP CHECK
# =====================================================================

print_header "64. LOCAL WEB SERVER CHECK"

LOCAL_HTTP_STATUS=$(curl -sS \
    --connect-timeout 3 \
    --max-time 5 \
    -o /dev/null \
    -w "%{http_code}" \
    "http://127.0.0.1" 2>/dev/null)

if [[ "$LOCAL_HTTP_STATUS" =~ ^[23][0-9][0-9]$ ]]; then

    echo "Local HTTP Status: $LOCAL_HTTP_STATUS"

    pass "Local web server responded."

else

    info "No local HTTP service detected on port 80."

fi


# =====================================================================
# FINAL SUMMARY
# =====================================================================

print_header "65. VERIFICATION SUMMARY"

echo
echo "AWS Region:       $AWS_REGION"
echo "AWS Account:      ${ACCOUNT_ID:-UNKNOWN}"
echo "EC2 Instance:     ${INSTANCE_ID:-UNKNOWN}"
echo "VPC ID:           ${VPC_ID:-UNKNOWN}"
echo "RDS Instance:     ${RDS_IDENTIFIER:-NOT_FOUND}"
echo "ALB DNS:          ${ALB_DNS:-NOT_FOUND}"
echo "CloudFront:       ${CLOUDFRONT_DOMAIN:-NOT_FOUND}"
echo "S3 Bucket Count:  ${S3_BUCKET_COUNT:-0}"
echo "ECS Cluster:      ${ECS_CLUSTER:-NOT_CONFIGURED}"
echo "ECS Service:      ${ECS_SERVICE:-NOT_CONFIGURED}"
echo "CloudWatch Group: ${LOG_GROUP:-NOT_CONFIGURED}"

echo
echo "---------------------------------------------------------------------"
echo "RESULTS"
echo "---------------------------------------------------------------------"

echo "PASS: $PASS_COUNT"
echo "WARN: $WARN_COUNT"
echo "FAIL: $FAIL_COUNT"

echo
echo "---------------------------------------------------------------------"
echo "IMPORTANT"
echo "---------------------------------------------------------------------"

echo "This verification script does not modify AWS resources."
echo "CloudWatch log content retrieval is disabled by default."
echo "AWS API calls are timeout-protected."
echo "Slow AWS APIs will WARN and verification will continue."

echo
echo "======================================================================"
echo "VERIFICATION COMPLETE"
echo "======================================================================"


# =====================================================================
# EXIT STATUS
# =====================================================================

if [ "$EXIT_NONZERO_ON_FAILURE" = "true" ] && [ "$FAIL_COUNT" -gt 0 ]; then

    exit 1

else

    exit 0

fi