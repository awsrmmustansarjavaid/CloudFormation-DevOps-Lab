# From Manual AWS Deployments to Infrastructure as Code: Building My First AWS DevOps Automation Lab with CloudFormation, Docker & GitHub

**Raja Muhammad Mustansar Javaid**
Cloud Engineer at Upwork

*August 4, 2026*

Every cloud engineer reaches a point where manually creating AWS resources through the Management Console is no longer enough. I wanted to understand how modern DevOps teams automate infrastructure, manage source code, and build repeatable deployment workflows. To achieve that, I started building my own AWS DevOps Automation Lab from scratch.

This project focuses on Infrastructure as Code (IaC) using AWS CloudFormation while integrating GitHub for version control, Docker for creating a consistent development environment, and Bash scripting for automation. Rather than simply following tutorials, I wanted to build each component myself, understand how everything works together, troubleshoot real-world issues, and document the complete process as a learning resource for both myself and other beginners.

Throughout this lab, I provisioned AWS infrastructure including a VPC, public and private subnets, Internet Gateway, route tables, security groups, Amazon EC2, Amazon RDS, and Amazon S3. I also automated common CloudFormation operations such as template validation, stack creation, deletion, and AWS CLI configuration through reusable Bash scripts, making deployments faster, more consistent, and less error-prone.

## Files You Still Need

Your `scripts/` folder is empty.

Create these files.

**scripts/**

- `git-commit-push.sh`
- `build-docker.sh`
- `run-container.sh`
- `validate-template.sh`
- `create-stack.sh`
- `delete-stack.sh`
- `cleanup-docker.sh`
- `aws-config.sh`

## Automating AWS CLI Configuration with a Simple Bash Script - A Small Step Toward DevOps Efficiency

Since you're on Windows 10, you can run this script using Git Bash, WSL (Ubuntu), or another Bash environment.

### aws-config.sh

**Step 2: Paste this script**

```bash
#!/bin/bash

# ==========================================================
# Script Name : aws-config.sh
# Description : Configure AWS CLI using stored credentials
# ==========================================================

# ----------------------------------------------------------
# AWS Credentials
# Replace the values below with your own credentials.
# ----------------------------------------------------------
AWS_ACCESS_KEY_ID="YOUR_AWS_ACCESS_KEY_ID"
AWS_SECRET_ACCESS_KEY="YOUR_AWS_SECRET_ACCESS_KEY"
AWS_REGION="ap-south-2"
AWS_OUTPUT_FORMAT="json"

echo "==============================================="
echo "        AWS CLI Configuration Script"
echo "==============================================="
echo

echo "Configuring AWS CLI..."
echo

# Configure AWS CLI
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set region "$AWS_REGION"
aws configure set output "$AWS_OUTPUT_FORMAT"

echo
echo "==============================================="
echo " AWS CLI Configuration Completed Successfully"
echo "==============================================="
echo

echo "Configuration Summary"
echo "------------------------------"
echo "Access Key ID : $AWS_ACCESS_KEY_ID"
echo "Secret Key    : ***************"
echo "Region        : $AWS_REGION"
echo "Output Format : $AWS_OUTPUT_FORMAT"
echo

echo "Running AWS CLI Authentication Test..."
echo

aws sts get-caller-identity

STATUS=$?

echo

if [ $STATUS -eq 0 ]; then
    echo "==============================================="
    echo "AWS CLI authentication was successful."
    echo "==============================================="
else
    echo "==============================================="
    echo "AWS CLI authentication failed."
    echo "Please verify your credentials."
    echo "==============================================="
fi
```

**Example execution**

```
===============================================
        AWS CLI Configuration Script
===============================================

AWS Access Key ID: AKIA********************
AWS Secret Access Key:
Default Region [ap-south-2]:
Output Format [json]:

Configuring AWS CLI...

===============================================
 AWS CLI Configuration Completed Successfully
===============================================

Configuration Summary
------------------------------
Access Key ID : AKIA********************
Secret Key    : ***************
Region        : ap-south-2
Output Format : json

Running AWS CLI Authentication Test...

{
    "UserId": "AIDAXXXXXXXXXXXXX",
    "Account": "537236558357",
    "Arn": "arn:aws:iam::537236558357:user/github-ci-cd-user"
}

✅ AWS CLI authentication was successful.
```

## Automate deletion with a Bash script

Create a file named:

### delete-stack.sh

Add the following:

```bash
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

### Running on Linux or macOS

Make it executable:

```bash
chmod +x delete-stack.sh
```

Run it:

```bash
./delete-stack.sh
```

### Running on Windows

If you're using Git Bash, WSL, or AWS CloudShell, you can run the same script.

**Run the Script**

Since your `bash.exe` is located at:

```
C:\Program Files\Git\bin\bash.exe
```

Run the script using:

**Option 1: Run the Script from the Script Directory**

Script Location

```
C:\Users\musta\Downloads\AWS-Labs\CloudFormation-DevOps-Lab\scripts\delete-stack.sh
```

Steps

Open PowerShell.
Change to the script directory:

```powershell
cd "C:\Users\musta\Downloads\AWS-Labs\CloudFormation-DevOps-Lab\scripts"
```

Run the script:

```powershell
& "C:\Program Files\Git\bin\bash.exe" "./delete-stack.sh"
```

**Option 2: Run the Script Using the Full File Path (No Need to Change Directory)**

Script Location

```
C:\Users\musta\Downloads\AWS-Labs\CloudFormation-DevOps-Lab\scripts\delete-stack.sh
```

Run Command

```powershell
& "C:\Program Files\Git\bin\bash.exe" "C:\Users\musta\Downloads\AWS-Labs\CloudFormation-DevOps-Lab\scripts\delete-stack.sh"
```

This method works from any PowerShell location, because it uses the script's full path.

If you're using PowerShell, it's better to use a PowerShell script instead.

Create:

### delete-stack.ps1

Contents:

```powershell
$StackName = "Lab01-CloudFormation"
$Region = "us-east-1"

Write-Host "Deleting CloudFormation stack..."

aws cloudformation delete-stack `
    --stack-name $StackName `
    --region $Region

Write-Host "Waiting for stack deletion..."

aws cloudformation wait stack-delete-complete `
    --stack-name $StackName `
    --region $Region

Write-Host "================================="
Write-Host "Stack deleted successfully!"
Write-Host "================================="
```

Run it:

```powershell
.\delete-stack.ps1
```

## Bash Script: Git Workflow - Updating Files in Your Local Repository

The following Bash script demonstrates the standard Git workflow for tracking, committing, and pushing changes to a GitHub repository. Each command is explained with comments, making it suitable for beginners learning Git and DevOps practices.

Create Bash Script File:

### git-commit-push.sh

```bash
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

### build-docker.sh

```bash
#!/bin/bash

docker compose build
```

### run-container.sh

```bash
#!/bin/bash

docker compose up
```

### validate-template.sh

```bash
#!/bin/bash

aws cloudformation validate-template \
--template-body file://templates/lab01.yaml
```

### create-stack.sh

```bash
#!/bin/bash

aws cloudformation create-stack \
--stack-name Lab01-CloudFormation \
--template-body file://templates/lab01.yaml \
--capabilities CAPABILITY_NAMED_IAM
```

`--capabilities CAPABILITY_NAMED_IAM` is not required for your current template, but adding it now won't hurt and is useful once you introduce IAM resources later.

### delete-stack.sh

```bash
#!/bin/bash

aws cloudformation delete-stack \
--stack-name Lab01-CloudFormation
```

### cleanup-docker.sh

```bash
#!/bin/bash

docker compose down

docker image prune -f
```

### verify-docker.sh

```bash
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

**Make it executable (Linux/macOS)**

```bash
chmod +x scripts/verify-docker.sh
```

On Windows with Git Bash, this step is optional.

**Run the script**

After starting your container:

```bash
docker compose up -d
```

Run:

```bash
./scripts/verify-docker.sh
```

or:

```bash
bash scripts/verify-docker.sh
```

**Expected output**

```
===========================================
 AWS DevOps CloudFormation Lab Verification
===========================================

Checking Docker container...
CONTAINER ID   IMAGE   STATUS
...

===========================================
Verifying installed tools...
===========================================

aws-cli/2.x.x

git version 2.xx.x

Python 3.xx.x

GNU bash, version 5.x.x

===========================================
Current Working Directory
===========================================

/workspace

===========================================
Project Files
===========================================

docker/
templates/
scripts/
README.md

===========================================
Verification Complete
===========================================
```

## Writing Production-Grade Bash Scripts: Lessons from an AWS DevOps Automation Lab

*Professional tips and tricks for hardening the scripts in your CloudFormation-DevOps-Lab project*

### 1. Security: Fix This Before Anything Else

Never hardcode AWS credentials in a script. `aws-config.sh` currently stores `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as plain text. If this file is committed to GitHub, the keys are compromised the moment it's pushed — even if you delete it later, it stays in Git history.

Use environment variables or a credentials file instead:

```bash
AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:?Set AWS_ACCESS_KEY_ID first}"
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:?Set AWS_SECRET_ACCESS_KEY first}"
```

Prefer IAM roles or AWS SSO over long-lived access keys whenever the environment supports it (EC2 instance roles, `aws sso login`, or `aws configure sso`).

Add a `.gitignore` entry for any file that might contain secrets (`*.env`, `aws-config.sh` if it holds real keys, `.aws/credentials`).

Mask secrets in output, as you already do for the secret key — apply the same masking to the access key ID in logs, not just the summary.

Consider AWS Secrets Manager or SSM Parameter Store for credentials once the lab grows beyond a personal learning project.

### 2. Defensive Scripting Habits

Start every script with strict mode:

```bash
set -euo pipefail
```

- `-e` exits on any command failure
- `-u` catches unset variables
- `-o pipefail` catches failures inside piped commands

This alone would have caught the missing line continuation in `create-stack.sh`.

Always quote your variables (`"$STACK_NAME"`, `"$REGION"`) to avoid word-splitting and globbing issues — you're already doing this well in `delete-stack.sh`.

Check exit codes explicitly where a silent failure would be costly, as you did with `STATUS=$?` in `aws-config.sh`. Apply the same pattern to `create-stack.sh` and `validate-template.sh`.

Validate before you deploy. `validate-template.sh` should run automatically inside `create-stack.sh` before the stack creation call, not just exist as a separate manual step.

### 3. Fix the Syntax Bug in create-stack.sh

Your script is missing a line-continuation backslash:

```bash
aws cloudformation create-stack \
  --stack-name Lab01-CloudFormation \
  --template-body file://templates/lab01.yaml \
  --capabilities CAPABILITY_NAMED_IAM
```

Without the trailing `\` after `lab01.yaml`, Bash treats `--capabilities CAPABILITY_NAMED_IAM` as a separate (invalid) command.

Lint your scripts automatically with ShellCheck — it catches exactly this class of error before you run the script:

```bash
shellcheck scripts/*.sh
```

### 4. Parameterize Instead of Hardcoding

`STACK_NAME` and `REGION` are hardcoded in both `create-stack.sh` and `delete-stack.sh`. Centralize them in one config file:

```bash
# scripts/config.sh
STACK_NAME="Lab01-CloudFormation"
REGION="us-east-1"
TEMPLATE_PATH="templates/lab01.yaml"
```

Then source it:

```bash
source "$(dirname "$0")/config.sh"
```

Accept command-line overrides for flexibility across environments:

```bash
STACK_NAME="${1:-Lab01-CloudFormation}"
```

Watch for region mismatches — `aws-config.sh` sets the default region to `ap-south-2`, while `create-stack.sh`/`delete-stack.sh` use `us-east-1`. Decide on one source of truth to avoid deploying to the wrong region.

### 5. Make Scripts Idempotent and Safer to Re-run

Check if a stack already exists before creating it, so re-running the script doesn't fail with a confusing `AlreadyExistsException`:

```bash
if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" &>/dev/null; then
  echo "Stack already exists. Updating instead..."
  aws cloudformation update-stack --stack-name "$STACK_NAME" ...
else
  aws cloudformation create-stack --stack-name "$STACK_NAME" ...
fi
```

Add `aws cloudformation wait stack-create-complete` to `create-stack.sh`, mirroring what you already do well in `delete-stack.sh` — this prevents the script from exiting before the stack is actually ready.

Wrap Docker cleanup in confirmations for anything destructive. `cleanup-docker.sh` runs `docker image prune -f`, which force-deletes images without asking — fine for a lab, risky as a habit to carry into production scripts.

### 6. Consistency and Readability

Standardize your header comment block across all scripts (you already do this nicely in `aws-config.sh` and `delete-stack.sh`) — apply the same format to `build-docker.sh`, `run-container.sh`, and `cleanup-docker.sh` for a professional, uniform look.

Use consistent echo formatting for section banners (`===...===`) — it's a small touch, but it makes script output easy to scan, especially useful when you chain scripts together in a CI/CD pipeline.

Name scripts by verb-noun convention consistently (`create-stack.sh`, `delete-stack.sh`, `validate-template.sh`) — you're already following this well; keep it going for future scripts (e.g., `update-stack.sh`).

### 7. Cross-Platform Considerations (Windows + Git Bash/WSL)

Watch for CRLF line endings. Files edited on Windows sometimes save with `\r\n`, which breaks the shebang line on Linux/Git Bash with a cryptic bad interpreter error. Fix with:

```bash
sed -i 's/\r$//' scripts/*.sh
```

or configure Git to handle this automatically via `.gitattributes`:

```
*.sh text eol=lf
```

Keep `chmod +x` instructions visible in your documentation, as you do — Windows users forget this step most often since NTFS doesn't track the execute bit the same way.

For teams split between PowerShell and Bash, consider maintaining thin PowerShell wrappers (as you did for `delete-stack.ps1`) only for the most commonly run scripts, rather than duplicating everything.

### 8. Logging and Auditability

Add timestamped logs for anything that touches production infrastructure:

```bash
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Deleting stack: $STACK_NAME"
```

Redirect output to a log file in addition to the console for scripts run in automation:

```bash
exec > >(tee -a "logs/deploy-$(date +%Y%m%d-%H%M%S).log") 2>&1
```

Log the Git commit hash at deploy time in `create-stack.sh` so you always know which version of the template produced which stack.

### 9. Git Workflow Script Improvements

Avoid generic commit messages like "Describe your changes" making it into an actual commit — prompt for input instead:

```bash
read -rp "Enter commit message: " COMMIT_MSG
git commit -m "$COMMIT_MSG"
```

Add a safety check before pushing, e.g., confirming the current branch is the intended one:

```bash
CURRENT_BRANCH=$(git branch --show-current)
echo "You are about to push to: $CURRENT_BRANCH"
read -rp "Continue? (y/n): " CONFIRM
[[ "$CONFIRM" == "y" ]] || exit 1
```

Consider pre-commit hooks (e.g., via `pre-commit`) to run ShellCheck or cfn-lint automatically before every commit.

### 10. Documentation and Onboarding

Add a `--help` flag to each script for self-documentation:

```bash
[[ "$1" == "--help" ]] && { echo "Usage: $0 [stack-name]"; exit 0; }
```

Keep a single `scripts/README.md` summarizing what each script does, its prerequisites, and example usage — this turns your `scripts/` folder into a genuinely reusable toolkit rather than a set of one-off files.

Document expected AWS IAM permissions needed to run each script (CloudFormation, EC2, RDS, S3 access) so other beginners following your lab know what to provision on their own accounts.

## Final Thoughts

This project reinforced an important lesson: DevOps is not only about learning individual tools—it's about understanding how those tools work together to create reliable, repeatable, and automated workflows.

Building this lab helped me gain hands-on experience with Infrastructure as Code, version control, containerization, automation, and AWS best practices. More importantly, it strengthened my troubleshooting skills and showed me the value of documenting every step of the learning process.

This is only the beginning of my DevOps journey. My next goal is to expand this lab by incorporating Terraform, GitHub Actions CI/CD pipelines, Amazon ECR, Amazon ECS, monitoring with Amazon CloudWatch, and production-ready deployment practices. Continuous learning, practical experience, and consistent improvement remain my priorities, and I'm excited to keep building and sharing what I learn along the way.

If you're beginning your own AWS or DevOps journey, I encourage you to build real projects, experiment freely, make mistakes, and keep improving. Practical experience is one of the best ways to grow your skills and confidence.
