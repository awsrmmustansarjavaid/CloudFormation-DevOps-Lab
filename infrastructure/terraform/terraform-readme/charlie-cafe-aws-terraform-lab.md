# 🚀 Charlie Cafe AWS Terraform Lab

## Complete Configuration → Deployment → Verification → Cleanup Guide

> **Project:** Charlie Cafe AWS DevOps Lab
> **Infrastructure as Code:** Terraform
> **Cloud Provider:** AWS
> **Primary Environment:** Development
> **Purpose:** Provision, deploy, verify, and safely destroy the Charlie Cafe AWS infrastructure using Terraform.

---

## 📋 Table of Contents

1. [Project Overview](#1-project-overview)
2. [Prerequisites](#2-prerequisites)
3. [Final Terraform Project Structure](#3-final-terraform-project-structure)
4. [Terraform Configuration Files](#4-terraform-configuration-files)
5. [AWS Authentication](#5-aws-authentication)
6. [Terraform Initialization](#6-terraform-initialization)
7. [Terraform Formatting and Validation](#7-terraform-formatting-and-validation)
8. [Terraform Plan](#8-terraform-plan)
9. [Terraform Deployment](#9-terraform-deployment)
10. [Deployment Verification](#10-deployment-verification)
11. [Post-Deployment Testing](#11-post-deployment-testing)
12. [Terraform State](#12-terraform-state)
13. [Troubleshooting](#13-troubleshooting)
14. [Cleanup and Destroy](#14-cleanup-and-destroy)
15. [GitHub Actions Integration](#15-github-actions-integration)
16. [Recommended Workflow](#16-recommended-workflow)
17. [Final Checklist](#17-final-checklist)

---

# 1. Project Overview

The **Charlie Cafe AWS Terraform Lab** converts the infrastructure previously managed through AWS CloudFormation into a Terraform-based Infrastructure as Code (IaC) project.

The goal is to manage the AWS environment using Terraform for:

* Infrastructure provisioning
* Infrastructure updates
* Configuration management
* Deployment automation
* Infrastructure verification
* Infrastructure cleanup
* CI/CD integration
* Reproducible development environments

Terraform allows the complete AWS infrastructure to be described as code and managed through a consistent workflow:

```text
Terraform Configuration
        │
        ▼
terraform init
        │
        ▼
terraform fmt
        │
        ▼
terraform validate
        │
        ▼
terraform plan
        │
        ▼
terraform apply
        │
        ▼
AWS Infrastructure
        │
        ▼
Verification
        │
        ▼
terraform destroy
```

---

# 2. Prerequisites

Before running the Terraform project, make sure the following tools are installed.

## 2.1 Required Software

| Tool              | Purpose                            |
| ----------------- | ---------------------------------- |
| AWS CLI           | Authenticate and interact with AWS |
| Terraform         | Infrastructure as Code             |
| Git               | Source-code management             |
| GitHub            | Repository and CI/CD               |
| VS Code           | Recommended code editor            |
| Bash / PowerShell | Running helper scripts             |

Verify the installations:

### Terraform

```bash
terraform version
```

Expected output should resemble:

```text
Terraform v1.x.x
```

### AWS CLI

```bash
aws --version
```

### Git

```bash
git --version
```

---

# 3. Final Terraform Project Structure

## 3.1 Recommended Modular Structure

For a professional and scalable Terraform project, the following structure is recommended:

```text
CloudFormation-DevOps-Lab/
│
├── terraform/
│   │
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   ├── providers.tf
│   ├── terraform.tfvars
│   ├── .gitignore
│   │
│   ├── modules/
│   │   ├── network/
│   │   ├── security/
│   │   ├── ec2/
│   │   ├── rds/
│   │   ├── ecs/
│   │   ├── ecr/
│   │   ├── s3/
│   │   ├── cloudfront/
│   │   ├── alb/
│   │   ├── lambda/
│   │   ├── dynamodb/
│   │   ├── iam/
│   │   ├── waf/
│   │   └── monitoring/
│   │
│   └── environments/
│       └── dev/
│
├── scripts/
│   ├── verify-terraform.sh
│   ├── terraform-deploy.sh
│   └── terraform-destroy.sh
│
└── .github/
    └── workflows/
        ├── aws-terraform-deploy.yml
        └── aws-terraform-delete.yml
```

This structure separates the infrastructure into reusable Terraform modules.

For example:

```text
modules/
├── network/
├── security/
├── ec2/
├── rds/
└── ecs/
```

Each module can manage a specific area of the AWS architecture.

---

## 3.2 Simple Non-Modular Structure

If the project is not modular, that is completely valid.

A smaller Terraform project can use:

```text
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── versions.tf
├── terraform.tfvars
└── .gitignore
```

Terraform automatically loads all `.tf` files in the same directory.

Therefore, the following files:

```text
main.tf
variables.tf
outputs.tf
providers.tf
versions.tf
```

are treated as one Terraform configuration.

### Important

The filenames are mainly for organization and readability.

Terraform does **not** require everything to be inside `main.tf`.

---

# 4. Terraform Configuration Files

A professional Terraform project normally separates configuration responsibilities.

## 4.1 `versions.tf`

Defines Terraform and provider version requirements.

Example:

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

---

## 4.2 `providers.tf`

Defines the AWS provider.

Example:

```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "CharlieCafe"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
```

---

## 4.3 `variables.tf`

Defines configurable Terraform variables.

Example:

```hcl
variable "aws_region" {
  description = "AWS region where the infrastructure will be deployed"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}
```

---

## 4.4 `terraform.tfvars`

Provides values for Terraform variables.

Example:

```hcl
aws_region  = "ap-southeast-1"
environment = "dev"
```

### Security Warning

Do not place passwords, API keys, access keys, or other sensitive credentials inside `terraform.tfvars`.

For example, avoid:

```hcl
password = "MySuperSecretPassword"
```

Use AWS Secrets Manager, environment variables, or another secure secret-management mechanism instead.

---

## 4.5 `main.tf`

Contains the primary infrastructure resources and/or module calls.

Example:

```hcl
module "network" {
  source = "./modules/network"

  environment = var.environment
}
```

---

## 4.6 `outputs.tf`

Defines values that should be displayed after deployment.

Example:

```hcl
output "vpc_id" {
  description = "ID of the Charlie Cafe VPC"
  value       = module.network.vpc_id
}

output "application_url" {
  description = "Application URL"
  value       = module.alb.application_url
}
```

After deployment:

```bash
terraform output
```

can be used to display the outputs.

---

# 5. AWS Authentication

Terraform needs permission to communicate with AWS.

The recommended approach for local development is to configure the AWS CLI.

Run:

```bash
aws configure
```

Provide:

```text
AWS Access Key ID:
AWS Secret Access Key:
Default region name:
Default output format:
```

Example:

```text
AWS Access Key ID:     ********
AWS Secret Access Key: ********
Default region name:  ap-southeast-1
Default output format: json
```

---

## 5.1 Verify AWS Authentication

Run:

```bash
aws sts get-caller-identity
```

Expected output:

```json
{
    "UserId": "XXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/terraform-user"
}
```

If this command fails, fix AWS authentication before running Terraform.

---

## 5.2 Recommended IAM Permissions

The IAM identity used by Terraform must have sufficient permissions for the AWS resources being created.

Depending on the lab, permissions may be required for services such as:

```text
VPC
IAM
EC2
ECS
ECR
RDS
S3
CloudFront
Elastic Load Balancing
Lambda
DynamoDB
CloudWatch
CloudTrail
WAF
Secrets Manager
KMS
```

For a production environment, avoid using unrestricted administrator permissions.

Use least-privilege IAM policies appropriate for the infrastructure.

---

# 6. Terraform Initialization

Move into the Terraform directory:

```bash
cd terraform
```

Initialize Terraform:

```bash
terraform init
```

Terraform will:

1. Initialize the working directory.
2. Download required providers.
3. Initialize modules.
4. Configure the backend if one is defined.
5. Prepare the project for planning and deployment.

Successful initialization normally ends with a message similar to:

```text
Terraform has been successfully initialized!
```

---

# 7. Terraform Formatting and Validation

Before creating infrastructure, format and validate the configuration.

## 7.1 Format Terraform Code

Run:

```bash
terraform fmt -recursive
```

This formats Terraform files according to Terraform's standard formatting conventions.

To check formatting without modifying files:

```bash
terraform fmt -check -recursive
```

---

## 7.2 Validate Configuration

Run:

```bash
terraform validate
```

Expected result:

```text
Success! The configuration is valid.
```

If validation fails, do not continue to deployment.

Fix the configuration first.

---

## 7.3 Recommended Validation Sequence

Run:

```bash
terraform fmt -recursive
terraform validate
```

Then:

```bash
terraform plan
```

---

# 8. Terraform Plan

The Terraform plan is one of the most important safety steps.

Run:

```bash
terraform plan
```

Terraform compares:

```text
Terraform Configuration
        +
Terraform State
        +
Current AWS Infrastructure
        │
        ▼
Terraform Plan
```

The plan tells you what Terraform intends to do.

Typical symbols include:

```text
+ create
~ update
- destroy
-/+ replace
```

For example:

```text
Plan: 25 to add, 0 to change, 0 to destroy.
```

Before running `terraform apply`, carefully review the plan.

---

## 8.1 Save the Plan

For more controlled deployments:

```bash
terraform plan -out=tfplan
```

Then review and apply the exact saved plan:

```bash
terraform apply tfplan
```

This is preferable for controlled CI/CD deployments because the plan being reviewed is the plan that gets applied.

---

# 9. Terraform Deployment

Once the plan has been reviewed, deploy the infrastructure.

## 9.1 Interactive Deployment

Run:

```bash
terraform apply
```

Terraform will display the planned changes and ask for confirmation:

```text
Do you want to perform these actions?

Enter a value:
```

Enter:

```text
yes
```

Terraform will then create or update the AWS infrastructure.

---

## 9.2 Automatic Deployment

For automation:

```bash
terraform apply -auto-approve
```

### Warning

Do not use `-auto-approve` casually in production.

For CI/CD pipelines, it can be appropriate when the pipeline has already performed validation and plan approval according to the team's deployment process.

---

# 10. Deployment Verification

After Terraform finishes successfully, verify the infrastructure.

Start with:

```bash
terraform output
```

This displays the outputs defined in `outputs.tf`.

For a specific output:

```bash
terraform output application_url
```

---

## 10.1 Check Terraform State

Run:

```bash
terraform state list
```

This displays resources currently tracked by Terraform.

Example:

```text
module.network.aws_vpc.main
module.network.aws_subnet.public_1
module.network.aws_subnet.public_2
module.ecs.aws_ecs_cluster.main
module.ecr.aws_ecr_repository.main
module.alb.aws_lb.main
```

---

## 10.2 Verify AWS Resources

Terraform state alone is not sufficient for application verification.

Use the AWS CLI to verify important resources.

### AWS Identity

```bash
aws sts get-caller-identity
```

### VPC

```bash
aws ec2 describe-vpcs
```

### Subnets

```bash
aws ec2 describe-subnets
```

### Security Groups

```bash
aws ec2 describe-security-groups
```

### ECR

```bash
aws ecr describe-repositories
```

### ECS

```bash
aws ecs list-clusters
```

### ECS Services

```bash
aws ecs list-services \
  --cluster CharlieCafe-Cluster
```

### ECS Tasks

```bash
aws ecs list-tasks \
  --cluster CharlieCafe-Cluster
```

### RDS

```bash
aws rds describe-db-instances
```

### S3

```bash
aws s3 ls
```

### Lambda

```bash
aws lambda list-functions
```

### DynamoDB

```bash
aws dynamodb list-tables
```

---

# 11. Post-Deployment Testing

Infrastructure deployment is not complete until the application is tested.

---

## 11.1 Check Terraform Outputs

```bash
terraform output
```

Look for values such as:

```text
application_url
alb_dns_name
cloudfront_domain_name
ecr_repository_url
ecs_cluster_name
ecs_service_name
vpc_id
```

---

## 11.2 Test Application URL

If Terraform provides an application URL:

```bash
terraform output -raw application_url
```

Open the resulting URL in a browser.

---

## 11.3 Test HTTP Connectivity

You can also use:

```bash
curl -I https://YOUR_APPLICATION_URL
```

A successful application may return:

```text
HTTP/2 200
```

or another expected HTTP response.

---

## 11.4 Verify ECS Service

If the application uses ECS:

```bash
aws ecs describe-services \
  --cluster CharlieCafe-Cluster \
  --services CharlieCafe-Service
```

Check:

```text
desiredCount
runningCount
pendingCount
status
```

The expected state should generally be:

```text
status       = ACTIVE
desiredCount = 1
runningCount = 1
pendingCount = 0
```

---

## 11.5 Verify ECS Tasks

Run:

```bash
aws ecs list-tasks \
  --cluster CharlieCafe-Cluster \
  --service-name CharlieCafe-Service
```

Then inspect the task:

```bash
aws ecs describe-tasks \
  --cluster CharlieCafe-Cluster \
  --tasks TASK_ID
```

---

## 11.6 Verify Load Balancer Target Health

If an Application Load Balancer is used, verify that registered targets are healthy.

The target state should be:

```text
healthy
```

Unhealthy targets should be investigated before considering the deployment successful.

---

# 12. Terraform State

Terraform uses a state file to track infrastructure.

By default:

```text
terraform.tfstate
```

contains information about resources managed by Terraform.

### Important

Do **not** commit the following to Git:

```text
terraform.tfstate
terraform.tfstate.*
.terraform/
```

The state file can contain sensitive infrastructure information.

---

## 12.1 Recommended `.gitignore`

Example:

```gitignore
# Terraform
.terraform/
*.tfstate
*.tfstate.*
crash.log
crash.*.log

# Terraform plans
*.tfplan
tfplan

# Variable files that may contain secrets
*.tfvars
*.tfvars.json

# Local override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Terraform lock file should normally be committed
# .terraform.lock.hcl

# OS files
.DS_Store
Thumbs.db
```

### Important Note

For team projects, the `.terraform.lock.hcl` file should normally be committed because it locks provider versions and improves reproducibility.

If `terraform.tfvars` contains only non-sensitive development values, you may choose to commit it. Otherwise, keep it ignored and provide an example file such as:

```text
terraform.tfvars.example
```

---

# 13. Troubleshooting

## 13.1 Terraform Command Not Found

If you receive:

```text
terraform is not recognized
```

or:

```text
terraform: command not found
```

Terraform is either not installed or is not available in the system `PATH`.

Verify:

```bash
terraform version
```

---

## 13.2 AWS Authentication Error

If Terraform reports an AWS credential error, run:

```bash
aws sts get-caller-identity
```

If that fails, configure AWS credentials:

```bash
aws configure
```

---

## 13.3 AccessDenied Error

Example:

```text
AccessDenied
```

The IAM identity does not have the required permissions.

Check:

```bash
aws sts get-caller-identity
```

Then review the IAM policies attached to the identity.

---

## 13.4 Terraform Validation Error

Run:

```bash
terraform validate
```

Read the reported file and line number.

For example:

```text
Error: Reference to undeclared resource
```

Check:

* Resource name
* Module name
* Variable name
* Output reference
* Provider configuration

---

## 13.5 Terraform State Lock

If using a remote backend, Terraform may report that the state is locked.

Do **not** immediately force-unlock the state.

First confirm that another Terraform process is not currently running.

Only use:

```bash
terraform force-unlock LOCK_ID
```

when you are certain the lock is stale.

---

## 13.6 Resource Already Exists

Terraform may fail when an AWS resource already exists outside Terraform.

Determine whether the resource should be managed by Terraform.

If it should, import it using:

```bash
terraform import RESOURCE_ADDRESS RESOURCE_ID
```

Then run:

```bash
terraform plan
```

---

# 14. Cleanup and Destroy

When the lab is finished, destroy the infrastructure to avoid unnecessary AWS charges.

## 14.1 Review Destroy Plan

Run:

```bash
terraform plan -destroy
```

Carefully review the resources Terraform intends to remove.

---

## 14.2 Destroy Infrastructure

Run:

```bash
terraform destroy
```

Terraform will ask for confirmation.

Enter:

```text
yes
```

---

## 14.3 Automatic Destroy

For automation:

```bash
terraform destroy -auto-approve
```

Use this carefully.

This command can permanently remove infrastructure.

---

## 14.4 Verify Cleanup

After destruction:

```bash
terraform state list
```

The expected result should be empty if the entire Terraform-managed infrastructure was destroyed.

Also verify the AWS console and CLI to make sure important resources have been removed.

For example:

```bash
aws ecs list-clusters
```

```bash
aws ecr describe-repositories
```

```bash
aws rds describe-db-instances
```

```bash
aws s3 ls
```

---

# 15. GitHub Actions Integration

After successfully deploying Terraform locally, the project can be integrated with GitHub Actions.

Recommended workflow files:

```text
.github/
└── workflows/
    ├── aws-terraform-deploy.yml
    └── aws-terraform-delete.yml
```

---

## 15.1 Terraform Deployment Workflow

A typical deployment pipeline should perform:

```text
Checkout
   │
   ▼
Configure AWS Credentials
   │
   ▼
Terraform Init
   │
   ▼
Terraform Format Check
   │
   ▼
Terraform Validate
   │
   ▼
Terraform Plan
   │
   ▼
Terraform Apply
   │
   ▼
Verification
```

---

## 15.2 Terraform Cleanup Workflow

The cleanup workflow should perform:

```text
Checkout
   │
   ▼
Configure AWS Credentials
   │
   ▼
Terraform Init
   │
   ▼
Terraform Validate
   │
   ▼
Terraform Plan - Destroy
   │
   ▼
Terraform Destroy
   │
   ▼
Verification
```

---

## 15.3 Recommended GitHub Secrets

Do not hard-code AWS credentials inside workflow files.

Depending on the authentication method, configure the required GitHub secrets or use GitHub OIDC with an AWS IAM role.

For traditional credentials, examples include:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
```

For a production-oriented setup, prefer **GitHub Actions OIDC + AWS IAM Role** rather than long-lived AWS access keys.

---

# 16. Recommended Workflow

The recommended development workflow for this lab is:

## Step 1 — Clone Repository

```bash
git clone YOUR_REPOSITORY_URL
```

```bash
cd CloudFormation-DevOps-Lab
```

---

## Step 2 — Enter Terraform Directory

```bash
cd terraform
```

---

## Step 3 — Verify AWS Credentials

```bash
aws sts get-caller-identity
```

---

## Step 4 — Initialize Terraform

```bash
terraform init
```

---

## Step 5 — Format Code

```bash
terraform fmt -recursive
```

---

## Step 6 — Validate

```bash
terraform validate
```

---

## Step 7 — Create Plan

```bash
terraform plan -out=tfplan
```

---

## Step 8 — Review Plan

Check:

```text
Resources to create
Resources to modify
Resources to destroy
```

Make sure the proposed changes are expected.

---

## Step 9 — Deploy

```bash
terraform apply tfplan
```

---

## Step 10 — Verify Outputs

```bash
terraform output
```

---

## Step 11 — Verify AWS Resources

Use the AWS CLI:

```bash
aws sts get-caller-identity
```

Then verify the individual services used by the Charlie Cafe architecture.

---

## Step 12 — Test Application

Open the application URL and test:

* Frontend
* API
* Authentication
* Database connectivity
* Application functionality
* Load balancer
* ECS service
* CloudFront, if applicable

---

## Step 13 — Commit Changes

From the repository root:

```bash
git status
```

Then:

```bash
git add .
```

```bash
git commit -m "Add Charlie Cafe Terraform infrastructure"
```

```bash
git push
```

---

## Step 14 — Destroy When Finished

When the lab is no longer required:

```bash
terraform plan -destroy
```

Then:

```bash
terraform destroy
```

---

# 17. Final Checklist

Use the following checklist before considering the Terraform lab complete.

## Terraform Configuration

* [ ] Terraform is installed.
* [ ] AWS CLI is installed.
* [ ] Git is installed.
* [ ] Terraform project structure is organized.
* [ ] Provider configuration is correct.
* [ ] Variables are defined.
* [ ] Outputs are defined.
* [ ] Modules are correctly referenced where applicable.
* [ ] Sensitive information is not hard-coded.

## AWS Authentication

* [ ] AWS credentials are configured.
* [ ] `aws sts get-caller-identity` succeeds.
* [ ] Terraform has the required IAM permissions.

## Terraform Validation

* [ ] `terraform init` succeeds.
* [ ] `terraform fmt -recursive` succeeds.
* [ ] `terraform validate` succeeds.
* [ ] `terraform plan` succeeds.
* [ ] Terraform plan was reviewed.

## Deployment

* [ ] `terraform apply` succeeds.
* [ ] Terraform outputs are available.
* [ ] Terraform state contains expected resources.
* [ ] AWS resources exist.
* [ ] ECS services are running where applicable.
* [ ] ECS tasks are healthy where applicable.
* [ ] ALB targets are healthy where applicable.
* [ ] RDS is available where applicable.
* [ ] ECR repositories exist where applicable.
* [ ] Application URL responds successfully.

## Security

* [ ] No AWS access keys are committed to Git.
* [ ] No passwords are committed to Git.
* [ ] Sensitive `.tfvars` files are protected.
* [ ] Terraform state is protected.
* [ ] IAM permissions follow least privilege where possible.
* [ ] Production deployments use secure authentication such as OIDC where appropriate.

## Cleanup

* [ ] `terraform plan -destroy` reviewed.
* [ ] `terraform destroy` completed.
* [ ] Terraform state is empty or reflects the remaining intended resources.
* [ ] AWS console verified.
* [ ] Unwanted billable resources are removed.

---

# 🎯 Final Terraform Command Reference

| Purpose                 | Command                           |
| ----------------------- | --------------------------------- |
| Check Terraform version | `terraform version`               |
| Initialize Terraform    | `terraform init`                  |
| Format Terraform        | `terraform fmt -recursive`        |
| Check formatting        | `terraform fmt -check -recursive` |
| Validate configuration  | `terraform validate`              |
| Create plan             | `terraform plan`                  |
| Save plan               | `terraform plan -out=tfplan`      |
| Apply saved plan        | `terraform apply tfplan`          |
| Apply interactively     | `terraform apply`                 |
| Apply automatically     | `terraform apply -auto-approve`   |
| Show outputs            | `terraform output`                |
| List managed resources  | `terraform state list`            |
| Inspect resource        | `terraform state show RESOURCE`   |
| Plan destruction        | `terraform plan -destroy`         |
| Destroy infrastructure  | `terraform destroy`               |
| Automatic destruction   | `terraform destroy -auto-approve` |

---

# 🏁 Conclusion

The Charlie Cafe Terraform Lab should follow a predictable Infrastructure as Code lifecycle:

```text
┌───────────────────────────┐
│ Terraform Configuration   │
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│ terraform init            │
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│ fmt + validate            │
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│ terraform plan            │
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│ terraform apply           │
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│ AWS Infrastructure        │
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│ Verification & Testing    │
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│ terraform destroy         │
└───────────────────────────┘
```

This workflow provides a clean foundation for managing the Charlie Cafe AWS environment locally and later automating the same infrastructure through GitHub Actions.

> **Recommended practice:** Always run `terraform fmt`, `terraform validate`, and `terraform plan` before `terraform apply`, and always review the planned changes before creating or destroying AWS resources.

---

# 🚀 Charlie Cafe AWS Terraform Lab

## Complete Configuration → Deployment → Verification → Cleanup Guide

---

# 1. Final Terraform Project Structure

I recommend organizing your repository like this:

```text
CloudFormation-DevOps-Lab/
│
├── terraform/
│   │
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   ├── providers.tf
│   ├── terraform.tfvars
│   ├── .gitignore
│   │
│   ├── modules/
│   │   ├── network/
│   │   ├── security/
│   │   ├── ec2/
│   │   ├── rds/
│   │   ├── ecs/
│   │   ├── ecr/
│   │   ├── s3/
│   │   ├── cloudfront/
│   │   ├── alb/
│   │   ├── lambda/
│   │   ├── dynamodb/
│   │   ├── iam/
│   │   ├── waf/
│   │   └── monitoring/
│   │
│   └── environments/
│       └── dev/
│
├── scripts/
│   ├── verify-terraform.sh
│   ├── terraform-deploy.sh
│   └── terraform-destroy.sh
│
└── .github/
    └── workflows/
        ├── aws-terraform-deploy.yml
        └── aws-terraform-delete.yml
```

If your Terraform project is **not modular**, that's completely fine.

For example:

```text
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── versions.tf
└── terraform.tfvars
```

is also perfectly valid.

---

# 2. Install Required Software

You need these tools on your Windows machine:

```text
AWS CLI
Terraform
Git
PowerShell
```

Optional but useful:

```text
VS Code
GitHub CLI
jq
```

---

# 3. Verify Terraform Installation

Open PowerShell.

Run:

```powershell
terraform version
```

You should see something similar to:

```text
Terraform v1.x.x
```

Then:

```powershell
terraform -help
```

If Terraform is installed correctly, you will get the Terraform command help.

---

# 4. Verify AWS CLI

Run:

```powershell
aws --version
```

Example:

```text
aws-cli/2.x.x
```

Then:

```powershell
aws sts get-caller-identity
```

You should receive something like:

```json
{
    "UserId": "XXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/terraform-user"
}
```

This is extremely important.

Terraform must deploy into the **same AWS account** that you expect.

---

# 5. Configure AWS Credentials

For local Terraform development, configure AWS CLI.

Run:

```powershell
aws configure
```

Enter:

```text
AWS Access Key ID:
AWS Secret Access Key:
Default region name: us-east-1
Default output format: json
```

Then verify:

```powershell
aws sts get-caller-identity
```

---

# 6. Recommended: Use AWS Profile

Instead of relying on the default profile, I recommend creating a dedicated profile.

For example:

```powershell
aws configure --profile charlie-cafe
```

Enter your credentials.

Then test:

```powershell
aws sts get-caller-identity --profile charlie-cafe
```

You can then configure Terraform to use:

```hcl
provider "aws" {
  region  = var.aws_region
  profile = "charlie-cafe"
}
```

However, **do not commit AWS credentials into GitHub or Terraform files**.

---

# 7. IMPORTANT — Do Not Put AWS Credentials in Terraform

Never do this:

```hcl
provider "aws" {
  access_key = "AKIA..."
  secret_key = "..."
}
```

❌ Do not do it.

Use:

```text
AWS CLI profile
```

or environment variables:

```powershell
$env:AWS_ACCESS_KEY_ID="..."
$env:AWS_SECRET_ACCESS_KEY="..."
$env:AWS_REGION="us-east-1"
```

For GitHub Actions, use GitHub Secrets or preferably GitHub OIDC.

---

# 8. Check Your Terraform Provider

Your `providers.tf` should look approximately like:

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

Your exact AWS provider version may differ depending on the Terraform code you already created.

Do **not** blindly change provider versions if your code was written for a particular version.

---

# 9. Configure Terraform Variables

For example:

```hcl
variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "CharlieCafe"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}
```

Your actual variables will depend on your Terraform implementation.

---

# 10. Create `terraform.tfvars`

Example:

```hcl
aws_region   = "us-east-1"
project_name = "CharlieCafe"
environment  = "dev"
```

If you have VPC/subnet variables:

```hcl
vpc_id = "vpc-xxxxxxxx"

public_subnet_1 = "subnet-xxxxxxxx"
public_subnet_2 = "subnet-xxxxxxxx"

private_subnet_1 = "subnet-xxxxxxxx"
private_subnet_2 = "subnet-xxxxxxxx"
```

Use the variables required by **your actual Terraform code**.

---

# 11. Protect `terraform.tfvars`

If it contains sensitive information, add it to `.gitignore`.

Example:

```gitignore
# Terraform working directory
.terraform/

# Terraform state
*.tfstate
*.tfstate.*

# Terraform variable files
terraform.tfvars
*.tfvars

# Terraform crash logs
crash.log
crash.*.log

# Terraform plan files
*.tfplan

# Secrets
.env
.env.*

# IDE
.vscode/
.idea/
```

---

# 12. VERY IMPORTANT — Terraform State

Terraform creates:

```text
terraform.tfstate
```

This file is extremely important.

It tells Terraform:

> "These AWS resources belong to this Terraform configuration."

Never casually delete:

```text
terraform.tfstate
```

If you lose the state, Terraform may no longer know that the AWS resources already exist.

---

# 13. Recommended — Use an S3 Backend

For a serious project, use a remote backend.

Example:

```hcl
terraform {
  backend "s3" {
    bucket = "charlie-cafe-terraform-state"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}
```

For your **first local test**, however, you can start with local state.

Once everything works, migrate to an S3 backend with appropriate locking/versioning.

---

# 14. Go to Terraform Directory

PowerShell:

```powershell
cd C:\Users\musta\Downloads\AWS-Labs\CloudFormation-DevOps-Lab\terraform
```

Then:

```powershell
Get-ChildItem
```

You should see something like:

```text
main.tf
variables.tf
outputs.tf
providers.tf
versions.tf
terraform.tfvars
```

---

# 15. Format Terraform Code

Run:

```powershell
terraform fmt -recursive
```

This automatically formats `.tf` files.

Then:

```powershell
terraform fmt -check -recursive
```

If successful, your formatting is correct.

---

# 16. Initialize Terraform

This is the first major Terraform command:

```powershell
terraform init
```

Terraform will:

1. Download the AWS provider.
2. Initialize the backend.
3. Initialize modules.
4. Prepare the working directory.

You should eventually see:

```text
Terraform has been successfully initialized!
```

---

# 17. Validate Terraform Configuration

Run:

```powershell
terraform validate
```

Expected:

```text
Success! The configuration is valid.
```

If you receive errors, **do not run `terraform apply` yet**.

Fix all validation errors first.

---

# 18. Check Terraform Providers

Run:

```powershell
terraform providers
```

This helps verify which providers/modules your project is using.

---

# 19. Create a Terraform Plan

Now run:

```powershell
terraform plan
```

Terraform will inspect your configuration and determine what it wants to create/change/delete.

You may see:

```text
Plan: 85 to add, 0 to change, 0 to destroy.
```

The exact number depends on your lab.

---

# 20. Save the Terraform Plan

For a professional workflow, use:

```powershell
terraform plan -out=tfplan
```

Then inspect:

```powershell
terraform show tfplan
```

This is better than immediately applying an unreviewed plan.

---

# 21. VERY IMPORTANT — Review Destroy Operations

Before applying, look for:

```text
-/+
```

and:

```text
destroy
```

If you expected a new deployment but Terraform says:

```text
Plan: 30 to add, 0 to change, 50 to destroy.
```

**STOP.**

Do not apply until you understand why Terraform wants to destroy resources.

---

# 22. First Terraform Deployment

If the plan is correct:

```powershell
terraform apply tfplan
```

Terraform will create your infrastructure.

Depending on your architecture, this may include:

```text
VPC
Subnets
Route Tables
Internet Gateway
NAT Gateway
Security Groups
IAM Roles
EC2
RDS
S3
CloudFront
ALB
ECR
ECS
Lambda
DynamoDB
WAF
CloudWatch
CloudTrail
KMS
Secrets Manager
```

The actual list depends on your Terraform code.

---

# 23. Alternative — Direct Apply

You can also use:

```powershell
terraform apply
```

Terraform will show the plan and ask:

```text
Do you want to perform these actions?

  Enter a value:
```

Enter:

```text
yes
```

I recommend:

```powershell
terraform plan -out=tfplan
terraform apply tfplan
```

for your lab.

---

# 24. Watch Terraform Carefully

During deployment you might see:

```text
aws_vpc.main: Creating...
aws_subnet.public_1: Creating...
aws_security_group.web: Creating...
aws_instance.web: Creating...
aws_db_instance.mysql: Creating...
aws_ecs_cluster.main: Creating...
```

Some AWS resources take several minutes.

Especially:

```text
RDS
CloudFront
WAF
ALB
ECS
NAT Gateway
```

Do not assume something is broken simply because Terraform is waiting.

---

# 25. Verify Terraform State

After deployment:

```powershell
terraform state list
```

You should see resources such as:

```text
aws_vpc.main
aws_subnet.public_1
aws_subnet.public_2
aws_security_group.web
aws_instance.web
aws_db_instance.mysql
aws_ecr_repository.app
aws_ecs_cluster.main
aws_ecs_service.app
```

Your exact resource names will depend on your code.

---

# 26. Check Terraform Outputs

Run:

```powershell
terraform output
```

For a specific output:

```powershell
terraform output application_url
```

If an output is sensitive:

```powershell
terraform output -json
```

Be careful with sensitive outputs.

---

# 27. Verify AWS Account

Run:

```powershell
aws sts get-caller-identity
```

Confirm:

```text
Account
Arn
```

are correct.

---

# 28. Verify VPC

Run:

```powershell
aws ec2 describe-vpcs `
  --region us-east-1 `
  --query "Vpcs[].[VpcId,CidrBlock,State]" `
  --output table
```

---

# 29. Verify Subnets

```powershell
aws ec2 describe-subnets `
  --region us-east-1 `
  --query "Subnets[].[SubnetId,VpcId,AvailabilityZone,CidrBlock]" `
  --output table
```

Check that the expected public/private subnets exist.

---

# 30. Verify EC2

```powershell
aws ec2 describe-instances `
  --region us-east-1 `
  --query "Reservations[].Instances[].[InstanceId,State.Name,PrivateIpAddress,PublicIpAddress]" `
  --output table
```

Check:

```text
Instance ID
State
Private IP
Public IP
```

---

# 31. Verify EC2 Through SSM

If your EC2 instance uses Systems Manager:

```powershell
aws ssm describe-instance-information `
  --region us-east-1 `
  --output table
```

You want:

```text
PingStatus
---------
Online
```

This is important because your deployment/cleanup workflows use SSM.

---

# 32. Verify Docker on EC2

Use SSM:

```powershell
aws ssm send-command `
  --instance-ids "i-xxxxxxxxxxxxxxxxx" `
  --document-name "AWS-RunShellScript" `
  --parameters commands="docker --version" `
  --region us-east-1
```

Then retrieve the command result.

---

# 33. Verify RDS

Run:

```powershell
aws rds describe-db-instances `
  --region us-east-1 `
  --query "DBInstances[].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address,Endpoint.Port,DeletionProtection]" `
  --output table
```

Expected:

```text
available
```

for the DB status.

---

# 34. Verify RDS Security

Confirm your RDS database is **not unnecessarily exposed to the public internet**.

Check:

```powershell
aws rds describe-db-instances `
  --region us-east-1 `
  --query "DBInstances[].[DBInstanceIdentifier,PubliclyAccessible]" `
  --output table
```

Ideally:

```text
False
```

for a private database architecture.

---

# 35. Verify Secrets Manager

If your Terraform creates an RDS secret:

```powershell
aws secretsmanager list-secrets `
  --region us-east-1 `
  --query "SecretList[].[Name,ARN]" `
  --output table
```

Do **not** print secret values unnecessarily.

---

# 36. Verify ECR

Run:

```powershell
aws ecr describe-repositories `
  --region us-east-1 `
  --query "repositories[].[repositoryName,repositoryUri]" `
  --output table
```

Look for:

```text
charlie-cafe
```

if that is the repository name used by your Terraform configuration.

---

# 37. Verify ECR Images

```powershell
aws ecr list-images `
  --repository-name charlie-cafe `
  --region us-east-1 `
  --output table
```

If your repository is initially empty, that is not necessarily an error.

---

# 38. Verify ECS Cluster

```powershell
aws ecs list-clusters `
  --region us-east-1
```

Then:

```powershell
aws ecs describe-clusters `
  --clusters CharlieCafe-Cluster `
  --region us-east-1 `
  --output table
```

Use the actual cluster name from:

```powershell
terraform output
```

if it differs.

---

# 39. Verify ECS Service

```powershell
aws ecs describe-services `
  --cluster CharlieCafe-Cluster `
  --services CharlieCafe-Service `
  --region us-east-1 `
  --query "services[].[serviceName,status,runningCount,desiredCount,pendingCount]" `
  --output table
```

You ideally want:

```text
STATUS       RUNNING   DESIRED
ACTIVE       1         1
```

---

# 40. Verify ECS Tasks

```powershell
aws ecs list-tasks `
  --cluster CharlieCafe-Cluster `
  --service-name CharlieCafe-Service `
  --region us-east-1
```

Then:

```powershell
aws ecs describe-tasks `
  --cluster CharlieCafe-Cluster `
  --tasks <TASK-ID> `
  --region us-east-1
```

---

# 41. Verify ALB

Run:

```powershell
aws elbv2 describe-load-balancers `
  --region us-east-1 `
  --query "LoadBalancers[].[LoadBalancerName,DNSName,State.Code]" `
  --output table
```

You want:

```text
State
-----
active
```

---

# 42. Verify Target Group

Get target groups:

```powershell
aws elbv2 describe-target-groups `
  --region us-east-1 `
  --query "TargetGroups[].[TargetGroupName,TargetGroupArn,Port,Protocol]" `
  --output table
```

Then check health:

```powershell
aws elbv2 describe-target-health `
  --target-group-arn <TARGET-GROUP-ARN> `
  --region us-east-1
```

You want:

```text
healthy
```

---

# 43. Test Application

If Terraform outputs:

```text
application_url = "http://..."
```

run:

```powershell
curl.exe http://YOUR-ALB-DNS
```

Or:

```powershell
Invoke-WebRequest http://YOUR-ALB-DNS
```

For HTTPS:

```powershell
curl.exe https://YOUR-DOMAIN
```

---

# 44. Verify S3

Run:

```powershell
aws s3api list-buckets `
  --query "Buckets[].Name" `
  --output table
```

If Terraform creates a bucket for the application:

```powershell
aws s3api head-bucket --bucket <BUCKET-NAME>
```

---

# 45. Verify CloudFront

```powershell
aws cloudfront list-distributions `
  --query "DistributionList.Items[].[Id,Status,DomainName]" `
  --output table
```

CloudFront can take time to reach:

```text
Deployed
```

---

# 46. Verify Lambda

```powershell
aws lambda list-functions `
  --region us-east-1 `
  --query "Functions[].[FunctionName,Runtime,State]" `
  --output table
```

---

# 47. Verify DynamoDB

```powershell
aws dynamodb list-tables `
  --region us-east-1
```

For your Charlie Cafe lab, check your expected table, for example:

```text
CafeOrders
```

or whatever table name your Terraform code creates.

---

# 48. Verify WAF

If Terraform creates WAF:

```powershell
aws wafv2 list-web-acls `
  --scope REGIONAL `
  --region us-east-1 `
  --output table
```

If CloudFront uses WAF, remember CloudFront WAF resources use:

```text
--scope CLOUDFRONT
--region us-east-1
```

---

# 49. Verify CloudWatch

Check log groups:

```powershell
aws logs describe-log-groups `
  --region us-east-1 `
  --query "logGroups[].logGroupName" `
  --output table
```

---

# 50. Verify IAM

List Terraform-created roles:

```powershell
aws iam list-roles `
  --query "Roles[].[RoleName,Arn]" `
  --output table
```

Do not delete IAM resources manually if Terraform owns them.

---

# 51. Verify KMS

If your Terraform configuration creates a KMS key:

```powershell
aws kms list-keys `
  --region us-east-1
```

Then:

```powershell
aws kms list-aliases `
  --region us-east-1
```

---

# 52. The Most Important Terraform Verification

Run:

```powershell
terraform plan
```

**after deployment.**

This is one of the best checks.

If everything is correct, Terraform should ideally report:

```text
No changes. Your infrastructure matches the configuration.
```

That means:

> Terraform configuration = Terraform state = AWS infrastructure

This is exactly what you want.

---

# 53. Create a Complete Verification Script

You should eventually have:

```text
scripts/
└── verify-terraform.sh
```

The script can check:

```text
1. Terraform
2. AWS identity
3. VPC
4. Subnets
5. EC2
6. SSM
7. Docker
8. RDS
9. Secrets Manager
10. ECR
11. ECS
12. ECS Service
13. ECS Tasks
14. ALB
15. Target Group
16. S3
17. CloudFront
18. Lambda
19. DynamoDB
20. WAF
21. CloudWatch
22. Terraform state
23. Terraform outputs
24. terraform plan
```

This will become your final lab verification tool.

---

# 54. Terraform GitHub Actions Workflow

Once local Terraform deployment works, then move to GitHub Actions.

Your workflow structure should be:

```text
.github/
└── workflows/
    ├── aws-terraform-deploy.yml
    └── aws-terraform-delete.yml
```

The deployment workflow should roughly perform:

```text
Checkout
   ↓
Configure AWS
   ↓
Verify AWS identity
   ↓
Setup Terraform
   ↓
Terraform Init
   ↓
Terraform Format Check
   ↓
Terraform Validate
   ↓
Terraform Plan
   ↓
Terraform Apply
   ↓
Terraform Output
   ↓
AWS Verification
```

---

# 55. GitHub Secrets

If you're using static AWS credentials for your current lab, configure:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
```

If your Terraform code requires additional secrets, configure only those that are genuinely necessary.

However, for a portfolio/production-quality GitHub Actions setup, I strongly recommend eventually switching to:

```text
GitHub Actions
      ↓
OIDC
      ↓
AWS IAM Role
      ↓
Terraform
```

instead of long-lived access keys.

---

# 56. Terraform Deploy Workflow

Your new workflow:

```text
aws-terraform-deploy.yml
```

should perform:

```text
Checkout Repository
        ↓
Configure AWS
        ↓
Verify AWS Account
        ↓
Setup Terraform
        ↓
Terraform Init
        ↓
Terraform Format Check
        ↓
Terraform Validate
        ↓
Terraform Plan
        ↓
Terraform Apply
        ↓
Terraform Output
        ↓
Verify AWS Resources
```

---

# 57. Terraform Delete Workflow

Your converted:

```text
aws-terraform-delete.yml
```

should be much simpler than the old CloudFormation cleanup workflow.

Terraform already knows the resources it owns through state.

The normal sequence is:

```text
Terraform Init
       ↓
Terraform Validate
       ↓
Terraform Plan -destroy
       ↓
Review
       ↓
Terraform Destroy
       ↓
Terraform Verification
```

Run locally first:

```powershell
terraform plan -destroy
```

Review everything.

Then:

```powershell
terraform destroy
```

Terraform will ask:

```text
Do you really want to destroy all resources?
```

Enter:

```text
yes
```

---

# 58. IMPORTANT — Do Not Mix CloudFormation and Terraform

This is extremely important for your migration.

You are moving from:

```text
CloudFormation
```

to:

```text
Terraform
```

Do **not** let both systems manage the same AWS resource.

For example, avoid:

```text
CloudFormation → EC2
Terraform      → same EC2
```

or:

```text
CloudFormation → ECS
Terraform      → same ECS
```

This creates management conflicts.

---

# 59. Your Migration Strategy

Because your existing lab was originally CloudFormation-based, I recommend this sequence:

### Phase 1 — Backup

Keep your existing CloudFormation code.

```text
cloudformation/
```

Do not delete it yet.

---

### Phase 2 — Terraform Validation

Create:

```text
terraform/
```

and test locally.

---

### Phase 3 — Terraform Plan

Run:

```powershell
terraform plan
```

Make sure Terraform intends to create exactly what you expect.

---

### Phase 4 — New Terraform Environment

Ideally deploy Terraform into a clean/test environment first.

For example:

```text
CharlieCafe-TF-Dev
```

This avoids Terraform accidentally interfering with CloudFormation resources.

---

### Phase 5 — Verify

Run:

```powershell
terraform plan
```

after deployment.

Expected:

```text
No changes.
```

Then run your AWS verification script.

---

### Phase 6 — Destroy Terraform Lab

Once testing is complete:

```powershell
terraform plan -destroy
```

Then:

```powershell
terraform destroy
```

Verify AWS is clean.

---

### Phase 7 — GitHub Actions

Only after local Terraform works correctly should you automate:

```text
aws-terraform-deploy.yml
aws-terraform-delete.yml
```

---

# 60. Recommended Final Terraform Workflow

Your complete DevOps workflow should eventually look like this:

```text
                   GitHub Repository
                          │
                          ▼
                  GitHub Actions
                          │
                          ▼
                  Terraform Init
                          │
                          ▼
                  Terraform Validate
                          │
                          ▼
                    Terraform Plan
                          │
                          ▼
                    Terraform Apply
                          │
                          ▼
                  ┌───────────────┐
                  │     AWS       │
                  │               │
                  │ VPC           │
                  │ EC2           │
                  │ RDS           │
                  │ ECS           │
                  │ ECR           │
                  │ ALB           │
                  │ S3            │
                  │ CloudFront     │
                  │ Lambda        │
                  │ DynamoDB       │
                  │ WAF           │
                  │ IAM           │
                  │ KMS           │
                  │ CloudWatch     │
                  └───────────────┘
                          │
                          ▼
                   Verification
                          │
                          ▼
                  terraform plan
                          │
                          ▼
                     No changes
```

---

# 61. The Exact Order I Recommend You Follow

Don't try to do everything at once.

Use this order:

### Step 1

Install/verify:

```powershell
terraform version
aws --version
git --version
```

### Step 2

Verify AWS:

```powershell
aws sts get-caller-identity
```

### Step 3

Go to Terraform:

```powershell
cd C:\Users\musta\Downloads\AWS-Labs\CloudFormation-DevOps-Lab\terraform
```

### Step 4

Format:

```powershell
terraform fmt -recursive
```

### Step 5

Initialize:

```powershell
terraform init
```

### Step 6

Validate:

```powershell
terraform validate
```

### Step 7

Create plan:

```powershell
terraform plan -out=tfplan
```

### Step 8

Review plan.

### Step 9

Apply:

```powershell
terraform apply tfplan
```

### Step 10

Check state:

```powershell
terraform state list
```

### Step 11

Check outputs:

```powershell
terraform output
```

### Step 12

Verify AWS:

```powershell
aws sts get-caller-identity
```

Then verify:

```text
VPC
Subnets
EC2
SSM
Docker
RDS
Secrets Manager
ECR
ECS
ECS Service
ECS Tasks
ALB
Target Group
S3
CloudFront
Lambda
DynamoDB
WAF
CloudWatch
KMS
IAM
```

### Step 13

Run:

```powershell
terraform plan
```

Expected:

```text
No changes.
```

### Step 14

Only then configure:

```text
aws-terraform-deploy.yml
```

### Step 15

Test GitHub Actions deployment.

### Step 16

Test Terraform cleanup:

```powershell
terraform plan -destroy
```

### Step 17

Destroy:

```powershell
terraform destroy
```

### Step 18

Final AWS verification.

---

# 62. One Important Difference From Your Old CloudFormation Workflow

Your old workflow needed a lot of manual cleanup logic:

```text
Discover CloudFormation stack
       ↓
Discover ECS
       ↓
Stop ECS
       ↓
Delete ECR images
       ↓
Delete ECS stack
       ↓
Clean Docker
       ↓
Empty S3
       ↓
Delete S3 stack
       ↓
Disable RDS protection
       ↓
Delete root stack
       ↓
Retry failures
       ↓
Force delete
```

With Terraform, the normal model becomes:

```text
Terraform State
      ↓
terraform plan -destroy
      ↓
Review
      ↓
terraform destroy
      ↓
Terraform destroys managed resources
      ↓
AWS verification
```

That's one of the major benefits of moving your lab to Terraform.

**However**, resources created outside Terraform, manually-created AWS resources, resources protected from deletion, or resources with special AWS dependencies may still require manual intervention.

---

# 63. Your Final "Definition of Done"

I would consider your Terraform version of the Charlie Cafe lab complete when all of these are true:

```text
[✓] Terraform installed
[✓] AWS CLI configured
[✓] AWS identity verified
[✓] Terraform provider configured
[✓] Variables configured
[✓] terraform.tfvars configured
[✓] Secrets protected
[✓] Terraform initialized
[✓] Terraform formatted
[✓] Terraform validated
[✓] Terraform plan reviewed
[✓] Terraform apply successful
[✓] Terraform state created
[✓] Terraform outputs working
[✓] VPC verified
[✓] EC2 verified
[✓] SSM verified
[✓] Docker verified
[✓] RDS verified
[✓] Secrets Manager verified
[✓] ECR verified
[✓] ECS verified
[✓] ECS service verified
[✓] ECS tasks verified
[✓] ALB verified
[✓] Target group healthy
[✓] Application URL tested
[✓] S3 verified
[✓] CloudFront verified
[✓] Lambda verified
[✓] DynamoDB verified
[✓] WAF verified
[✓] CloudWatch verified
[✓] KMS verified
[✓] IAM verified
[✓] terraform plan = No changes
[✓] GitHub Terraform deploy workflow tested
[✓] Terraform destroy plan reviewed
[✓] Terraform destroy tested
[✓] Final AWS cleanup verified
```

---

# Best Next Step

Since you already have the **Terraform code**, I recommend **not changing the architecture again yet**. The best next move is to take your actual Terraform files (`main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, modules, etc.) and go through them **file-by-file**.

I can then give you the exact:

1. **Terraform project structure**
2. **`terraform.tfvars` configuration**
3. **AWS credentials/profile configuration**
4. **`terraform init`**
5. **`terraform validate`**
6. **`terraform plan`**
7. **`terraform apply`**
8. **exact AWS CLI verification commands matching your resources**
9. **final `verify-terraform.sh`**
10. **final `aws-terraform-deploy.yml`**
11. **final `aws-terraform-delete.yml`**
12. **complete destroy/cleanup procedure**

That will be much safer than using generic commands because I can make the verification commands match the **exact resource names and outputs in your Terraform code**.
---

