# ================================================================
# AWS FULL ACCOUNT / REGION CLEANUP SCRIPT
# ================================================================
#
# File:
#   scripts/aws-full-cleanup.ps1
#
# Purpose:
#   Discover and delete AWS resources used by the Charlie Cafe /
#   AWS Hybrid IaC Lab.
#
# Resources handled:
#
#   1. CloudFront distributions
#   2. S3 buckets and all objects/versions/delete markers
#   3. ECS services
#   4. ECS tasks
#   5. ECS clusters
#   6. ECR repositories
#   7. RDS DB instances
#   8. RDS DB clusters
#   9. Secrets Manager secrets
#  10. VPC endpoints
#  11. NAT gateways
#  12. Elastic IPs associated with NAT gateways
#  13. Internet gateways
#  14. Route tables
#  15. Network interfaces
#  16. Subnets
#  17. Security groups
#  18. VPCs
#
# IMPORTANT:
#
#   This script is DESTRUCTIVE.
#
#   Preview:
#       .\aws-full-cleanup.ps1 -Region us-east-1
#
#   Actual deletion:
#       .\aws-full-cleanup.ps1 -Region us-east-1 -Execute
#
#   The script does NOT delete anything unless -Execute is supplied.
#
# ================================================================

[CmdletBinding()]
param(

    # ------------------------------------------------------------
    # AWS region containing the lab resources
    # ------------------------------------------------------------
    [Parameter(Mandatory = $false)]
    [string]$Region = "us-east-1",

    # ------------------------------------------------------------
    # AWS CLI profile
    #
    # Leave empty to use the default AWS CLI credentials.
    #
    # Example:
    #
    #   -Profile "default"
    #   -Profile "dev"
    # ------------------------------------------------------------
    [Parameter(Mandatory = $false)]
    [string]$Profile = "",

    # ------------------------------------------------------------
    # Actually perform deletion.
    #
    # Without this switch the script is PREVIEW ONLY.
    # ------------------------------------------------------------
    [switch]$Execute,

    # ------------------------------------------------------------
    # By default, default VPCs are protected.
    #
    # Use:
    #
    #   -DeleteDefaultVpc
    #
    # only if you intentionally want default VPC deletion.
    # ------------------------------------------------------------
    [switch]$DeleteDefaultVpc
)

# ================================================================
# GLOBAL SETTINGS
# ================================================================

$ErrorActionPreference = "Continue"

# Maximum retry count for operations that may temporarily fail.
$MaxRetries = 10

# Seconds between retry attempts.
$RetryDelaySeconds = 10

# NAT gateway deletion can take several minutes.
$NatWaitSeconds = 15

# ================================================================
# AWS CLI COMMAND BUILDER
# ================================================================

function Get-AwsBaseArgs {

    $args = @(
        "--region"
        $Region
        "--no-cli-pager"
    )

    if (-not [string]::IsNullOrWhiteSpace($Profile)) {

        $args += @(
            "--profile"
            $Profile
        )
    }

    return $args
}

# ================================================================
# RUN AWS CLI
# ================================================================

function Invoke-AwsCli {

    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $baseArgs = Get-AwsBaseArgs

    $finalArgs = $baseArgs + $Arguments

    & aws @finalArgs 2>&1
}

# ================================================================
# RUN AWS CLI AND RETURN JSON
# ================================================================

function Invoke-AwsJson {

    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $output = Invoke-AwsCli -Arguments $Arguments

    if ($LASTEXITCODE -ne 0) {

        return $null
    }

    if ([string]::IsNullOrWhiteSpace(($output -join ""))) {

        return $null
    }

    try {

        return ($output -join "`n") | ConvertFrom-Json
    }
    catch {

        return $null
    }
}

# ================================================================
# LOGGING FUNCTIONS
# ================================================================

function Write-Info {

    param([string]$Message)

    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {

    param([string]$Message)

    Write-Host "[PASS] $Message" -ForegroundColor Green
}

function Write-WarningMessage {

    param([string]$Message)

    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Failure {

    param([string]$Message)

    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Write-Section {

    param([string]$Title)

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor DarkCyan
    Write-Host $Title -ForegroundColor White
    Write-Host "============================================================" -ForegroundColor DarkCyan
}

# ================================================================
# EXECUTION GUARD
# ================================================================

function Confirm-Execution {

    if ($Execute) {

        Write-WarningMessage "DESTRUCTIVE MODE ENABLED."
        Write-WarningMessage "AWS resources WILL be deleted."

        Write-Host ""

        $confirmation = Read-Host "Type DELETE to continue"

        if ($confirmation -ne "DELETE") {

            Write-WarningMessage "Confirmation failed. Cleanup cancelled."

            exit 1
        }

        return
    }

    Write-WarningMessage "PREVIEW MODE."
    Write-WarningMessage "No resources will actually be deleted."
    Write-WarningMessage "Use -Execute to perform deletion."

    Write-Host ""
}

# ================================================================
# AWS CLI CHECK
# ================================================================

function Test-AwsCli {

    Write-Section "01 - AWS CLI CHECK"

    $awsVersion = aws --version 2>&1

    if ($LASTEXITCODE -ne 0) {

        Write-Failure "AWS CLI is not installed or not available in PATH."

        exit 1
    }

    Write-Info "AWS CLI: $awsVersion"

    $identity = Invoke-AwsJson -Arguments @(
        "sts"
        "get-caller-identity"
    )

    if ($null -eq $identity) {

        Write-Failure "Unable to authenticate to AWS."

        exit 1
    }

    Write-Success "AWS authentication successful."

    Write-Info "Account ID: $($identity.Account)"
    Write-Info "User/Role: $($identity.Arn)"
    Write-Info "Region: $Region"
}

# ================================================================
# WAIT FUNCTION
# ================================================================

function Wait-Seconds {

    param(
        [int]$Seconds
    )

    Start-Sleep -Seconds $Seconds
}

# ================================================================
# 02 - CLOUDFRONT
# ================================================================
#
# CloudFront is GLOBAL.
#
# It does not use the normal regional AWS resource model.
#
# AWS requires a distribution to be disabled before deletion.
# ================================================================

function Remove-CloudFront {

    Write-Section "02 - CLOUDFRONT CLEANUP"

    $data = Invoke-AwsJson -Arguments @(
        "cloudfront"
        "list-distributions"
    )

    if ($null -eq $data) {

        Write-Info "No CloudFront distributions found."

        return
    }

    if ($null -eq $data.DistributionList.Items) {

        Write-Info "No CloudFront distributions found."

        return
    }

    foreach ($distribution in $data.DistributionList.Items) {

        $id = $distribution.Id
        $enabled = $distribution.Enabled

        Write-Info "CloudFront distribution: $id"

        if (-not $Execute) {

            Write-WarningMessage "PREVIEW: Would disable/delete CloudFront $id"

            continue
        }

        # --------------------------------------------------------
        # Get current distribution configuration.
        # --------------------------------------------------------

        $config = Invoke-AwsJson -Arguments @(
            "cloudfront"
            "get-distribution-config"
            "--id"
            $id
        )

        if ($null -eq $config) {

            Write-Failure "Unable to read CloudFront configuration: $id"

            continue
        }

        $etag = $config.ETag
        $distributionConfig = $config.DistributionConfig

        # --------------------------------------------------------
        # Disable distribution if required.
        # --------------------------------------------------------

        if ($enabled) {

            Write-Info "Disabling CloudFront distribution: $id"

            $distributionConfig.Enabled = $false

            $tempFile = Join-Path $env:TEMP "cloudfront-$id.json"

            $distributionConfig |
                ConvertTo-Json -Depth 100 |
                Set-Content -Path $tempFile -Encoding UTF8

            Invoke-AwsCli -Arguments @(
                "cloudfront"
                "update-distribution"
                "--id"
                $id
                "--if-match"
                $etag
                "--distribution-config"
                "file://$tempFile"
            ) | Out-Null

            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

            Write-Info "Waiting for CloudFront distribution to become deployed..."

            Invoke-AwsCli -Arguments @(
                "cloudfront"
                "wait"
                "distribution-deployed"
                "--id"
                $id
            ) | Out-Null
        }

        # --------------------------------------------------------
        # Get fresh ETag.
        # --------------------------------------------------------

        $freshConfig = Invoke-AwsJson -Arguments @(
            "cloudfront"
            "get-distribution-config"
            "--id"
            $id
        )

        if ($null -eq $freshConfig) {

            Write-Failure "Unable to get fresh CloudFront ETag: $id"

            continue
        }

        $freshEtag = $freshConfig.ETag

        # --------------------------------------------------------
        # Delete distribution.
        # --------------------------------------------------------

        Write-Info "Deleting CloudFront distribution: $id"

        Invoke-AwsCli -Arguments @(
            "cloudfront"
            "delete-distribution"
            "--id"
            $id
            "--if-match"
            $freshEtag
        ) | Out-Null

        if ($LASTEXITCODE -eq 0) {

            Write-Success "CloudFront deleted: $id"
        }
        else {

            Write-Failure "CloudFront deletion failed: $id"
        }
    }
}

# ================================================================
# 03 - S3
# ================================================================

function Remove-S3 {

    Write-Section "03 - S3 CLEANUP"

    $buckets = Invoke-AwsJson -Arguments @(
        "s3api"
        "list-buckets"
    )

    if ($null -eq $buckets) {

        Write-Info "No S3 buckets found."

        return
    }

    foreach ($bucket in $buckets.Buckets) {

        $bucketName = $bucket.Name

        Write-Info "S3 bucket discovered: $bucketName"

        if (-not $Execute) {

            Write-WarningMessage "PREVIEW: Would empty and delete bucket $bucketName"

            continue
        }

        # --------------------------------------------------------
        # Delete all normal objects.
        # --------------------------------------------------------

        Write-Info "Deleting normal objects from $bucketName"

        Invoke-AwsCli -Arguments @(
            "s3"
            "rm"
            "s3://$bucketName"
            "--recursive"
        ) | Out-Null

        # --------------------------------------------------------
        # Delete versioned objects and delete markers.
        #
        # This is important for versioned S3 buckets.
        # --------------------------------------------------------

        Write-Info "Deleting object versions and delete markers..."

        while ($true) {

            $versions = Invoke-AwsJson -Arguments @(
                "s3api"
                "list-object-versions"
                "--bucket"
                $bucketName
            )

            if ($null -eq $versions) {

                break
            }

            $objects = @()

            if ($versions.Versions) {

                foreach ($version in $versions.Versions) {

                    $objects += [PSCustomObject]@{
                        Key       = $version.Key
                        VersionId = $version.VersionId
                    }
                }
            }

            if ($versions.DeleteMarkers) {

                foreach ($marker in $versions.DeleteMarkers) {

                    $objects += [PSCustomObject]@{
                        Key       = $marker.Key
                        VersionId = $marker.VersionId
                    }
                }
            }

            if ($objects.Count -eq 0) {

                break
            }

            # ----------------------------------------------------
            # AWS S3 delete-objects accepts maximum 1000 objects
            # per request.
            # ----------------------------------------------------

            for ($i = 0; $i -lt $objects.Count; $i += 1000) {

                $end = [Math]::Min(
                    $i + 999,
                    $objects.Count - 1
                )

                $batch = @(
                    $objects[$i..$end]
                )

                $deletePayload = @{
                    Objects = $batch
                    Quiet   = $true
                }

                $tempFile = Join-Path $env:TEMP "s3-delete-$([guid]::NewGuid()).json"

                $deletePayload |
                    ConvertTo-Json -Depth 20 |
                    Set-Content -Path $tempFile -Encoding UTF8

                Invoke-AwsCli -Arguments @(
                    "s3api"
                    "delete-objects"
                    "--bucket"
                    $bucketName
                    "--delete"
                    "file://$tempFile"
                ) | Out-Null

                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            }
        }

        # --------------------------------------------------------
        # Delete bucket.
        # --------------------------------------------------------

        Write-Info "Deleting S3 bucket: $bucketName"

        Invoke-AwsCli -Arguments @(
            "s3api"
            "delete-bucket"
            "--bucket"
            $bucketName
        ) | Out-Null

        if ($LASTEXITCODE -eq 0) {

            Write-Success "S3 bucket deleted: $bucketName"
        }
        else {

            Write-Failure "S3 bucket deletion failed: $bucketName"
        }
    }
}

# ================================================================
# 04 - ECS SERVICES
# ================================================================

function Remove-Ecs {

    Write-Section "04 - ECS CLEANUP"

    $clustersData = Invoke-AwsJson -Arguments @(
        "ecs"
        "list-clusters"
    )

    if ($null -eq $clustersData) {

        Write-Info "No ECS clusters found."

        return
    }

    foreach ($clusterArn in $clustersData.clusterArns) {

        $clusterName = ($clusterArn -split "/")[-1]

        Write-Info "ECS cluster: $clusterName"

        # --------------------------------------------------------
        # List services.
        # --------------------------------------------------------

        $servicesData = Invoke-AwsJson -Arguments @(
            "ecs"
            "list-services"
            "--cluster"
            $clusterArn
        )

        if ($null -ne $servicesData) {

            foreach ($serviceArn in $servicesData.serviceArns) {

                $serviceName = ($serviceArn -split "/")[-1]

                Write-Info "ECS service: $serviceName"

                if (-not $Execute) {

                    Write-WarningMessage "PREVIEW: Would delete ECS service $serviceName"

                    continue
                }

                # ------------------------------------------------
                # Scale service to zero.
                # ------------------------------------------------

                Invoke-AwsCli -Arguments @(
                    "ecs"
                    "update-service"
                    "--cluster"
                    $clusterArn
                    "--service"
                    $serviceArn
                    "--desired-count"
                    "0"
                ) | Out-Null

                # ------------------------------------------------
                # Delete service.
                # ------------------------------------------------

                Invoke-AwsCli -Arguments @(
                    "ecs"
                    "delete-service"
                    "--cluster"
                    $clusterArn
                    "--service"
                    $serviceArn
                    "--force"
                ) | Out-Null

                Write-Success "ECS service deleted: $serviceName"
            }
        }

        if ($Execute) {

            # ----------------------------------------------------
            # Stop running ECS tasks.
            # ----------------------------------------------------

            $tasksData = Invoke-AwsJson -Arguments @(
                "ecs"
                "list-tasks"
                "--cluster"
                $clusterArn
                "--desired-status"
                "RUNNING"
            )

            if ($null -ne $tasksData) {

                foreach ($taskArn in $tasksData.taskArns) {

                    Write-Info "Stopping ECS task: $taskArn"

                    Invoke-AwsCli -Arguments @(
                        "ecs"
                        "stop-task"
                        "--cluster"
                        $clusterArn
                        "--task"
                        $taskArn
                    ) | Out-Null
                }
            }

            # ----------------------------------------------------
            # Delete ECS cluster.
            # ----------------------------------------------------

            Write-Info "Deleting ECS cluster: $clusterName"

            Invoke-AwsCli -Arguments @(
                "ecs"
                "delete-cluster"
                "--cluster"
                $clusterArn
            ) | Out-Null

            if ($LASTEXITCODE -eq 0) {

                Write-Success "ECS cluster deleted: $clusterName"
            }
            else {

                Write-Failure "ECS cluster deletion failed: $clusterName"
            }
        }
    }
}

# ================================================================
# 05 - ECR
# ================================================================

function Remove-Ecr {

    Write-Section "05 - ECR CLEANUP"

    $repos = Invoke-AwsJson -Arguments @(
        "ecr"
        "describe-repositories"
    )

    if ($null -eq $repos) {

        Write-Info "No ECR repositories found."

        return
    }

    foreach ($repo in $repos.repositories) {

        $repoName = $repo.repositoryName

        Write-Info "ECR repository: $repoName"

        if (-not $Execute) {

            Write-WarningMessage "PREVIEW: Would force-delete ECR repository $repoName"

            continue
        }

        Invoke-AwsCli -Arguments @(
            "ecr"
            "delete-repository"
            "--repository-name"
            $repoName
            "--force"
        ) | Out-Null

        if ($LASTEXITCODE -eq 0) {

            Write-Success "ECR repository deleted: $repoName"
        }
        else {

            Write-Failure "ECR repository deletion failed: $repoName"
        }
    }
}

# ================================================================
# 06 - RDS
# ================================================================

function Remove-Rds {

    Write-Section "06 - RDS CLEANUP"

    # ------------------------------------------------------------
    # DB INSTANCES
    # ------------------------------------------------------------

    $instances = Invoke-AwsJson -Arguments @(
        "rds"
        "describe-db-instances"
    )

    if ($null -ne $instances) {

        foreach ($db in $instances.DBInstances) {

            $identifier = $db.DBInstanceIdentifier

            Write-Info "RDS DB instance: $identifier"

            if (-not $Execute) {

                Write-WarningMessage "PREVIEW: Would delete RDS instance $identifier"

                continue
            }

            # ----------------------------------------------------
            # Delete without creating a final snapshot.
            #
            # Change this if you need a backup.
            # ----------------------------------------------------

            Invoke-AwsCli -Arguments @(
                "rds"
                "delete-db-instance"
                "--db-instance-identifier"
                $identifier
                "--skip-final-snapshot"
                "--delete-automated-backups"
            ) | Out-Null

            if ($LASTEXITCODE -eq 0) {

                Write-Success "RDS deletion requested: $identifier"
            }
            else {

                Write-Failure "RDS deletion failed: $identifier"
            }
        }
    }

    # ------------------------------------------------------------
    # DB CLUSTERS / AURORA
    # ------------------------------------------------------------

    $clusters = Invoke-AwsJson -Arguments @(
        "rds"
        "describe-db-clusters"
    )

    if ($null -ne $clusters) {

        foreach ($cluster in $clusters.DBClusters) {

            $identifier = $cluster.DBClusterIdentifier

            Write-Info "RDS cluster: $identifier"

            if (-not $Execute) {

                Write-WarningMessage "PREVIEW: Would delete RDS cluster $identifier"

                continue
            }

            Invoke-AwsCli -Arguments @(
                "rds"
                "delete-db-cluster"
                "--db-cluster-identifier"
                $identifier
                "--skip-final-snapshot"
            ) | Out-Null

            if ($LASTEXITCODE -eq 0) {

                Write-Success "RDS cluster deletion requested: $identifier"
            }
            else {

                Write-Failure "RDS cluster deletion failed: $identifier"
            }
        }
    }
}

# ================================================================
# 07 - SECRETS MANAGER
# ================================================================

function Remove-Secrets {

    Write-Section "07 - SECRETS MANAGER CLEANUP"

    $secrets = Invoke-AwsJson -Arguments @(
        "secretsmanager"
        "list-secrets"
    )

    if ($null -eq $secrets) {

        Write-Info "No Secrets Manager secrets found."

        return
    }

    foreach ($secret in $secrets.SecretList) {

        $arn = $secret.ARN
        $name = $secret.Name

        Write-Info "Secret: $name"

        if (-not $Execute) {

            Write-WarningMessage "PREVIEW: Would delete secret $name"

            continue
        }

        Invoke-AwsCli -Arguments @(
            "secretsmanager"
            "delete-secret"
            "--secret-id"
            $arn
            "--force-delete-without-recovery"
        ) | Out-Null

        if ($LASTEXITCODE -eq 0) {

            Write-Success "Secret deleted: $name"
        }
        else {

            Write-Failure "Secret deletion failed: $name"
        }
    }
}

# ================================================================
# 08 - VPC ENDPOINTS
# ================================================================

function Remove-VpcEndpoints {

    Write-Section "08 - VPC ENDPOINT CLEANUP"

    $data = Invoke-AwsJson -Arguments @(
        "ec2"
        "describe-vpc-endpoints"
    )

    if ($null -eq $data) {

        Write-Info "No VPC endpoints found."

        return
    }

    foreach ($endpoint in $data.VpcEndpoints) {

        $id = $endpoint.VpcEndpointId

        Write-Info "VPC endpoint: $id"

        if (-not $Execute) {

            Write-WarningMessage "PREVIEW: Would delete VPC endpoint $id"

            continue
        }

        Invoke-AwsCli -Arguments @(
            "ec2"
            "delete-vpc-endpoints"
            "--vpc-endpoint-ids"
            $id
        ) | Out-Null

        if ($LASTEXITCODE -eq 0) {

            Write-Success "VPC endpoint deleted: $id"
        }
        else {

            Write-Failure "VPC endpoint deletion failed: $id"
        }
    }
}

# ================================================================
# 09 - NAT GATEWAYS
# ================================================================

function Remove-NatGateways {

    Write-Section "09 - NAT GATEWAY CLEANUP"

    $data = Invoke-AwsJson -Arguments @(
        "ec2"
        "describe-nat-gateways"
        "--filter"
        "Name=state,Values=available,pending,failed"
    )

    if ($null -eq $data) {

        Write-Info "No NAT gateways found."

        return
    }

    foreach ($nat in $data.NatGateways) {

        $natId = $nat.NatGatewayId

        Write-Info "NAT gateway: $natId"

        if (-not $Execute) {

            Write-WarningMessage "PREVIEW: Would delete NAT gateway $natId"

            continue
        }

        Invoke-AwsCli -Arguments @(
            "ec2"
            "delete-nat-gateway"
            "--nat-gateway-id"
            $natId
        ) | Out-Null

        if ($LASTEXITCODE -eq 0) {

            Write-Success "NAT gateway deletion requested: $natId"
        }
        else {

            Write-Failure "NAT gateway deletion failed: $natId"
        }
    }

    # ------------------------------------------------------------
    # Wait for NAT gateways to disappear.
    # ------------------------------------------------------------

    if ($Execute) {

        Write-Info "Waiting for NAT gateways to finish deleting..."

        for ($attempt = 1; $attempt -le 40; $attempt++) {

            $remaining = Invoke-AwsJson -Arguments @(
                "ec2"
                "describe-nat-gateways"
                "--filter"
                "Name=state,Values=pending,available,deleting"
            )

            if ($null -eq $remaining -or
                $null -eq $remaining.NatGateways -or
                $remaining.NatGateways.Count -eq 0) {

                Write-Success "NAT gateways are gone."

                break
            }

            Write-Info "NAT gateways still deleting. Waiting..."

            Wait-Seconds -Seconds $NatWaitSeconds
        }
    }
}

# ================================================================
# 10 - ELASTIC IP ADDRESSES
# ================================================================
#
# NAT gateways may have Elastic IPs.
#
# Release only EIPs that are NOT currently associated.
# ================================================================

function Remove-UnassociatedElasticIps {

    Write-Section "10 - ELASTIC IP CLEANUP"

    $data = Invoke-AwsJson -Arguments @(
        "ec2"
        "describe-addresses"
    )

    if ($null -eq $data) {

        Write-Info "No Elastic IPs found."

        return
    }

    foreach ($address in $data.Addresses) {

        $allocationId = $address.AllocationId
        $publicIp = $address.PublicIp
        $associationId = $address.AssociationId

        if ($associationId) {

            Write-Info "EIP still associated: $publicIp"

            continue
        }

        Write-Info "Unassociated EIP: $publicIp"

        if (-not $Execute) {

            Write-WarningMessage "PREVIEW: Would release EIP $publicIp"

            continue
        }

        if ($allocationId) {

            Invoke-AwsCli -Arguments @(
                "ec2"
                "release-address"
                "--allocation-id"
                $allocationId
            ) | Out-Null

            if ($LASTEXITCODE -eq 0) {

                Write-Success "EIP released: $publicIp"
            }
            else {

                Write-Failure "EIP release failed: $publicIp"
            }
        }
    }
}

# ================================================================
# 11 - INTERNET GATEWAYS
# ================================================================

function Remove-InternetGateways {

    Write-Section "11 - INTERNET GATEWAY CLEANUP"

    $data = Invoke-AwsJson -Arguments @(
        "ec2"
        "describe-internet-gateways"
    )

    if ($null -eq $data) {

        Write-Info "No Internet Gateways found."

        return
    }

    foreach ($igw in $data.InternetGateways) {

        $igwId = $igw.InternetGatewayId

        Write-Info "Internet Gateway: $igwId"

        if (-not $Execute) {

            Write-WarningMessage "PREVIEW: Would detach/delete IGW $igwId"

            continue
        }

        foreach ($attachment in $igw.Attachments) {

            if ($attachment.VpcId) {

                Write-Info "Detaching $igwId from VPC $($attachment.VpcId)"

                Invoke-AwsCli -Arguments @(
                    "ec2"
                    "detach-internet-gateway"
                    "--internet-gateway-id"
                    $igwId
                    "--vpc-id"
                    $attachment.VpcId
                ) | Out-Null
            }
        }

        Invoke-AwsCli -Arguments @(
            "ec2"
            "delete-internet-gateway"
            "--internet-gateway-id"
            $igwId
        ) | Out-Null

        if ($LASTEXITCODE -eq 0) {

            Write-Success "Internet Gateway deleted: $igwId"
        }
        else {

            Write-Failure "Internet Gateway deletion failed: $igwId"
        }
    }
}

# ================================================================
# 12 - ROUTE TABLES
# ================================================================

function Remove-RouteTables {

    Write-Section "12 - ROUTE TABLE CLEANUP"

    $data = Invoke-AwsJson -Arguments @(
        "ec2"
        "describe-route-tables"
    )

    if ($null -eq $data) {

        Write-Info "No route tables found."

        return
    }

    foreach ($rt in $data.RouteTables) {

        $routeTableId = $rt.RouteTableId

        # --------------------------------------------------------
        # Main route tables cannot be deleted.
        # They disappear automatically when their VPC disappears.
        # --------------------------------------------------------

        $isMain = $false

        foreach ($association in $rt.Associations) {

            if ($association.Main -eq $true) {

                $isMain = $true
            }
        }

        if ($isMain) {

            Write-Info "Skipping main route table: $routeTableId"

            continue
        }

        Write-Info "Route table: $routeTableId"

        if (-not $Execute) {

            Write-WarningMessage "PREVIEW: Would delete route table $routeTableId"

            continue
        }

        # --------------------------------------------------------
        # Delete explicit route-table associations.
        # --------------------------------------------------------

        foreach ($association in $rt.Associations) {

            if ($association.RouteTableAssociationId) {

                Invoke-AwsCli -Arguments @(
                    "ec2"
                    "disassociate-route-table"
                    "--association-id"
                    $association.RouteTableAssociationId
                ) | Out-Null
            }
        }

        Invoke-AwsCli -Arguments @(
            "ec2"
            "delete-route-table"
            "--route-table-id"
            $routeTableId
        ) | Out-Null

        if ($LASTEXITCODE -eq 0) {

            Write-Success "Route table deleted: $routeTableId"
        }
        else {

            Write-WarningMessage "Route table could not be deleted: $routeTableId"
        }
    }
}

# ================================================================
# 13 - NETWORK INTERFACES
# ================================================================
#
# Some ENIs are AWS-managed and cannot be manually deleted.
#
# We attempt deletion only where AWS permits it.
# ================================================================

function Remove-NetworkInterfaces {

    Write-Section "13 - NETWORK INTERFACE CLEANUP"

    $data = Invoke-AwsJson -Arguments @(
        "ec2"
        "describe-network-interfaces"
    )

    if ($null -eq $data) {

        Write-Info "No network interfaces found."

        return
    }

    foreach ($eni in $data.NetworkInterfaces) {

        $eniId = $eni.NetworkInterfaceId
        $status = $eni.Status
        $description = $eni.Description

        Write-Info "ENI: $eniId"
        Write-Info "Status: $status"
        Write-Info "Description: $description"

        # --------------------------------------------------------
        # Only available ENIs can normally be deleted manually.
        # In-use AWS-managed ENIs must be removed by deleting the
        # service that owns them.
        # --------------------------------------------------------

        if ($status -ne "available") {

            Write-WarningMessage "Skipping ENI because it is in use: $eniId"

            continue
        }

        if (-not $Execute) {

            Write-WarningMessage "PREVIEW: Would delete available ENI $eniId"

            continue
        }

        Invoke-AwsCli -Arguments @(
            "ec2"
            "delete-network-interface"
            "--network-interface-id"
            $eniId
        ) | Out-Null

        if ($LASTEXITCODE -eq 0) {

            Write-Success "ENI deleted: $eniId"
        }
        else {

            Write-WarningMessage "Could not delete ENI: $eniId"
        }
    }
}

# ================================================================
# 14 - SUBNETS
# ================================================================

function Remove-Subnets {

    Write-Section "14 - SUBNET CLEANUP"

    $data = Invoke-AwsJson -Arguments @(
        "ec2"
        "describe-subnets"
    )

    if ($null -eq $data) {

        Write-Info "No subnets found."

        return
    }

    foreach ($subnet in $data.Subnets) {

        $subnetId = $subnet.SubnetId

        Write-Info "Subnet: $subnetId"

        if (-not $Execute) {

            Write-WarningMessage "PREVIEW: Would delete subnet $subnetId"

            continue
        }

        Invoke-AwsCli -Arguments @(
            "ec2"
            "delete-subnet"
            "--subnet-id"
            $subnetId
        ) | Out-Null

        if ($LASTEXITCODE -eq 0) {

            Write-Success "Subnet deleted: $subnetId"
        }
        else {

            Write-WarningMessage "Subnet could not be deleted: $subnetId"
        }
    }
}

# ================================================================
# 15 - SECURITY GROUPS
# ================================================================

function Remove-SecurityGroups {

    Write-Section "15 - SECURITY GROUP CLEANUP"

    $data = Invoke-AwsJson -Arguments @(
        "ec2"
        "describe-security-groups"
    )

    if ($null -eq $data) {

        Write-Info "No security groups found."

        return
    }

    foreach ($sg in $data.SecurityGroups) {

        $groupId = $sg.GroupId
        $groupName = $sg.GroupName
        $vpcId = $sg.VpcId

        # --------------------------------------------------------
        # Default security groups cannot be deleted.
        # They disappear with their VPC.
        # --------------------------------------------------------

        if ($groupName -eq "default") {

            Write-Info "Skipping default security group: $groupId"

            continue
        }

        Write-Info "Security Group: $groupName ($groupId)"

        if (-not $Execute) {

            Write-WarningMessage "PREVIEW: Would delete security group $groupId"

            continue
        }

        Invoke-AwsCli -Arguments @(
            "ec2"
            "delete-security-group"
            "--group-id"
            $groupId
        ) | Out-Null

        if ($LASTEXITCODE -eq 0) {

            Write-Success "Security group deleted: $groupId"
        }
        else {

            Write-WarningMessage "Security group could not be deleted: $groupId"
        }
    }
}

# ================================================================
# 16 - VPCS
# ================================================================

function Remove-Vpcs {

    Write-Section "16 - VPC CLEANUP"

    $data = Invoke-AwsJson -Arguments @(
        "ec2"
        "describe-vpcs"
    )

    if ($null -eq $data) {

        Write-Info "No VPCs found."

        return
    }

    foreach ($vpc in $data.Vpcs) {

        $vpcId = $vpc.VpcId
        $isDefault = $vpc.IsDefault

        Write-Info "VPC: $vpcId"

        if ($isDefault -and -not $DeleteDefaultVpc) {

            Write-WarningMessage "Skipping DEFAULT VPC: $vpcId"
            Write-WarningMessage "Use -DeleteDefaultVpc if you intentionally want to delete it."

            continue
        }

        if (-not $Execute) {

            Write-WarningMessage "PREVIEW: Would delete VPC $vpcId"

            continue
        }

        Invoke-AwsCli -Arguments @(
            "ec2"
            "delete-vpc"
            "--vpc-id"
            $vpcId
        ) | Out-Null

        if ($LASTEXITCODE -eq 0) {

            Write-Success "VPC deleted: $vpcId"
        }
        else {

            Write-Failure "VPC deletion failed: $vpcId"
            Write-WarningMessage "There may still be a dependency attached to this VPC."
        }
    }
}

# ================================================================
# MAIN EXECUTION
# ================================================================

Write-Host ""
Write-Host "################################################################" -ForegroundColor Red
Write-Host "#              AWS COMPLETE CLEANUP SCRIPT                    #" -ForegroundColor Red
Write-Host "################################################################" -ForegroundColor Red
Write-Host ""

Write-Info "AWS Region: $Region"

if ($Execute) {

    Write-WarningMessage "MODE: DESTRUCTIVE EXECUTION"
}
else {

    Write-WarningMessage "MODE: PREVIEW ONLY"
}

Write-Host ""

# ---------------------------------------------------------------
# Confirm execution mode.
# ---------------------------------------------------------------

Confirm-Execution

# ---------------------------------------------------------------
# Validate AWS CLI and credentials.
# ---------------------------------------------------------------

Test-AwsCli

# ================================================================
# RESOURCE DELETION ORDER
# ================================================================
#
# The order is extremely important.
#
# Application resources
#       ↓
# Network endpoints
#       ↓
# NAT
#       ↓
# Internet Gateway
#       ↓
# ENIs
#       ↓
# Route tables
#       ↓
# Subnets
#       ↓
# Security groups
#       ↓
# VPC
#
# ================================================================

Remove-CloudFront

Remove-S3

Remove-Ecs

Remove-Ecr

Remove-Rds

Remove-Secrets

Remove-VpcEndpoints

Remove-NatGateways

Remove-UnassociatedElasticIps

Remove-InternetGateways

Remove-NetworkInterfaces

Remove-RouteTables

Remove-Subnets

Remove-SecurityGroups

Remove-Vpcs

# ================================================================
# FINAL MESSAGE
# ================================================================

Write-Section "17 - CLEANUP COMPLETE"

if ($Execute) {

    Write-Success "Cleanup process finished."

    Write-Host ""
    Write-Info "Some AWS resources may still be deleting asynchronously."
    Write-Info "Run the script again if dependencies remain."
    Write-Info "This is especially common with RDS, NAT gateways and CloudFront."
}
else {

    Write-WarningMessage "Preview finished."
    Write-WarningMessage "Nothing was deleted."
    Write-Host ""
    Write-Info "To actually delete resources run:"
    Write-Host ""
    Write-Host ".\aws-full-cleanup.ps1 -Region $Region -Execute" -ForegroundColor Yellow
}

Write-Host ""
