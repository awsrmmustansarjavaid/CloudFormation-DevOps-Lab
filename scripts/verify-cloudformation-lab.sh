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