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