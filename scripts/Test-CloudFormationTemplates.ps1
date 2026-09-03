#requires -Version 5.1

<#
.SYNOPSIS
    Complete local CloudFormation validation and troubleshooting script.

.DESCRIPTION
    Test-CloudFormationTemplates.ps1 validates AWS CloudFormation templates
    locally from Windows PowerShell and creates a complete diagnostic report.

    The script performs:

      1. AWS CLI availability check
      2. AWS identity check
      3. AWS region check
      4. cfn-lint availability check
      5. CloudFormation validation of every YAML template
      6. cfn-lint validation of every YAML template
      7. main.yaml structural/reference checks
      8. ECS/ECR template checks
      9. S3/CloudFront template checks
     10. Nested-stack reference checks
     11. TemplateURL checks
     12. Condition checks
     13. DependsOn checks
     14. Ref/GetAtt checks
     15. Existing CloudFormation stack checks
     16. Failed CloudFormation event checks
     17. Nested-stack inspection
     18. Complete timestamped report generation

.NOTES
    Recommended location:

    CloudFormation-DevOps-Lab\
      infrastructure\
        aws-cloudformation\
          templates\
            Test-CloudFormationTemplates.ps1

    Run this script from the templates directory.

    IMPORTANT:
    This script DOES NOT create, update, or delete CloudFormation stacks.
    It is a validation and diagnostic script only.

.EXAMPLE
    .\Test-CloudFormationTemplates.ps1

.EXAMPLE
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
    .\Test-CloudFormationTemplates.ps1
#>

# ============================================================
# CONFIGURATION
# ============================================================

$ErrorActionPreference = "Continue"

# Directory containing this script.
# This allows the script to work correctly even if launched
# from another PowerShell directory.
$TemplateDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

# Report directory.
$ReportDirectory = Join-Path $TemplateDirectory "validation-reports"

# Create report directory if it does not exist.
if (-not (Test-Path $ReportDirectory)) {
    New-Item -ItemType Directory -Path $ReportDirectory -Force | Out-Null
}

# Create timestamp for report filename.
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$ReportFile = Join-Path `
    $ReportDirectory `
    "CloudFormation-Validation-Report-$Timestamp.txt"

# Main template name.
$MainTemplate = Join-Path $TemplateDirectory "main.yaml"

# ECS/ECR template.
$EcsEcrTemplate = Join-Path $TemplateDirectory "aws-ecs-ecr.yaml"

# S3 + CloudFront template.
$CloudFrontTemplate = Join-Path `
    $TemplateDirectory `
    "s3-website-cloudfront.yaml"


# ============================================================
# REPORT INITIALIZATION
# ============================================================

$ReportLines = New-Object System.Collections.Generic.List[string]

function Write-Report {
    param(
        [string]$Message = ""
    )

    $ReportLines.Add($Message)
}

function Write-Section {
    param(
        [string]$Title
    )

    $Line = "=" * 78

    Write-Host ""
    Write-Host $Line -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host $Line -ForegroundColor Cyan

    Write-Report ""
    Write-Report $Line
    Write-Report $Title
    Write-Report $Line
}

function Write-Info {
    param(
        [string]$Message
    )

    Write-Host "[INFO] $Message" -ForegroundColor White
    Write-Report "[INFO] $Message"
}

function Write-Pass {
    param(
        [string]$Message
    )

    Write-Host "[PASS] $Message" -ForegroundColor Green
    Write-Report "[PASS] $Message"
}

function Write-Warn {
    param(
        [string]$Message
    )

    Write-Host "[WARN] $Message" -ForegroundColor Yellow
    Write-Report "[WARN] $Message"
}

function Write-Fail {
    param(
        [string]$Message
    )

    Write-Host "[FAIL] $Message" -ForegroundColor Red
    Write-Report "[FAIL] $Message"
}

function Write-CommandOutput {
    param(
        [string[]]$Output
    )

    foreach ($Line in $Output) {
        Write-Host "    $Line"
        Write-Report "    $Line"
    }
}


# ============================================================
# REPORT HEADER
# ============================================================

Write-Section "AWS CLOUDFORMATION LOCAL VALIDATION REPORT"

Write-Report "Project:"
Write-Report "CloudFormation-DevOps-Lab"

Write-Report ""
Write-Report "Template Directory:"
Write-Report $TemplateDirectory

Write-Report ""
Write-Report "Report Generated:"
Write-Report (Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Write-Report ""
Write-Report "Purpose:"
Write-Report "Validate CloudFormation templates locally and diagnose"
Write-Report "possible reasons for ECS/ECR, S3, CloudFront or nested"
Write-Report "stack creation failures."

Write-Report ""
Write-Report "IMPORTANT:"
Write-Report "This script does NOT create, update, or delete AWS resources."


# ============================================================
# 1. VERIFY TEMPLATE DIRECTORY
# ============================================================

Write-Section "1. TEMPLATE DIRECTORY CHECK"

Write-Info "Checking template directory..."

if (Test-Path $TemplateDirectory) {

    Write-Pass "Template directory exists:"
    Write-Info $TemplateDirectory

}
else {

    Write-Fail "Template directory does not exist."
}


# ============================================================
# 2. LIST YAML TEMPLATES
# ============================================================

Write-Section "2. CLOUDFORMATION YAML FILES"

$YamlFiles = Get-ChildItem `
    -Path $TemplateDirectory `
    -Filter "*.yaml" `
    -File `
    -ErrorAction SilentlyContinue

if ($YamlFiles.Count -eq 0) {

    Write-Fail "No YAML templates were found."

}
else {

    Write-Pass "$($YamlFiles.Count) YAML template(s) found."

    foreach ($File in $YamlFiles) {
        Write-Info $File.Name
    }
}


# ============================================================
# 3. AWS CLI CHECK
# ============================================================

Write-Section "3. AWS CLI CHECK"

$AwsCommand = Get-Command aws -ErrorAction SilentlyContinue

if ($null -eq $AwsCommand) {

    Write-Fail "AWS CLI is not installed or is not available in PATH."

}
else {

    Write-Pass "AWS CLI found."

    $AwsVersion = aws --version 2>&1

    Write-CommandOutput @(
        "$AwsVersion"
    )
}


# ============================================================
# 4. AWS IDENTITY
# ============================================================

Write-Section "4. AWS ACCOUNT / IDENTITY CHECK"

if ($null -ne $AwsCommand) {

    $IdentityOutput = aws sts get-caller-identity 2>&1

    if ($LASTEXITCODE -eq 0) {

        Write-Pass "AWS authentication is working."

        Write-CommandOutput $IdentityOutput

    }
    else {

        Write-Fail "AWS authentication failed."

        Write-CommandOutput $IdentityOutput
    }
}
else {

    Write-Warn "Skipped because AWS CLI is unavailable."
}


# ============================================================
# 5. AWS REGION
# ============================================================

Write-Section "5. AWS REGION CHECK"

if ($null -ne $AwsCommand) {

    $Region = aws configure get region 2>&1

    if ([string]::IsNullOrWhiteSpace(($Region | Out-String))) {

        Write-Warn "No default AWS CLI region is configured."

    }
    else {

        Write-Pass "Configured AWS region:"
        Write-CommandOutput $Region
    }
}
else {

    Write-Warn "Skipped because AWS CLI is unavailable."
}


# ============================================================
# 6. CFN-LINT CHECK
# ============================================================

Write-Section "6. CFN-LINT CHECK"

$CfnLintCommand = Get-Command cfn-lint -ErrorAction SilentlyContinue

if ($null -eq $CfnLintCommand) {

    Write-Warn "cfn-lint is not installed or is not available in PATH."

    Write-Info "Install it with:"
    Write-Info "py -m pip install cfn-lint"

}
else {

    Write-Pass "cfn-lint found."

    $CfnLintVersion = cfn-lint --version 2>&1

    Write-CommandOutput @(
        "$CfnLintVersion"
    )
}


# ============================================================
# 7. AWS CLOUDFORMATION VALIDATE-TEMPLATE
# ============================================================

Write-Section "7. AWS CLOUDFORMATION TEMPLATE VALIDATION"

if ($null -eq $AwsCommand) {

    Write-Warn "AWS CLI unavailable. Skipping AWS validation."

}
else {

    foreach ($File in $YamlFiles) {

        Write-Host ""
        Write-Host "Testing: $($File.Name)" -ForegroundColor Yellow

        Write-Report ""
        Write-Report "Testing: $($File.Name)"

        $Output = aws cloudformation validate-template `
            --template-body "file://$($File.FullName)" 2>&1

        if ($LASTEXITCODE -eq 0) {

            Write-Pass "AWS CloudFormation validation passed."

            Write-CommandOutput $Output

        }
        else {

            Write-Fail "AWS CloudFormation validation FAILED."

            Write-CommandOutput $Output
        }
    }
}


# ============================================================
# 8. CFN-LINT VALIDATION
# ============================================================

Write-Section "8. CFN-LINT VALIDATION"

if ($null -eq $CfnLintCommand) {

    Write-Warn "cfn-lint unavailable. Skipping lint validation."

}
else {

    foreach ($File in $YamlFiles) {

        Write-Host ""
        Write-Host "Linting: $($File.Name)" -ForegroundColor Yellow

        Write-Report ""
        Write-Report "Linting: $($File.Name)"

        $LintOutput = cfn-lint `
            "$($File.FullName)" 2>&1

        if ($LASTEXITCODE -eq 0) {

            Write-Pass "cfn-lint passed."

        }
        else {

            Write-Fail "cfn-lint found one or more issues."

        }

        if ($LintOutput) {
            Write-CommandOutput $LintOutput
        }
    }
}


# ============================================================
# 9. MAIN.YAML EXISTENCE CHECK
# ============================================================

Write-Section "9. MAIN.YAML CHECK"

if (Test-Path $MainTemplate) {

    Write-Pass "main.yaml exists."

}
else {

    Write-Fail "main.yaml was not found."
}


# ============================================================
# 10. ECS/ECR TEMPLATE CHECK
# ============================================================

Write-Section "10. ECS/ECR TEMPLATE CHECK"

if (Test-Path $EcsEcrTemplate) {

    Write-Pass "aws-ecs-ecr.yaml exists."

    $EcsContent = Get-Content `
        -Path $EcsEcrTemplate `
        -Raw

    Write-Info "Searching for ECR resources..."

    if ($EcsContent -match "AWS::ECR::") {

        Write-Pass "ECR resource definitions detected."

    }
    else {

        Write-Warn "No AWS::ECR resources detected."
    }

    Write-Info "Searching for ECS resources..."

    if ($EcsContent -match "AWS::ECS::") {

        Write-Pass "ECS resource definitions detected."

    }
    else {

        Write-Warn "No AWS::ECS resources detected."
    }

}
else {

    Write-Fail "aws-ecs-ecr.yaml was not found."
}


# ============================================================
# 11. S3 / CLOUDFRONT TEMPLATE CHECK
# ============================================================

Write-Section "11. S3 / CLOUDFRONT TEMPLATE CHECK"

if (Test-Path $CloudFrontTemplate) {

    Write-Pass "s3-website-cloudfront.yaml exists."

    $CloudFrontContent = Get-Content `
        -Path $CloudFrontTemplate `
        -Raw

    Write-Info "Searching for S3 resources..."

    if ($CloudFrontContent -match "AWS::S3::") {

        Write-Pass "S3 resource definitions detected."

    }
    else {

        Write-Warn "No AWS::S3 resources detected."
    }

    Write-Info "Searching for CloudFront resources..."

    if ($CloudFrontContent -match "AWS::CloudFront::") {

        Write-Pass "CloudFront resource definitions detected."

    }
    else {

        Write-Warn "No AWS::CloudFront resources detected."
    }

}
else {

    Write-Fail "s3-website-cloudfront.yaml was not found."
}


# ============================================================
# 12. MAIN.YAML NESTED STACK CHECK
# ============================================================

Write-Section "12. MAIN.YAML NESTED STACK CHECK"

if (Test-Path $MainTemplate) {

    Write-Info "Searching for AWS::CloudFormation::Stack..."

    $NestedStackMatches = Select-String `
        -Path $MainTemplate `
        -Pattern "AWS::CloudFormation::Stack"

    if ($NestedStackMatches) {

        Write-Pass "Nested stack resources detected."

        foreach ($Match in $NestedStackMatches) {

            Write-CommandOutput @(
                "Line $($Match.LineNumber): $($Match.Line.Trim())"
            )
        }

    }
    else {

        Write-Warn "No nested stack resource definitions detected."
    }
}


# ============================================================
# 13. TEMPLATEURL CHECK
# ============================================================

Write-Section "13. TEMPLATEURL CHECK"

if (Test-Path $MainTemplate) {

    $TemplateUrlMatches = Select-String `
        -Path $MainTemplate `
        -Pattern "TemplateURL"

    if ($TemplateUrlMatches) {

        Write-Pass "TemplateURL references found."

        foreach ($Match in $TemplateUrlMatches) {

            Write-CommandOutput @(
                "Line $($Match.LineNumber): $($Match.Line.Trim())"
            )
        }

    }
    else {

        Write-Warn "No TemplateURL references found."
    }
}


# ============================================================
# 14. ECS/ECR REFERENCES IN MAIN.YAML
# ============================================================

Write-Section "14. ECS/ECR REFERENCES IN MAIN.YAML"

if (Test-Path $MainTemplate) {

    $EcsMatches = Select-String `
        -Path $MainTemplate `
        -Pattern "Ecs|ECS|Ecr|ECR"

    if ($EcsMatches) {

        Write-Pass "ECS/ECR references found in main.yaml."

        foreach ($Match in $EcsMatches) {

            Write-CommandOutput @(
                "Line $($Match.LineNumber): $($Match.Line.Trim())"
            )
        }

    }
    else {

        Write-Warn "No ECS/ECR references found in main.yaml."
    }
}


# ============================================================
# 15. S3 / CLOUDFRONT REFERENCES IN MAIN.YAML
# ============================================================

Write-Section "15. S3/CLOUDFRONT REFERENCES IN MAIN.YAML"

if (Test-Path $MainTemplate) {

    $S3CloudFrontMatches = Select-String `
        -Path $MainTemplate `
        -Pattern "S3|s3|CloudFront|cloudfront"

    if ($S3CloudFrontMatches) {

        Write-Pass "S3/CloudFront references found."

        foreach ($Match in $S3CloudFrontMatches) {

            Write-CommandOutput @(
                "Line $($Match.LineNumber): $($Match.Line.Trim())"
            )
        }

    }
    else {

        Write-Warn "No S3/CloudFront references found."
    }
}


# ============================================================
# 16. CONDITIONS CHECK
# ============================================================

Write-Section "16. CLOUDFORMATION CONDITIONS CHECK"

if (Test-Path $MainTemplate) {

    $ConditionMatches = Select-String `
        -Path $MainTemplate `
        -Pattern "Conditions:|Condition:"

    if ($ConditionMatches) {

        Write-Warn "Conditions detected. Review whether ECS/ECR is being skipped."

        foreach ($Match in $ConditionMatches) {

            Write-CommandOutput @(
                "Line $($Match.LineNumber): $($Match.Line.Trim())"
            )
        }

    }
    else {

        Write-Info "No CloudFormation Conditions detected."
    }
}


# ============================================================
# 17. DEPENDSON CHECK
# ============================================================

Write-Section "17. DEPENDSON CHECK"

if (Test-Path $MainTemplate) {

    $DependsMatches = Select-String `
        -Path $MainTemplate `
        -Pattern "DependsOn"

    if ($DependsMatches) {

        Write-Warn "DependsOn references detected."

        foreach ($Match in $DependsMatches) {

            Write-CommandOutput @(
                "Line $($Match.LineNumber): $($Match.Line.Trim())"
            )
        }

    }
    else {

        Write-Info "No DependsOn references detected."
    }
}


# ============================================================
# 18. REF CHECK
# ============================================================

Write-Section "18. REF REFERENCES CHECK"

if (Test-Path $MainTemplate) {

    $RefMatches = Select-String `
        -Path $MainTemplate `
        -Pattern "!Ref"

    if ($RefMatches) {

        Write-Info "Ref references found."

        foreach ($Match in $RefMatches) {

            Write-CommandOutput @(
                "Line $($Match.LineNumber): $($Match.Line.Trim())"
            )
        }

    }
    else {

        Write-Info "No !Ref references found."
    }
}


# ============================================================
# 19. GETATT CHECK
# ============================================================

Write-Section "19. GETATT REFERENCES CHECK"

if (Test-Path $MainTemplate) {

    $GetAttMatches = Select-String `
        -Path $MainTemplate `
        -Pattern "!GetAtt"

    if ($GetAttMatches) {

        Write-Info "GetAtt references found."

        foreach ($Match in $GetAttMatches) {

            Write-CommandOutput @(
                "Line $($Match.LineNumber): $($Match.Line.Trim())"
            )
        }

    }
    else {

        Write-Info "No !GetAtt references found."
    }
}


# ============================================================
# 20. OUTPUTS CHECK
# ============================================================

Write-Section "20. OUTPUTS CHECK"

foreach ($File in $YamlFiles) {

    $OutputMatches = Select-String `
        -Path $File.FullName `
        -Pattern "^Outputs:"

    if ($OutputMatches) {

        Write-Info "$($File.Name) contains Outputs."

        foreach ($Match in $OutputMatches) {

            Write-CommandOutput @(
                "Line $($Match.LineNumber): $($Match.Line.Trim())"
            )
        }
    }
}


# ============================================================
# 21. AWS CLOUDFORMATION STACK LIST
# ============================================================

Write-Section "21. EXISTING CLOUDFORMATION STACKS"

if ($null -ne $AwsCommand) {

    $Stacks = aws cloudformation list-stacks `
        --query "StackSummaries[].{Name:StackName,Status:StackStatus,Updated:LastUpdatedTime}" `
        --output table 2>&1

    if ($LASTEXITCODE -eq 0) {

        Write-Pass "CloudFormation stack query succeeded."

        Write-CommandOutput $Stacks

    }
    else {

        Write-Fail "Unable to retrieve CloudFormation stacks."

        Write-CommandOutput $Stacks
    }
}
else {

    Write-Warn "Skipped because AWS CLI is unavailable."
}


# ============================================================
# 22. DETECT POSSIBLE MAIN STACK
# ============================================================

Write-Section "22. CLOUDFORMATION STACK IDENTIFICATION"

$StackName = $null

if ($null -ne $AwsCommand) {

    $StackNames = aws cloudformation list-stacks `
        --query "StackSummaries[].StackName" `
        --output text 2>&1

    if ($LASTEXITCODE -eq 0 -and $StackNames) {

        Write-Info "Available CloudFormation stacks:"

        foreach ($Name in ($StackNames -split "`t|`r|`n")) {

            if (-not [string]::IsNullOrWhiteSpace($Name)) {

                Write-CommandOutput @(
                    $Name
                )
            }
        }

        # Try to automatically identify a likely project stack.
        $PossibleStack = $StackNames `
            -split "`t|`r|`n" |
            Where-Object {
                $_ -match "CloudFormation|DevOps|Charlie|Cafe"
            } |
            Select-Object -First 1

        if ($PossibleStack) {

            $StackName = $PossibleStack

            Write-Pass "Possible project stack detected:"
            Write-Info $StackName

        }
        else {

            Write-Warn "Could not automatically identify the project stack."
            Write-Info "Set `$StackName manually in this script if required."
        }
    }
}


# ============================================================
# 23. MAIN STACK EVENTS
# ============================================================

Write-Section "23. CLOUDFORMATION STACK EVENTS"

if ($StackName) {

    Write-Info "Checking stack events for:"
    Write-Info $StackName

    $Events = aws cloudformation describe-stack-events `
        --stack-name $StackName `
        --query "StackEvents[].{Time:Timestamp,LogicalId:LogicalResourceId,Status:ResourceStatus,Reason:ResourceStatusReason}" `
        --output table 2>&1

    if ($LASTEXITCODE -eq 0) {

        Write-Pass "Stack events retrieved."

        Write-CommandOutput $Events

    }
    else {

        Write-Fail "Unable to retrieve stack events."

        Write-CommandOutput $Events
    }

}
else {

    Write-Warn "No project stack identified. Stack event check skipped."
}


# ============================================================
# 24. FAILED CLOUDFORMATION EVENTS
# ============================================================

Write-Section "24. CLOUDFORMATION FAILED EVENTS"

if ($StackName) {

    $FailedEvents = aws cloudformation describe-stack-events `
        --stack-name $StackName `
        --query "StackEvents[?contains(ResourceStatus, 'FAILED')].[Timestamp,LogicalResourceId,ResourceStatus,ResourceStatusReason]" `
        --output table 2>&1

    if ($LASTEXITCODE -eq 0) {

        if ($FailedEvents) {

            Write-Fail "FAILED CloudFormation events detected."

            Write-CommandOutput $FailedEvents

        }
        else {

            Write-Pass "No FAILED CloudFormation events were returned."
        }

    }
    else {

        Write-Fail "Unable to retrieve failed events."

        Write-CommandOutput $FailedEvents
    }

}
else {

    Write-Warn "Skipped because no project stack was identified."
}


# ============================================================
# 25. STACK RESOURCE CHECK
# ============================================================

Write-Section "25. CLOUDFORMATION STACK RESOURCES"

if ($StackName) {

    $Resources = aws cloudformation list-stack-resources `
        --stack-name $StackName `
        --query "StackResourceSummaries[].{LogicalId:LogicalResourceId,PhysicalId:PhysicalResourceId,Type:ResourceType,Status:ResourceStatus}" `
        --output table 2>&1

    if ($LASTEXITCODE -eq 0) {

        Write-Pass "Stack resources retrieved."

        Write-CommandOutput $Resources

    }
    else {

        Write-Fail "Unable to retrieve stack resources."

        Write-CommandOutput $Resources
    }

}
else {

    Write-Warn "Skipped because no project stack was identified."
}


# ============================================================
# 26. NESTED STACK DISCOVERY
# ============================================================

Write-Section "26. NESTED STACK DISCOVERY"

if ($StackName) {

    $NestedStacks = aws cloudformation list-stack-resources `
        --stack-name $StackName `
        --query "StackResourceSummaries[?ResourceType=='AWS::CloudFormation::Stack'].[LogicalResourceId,PhysicalResourceId,ResourceStatus]" `
        --output table 2>&1

    if ($LASTEXITCODE -eq 0) {

        Write-Pass "Nested stack query completed."

        Write-CommandOutput $NestedStacks

    }
    else {

        Write-Fail "Unable to retrieve nested stacks."

        Write-CommandOutput $NestedStacks
    }

}
else {

    Write-Warn "Skipped because no project stack was identified."
}


# ============================================================
# 27. ECS/ECR NESTED STACK EVENTS
# ============================================================

Write-Section "27. ECS/ECR NESTED STACK DIAGNOSTICS"

if ($StackName) {

    $NestedStackData = aws cloudformation list-stack-resources `
        --stack-name $StackName `
        --query "StackResourceSummaries[?ResourceType=='AWS::CloudFormation::Stack'].[LogicalResourceId,PhysicalResourceId]" `
        --output text 2>&1

    if ($LASTEXITCODE -eq 0) {

        foreach ($NestedLine in ($NestedStackData -split "`r?`n")) {

            if ([string]::IsNullOrWhiteSpace($NestedLine)) {
                continue
            }

            $Parts = $NestedLine -split "`t"

            if ($Parts.Count -ge 2) {

                $LogicalId = $Parts[0]
                $PhysicalId = $Parts[1]

                # Only inspect nested stacks whose logical ID
                # appears related to ECS/ECR.
                if ($LogicalId -match "Ecs|ECS|Ecr|ECR") {

                    Write-Info "ECS/ECR nested stack detected:"
                    Write-Info $LogicalId

                    Write-Info "Nested stack physical ID:"
                    Write-Info $PhysicalId

                    $NestedEvents = aws cloudformation describe-stack-events `
                        --stack-name $PhysicalId `
                        --query "StackEvents[?contains(ResourceStatus, 'FAILED')].[Timestamp,LogicalResourceId,ResourceStatus,ResourceStatusReason]" `
                        --output table 2>&1

                    if ($LASTEXITCODE -eq 0) {

                        if ($NestedEvents) {

                            Write-Fail "ECS/ECR nested stack contains FAILED events."

                            Write-CommandOutput $NestedEvents

                        }
                        else {

                            Write-Pass "No FAILED events found in ECS/ECR nested stack."
                        }

                    }
                    else {

                        Write-Fail "Unable to inspect ECS/ECR nested stack."

                        Write-CommandOutput $NestedEvents
                    }
                }
            }
        }
    }
}


# ============================================================
# 28. SEARCH FOR COMMON CLOUDFORMATION PROBLEM PATTERNS
# ============================================================

Write-Section "28. COMMON CLOUDFORMATION PROBLEM PATTERN SEARCH"

foreach ($File in $YamlFiles) {

    Write-Info "Scanning $($File.Name)..."

    $Content = Get-Content `
        -Path $File.FullName `
        -Raw

    # Search for unresolved placeholder AMI values.
    if ($Content -match "ami-xxxxxxxx|ami-XXXX|YOUR_AMI|REPLACE_ME") {

        Write-Warn "$($File.Name) contains a possible AMI placeholder."
    }

    # Search for obvious placeholder values.
    if ($Content -match "YOUR_|CHANGE_ME|REPLACE_ME|PLACEHOLDER") {

        Write-Warn "$($File.Name) contains possible placeholder values."
    }

    # Search for empty TemplateURL.
    if ($Content -match "TemplateURL:\s*$") {

        Write-Warn "$($File.Name) contains an empty TemplateURL."
    }

    # Search for hardcoded account IDs.
    if ($Content -match "\b\d{12}\b") {

        Write-Info "$($File.Name) contains a 12-digit AWS account ID."
    }

    # Search for hardcoded regions.
    if ($Content -match "us-east-1|us-east-2|us-west-1|us-west-2|eu-west-1|ap-southeast-1|ap-south-1") {

        Write-Info "$($File.Name) contains a hardcoded AWS region."
    }
}


# ============================================================
# 29. FILE SIZE / BASIC FILE HEALTH
# ============================================================

Write-Section "29. TEMPLATE FILE HEALTH"

foreach ($File in $YamlFiles) {

    $SizeKB = [Math]::Round(
        ($File.Length / 1KB),
        2
    )

    Write-Info "$($File.Name) - $SizeKB KB"

    if ($File.Length -eq 0) {

        Write-Fail "$($File.Name) is EMPTY."
    }
}


# ============================================================
# 30. GIT STATUS
# ============================================================

Write-Section "30. GIT STATUS"

$GitCommand = Get-Command git -ErrorAction SilentlyContinue

if ($null -ne $GitCommand) {

    $GitRoot = git -C $TemplateDirectory rev-parse --show-toplevel 2>&1

    if ($LASTEXITCODE -eq 0) {

        Write-Pass "Git repository detected."

        Write-Info "Repository root:"
        Write-Info $GitRoot

        $GitStatus = git -C $GitRoot status --short 2>&1

        if ($GitStatus) {

            Write-Info "Git working tree changes:"
            Write-CommandOutput $GitStatus

        }
        else {

            Write-Pass "Git working tree is clean."
        }

    }
    else {

        Write-Info "Template directory is not inside a Git repository."
    }

}
else {

    Write-Info "Git is not installed or unavailable."
}


# ============================================================
# 31. FINAL DIAGNOSTIC SUMMARY
# ============================================================

Write-Section "31. FINAL DIAGNOSTIC SUMMARY"

Write-Info "Validation completed."

Write-Report ""
Write-Report "Recommended investigation order:"
Write-Report ""
Write-Report "1. Fix every cfn-lint ERROR."
Write-Report "2. Fix every AWS validate-template ERROR."
Write-Report "3. Verify main.yaml contains the ECS/ECR nested stack."
Write-Report "4. Verify the ECS/ECR TemplateURL."
Write-Report "5. Verify ECS/ECR logical IDs."
Write-Report "6. Verify Ref and GetAtt references."
Write-Report "7. Verify nested-stack Outputs."
Write-Report "8. Check Conditions that may skip ECS/ECR."
Write-Report "9. Check DependsOn relationships."
Write-Report "10. Check CloudFormation FAILED events."
Write-Report "11. Check the nested ECS/ECR stack FAILED events."
Write-Report "12. Check S3/CloudFront failures because they were recently added."

Write-Report ""
Write-Report "Important diagnostic note:"
Write-Report "AWS validate-template confirms template syntax/structure."
Write-Report "It does NOT guarantee successful resource creation."
Write-Report "CloudFormation stack events are required to identify"
Write-Report "runtime deployment failures."


# ============================================================
# 32. SAVE REPORT
# ============================================================

Write-Section "32. SAVE COMPLETE REPORT"

$ReportLines |
    Set-Content `
        -Path $ReportFile `
        -Encoding UTF8

if (Test-Path $ReportFile) {

    Write-Pass "Complete validation report saved."

    Write-Host ""
    Write-Host "REPORT FILE:" -ForegroundColor Cyan
    Write-Host $ReportFile -ForegroundColor Green

}
else {

    Write-Fail "Unable to save validation report."
}


# ============================================================
# 33. FINAL SCREEN MESSAGE
# ============================================================

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "CLOUDFORMATION VALIDATION FINISHED" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "Report:" -ForegroundColor Yellow
Write-Host $ReportFile -ForegroundColor Green

Write-Host ""
Write-Host "Next step:" -ForegroundColor Yellow
Write-Host "Open the report and look for [FAIL] and [WARN] entries." -ForegroundColor White

Write-Host ""
Write-Host "The script did NOT create, update, or delete AWS resources." -ForegroundColor Cyan

Write-Host ""