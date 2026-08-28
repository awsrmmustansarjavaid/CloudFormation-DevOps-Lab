

3. Very important: check ALL Terraform files

Because this happened in two files, I strongly recommend checking the entire directory rather than fixing only these two.

From PowerShell, go to your project:

```
cd C:\Users\musta\Downloads\AWS-Labs\CloudFormation-DevOps-Lab
```

Then run:

```
Get-ChildItem .\infrastructure\terraform -Filter *.tf -File |
ForEach-Object {
    Write-Host "`n=============================================="
    Write-Host $_.FullName
    Write-Host "=============================================="

    Select-String -Path $_.FullName -Pattern '```'
}
```

If Markdown code fences exist, you will see output such as:

```
infrastructure\terraform\provider.tf:247:```
infrastructure\terraform\rds.tf:238:```
```

You should remove all those lines.

4. You can automatically remove them

If you want PowerShell to remove literal Markdown code-fence lines from all .tf files in your Terraform directory, use:

```
Get-ChildItem .\infrastructure\terraform -Filter *.tf -File |
ForEach-Object {
    $content = Get-Content $_.FullName

    $cleaned = $content |
        Where-Object { $_ -notmatch '^\s*```\s*$' }

    Set-Content -Path $_.FullName -Value $cleaned
}
```

This removes only lines that consist of Markdown triple-backticks.

It does not intentionally modify your Terraform resources, variables, providers, etc.

Then verify:

```
Get-ChildItem .\infrastructure\terraform -Filter *.tf -File |
ForEach-Object {
    Select-String -Path $_.FullName -Pattern '```'
}
```

If this command produces no output, there are no Markdown fences left in your .tf files.

5. Run Terraform formatting

Now:

```
cd .\infrastructure\terraform
```

Run:

```
terraform fmt -recursive
```

Then:

```
terraform validate
```

You want:

```
Success! The configuration is valid.
```

Then:

```
terraform plan
```

Only after these work locally should you push to GitHub.

6. Your cleanup workflow should also validate correctly

Your GitHub Actions cleanup workflow should be using:

```
TERRAFORM_WORKING_DIRECTORY: infrastructure/terraform
```

not:

```
TERRAFORM_WORKING_DIRECTORY: infrastructure/terraform/ecs
```

Your current repository structure, based on the previous error, is:

```
infrastructure/
│
├── terraform/
│   ├── provider.tf
│   ├── rds.tf
│   ├── ec2.tf
│   ├── ecs_ecr.tf
│   ├── network.tf
│   ├── security.tf
│   ├── s3.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── locals.tf
│   ├── versions.tf
│   └── template_bucket.tf
│
└── aws-cloudformation/
```

So your Terraform root is:

```
infrastructure/terraform
```

7. I recommend one additional check before pushing

Run this from the repository root:

```
terraform -chdir=infrastructure/terraform fmt -check -recursive
```

Then:

```
terraform -chdir=infrastructure/terraform validate
```

Then:

```
git status
```

Then inspect the changes:

```
git diff -- infrastructure/terraform
```

Make sure the diff contains only the removal of accidental:


and formatting changes from `terraform fmt`.

```

```

Then commit:

```powershell
git add infrastructure/terraform
git commit -m "Fix Terraform configuration formatting"
git push origin main
The key point
```

Your current failure:

```
provider.tf line 247: ```
rds.tf line 238: ```
```

means Markdown formatting was accidentally copied into the actual .tf files.

Do not change AWS credentials, IAM permissions, RDS, ECS, VPC, or the cleanup logic to solve this particular error. First remove the ``` lines and get:

```
terraform fmt
        ↓
terraform validate
        ↓
terraform plan

working locally.
```


This is a **different and much simpler problem** now. Your Terraform initialization is successful.

The failure is specifically here:

```text
TERRAFORM FORMAT CHECK

provider.tf
rds.tf

Error: Terraform exited with code 3.
```

### What this means

Your workflow currently runs:

```bash
terraform fmt -check -recursive
```

`-check` means:

> "Fail the workflow if any `.tf` file is not formatted exactly as Terraform expects."

Terraform found these two files that need formatting:

```text
provider.tf
rds.tf
```

This is **not an AWS error**, **not an IAM error**, and **not a Terraform initialization error**.

Your log proves `terraform init` succeeded and AWS provider `v6.62.0` installed successfully.

## Fix it locally

From your repository root:

```powershell
cd C:\Users\musta\Downloads\AWS-Labs\CloudFormation-DevOps-Lab
```

Run:

```powershell
terraform -chdir=infrastructure/terraform fmt -recursive
```

You should see:

```text
provider.tf
rds.tf
```

That's good. Terraform has reformatted those files.

Now run:

```powershell
terraform -chdir=infrastructure/terraform fmt -check -recursive
```

You should get **no filenames and no error**.

Then:

```powershell
terraform -chdir=infrastructure/terraform validate
```

You want:

```text
Success! The configuration is valid.
```

Then check what Terraform changed:

```powershell
git diff -- infrastructure/terraform/provider.tf infrastructure/terraform/rds.tf
```

If the changes are only formatting, commit them:

```powershell
git add infrastructure/terraform/provider.tf infrastructure/terraform/rds.tf
git commit -m "Format Terraform provider and RDS configuration"
git push origin main
```

---

## Important: commit `.terraform.lock.hcl`

Your GitHub Actions log also says:

```text
Terraform has created a lock file .terraform.lock.hcl
...
Include this file in your version control repository
```

You should commit it.

Check:

```powershell
git status
```

If you see:

```text
infrastructure/terraform/.terraform.lock.hcl
```

add it:

```powershell
git add infrastructure/terraform/.terraform.lock.hcl
```

Then:

```powershell
git add infrastructure/terraform/provider.tf
git add infrastructure/terraform/rds.tf

git commit -m "Fix Terraform formatting and lock provider version"

git push origin main
```

### Do NOT add `.terraform`

Do **not** commit:

```text
infrastructure/terraform/.terraform/
```

Your `.gitignore` should contain:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
crash.log
crash.*.log
```

But you **should commit**:

```text
.terraform.lock.hcl
```

---

# Why the workflow failed

Your pipeline is doing exactly what we asked it to do:

```text
Terraform Init
      ↓
      ✅
Terraform Format Check
      ↓
provider.tf  ← needs formatting
rds.tf       ← needs formatting
      ↓
      ❌
Terraform Validate
      ↓
skipped
Terraform Plan
      ↓
skipped
Terraform Apply
      ↓
skipped
```

So don't change the GitHub Actions workflow yet.

### The correct sequence is:

```powershell
cd C:\Users\musta\Downloads\AWS-Labs\CloudFormation-DevOps-Lab

terraform -chdir=infrastructure/terraform fmt -recursive

terraform -chdir=infrastructure/terraform fmt -check -recursive

terraform -chdir=infrastructure/terraform validate

terraform -chdir=infrastructure/terraform plan
```

If all four commands succeed, push the changes.

---

## One warning about your workflow

I would **keep** this step:

```yaml
- name: Terraform Format Check
  shell: bash
  working-directory: ${{ env.TERRAFORM_DIR }}
  run: |
    set -e

    echo "=============================================="
    echo "TERRAFORM FORMAT CHECK"
    echo "=============================================="

    terraform fmt -check -recursive

    echo ""
    echo "Terraform formatting check passed."
```

Don't replace it with:

```bash
terraform fmt -recursive
```

inside GitHub Actions.

The CI workflow should **check** formatting, while you format the files during development. That way GitHub catches formatting mistakes instead of silently modifying your repository during deployment.

### Current status

You're actually moving forward:

```text
AWS Credentials       ✅
Terraform Setup       ✅
Terraform Init        ✅
AWS Provider 6.62.0   ✅
Terraform Format      ❌ provider.tf + rds.tf
Terraform Validate    ⏭️
Terraform Plan        ⏭️
Terraform Apply       ⏭️
Docker                 ⏭️
ECR                    ⏭️
ECS                    ⏭️
```

**So the immediate fix is only `terraform fmt -recursive` on `provider.tf` and `rds.tf`, then validate and push.**

Good — you fixed the **formatting problem successfully**. The new error is straightforward.

### Current status

You now have:

```text
terraform fmt -recursive          ✅
terraform fmt -check -recursive   ✅
terraform validate                ❌
```

The validation error is:

```text
Error: Missing required provider

This configuration requires provider registry.terraform.io/hashicorp/aws,
but that provider isn't available.
```

This happened because `terraform validate` is being run **after the local `.terraform` provider installation is missing/stale**.

Your GitHub Actions run had already proven that `terraform init` successfully installs:

```text
hashicorp/aws v6.62.0
```

So locally, simply run `terraform init` again.

## Run these commands now

From your current directory:

```powershell
terraform -chdir=infrastructure/terraform init
```

You should see something similar to:

```text
Initializing the backend...
Initializing provider plugins...
- Reusing previous version of hashicorp/aws...
- Using previously-installed hashicorp/aws...
Terraform has been successfully initialized!
```

Then:

```powershell
terraform -chdir=infrastructure/terraform validate
```

You should get:

```text
Success! The configuration is valid.
```

Then run:

```powershell
terraform -chdir=infrastructure/terraform plan
```

---

## About your `git diff`

The diff you showed is exactly what `terraform fmt` was supposed to fix:

```diff
-provider "aws" {
-
-# -----------------------------------------------------
-# AWS REGION
+provider "aws" {
+
+  # -----------------------------------------------------
+  # AWS REGION
```

That's normal Terraform formatting.

Your `terraform fmt -check -recursive` returning **nothing** is actually a success:

```text
PS> terraform -chdir=infrastructure/terraform fmt -check -recursive
PS>
```

No output + exit code 0 = all files are correctly formatted.

---

## The `w` error

This:

```text
PS> w
w : The term 'w' is not recognized...
```

is completely unrelated. You accidentally typed `w` at the PowerShell prompt.

You can ignore it.

---

# Do this exact sequence

I recommend running the following **in this exact order**:

```powershell
cd C:\Users\musta\Downloads\AWS-Labs\CloudFormation-DevOps-Lab

terraform -chdir=infrastructure/terraform init

terraform -chdir=infrastructure/terraform fmt -check -recursive

terraform -chdir=infrastructure/terraform validate

terraform -chdir=infrastructure/terraform plan
```

### Expected progression

```text
INIT
  ↓
  ✅

FORMAT CHECK
  ↓
  ✅

VALIDATE
  ↓
  ✅

PLAN
  ↓
  ✅
```

If `validate` succeeds but `plan` fails, **don't change anything yet**. Send me the complete `terraform plan` error because that will be the next actual Terraform/AWS configuration issue.

---

## Then check your Git changes

After the commands succeed:

```powershell
git status
```

You should expect changes to:

```text
infrastructure/terraform/provider.tf
infrastructure/terraform/rds.tf
```

and potentially:

```text
infrastructure/terraform/.terraform.lock.hcl
```

The lock file should normally be committed:

```powershell
git add infrastructure/terraform/provider.tf
git add infrastructure/terraform/rds.tf
git add infrastructure/terraform/.terraform.lock.hcl
```

Then:

```powershell
git commit -m "Format Terraform configuration and update provider lock"
git push origin main
```

**Don't commit the `.terraform` directory.**

The important thing right now is: **run `terraform init` locally, then `validate`, then `plan`.** Your formatting issue is already fixed.

Yes — you have now identified **two separate issues**, and the important one blocking `terraform plan` is very clear.

## 1. Terraform `fmt` problem is fixed

Your GitHub Actions failure was:

```text
TERRAFORM FORMAT CHECK
provider.tf
rds.tf
Error: Terraform exited with code 3.
```

You ran:

```powershell
terraform -chdir=infrastructure/terraform fmt -recursive
```

and Terraform formatted:

```text
provider.tf
rds.tf
```

Then:

```powershell
terraform -chdir=infrastructure/terraform fmt -check -recursive
```

returned nothing, which means:

**✅ Terraform formatting is now clean.**

You should commit those formatting changes:

```powershell
git add infrastructure/terraform/provider.tf infrastructure/terraform/rds.tf
git commit -m "Format Terraform configuration"
```

Then push:

```powershell
git push
```

---

# 2. Terraform `validate` is also successful

After initializing the provider:

```powershell
terraform -chdir=infrastructure/terraform init
```

you ran:

```powershell
terraform -chdir=infrastructure/terraform validate
```

and received:

```text
Success! The configuration is valid, but there were some validation warnings as shown above.
```

So:

**✅ Terraform configuration syntax is valid.**

The warnings are not currently stopping deployment.

---

# 3. The actual blocking error is `key_pair_name`

This is the important part:

```text
Error: Invalid value for variable

var.key_pair_name is ""

key_pair_name must contain the name of an existing EC2 Key Pair.
```

Your `variables.tf` has a validation rule around line 418–424 that requires:

```text
key_pair_name
```

to contain an **existing EC2 Key Pair name**.

But Terraform is currently receiving:

```text
key_pair_name = ""
```

Therefore:

```text
terraform plan
```

fails.

---

# 4. Why is this happening?

Your Terraform lab appears to have an EC2 component that requires an EC2 key pair.

Terraform therefore expects something like:

```text
CharlieCafe-TF-KeyPair
```

But your current variable value is empty.

Most likely you have something similar to:

```hcl
variable "key_pair_name" {
  description = "Existing EC2 Key Pair name"
  type        = string
  default     = ""

  validation {
    condition     = ...
    error_message = "key_pair_name must contain the name of an existing EC2 Key Pair."
  }
}
```

The exact problem is therefore **not AWS provider, not Terraform formatting, and not Terraform syntax**.

It is the missing EC2 key-pair input.

---

# 5. First check your existing EC2 Key Pairs

Because your lab is using `us-east-1`, run:

```powershell
aws ec2 describe-key-pairs `
  --region us-east-1 `
  --query "KeyPairs[*].KeyName" `
  --output table
```

You should get something like:

```text
-------------------------
|    DescribeKeyPairs   |
+-----------------------+
|  CharlieCafe-KeyPair  |
|  my-aws-key           |
+-----------------------+
```

**Do not create a new key pair yet.**

First see what already exists.

---

# 6. If you already have a key pair

Suppose the command returns:

```text
CharlieCafe-KeyPair
```

Then you need to pass that value to Terraform.

### Option A — Recommended for your GitHub Actions lab

Set the Terraform variable through GitHub Actions:

```text
TF_VAR_key_pair_name
```

For example:

```yaml
env:
  TF_VAR_key_pair_name: ${{ secrets.TF_KEY_PAIR_NAME }}
```

Then create a GitHub repository secret:

```text
TF_KEY_PAIR_NAME
```

with the value:

```text
CharlieCafe-KeyPair
```

This is better than hardcoding your personal AWS key-pair name into the Terraform source.

---

# 7. For local testing right now

Since you are testing on PowerShell, you can temporarily set:

```powershell
$env:TF_VAR_key_pair_name="CharlieCafe-KeyPair"
```

Replace `CharlieCafe-KeyPair` with the **actual key pair returned by your AWS CLI command**.

Then run:

```powershell
terraform -chdir=infrastructure/terraform plan
```

---

# 8. Verify that the key pair actually exists

Before running `plan`, you can verify the exact name:

```powershell
aws ec2 describe-key-pairs `
  --key-names "CharlieCafe-KeyPair" `
  --region us-east-1
```

If it exists, AWS will return its information.

If it doesn't exist, AWS will return an error.

---

# 9. Important: Don't put the `.pem` file into Terraform

You **do not** need to provide Terraform with:

```text
C:\Users\musta\Downloads\CharlieCafe-KeyPair.pem
```

The Terraform EC2 resource needs the **AWS EC2 Key Pair name**, not the private-key file.

For example:

```hcl
key_name = var.key_pair_name
```

The value is:

```text
CharlieCafe-KeyPair
```

not:

```text
CharlieCafe-KeyPair.pem
```

---

# 10. There is another issue I noticed

Your `terraform plan` shows:

```text
aws_security_group.rds
```

with:

```text
description = "Allow MySQL from CharlieCafe-TF EC2 only"
```

and:

```text
description = "Allow MySQL access only from EC2 Web Security Group"
```

But the plan output you pasted does **not** show an EC2 instance being created among the 39 resources.

That deserves checking.

Your RDS security group appears to expect traffic from an EC2 Web Security Group, while your current plan seems to contain:

```text
aws_security_group.web
```

but no obvious:

```text
aws_instance
```

So before deployment, I would verify whether your Terraform conversion intentionally removed the EC2 resource or whether it is defined conditionally.

Run:

```powershell
terraform -chdir=infrastructure/terraform state list
```

Since this is a new configuration, it may currently be empty, but that's okay.

More importantly, run:

```powershell
Get-ChildItem infrastructure\terraform -Filter *.tf |
  Select-Object -ExpandProperty FullName
```

and:

```powershell
Get-ChildItem infrastructure\terraform -Filter *.tf |
  Select-String -Pattern 'aws_instance|key_pair_name|key_name'
```

That will tell us exactly **where the EC2/key-pair dependency comes from**.

---

# 11. The deprecation warnings are a separate cleanup

You also have:

```text
data.aws_region.current.name
```

and Terraform says:

```text
name is deprecated. Use region instead.
```

For example, you currently have:

```hcl
service_name = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
```

Modernize it to:

```hcl
service_name = "com.amazonaws.${data.aws_region.current.region}.ecr.api"
```

You have several occurrences.

Find all of them:

```powershell
Get-ChildItem infrastructure\terraform -Filter *.tf |
  Select-String -Pattern 'data\.aws_region\.current\.name'
```

You will probably see the 12 occurrences that Terraform reported.

You can replace:

```text
data.aws_region.current.name
```

with:

```text
data.aws_region.current.region
```

Then run:

```powershell
terraform -chdir=infrastructure/terraform fmt -recursive
```

and:

```powershell
terraform -chdir=infrastructure/terraform validate
```

The warnings should disappear.

---

# 12. Your correct troubleshooting sequence now

I recommend **not changing anything else yet**.

Run these commands in this exact order:

### Step 1 — Find your EC2 key pair

```powershell
aws ec2 describe-key-pairs `
  --region us-east-1 `
  --query "KeyPairs[*].KeyName" `
  --output table
```

### Step 2 — Set the existing key pair temporarily

Example:

```powershell
$env:TF_VAR_key_pair_name="YOUR-ACTUAL-KEY-PAIR-NAME"
```

### Step 3 — Validate

```powershell
terraform -chdir=infrastructure/terraform validate
```

### Step 4 — Plan

```powershell
terraform -chdir=infrastructure/terraform plan
```

---

## Current status

Your Terraform pipeline is now essentially at this point:

```text
Terraform fmt
      │
      ▼
    PASS ✅
      │
      ▼
Terraform init
      │
      ▼
    PASS ✅
      │
      ▼
Terraform validate
      │
      ▼
    PASS ✅
      │
      ▼
Terraform plan
      │
      ├── Deprecated warnings ⚠️
      │
      └── key_pair_name = "" ❌
                    │
                    ▼
             PLAN STOPS
```

So **don't modify the architecture yet**.

The immediate fix is to provide the name of an existing EC2 Key Pair.

**Run the `describe-key-pairs` command above and paste its output here.** Then I can tell you exactly what value to use and, after that, we can fix the GitHub Actions workflow so it receives `TF_VAR_key_pair_name` automatically rather than relying on your local PowerShell environment.
---

3. Verify there are no old references

After saving both files, run:

```
cd "C:\Users\musta\Downloads\AWS-Labs\CloudFormation-DevOps-Lab"

Get-ChildItem -Path .\infrastructure\terraform -Recurse -Filter *.tf |
    Select-String -Pattern 'data\.aws_region\.current\.name'
```

Expected result:

No output

Then check the new references:

```
Get-ChildItem -Path .\infrastructure\terraform -Recurse -Filter *.tf |
    Select-String -Pattern 'data\.aws_region\.current\.region'
```

You should see the six expected references.

4. Format Terraform

Run:

```
terraform -chdir=infrastructure/terraform fmt
```

Then:

```
terraform -chdir=infrastructure/terraform validate
```

Expected:

```
Success! The configuration is valid.
```

Then run:

```
terraform -chdir=infrastructure/terraform plan
```

You should no longer get:

```
Warning: Deprecated value used

name is deprecated. Use region instead.
```

---
### 1. First verify there are no .name references left

Run this from your project root:

```
cd "C:\Users\musta\Downloads\AWS-Labs\CloudFormation-DevOps-Lab"

Get-ChildItem -Path .\infrastructure\terraform -Recurse -Filter *.tf |
    Select-String -Pattern 'data\.aws_region\.current\.name'
```

Expected result:

```
No output
```

If you get no output, you have successfully removed the deprecated references.

### 2. Then format and validate

Run:

```
terraform -chdir=infrastructure/terraform fmt -recursive
```

Then:

```
terraform -chdir=infrastructure/terraform validate
```

You want:

```
Success! The configuration is valid.
```

### 3. Run the plan again

Because your previous plan showed:

```
Plan: 40 to add, 0 to change, 0 to destroy.
```

run:

```
terraform -chdir=infrastructure/terraform plan
```

If everything is correct, you should still see approximately:

```
Plan: 40 to add, 0 to change, 0 to destroy.
```

but the deprecated warning should disappear.

---
### Current status

I would not make more changes just because of this plan. The configuration has passed validation, and the plan is internally consistent.

Before applying, I recommend running:

```
terraform -chdir=infrastructure/terraform plan -out=tfplan
```

Then, if the displayed plan is exactly what you expect:

```
terraform -chdir=infrastructure/terraform apply tfplan
```

This is safer than running a fresh apply after the plan because Terraform will apply the saved plan.

---
## Best solution for your lab

If these existing resources are the resources you want Terraform to manage, import them into Terraform state.

You need to do this once.

### 1. Check Terraform state first

From your local project:

```
terraform -chdir=infrastructure/terraform state list
```

Look for:

```
aws_iam_role.ecs_task_execution
aws_iam_role.ecs_task
aws_lb.charlie_cafe
aws_lb_target_group.charlie_cafe
aws_db_subnet_group.mysql
```

If they are missing from the state, that confirms the problem.

2. Find the ALB ARN

Run:

```
aws elbv2 describe-load-balancers `
  --names CharlieCafe-TF-ALB `
  --region us-east-1 `
  --query "LoadBalancers[0].LoadBalancerArn" `
  --output text
```

Copy the returned ARN.

Then import:

```
terraform -chdir=infrastructure/terraform import `
  aws_lb.charlie_cafe `
  <ALB-ARN>
```

3. Find the Target Group ARN

```
aws elbv2 describe-target-groups `
  --names CharlieCafe-TF-TG `
  --region us-east-1 `
  --query "TargetGroups[0].TargetGroupArn" `
  --output text
```
Then:

```
terraform -chdir=infrastructure/terraform import `
  aws_lb_target_group.charlie_cafe `
  <TARGET-GROUP-ARN>
```

4. Import the IAM roles

For the execution role:

```
terraform -chdir=infrastructure/terraform import `
  aws_iam_role.ecs_task_execution `
  CharlieCafe-TF-ECSTaskExecutionRole
```

For the task role:

```
terraform -chdir=infrastructure/terraform import `
  aws_iam_role.ecs_task `
  CharlieCafe-TF-ECSTaskRole
```
5. Import the RDS subnet group

```
terraform -chdir=infrastructure/terraform import `
  aws_db_subnet_group.mysql `
  charliecafe-tf-rds-subnet-group
```

6. Verify the state

Run:

```
terraform -chdir=infrastructure/terraform state list
```

You should now see:

```
aws_iam_role.ecs_task_execution
aws_iam_role.ecs_task
aws_lb.charlie_cafe
aws_lb_target_group.charlie_cafe
aws_db_subnet_group.mysql
```
Then:

```
terraform -chdir=infrastructure/terraform plan
```

### What I recommend for your CharlieCafe Terraform lab

Before changing any .tf code, let's check three things:

```
terraform -chdir=infrastructure/terraform state list
terraform -chdir=infrastructure/terraform show
```

and:

```
terraform -chdir=infrastructure/terraform init
```

Then we can determine whether your Terraform state is missing these 5 resources or whether there is another state/backend problem.

---
### Step 1 — Find your existing EC2 key pairs

Run:

```
aws ec2 describe-key-pairs `
  --region us-east-1 `
  --query "KeyPairs[].KeyName" `
  --output table
```

You should get something like:

```
-----------------------
|    DescribeKeyPairs |
+---------------------+
| CharlieCafe-KeyPair |
| my-key              |
+---------------------+
```

### Step 2 — Check what Terraform currently has

Run:

```
terraform -chdir=infrastructure/terraform console
```

Then:

```
var.key_pair_name
```

It will probably return:

```
""
```

Exit:

```
exit
```


----
Before changing anything, let's inspect the Terraform configuration

I don't want you deleting state blindly.

Please run these commands from:

```
C:\Users\musta\Downloads\AWS-Labs\CloudFormation-DevOps-Lab
```

Command 1

```
terraform -chdir=infrastructure/terraform state list
```

Command 2

```
terraform -chdir=infrastructure/terraform state show aws_lb_target_group.charlie_cafe
```


Command 3

```
terraform -chdir=infrastructure/terraform state show aws_db_subnet_group.mysql
```

Command 4

```
aws rds describe-db-instances `
  --region us-east-1 `
  --query "DBInstances[].{Identifier:DBInstanceIdentifier,Status:DBInstanceStatus,VPC:DBSubnetGroup.VpcId,SubnetGroup:DBSubnetGroup.DBSubnetGroupName}" `
  --output table
```

Command 5

```
aws ecs list-clusters `
  --region us-east-1 `
  --query "clusterArns[]" `
  --output table
```



---