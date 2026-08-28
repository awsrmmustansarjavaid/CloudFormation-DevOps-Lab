




## Terraform directory

```
infrastructure/
│
├── aws-cloudformation/
│   ├── main-stack.yaml
│   ├── TemplateBucket-MainStack.yaml
│   ├── aws-ecs-ecr.yaml
│   │
│   └── nested/
│       ├── ec2-webserver.yaml
│       ├── aws-rds.yaml
│       └── s3.yaml
│
└── terraform/
    │
    ├── versions.tf
    ├── provider.tf
    ├── variables.tf
    ├── locals.tf
    │
    ├── network.tf
    ├── security.tf
    ├── ec2.tf
    ├── rds.tf
    ├── s3.tf
    ├── template_bucket.tf
    │
    ├── ecs_ecr.tf
    │
    ├── outputs.tf
    ├── terraform.tfvars.example
    └── .gitignore
```
## Terraform Source Code

### 1. versions.tf

This defines the Terraform and AWS provider requirements.

```

```

### 2. provider.tf

This configures AWS.

```

```

### 3. variables.tf

This contains the configurable values for the lab.

```

```

### 4. locals.tf

This avoids repeating names and makes the configuration easier to maintain.

```

```

### 5. network.tf

This converts the VPC/networking section of your main CloudFormation template.

```

```

### 6. security.tf

```

```

### 7. ec2.tf

This is where we convert the EC2 nested stack.

There are two ways to handle your bootstrap script.

I'm recommending that we preserve your current CloudFormation behavior first: EC2 downloads the script from GitHub.

```

```

#### Note about ManagedBy

Your CloudFormation EC2 had:

```
ManagedBy = CloudFormation
```

I intentionally did not retain that as an explicit resource tag because Terraform's provider-level default tags already adds:

```
ManagedBy = Terraform
```

That is the correct behavior after migration.

### 8. rds.tf

This converts your RDS nested stack.

```

```

#### Important RDS note

Your CloudFormation uses:

```
ManageMasterUserPassword: true
```

so we don't create a database password variable.

That's intentional.

### 9. s3.tf

```

```

### 10. outputs.tf

This converts your CloudFormation outputs.

```

```

### 11. terraform.tfvars.example

This file shows users what they need to configure.

Do not put real secrets in this file.

```

```

### 12. .gitignore

```
# =======================================================
# TERRAFORM GITIGNORE
# =======================================================

# -------------------------------------------------------
# Terraform working directory
# -------------------------------------------------------

.terraform/

# -------------------------------------------------------
# Terraform state files
# -------------------------------------------------------
#
# IMPORTANT:
# Terraform state can contain sensitive information.
# Never commit these files to Git.
# -------------------------------------------------------

*.tfstate
*.tfstate.*
terraform.tfstate
terraform.tfstate.backup

# -------------------------------------------------------
# Terraform variable files
# -------------------------------------------------------
#
# terraform.tfvars may contain environment-specific
# values and secrets.
# -------------------------------------------------------

*.tfvars
*.tfvars.json

# Allow the example file to be committed.

!terraform.tfvars.example

# -------------------------------------------------------
# Terraform plan files
# -------------------------------------------------------

*.tfplan
*.plan

# -------------------------------------------------------
# Terraform crash logs
# -------------------------------------------------------

crash.log
crash.*.log

# -------------------------------------------------------
# Override files
# -------------------------------------------------------

override.tf
override.tf.json
*_override.tf
*_override.tf.json

# -------------------------------------------------------
# Terraform CLI configuration
# -------------------------------------------------------

.terraformrc
terraform.rc

# -------------------------------------------------------
# OS files
# -------------------------------------------------------

.DS_Store
Thumbs.db

# -------------------------------------------------------
# Editor files
# -------------------------------------------------------

.vscode/
.idea/

# -------------------------------------------------------
# Temporary files
# -------------------------------------------------------

*.tmp
*.temp
```

# Terraform workflows

Recommended Terraform workflow architecture

I would keep the Terraform side parallel to your CloudFormation side:

```
                    GitHub Repository
                           |
             +-------------+-------------+
             |                           |
             v                           v
      CloudFormation                 Terraform
          Pipeline                   Pipeline
             |                           |
             v                           v
   CFN Infrastructure             Terraform Infrastructure
             |                           |
             v                           v
          Docker                     Docker
             |                           |
             v                           v
       ECR + ECS                  ECR + ECS
```

And specifically:

```
aws-terraform-deploy.yml
        |
        | Terraform init
        | Terraform validate
        | Terraform plan
        | Terraform apply
        v
 Terraform infrastructure
        |
        v
 aws-terraform-ecs-deploy.yml
        |
        v
      ECR
        |
        v
      ECS
```

while:

```
aws-cloudformation-deploy.yml
        |
        v
 CloudFormation infrastructure
        |
        v
aws-cloudformation-ecs-deploy.yml
        |
        v
     ECR/ECS
```

Important point about your current workflow

There is one thing I would not blindly copy into the Terraform workflows:

```
secrets: inherit
```

For a reusable workflow, this is valid when used at the caller job level, but the called workflow itself needs to declare the secrets it expects under workflow_call.

For example, the reusable Terraform ECS workflow should use something along the lines of:

```
on:
  workflow_call:
    secrets:
      AWS_ACCESS_KEY_ID:
        required: true

      AWS_SECRET_ACCESS_KEY:
        required: true

      AWS_REGION:
        required: true
```

Then the caller can use:

```
jobs:
  terraform-ecs-deploy:
    needs:
      - terraform-deploy

    uses: ./.github/workflows/aws-terraform-ecs-deploy.yml

    secrets: inherit
```

This avoids the Unexpected value 'inherit' problem you encountered earlier from putting secrets: inherit in the wrong location.

Terraform files I recommend

I would create these three files:

1. aws-terraform-deploy.yml

Purpose:

```
Checkout
   ↓
Configure AWS
   ↓
Verify AWS
   ↓
Verify Terraform
   ↓
Check Terraform files
   ↓
terraform fmt -check
   ↓
terraform init
   ↓
terraform validate
   ↓
terraform plan
   ↓
terraform apply
   ↓
Display Terraform outputs
```

This should be your main Terraform infrastructure deployment workflow.

2. aws-terraform-delete.yml

Purpose:

```
Manual workflow_dispatch
        ↓
Configure AWS
        ↓
Verify AWS
        ↓
Verify Terraform
        ↓
terraform init
        ↓
Show current state
        ↓
terraform plan -destroy
        ↓
terraform destroy
        ↓
Verify resources removed
```

I strongly recommend making Terraform destruction manual only.

For example:

```
on:
  workflow_dispatch:
```

rather than:

```
on:
  push:
    branches:
      - main
```

You don't want a normal Git push accidentally destroying your AWS infrastructure.

3. aws-terraform-ecs-deploy.yml

This should be your Terraform equivalent of:

```
aws-cloudformation-ecs-deploy.yml
```

Its responsibility should be:

```
Terraform infrastructure
        ↓
Verify ECR
        ↓
Authenticate Docker to ECR
        ↓
Build application image
        ↓
Tag image
        ↓
Push image to ECR
        ↓
Verify ECS cluster
        ↓
Verify ECS service
        ↓
Update ECS service
        ↓
Force new deployment
        ↓
Wait for ECS stability
        ↓
Verify running task
        ↓
Verify ALB target health
        ↓
Test application URL
```

That gives you a very clean architecture.

### One thing I recommend changing

Your current CloudFormation workflow has:

```
docker:
  needs: deploy
```

and then:

```
ecs-deploy:
  needs:
    - docker
```

That's perfectly reasonable.

For Terraform, I would use:

```
terraform-deploy:
```

then:

```
terraform-docker:
```

then:

```
terraform-ecs-deploy:
```

However, because you want separate files, the cleaner design is:

```
aws-terraform-deploy.yml
        |
        v
Terraform infrastructure
        |
        v
aws-terraform-ecs-deploy.yml
        |
        v
ECR + ECS
```

The Docker build/test can either remain inside the Terraform deployment workflow or be incorporated into the ECS workflow.

For your lab, I recommend keeping it in the ECS workflow because that makes the Terraform pipeline easier to understand.

### Suggested final six-file structure

Your repository will eventually look like:

```
CloudFormation-DevOps-Lab/
│
├── .github/
│   └── workflows/
│       │
│       ├── aws-cloudformation-deploy.yml
│       ├── aws-cloudformation-delete.yml
│       ├── aws-cloudformation-ecs-deploy.yml
│       │
│       ├── aws-terraform-deploy.yml
│       ├── aws-terraform-delete.yml
│       └── aws-terraform-ecs-deploy.yml
│
├── infrastructure/
│   │
│   ├── aws-cloudformation/
│   │   └── ...
│   │
│   └── terraform/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── versions.tf
│       ├── terraform.tfvars
│       └── ...
│
├── docker/
│   └── Dockerfile
│
├── docker-compose.yml
│
└── application/
    └── ...
```

Terraform workflow naming

I recommend these exact names:

| File                           | Purpose                                |
| ------------------------------ | -------------------------------------- |
| `aws-terraform-deploy.yml`     | Terraform infrastructure create/update |
| `aws-terraform-delete.yml`     | Terraform infrastructure destroy       |
| `aws-terraform-ecs-deploy.yml` | ECR image + ECS deployment             |


This is also consistent with your existing naming:

| CloudFormation                      | Terraform                      |
| ----------------------------------- | ------------------------------ |
| `aws-cloudformation-deploy.yml`     | `aws-terraform-deploy.yml`     |
| `aws-cloudformation-delete.yml`     | `aws-terraform-delete.yml`     |
| `aws-cloudformation-ecs-deploy.yml` | `aws-terraform-ecs-deploy.yml` |


Guidelines I will follow when creating them

For the Terraform workflows, I will keep the same very detailed teaching/comment style as your CloudFormation workflow.

Each workflow will contain:

# ==========================================================
clear workflow purpose
file location
architecture explanation
trigger explanation
environment variables
job explanation
step-by-step comments
AWS authentication
Terraform version
Terraform formatting check
Terraform initialization
Terraform validation
Terraform plan
Terraform apply/destroy
error handling
state handling
output handling
security notes
completion messages

And importantly, I will not mix CloudFormation logic into Terraform.

For example, the Terraform workflow should not do this:

```
aws cloudformation create-stack
```

or:

```
aws cloudformation update-stack
```

Terraform should be responsible for Terraform-managed infrastructure.

Likewise, I won't introduce an RDS password into GitHub Actions if your Terraform RDS design is also using AWS Secrets Manager.

### One more important design decision

Before I write the final three Terraform workflow files, I need to base them on your actual Terraform directory and Terraform resources rather than inventing paths, variables, stack names, ECR names, VPC variables, subnet variables, etc.

So the next thing to share is your:

```
infrastructure/terraform/
```

files, especially:

```
main.tf
providers.tf
variables.tf
outputs.tf
versions.tf
```

and any Terraform files responsible for:

```
VPC
EC2
RDS
S3
ECR
ECS
ALB
IAM
Secrets Manager
```

Once you share those, I can produce the three complete final Terraform GitHub workflow files with comments + implementation guidelines, matching your existing CloudFormation architecture instead of guessing Terraform variable names.

---
Your current GitHub Actions workflow is doing three different things:

1. Deploying AWS infrastructure with CloudFormation.
2. Building/testing Docker locally.
3. Calling a separate ECS/ECR workflow.

For Terraform, I recommend changing the architecture to:

```
GitHub Push / Manual
        |
        v
Terraform Init
        |
        v
Terraform Validate
        |
        v
Terraform Plan
        |
        v
Terraform Apply
        |
        v
AWS Infrastructure
        |
        v
Docker Build/Test
        |
        v
ECR
        |
        v
ECS Deployment
```

Also, Terraform should manage the S3 template bucket itself, rather than having a separate TemplateBucket-MainStack.yaml CloudFormation stack. Terraform does not need the nested-template upload mechanism that CloudFormation requires.

Below is the complete aws-terraform-deploy.yml I recommend.

.github/workflows/aws-terraform-deploy.yml

```

```

### Important Terraform directory structure

Your repository should now look approximately like this:

```
CharlieCafe/
│
├── .github/
│   └── workflows/
│       ├── aws-terraform-deploy.yml
│       └── aws-terraform-ecs-deploy.yml
│
├── infrastructure/
│   └── terraform/
│       │
│       ├── versions.tf
│       ├── providers.tf
│       ├── variables.tf
│       ├── main.tf
│       ├── outputs.tf
│       │
│       ├── vpc.tf
│       ├── subnets.tf
│       ├── routes.tf
│       ├── security-groups.tf
│       ├── ec2.tf
│       ├── s3.tf
│       ├── rds.tf
│       ├── iam.tf
│       └── secrets.tf
│
├── docker/
│   └── Dockerfile
│
├── docker-compose.yml
│
└── ...
```

### One important correction to the workflow

I deliberately changed this from your CloudFormation architecture:

```
TemplateBucket-MainStack.yaml
        ↓
S3 template bucket
        ↓
Nested CloudFormation templates
```

to Terraform:

```
Terraform
   |
   +---- VPC
   |
   +---- Subnets
   |
   +---- Route Tables
   |
   +---- Security Groups
   |
   +---- EC2
   |
   +---- S3
   |
   +---- RDS
   |
   +---- Secrets Manager
```

You do not need to upload .tf files to an S3 bucket for Terraform to deploy them.

Also, don't create a Terraform resource for the RDS password itself. Your RDS resource should use the AWS-managed password mechanism, conceptually:

```
resource "aws_db_instance" "mysql" {
  # ...

  manage_master_user_password = true
}
```

That preserves the security model you were using with:

```
ManageMasterUserPassword: true
```

from CloudFormation.

GitHub Secrets

At minimum, your current workflow expects:

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
KEY_PAIR_NAME
```

I recommend storing the key pair as:

```
KEY_PAIR_NAME = Lab-KeyPair
```

rather than hard-coding:

```
KEY_PAIR_NAME: Lab-KeyPair
```

So you can eventually change the workflow to:

```
env:
  AWS_REGION: us-east-1
  TERRAFORM_DIR: infrastructure/terraform
```

and pass:

```
env:
  TF_VAR_key_pair_name: ${{ secrets.KEY_PAIR_NAME }}
```

Very important: Terraform state

For your real AWS lab, do not let GitHub Actions use only local Terraform state. You should eventually use an S3 backend:

```
GitHub Actions
       |
       v
Terraform
       |
       v
S3 Terraform State
       |
       v
AWS Infrastructure
```

This is especially important because every GitHub Actions runner is temporary.

Final pipeline

Your converted architecture becomes:

```
                    GitHub
                       |
                       v
              aws-terraform-deploy.yml
                       |
             +---------+---------+
             |                   |
             v                   v
      Terraform Init       AWS Credentials
             |
             v
      Terraform Validate
             |
             v
        Terraform Plan
             |
             v
       Terraform Apply
             |
             v
       AWS Infrastructure
             |
             +----------------+
             |                |
             v                v
            RDS              EC2
             |                |
             v                v
     Secrets Manager         App
             |
             v
       Terraform Outputs
             |
             v
        Docker Job
             |
             v
       Docker Build
             |
             v
       Docker Test
             |
             v
        ECS Deploy
             |
             v
            ECR
             |
             v
            ECS
             |
             v
             ALB
```

One thing remains: your CloudFormation template contains the actual definitions of the VPC, subnets, routes, security groups, EC2, S3, RDS, IAM, etc. The workflow above only replaces the deployment mechanism. To make the conversion genuinely complete, those CloudFormation resources need to be converted into Terraform .tf files as well.

---



