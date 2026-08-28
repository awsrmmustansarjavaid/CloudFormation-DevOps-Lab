## Create a temporary/admin policy for github-ci-cd-user

You need to give github-ci-cd-user permission to run:

```
iam:PutRolePolicy
```

If you also need to manage this CloudFormation service role's inline policies later, I recommend allowing the related actions:

```
iam:PutRolePolicy
iam:GetRolePolicy
iam:DeleteRolePolicy
iam:ListRolePolicies
```

### Create this file in your project directory:

```
C:\Users\musta\Downloads\AWS-Labs\CloudFormation-DevOps-Lab\iam-policies\github-ci-cd-iam-management-policy.json
```

Put:

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ManageCharlieCafeCloudFormationRoleInlinePolicies",
      "Effect": "Allow",
      "Action": [
        "iam:PutRolePolicy",
        "iam:GetRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:ListRolePolicies"
      ],
      "Resource": "arn:aws:iam::type-your-aws-id-here:role/CharlieCafe-CloudFormation-ServiceRole"
    }
  ]
}
```

However, you cannot attach this policy to github-ci-cd-user using that same user unless the user already has permission to manage its own IAM policies.

So you have two options.

#### Option A — use an admin IAM identity

Sign in/configure AWS CLI with an administrator IAM identity, then attach the permission to github-ci-cd-user.

For example:

```
aws iam put-user-policy `
  --user-name github-ci-cd-user `
  --policy-name CharlieCafe-IAM-RolePolicyManagement `
  --policy-document file://C:/Users/musta/Downloads/AWS-Labs/CloudFormation-DevOps-Lab/iam-policies/github-ci-cd-iam-management-policy.json
```

Recommended PowerShell version

Using forward slashes is usually the simplest approach with AWS CLI:

```
aws iam put-user-policy `
  --user-name github-ci-cd-user `
  --policy-name CharlieCafe-IAM-RolePolicyManagement `
  --policy-document file://C:/Users/musta/Downloads/AWS-Labs/CloudFormation-DevOps-Lab/iam-policies/github-ci-cd-iam-management-policy.json
```

Or, since your current PowerShell directory appears to be:

```
C:\Users\musta\Downloads\AWS-Labs\CloudFormation-DevOps-Lab
```

you can use the relative path, which is cleaner:

```
aws iam put-user-policy `
  --user-name github-ci-cd-user `
  --policy-name CharlieCafe-IAM-RolePolicyManagement `
  --policy-document file://iam-policies/github-ci-cd-iam-management-policy.json
```

I recommend the relative-path version because it will continue working if you move the entire CloudFormation-DevOps-Lab project to another location.

Then verify:

```
aws iam list-user-policies `
  --user-name github-ci-cd-user
```

After that, your original command should work:

```
aws iam put-role-policy `
  --role-name CharlieCafe-CloudFormation-ServiceRole `
  --policy-name CharlieCafe-ECS-CloudFormation-Validation `
  --policy-document file://iam-policies/github-ci-cd-iam-management-policy.json
```

#### Option B — use AWS Console with an administrator

If you don't have another CLI identity, use an administrator account in the AWS IAM console.

Go to:

```
IAM → Users → github-ci-cd-user → Permissions → Add permissions → Create inline policy
```

Use the JSON above.

Then return to PowerShell and run your put-role-policy command again.

### After attaching the permission

Run:

```
aws iam put-role-policy `
  --role-name CharlieCafe-CloudFormation-ServiceRole `
  --policy-name CharlieCafe-ECS-CloudFormation-Validation `
  --policy-document file://cloudformation-ecs-validation-policy.json
```

Then verify:

```
aws iam list-role-policies `
  --role-name CharlieCafe-CloudFormation-ServiceRole
```

You should see:

```
CharlieCafe-ECS-CloudFormation-Validation
```

One important point: if github-ci-cd-user is intentionally your restricted GitHub CI/CD user, don't permanently give it broad IAM administration permissions. We can instead create a very narrowly scoped permission specifically for the CloudFormation role and the exact inline policies your GitHub workflow needs.

---
---

## Create a CharlieCafe-CloudFormation-Service

Add this inline policy to CharlieCafe-CloudFormation-ServiceRole

This is a practical policy for your Charlie Cafe ECS deployment and includes the CloudFormation early-validation permissions plus ECS/ECR/VPC/EC2/IAM read permissions.

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CloudFormationValidationRead",
      "Effect": "Allow",
      "Action": [
        "cloudformation:DescribeStacks",
        "cloudformation:DescribeStackEvents",
        "cloudformation:DescribeStackResources",
        "cloudformation:DescribeChangeSet",
        "cloudformation:GetTemplate",
        "cloudformation:ValidateTemplate",
        "cloudwatch:GetMetricData",
        "lambda:GetAccountSettings",
        "servicequotas:GetServiceQuota",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeRouteTables",
        "ec2:DescribeInternetGateways",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeNetworkInterfaces",
        "iam:GetAccountSummary",
        "iam:GetRole",
        "iam:GetRolePolicy",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "config:ListConfigurationRecorders",
        "s3:ListAllMyBuckets",
        "s3:ListBucket",
        "s3:ListBucketVersions",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:DescribeImages"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ECSReadAccess",
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeClusters",
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeTasks",
        "ecs:ListClusters",
        "ecs:ListServices",
        "ecs:ListTaskDefinitions",
        "ecs:ListTasks"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ECRAccess",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:DescribeRepositories",
        "ecr:DescribeImages",
        "ecr:ListImages"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EC2NetworkReadAccess",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeImages",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeRouteTables",
        "ec2:DescribeInternetGateways",
        "ec2:DescribeNatGateways",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeVpcEndpoints",
        "ec2:DescribeTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "S3ReadAccess",
      "Effect": "Allow",
      "Action": [
        "s3:ListAllMyBuckets",
        "s3:ListBucket",
        "s3:ListBucketVersions",
        "s3:GetBucketLocation",
        "s3:GetBucketVersioning",
        "s3:GetBucketPolicy",
        "s3:GetBucketAcl",
        "s3:GetObject",
        "s3:GetObjectVersion"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMReadAccess",
      "Effect": "Allow",
      "Action": [
        "iam:GetRole",
        "iam:GetRolePolicy",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:GetInstanceProfile",
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:ListPolicies",
        "iam:ListInstanceProfiles"
      ],
      "Resource": "*"
    }
  ]
}
```

PowerShell — attach it

Save the JSON as:

```
cloudformation-ecs-validation-policy.json
```

Then run:

```
aws iam put-role-policy `
  --role-name CharlieCafe-CloudFormation-ServiceRole `
  --policy-name CharlieCafe-ECS-CloudFormation-Validation `
  --policy-document file://iam-policies/cloudformation-ecs-validation-policy.json
```

Verify:

```
aws iam get-role-policy `
  --role-name CharlieCafe-CloudFormation-ServiceRole `
  --policy-name CharlieCafe-ECS-CloudFormation-Validation
```

Very important: your GitHub IAM user also needs iam:PassRole

There are two different IAM permission layers here.

Your GitHub Actions identity creates the CloudFormation change set, while CloudFormation assumes CharlieCafe-CloudFormation-ServiceRole to operate the stack. AWS explicitly requires the calling principal to have iam:PassRole when using a CloudFormation service role.

Therefore, on your GitHub Actions user/role, add:

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PassCharlieCafeCloudFormationRole",
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "arn:aws:iam::*:role/CharlieCafe-CloudFormation-ServiceRole"
    }
  ]
}
```

For your github-ci-cd-user, this is the important distinction:

```
GitHub Actions
     |
     | iam:PassRole
     v
CharlieCafe-CloudFormation-ServiceRole
     |
     | CloudFormation resource permissions
     v
ECS / ECR / EC2 / VPC / S3 / IAM / etc.
```

Also check the trust policy

Your CloudFormation role's trust policy must allow CloudFormation to assume it. It should contain cloudformation.amazonaws.com. AWS documents this requirement for CloudFormation service roles.

For example:

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudformation.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

Do not put Principal in an inline permissions policy. Principal belongs in the role's trust/assume-role policy. Your earlier IAM error about Has prohibited field Principal was caused by mixing these two policy types.

---

## Merged policy for your Charlie Cafe lab

Based strictly on the permissions you supplied, I would merge them into this policy.

Create:

```
charlie-cafe-cloudformation-terraform-policy.json
```

Put

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EC2Access",
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ECRAccess",
      "Effect": "Allow",
      "Action": [
        "ecr:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ECSAccess",
      "Effect": "Allow",
      "Action": [
        "ecs:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ElasticLoadBalancingAccess",
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchLogsAccess",
      "Effect": "Allow",
      "Action": [
        "logs:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "S3Access",
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:PutBucketVersioning",
        "s3:TagResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "RDSAccess",
      "Effect": "Allow",
      "Action": [
        "rds:CreateDBSnapshot",
        "rds:CreateDBInstance",
        "rds:CreateDBSubnetGroup",
        "rds:DescribeDBInstances",
        "rds:DescribeDBSubnetGroups",
        "rds:ModifyDBInstance",
        "rds:ModifyDBSubnetGroup",
        "rds:DeleteDBInstance",
        "rds:DeleteDBSubnetGroup",
        "rds:AddTagsToResource",
        "rds:ListTagsForResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SecretsManagerAccess",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:CreateSecret",
        "secretsmanager:DescribeSecret",
        "secretsmanager:TagResource",
        "secretsmanager:PutSecretValue",
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "*"
    },
    {
      "Sid": "KMSAccess",
      "Effect": "Allow",
      "Action": [
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:CreateGrant"
      ],
      "Resource": "*"
    },
    {
      "Sid": "LambdaAccess",
      "Effect": "Allow",
      "Action": [
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:PublishLayerVersion",
        "lambda:GetFunction",
        "lambda:ListFunctions"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SSMAccess",
      "Effect": "Allow",
      "Action": [
        "ssm:SendCommand",
        "ssm:GetCommandInvocation"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EC2DescribeAccess",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMRoleManagement",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:PassRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:CreateServiceLinkedRole"
      ],
      "Resource": "*"
    }
  ]
}
```

But there is a major caveat

This is a broad lab policy, not a least-privilege production policy.

For example:

```
"ec2:*"
```

and:

```
"ecs:*"
```

and:

```
"ecr:*"
```

give extremely broad access.

AWS recommends working backward from the CloudFormation templates and restricting the service role to only the actions/resources required.

For your hands-on Charlie Cafe lab, however, this can be useful while you're getting the deployment working.

6. Create the IAM role

From PowerShell:

```
aws iam create-role `
  --role-name CharlieCafe-CloudFormation-ServiceRole `
  --assume-role-policy-document file://iam-policies/cloudformation-trust-policy.json `
  --description "CloudFormation service role for Charlie Cafe infrastructure"
```

AWS CLI creates the role first and then permissions can be assigned to it.

7. Attach the merged inline policy

Run:

```
aws iam put-role-policy `
  --role-name CharlieCafe-CloudFormation-ServiceRole `
  --policy-name CharlieCafe-CloudFormation-Terraform-InlinePolicy `
  --policy-document file://iam-policies/charlie-cafe-cloudformation-terraform-policy.json
```

This creates an inline policy directly inside the role.

AWS supports embedding an inline policy in an IAM role using PutRolePolicy.

8. Verify the role

Run:

```
aws iam get-role `
  --role-name CharlieCafe-CloudFormation-ServiceRole
```

Then:

```
aws iam list-role-policies `
  --role-name CharlieCafe-CloudFormation-ServiceRole
```

You should see:

```
CharlieCafe-CloudFormation-Terraform-InlinePolicy
```

To inspect the actual policy:

```
aws iam get-role-policy `
  --role-name CharlieCafe-CloudFormation-ServiceRole `
  --policy-name CharlieCafe-CloudFormation-Terraform-InlinePolicy
```

9. Very important: your GitHub Actions user needs PassRole

Your GitHub Actions IAM principal needs permission to pass this role to CloudFormation.

For example:

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PassCharlieCafeCloudFormationRole",
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "arn:aws:iam::YOUR_ACCOUNT_ID:role/CharlieCafe-CloudFormation-ServiceRole"
    }
  ]
}
```

Replace:

```
YOUR_ACCOUNT_ID
```

with your AWS account ID.

AWS explicitly requires the principal creating/using the CloudFormation stack with a service role to have permission to pass that role.

10. Then your CloudFormation deployment can use the role

For example:

```
aws cloudformation deploy `
  --template-file template.yaml `
  --stack-name CharlieCafe-Stack `
  --capabilities CAPABILITY_NAMED_IAM `
  --role-arn arn:aws:iam::YOUR_ACCOUNT_ID:role/CharlieCafe-CloudFormation-ServiceRole
```

The important architecture becomes:

```
GitHub Actions
      |
      | iam:PassRole
      v
CloudFormation
      |
      | sts:AssumeRole
      v
CharlieCafe-CloudFormation-ServiceRole
      |
      +---- EC2
      +---- VPC
      +---- ECS
      +---- ECR
      +---- ALB
      +---- RDS
      +---- S3
      +---- Lambda
      +---- Secrets Manager
      +---- KMS
      +---- CloudWatch Logs
      +---- IAM
```

CloudFormation then uses the service role's credentials when performing stack operations.

11. Can Terraform use this same role?
Technically: YES.

Terraform doesn't care that the policy was originally designed for CloudFormation.

For example, if Terraform assumes this role, Terraform receives these permissions:

```
EC2
ECS
ECR
ALB
RDS
S3
IAM
Lambda
KMS
Secrets Manager
CloudWatch Logs
SSM
```

So the permissions policy can be shared.

But there is a problem

Your trust policy currently says:

```
"Principal": {
  "Service": "cloudformation.amazonaws.com"
}
```

Therefore:

```
CloudFormation → allowed
Terraform     → not allowed
```

Terraform cannot simply assume this role because the role trusts CloudFormation only.

12. What I recommend for your project

Since you are working with both:

CloudFormation
Terraform
GitHub Actions

I recommend not combining the trust relationships into one production role.

Use:

```
CharlieCafe-CloudFormation-ServiceRole
        |
        +-- CloudFormation trust
        |
        +-- CloudFormation permissions
```

and:

```
CharlieCafe-Terraform-ServiceRole
        |
        +-- Terraform/GitHub trust
        |
        +-- Terraform permissions
```

You can even use the same merged permissions document for both roles if this is a lab.

That gives you:

```
                    ┌─────────────────────────────┐
                    │ Shared Charlie Cafe Policy  │
                    │                             │
                    │ EC2 / ECS / ECR / RDS / S3 │
                    │ IAM / ALB / Lambda / KMS   │
                    │ Secrets / Logs / SSM        │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
                    ▼                             ▼
     CloudFormation Service Role          Terraform Service Role
     ──────────────────────────           ──────────────────────
     CloudFormation trust                 Terraform/GitHub trust
```

This is cleaner than allowing CloudFormation and Terraform to assume the exact same role.

13. One more thing: your current policy may still fail CloudFormation

This is important for your Charlie Cafe deployment.

Your S3 policy only contains:

```
s3:CreateBucket
s3:PutBucketVersioning
s3:TagResource
```

If your CloudFormation template deletes an S3 bucket, CloudFormation may need additional S3 permissions.

Similarly, your Lambda permissions contain:

```
lambda:UpdateFunctionCode
lambda:UpdateFunctionConfiguration
lambda:PublishLayerVersion
lambda:GetFunction
lambda:ListFunctions
```

but not:

```
lambda:CreateFunction
lambda:DeleteFunction
```

So if your CloudFormation template actually creates/deletes Lambda functions, this policy won't be sufficient.

The same principle applies to Secrets Manager, RDS snapshots, IAM policies, ECS, etc.

CloudFormation's service role must contain the permissions necessary for every resource operation performed by the template. AWS specifically recommends deriving those permissions from the resources and operations in your templates.

My recommendation for your Charlie Cafe lab

Don't blindly attach all seven original policies.

Use:

Role

```
CharlieCafe-CloudFormation-ServiceRole
```

Trust

```
cloudformation.amazonaws.com
```

First: create the role without the huge policy

Create

```
cloudformation-trust-policy.json
```

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudformation.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

Then:

```
aws iam create-role `
  --role-name CharlieCafe-CloudFormation-ServiceRole `
  --assume-role-policy-document file://cloudformation-trust-policy.json `
  --description "CloudFormation service role for Charlie Cafe"
```

One merged inline policy

```
CharlieCafe-CloudFormation-Terraform-InlinePolicy
```

GitHub Actions principal

```
iam:PassRole
```


Terraform

Use a separate Terraform role with the same/expanded permissions but an appropriate Terraform/GitHub trust relationship.

And do not put Principal in the inline permissions policy. Principal belongs in the role's trust policy. AWS's documented CloudFormation service-role trust policy follows exactly this separation.

If your goal is to get your current Charlie Cafe CloudFormation GitHub Actions deployment working, I would actually expand the merged policy one more time based on your actual CloudFormation templates so it includes the missing Create/Delete/Describe/Modify actions instead of waiting for one permission error at a time.


### attach iam role with github-ci-cd-user

1. Get your AWS Account ID

```
aws sts get-caller-identity --query Account --output text
```

Suppose it returns:

```
123456789012
```

2. Create github-ci-cd-passrole-policy.json

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PassCharlieCafeCloudFormationRole",
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "arn:aws:iam::123456789012:role/CharlieCafe-CloudFormation-ServiceRole"
    }
  ]
}
```

Replace 123456789012 with your actual account ID.

3. Attach it to github-ci-cd-user

Since you're using PowerShell:

```
aws iam put-user-policy `
  --user-name github-ci-cd-user `
  --policy-name CharlieCafe-CloudFormation-PassRole `
  --policy-document file://iam-policies/github-ci-cd-passrole-policy.json
```

If your file is in:

```
C:\Users\musta\Downloads\AWS-Labs\CloudFormation-DevOps-Lab\iam-policies\
```

then the command can be:

```
aws iam put-user-policy `
  --user-name github-ci-cd-user `
  --policy-name CharlieCafe-CloudFormation-PassRole `
  --policy-document file://C:\Users\musta\Downloads\AWS-Labs\CloudFormation-DevOps-Lab\iam-policies\github-ci-cd-passrole-policy.json
```

4. Verify

```
aws iam list-user-policies `
  --user-name github-ci-cd-user
```

You should see:

```
CharlieCafe-CloudFormation-PassRole
```

Then inspect it:

```
aws iam get-user-policy `
  --user-name github-ci-cd-user `
  --policy-name CharlieCafe-CloudFormation-PassRole
```

5. Use the role in CloudFormation

Your GitHub Actions command should specify:

```
--role-arn arn:aws:iam::YOUR_ACCOUNT_ID:role/CharlieCafe-CloudFormation-ServiceRole
```

For example:

```
aws cloudformation deploy `
  --template-file main.yaml `
  --stack-name CharlieCafe-Stack `
  --capabilities CAPABILITY_NAMED_IAM `
  --role-arn arn:aws:iam::123456789012:role/CharlieCafe-CloudFormation-ServiceRole
```

The relationship is therefore:

```
github-ci-cd-user
       |
       | iam:PassRole
       v
CharlieCafe-CloudFormation-ServiceRole
       |
       | assumed by CloudFormation
       v
CloudFormation
       |
       +-- ECS
       +-- ECR
       +-- EC2
       +-- ALB
       +-- RDS
       +-- S3
       +-- Lambda
       +-- IAM
```

Don't try to attach the role directly to github-ci-cd-user. Give the user iam:PassRole permission on the role, and make sure the role's trust policy trusts cloudformation.amazonaws.com.

---
How to Use CharlieCafe-CloudFormation-ServiceRole with github-ci-cd-user

There is one important correction first:

You cannot directly attach an IAM role to an IAM user.

IAM users receive permissions through policies. Your github-ci-cd-user should be granted iam:PassRole permission for CharlieCafe-CloudFormation-ServiceRole, and then GitHub Actions/CloudFormation passes that role to CloudFormation.

AWS documents this exact model: the CloudFormation service role is assumed by CloudFormation, while the IAM principal that creates/updates the stack needs iam:PassRole permission for that Role

# Attach `CharlieCafe-CloudFormation-ServiceRole` to `github-ci-cd-user`

## Overview

In AWS IAM, you do **not** directly attach an IAM role to an IAM user.

For the Charlie Cafe CloudFormation deployment, the correct architecture is:

```text
GitHub Actions
      |
      | Uses AWS credentials
      v
github-ci-cd-user
      |
      | iam:PassRole
      v
CharlieCafe-CloudFormation-ServiceRole
      |
      | sts:AssumeRole
      v
AWS CloudFormation
      |
      +---- ECS
      +---- ECR
      +---- EC2
      +---- ALB
      +---- RDS
      +---- S3
      +---- Lambda
      +---- IAM
      +---- Secrets Manager
      +---- KMS
```

The `CharlieCafe-CloudFormation-ServiceRole` contains the permissions that **CloudFormation needs to create, update, and delete your Charlie Cafe infrastructure**.

The `github-ci-cd-user` only needs permission to **pass that role to CloudFormation**, along with whatever CloudFormation API permissions your GitHub Actions workflow itself requires.

AWS recommends restricting `iam:PassRole` to only the specific roles that the principal is allowed to pass.

---

# Part 1 — Verify Your CloudFormation Role

Your role should be:

```text
CharlieCafe-CloudFormation-ServiceRole
```

First verify it from PowerShell:

```powershell
aws iam get-role `
  --role-name CharlieCafe-CloudFormation-ServiceRole
```

You should receive information similar to:

```text
CharlieCafe-CloudFormation-ServiceRole
```

---

# Part 2 — Verify the CloudFormation Trust Policy

The role's trust policy should allow CloudFormation to assume it.

The recommended trust relationship is:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudformation.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

The important part is:

```json
"Principal": {
  "Service": "cloudformation.amazonaws.com"
}
```

This means:

```text
CloudFormation
      |
      | AssumeRole
      v
CharlieCafe-CloudFormation-ServiceRole
```

AWS recommends a CloudFormation service role trust policy that allows `cloudformation.amazonaws.com` to assume the role.

---

# Part 3 — Get Your AWS Account ID

Run:

```powershell
aws sts get-caller-identity `
  --query Account `
  --output text
```

Example result:

```text
123456789012
```

You will use your account ID in the role ARN.

The role ARN will be:

```text
arn:aws:iam::123456789012:role/CharlieCafe-CloudFormation-ServiceRole
```

Replace `123456789012` with your real AWS account ID.

---

# Part 4 — AWS Console Method

## Step 1 — Open IAM

Sign in to the AWS Management Console.

Open:

**IAM**

Then select:

**Users**

---

## Step 2 — Open `github-ci-cd-user`

Find:

```text
github-ci-cd-user
```

Click the user.

---

## Step 3 — Open Permissions

Select:

**Permissions**

You will see the policies currently attached to:

```text
github-ci-cd-user
```

---

## Step 4 — Add a Permission

Click:

**Add permissions**

Then choose:

**Create inline policy**

For this particular use case, an inline policy is convenient because the permission is specifically for your Charlie Cafe CloudFormation role.

---

# Part 5 — Create the `iam:PassRole` Policy

Choose the **JSON** policy editor.

Paste:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PassCharlieCafeCloudFormationRole",
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "arn:aws:iam::123456789012:role/CharlieCafe-CloudFormation-ServiceRole",
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": "cloudformation.amazonaws.com"
        }
      }
    }
  ]
}
```

Change:

```text
123456789012
```

to your actual AWS account ID.

The important permission is:

```json
"Action": "iam:PassRole"
```

and the important resource is:

```text
arn:aws:iam::YOUR_ACCOUNT_ID:role/CharlieCafe-CloudFormation-ServiceRole
```

The `iam:PassedToService` condition further restricts the role so it can be passed specifically to CloudFormation. AWS documents this condition key for restricting which service receives the role.

---

# Part 6 — Name the Policy

Use a name such as:

```text
CharlieCafe-CloudFormation-PassRole
```

Then click:

**Create policy**

Your user should now have:

```text
github-ci-cd-user
        |
        +-- CharlieCafe-CloudFormation-PassRole
                  |
                  +-- iam:PassRole
                  |
                  +-- CharlieCafe-CloudFormation-ServiceRole
```

---

# Part 7 — PowerShell Method

You can perform the same configuration using AWS CLI.

## Step 1 — Create the Policy File

Inside your project:

```text
CloudFormation-DevOps-Lab
│
└── iam-policies
    └── github-ci-cd-cloudformation-passrole-policy.json
```

Put this inside the file:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PassCharlieCafeCloudFormationRole",
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "arn:aws:iam::YOUR_ACCOUNT_ID:role/CharlieCafe-CloudFormation-ServiceRole",
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": "cloudformation.amazonaws.com"
        }
      }
    }
  ]
}
```

Replace:

```text
YOUR_ACCOUNT_ID
```

with your AWS account ID.

---

# Part 8 — Attach the Inline Policy to `github-ci-cd-user`

Because you are using PowerShell, run:

```powershell
aws iam put-user-policy `
  --user-name github-ci-cd-user `
  --policy-name CharlieCafe-CloudFormation-PassRole `
  --policy-document file://iam-policies/github-ci-cd-cloudformation-passrole-policy.json
```

This creates an inline policy on:

```text
github-ci-cd-user
```

The policy grants:

```text
iam:PassRole
```

only for:

```text
CharlieCafe-CloudFormation-ServiceRole
```

---

# Part 9 — If Your Project Path Is This

If your project is located at:

```text
C:\Users\musta\Downloads\AWS-Labs\CloudFormation-DevOps-Lab
```

and your policy is located at:

```text
C:\Users\musta\Downloads\AWS-Labs\CloudFormation-DevOps-Lab\iam-policies\github-ci-cd-cloudformation-passrole-policy.json
```

you can run:

```powershell
aws iam put-user-policy `
  --user-name github-ci-cd-user `
  --policy-name CharlieCafe-CloudFormation-PassRole `
  --policy-document file://C:\Users\musta\Downloads\AWS-Labs\CloudFormation-DevOps-Lab\iam-policies\github-ci-cd-cloudformation-passrole-policy.json
```

---

# Part 10 — Verify the Policy

Run:

```powershell
aws iam list-user-policies `
  --user-name github-ci-cd-user
```

You should see:

```text
CharlieCafe-CloudFormation-PassRole
```

Then inspect the policy:

```powershell
aws iam get-user-policy `
  --user-name github-ci-cd-user `
  --policy-name CharlieCafe-CloudFormation-PassRole
```

You should see:

```text
Action:
    iam:PassRole

Resource:
    arn:aws:iam::YOUR_ACCOUNT_ID:role/CharlieCafe-CloudFormation-ServiceRole
```

---

# Part 11 — Verify the Role's Trust Relationship

Run:

```powershell
aws iam get-role `
  --role-name CharlieCafe-CloudFormation-ServiceRole `
  --query "Role.AssumeRolePolicyDocument"
```

You want the trust policy to contain:

```json
{
  "Principal": {
    "Service": "cloudformation.amazonaws.com"
  }
}
```

The complete relationship should be:

```text
github-ci-cd-user
       |
       | iam:PassRole
       |
       v
CharlieCafe-CloudFormation-ServiceRole
       |
       | Trusts
       |
       v
cloudformation.amazonaws.com
```

---

# Part 12 — Use the Role in CloudFormation

When GitHub Actions creates or updates your CloudFormation stack, specify the role ARN.

For AWS CLI:

```powershell
aws cloudformation deploy `
  --template-file main.yaml `
  --stack-name CharlieCafe-Stack `
  --capabilities CAPABILITY_NAMED_IAM `
  --role-arn arn:aws:iam::YOUR_ACCOUNT_ID:role/CharlieCafe-CloudFormation-ServiceRole
```

For example:

```powershell
aws cloudformation deploy `
  --template-file main.yaml `
  --stack-name CharlieCafe-Stack `
  --capabilities CAPABILITY_NAMED_IAM `
  --role-arn arn:aws:iam::123456789012:role/CharlieCafe-CloudFormation-ServiceRole
```

CloudFormation then uses the service role's permissions to operate on the resources in the stack.

---

# Part 13 — GitHub Actions Example

Your GitHub Actions workflow can use:

```yaml
- name: Deploy CloudFormation Stack
  run: |
    aws cloudformation deploy \
      --template-file infrastructure/cloudformation/main.yaml \
      --stack-name CharlieCafe-Stack \
      --capabilities CAPABILITY_NAMED_IAM \
      --role-arn arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/CharlieCafe-CloudFormation-ServiceRole
```

The AWS credentials used by the GitHub Actions workflow must belong to an identity that has permission to pass the role.

In your case:

```text
GitHub Actions
      |
      v
github-ci-cd-user
      |
      | iam:PassRole
      v
CharlieCafe-CloudFormation-ServiceRole
      |
      v
CloudFormation
```

---

# Part 14 — Important Difference Between `iam:PassRole` and `sts:AssumeRole`

These two permissions are often confused.

## `iam:PassRole`

This is what `github-ci-cd-user` needs.

```text
github-ci-cd-user
       |
       | iam:PassRole
       v
CloudFormation
       |
       v
CloudFormation Service Role
```

The user is **not assuming the CloudFormation service role**.

It is giving CloudFormation permission to use the role.

---

## `sts:AssumeRole`

This is what CloudFormation needs through the role's trust policy.

```text
CloudFormation
       |
       | sts:AssumeRole
       v
CharlieCafe-CloudFormation-ServiceRole
```

The trust policy allows this.

---

# Part 15 — What NOT to Do

Do not try to add this to the user:

```json
{
  "Action": "sts:AssumeRole",
  "Resource": "arn:aws:iam::ACCOUNT_ID:role/CharlieCafe-CloudFormation-ServiceRole"
}
```

for the normal CloudFormation service-role workflow.

You don't need to make `github-ci-cd-user` assume the CloudFormation service role itself.

Instead, use:

```json
{
  "Action": "iam:PassRole",
  "Resource": "arn:aws:iam::ACCOUNT_ID:role/CharlieCafe-CloudFormation-ServiceRole"
}
```

AWS specifically distinguishes passing a role to an AWS service from assuming the role yourself.

---

# Part 16 — Recommended Final IAM Configuration

Your Charlie Cafe setup should look like this:

```text
AWS Account
│
├── IAM User
│   └── github-ci-cd-user
│       │
│       ├── Existing GitHub Actions policies
│       │
│       └── CharlieCafe-CloudFormation-PassRole
│               │
│               └── iam:PassRole
│                   └── CharlieCafe-CloudFormation-ServiceRole
│
└── IAM Role
    └── CharlieCafe-CloudFormation-ServiceRole
        │
        ├── Trust:
        │   └── cloudformation.amazonaws.com
        │
        └── Inline Policies
            ├── ECS permissions
            ├── ECR permissions
            ├── EC2 permissions
            ├── ALB permissions
            ├── RDS permissions
            ├── S3 permissions
            ├── Lambda permissions
            ├── IAM permissions
            ├── Secrets Manager permissions
            └── KMS permissions
```

This is the correct architecture for your use case. AWS recommends limiting the principal's `iam:PassRole` permission to the specific CloudFormation service role rather than allowing it to pass arbitrary roles.

---

# Part 17 — Quick PowerShell Commands

### Check account ID

```powershell
aws sts get-caller-identity --query Account --output text
```

### Check role

```powershell
aws iam get-role `
  --role-name CharlieCafe-CloudFormation-ServiceRole
```

### Add PassRole policy

```powershell
aws iam put-user-policy `
  --user-name github-ci-cd-user `
  --policy-name CharlieCafe-CloudFormation-PassRole `
  --policy-document file://iam-policies/github-ci-cd-cloudformation-passrole-policy.json
```

### List user inline policies

```powershell
aws iam list-user-policies `
  --user-name github-ci-cd-user
```

### Get the PassRole policy

```powershell
aws iam get-user-policy `
  --user-name github-ci-cd-user `
  --policy-name CharlieCafe-CloudFormation-PassRole
```

### Check the role's inline policies

```powershell
aws iam list-role-policies `
  --role-name CharlieCafe-CloudFormation-ServiceRole
```

### Check the role trust policy

```powershell
aws iam get-role `
  --role-name CharlieCafe-CloudFormation-ServiceRole `
  --query "Role.AssumeRolePolicyDocument"
```

---

# Final Result

You don't technically **attach the IAM role to `github-ci-cd-user`**.

You configure:

```text
github-ci-cd-user
        |
        | iam:PassRole
        v
CharlieCafe-CloudFormation-ServiceRole
        |
        | trusted by
        v
CloudFormation
```

That is exactly how your `github-ci-cd-user` should use the `CharlieCafe-CloudFormation-ServiceRole` during your Charlie Cafe CloudFormation deployment.


---
---














