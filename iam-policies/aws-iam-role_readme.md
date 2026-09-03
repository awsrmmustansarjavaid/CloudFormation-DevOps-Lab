# Iam Role for cloudformation

## CharlieCafe-CloudFormation-ServiceRole

- ###  Trust relationships:

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

- ### Attach IAM Policies

- 1. aws-rds-CreateDBSnapshot

- 2. CharlieCafe-CloudFormation-ServiceRole-Policy

- 3. CharlieCafe-RDS-SecretsManager-KMS-Policy


---
## CharlieCafe-Terraform-ServiceRole

- ###  Trust relationships:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::537236558357:root"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```

### Step 3 — Trust policy

If you're going to use GitHub Actions OIDC, use a trust relationship along these lines:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::537236558357:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:YOUR-GITHUB-USERNAME/YOUR-REPOSITORY:*"
                }
            }
        }
    ]
}
```


- ### Attach IAM Policies

- 1. aws-rds-CreateDBSnapshot

- 2. CharlieCafe-Terraform-ServiceRole-Policy

- 3. CharlieCafe-TF-RDS-SecretsManager-KMS-Policy


---

Creating the role in AWS Console

Open the AWS IAM Console.

Then:


Step 1 — Roles

Go to:

IAM → Roles → Create role

AWS documents this exact console flow for creating service roles.

Step 2 — Trusted entity

For a GitHub Actions OIDC Terraform role, choose:

Trusted entity type: Custom trust policy

Don't select CloudFormation.

You do not want:

```
AWS service
    ↓
CloudFormation
```

because that would create essentially another CloudFormation service role.

Step 3 — Trust policy

If you're going to use GitHub Actions OIDC, use a trust relationship along these lines:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::537236558357:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:YOUR-GITHUB-USERNAME/YOUR-REPOSITORY:*"
                }
            }
        }
    ]
}
```

Do not paste YOUR-GITHUB-USERNAME/YOUR-REPOSITORY literally.

Replace it with your actual GitHub repository.

For example, if your repository were:

```
charlie-cafe-devops
```

under GitHub user/org:

```
mycompany
```

then:

```
"token.actions.githubusercontent.com:sub": "repo:mycompany/charlie-cafe-devops:*"
```

For even tighter security, we can restrict it to a particular branch instead of allowing every subject in the repository.

Step 4 — Role name

Enter:

```
CharlieCafe-Terraform-ServiceRole
```

This is a good name and matches your CloudFormation naming convention.

AWS role names must be unique within the account, and the name can't subsequently be edited.

Description:

```
Terraform deployment service role for the Charlie Cafe AWS DevOps lab
```

Then:

Next

Step 5 — Attach your Terraform policies

This is where your previous work comes together.

You currently have at least these Terraform policies:

Policy 1
```
CharlieCafe-Terraform-ServiceRole-Policy
```

Policy 2

```
CharlieCafe-TF-RDS-SecretsManager-KMS-Policy
```

Attach both.

The IAM console allows customer-managed policies to be attached to roles..

But don't attach the CloudFormation policies

Do not attach:

CharlieCafe-CloudFormation-ServiceRole-Policy

or:

CharlieCafe-RDS-SecretsManager-KMS-Policy

to the Terraform role.

Keep the environments separated:

                    Charlie Cafe
                         │
             ┌───────────┴───────────┐
             │                       │
       CloudFormation            Terraform
             │                       │
             ▼                       ▼
CloudFormation Role          Terraform Role
             │                       │
             ├─ CFN Policy            ├─ TF Policy
             ├─ RDS/KMS Policy        ├─ TF RDS/KMS Policy
             └─ Policy #3             └─ TF Policy #3

That's a much cleaner design.

Step 6 — Create role

Review:

Role name:
CharlieCafe-Terraform-ServiceRole

Then click:

Create role

After creation, open the role.

You should see:

CharlieCafe-Terraform-ServiceRole

and under Permissions:

Permissions policies

CharlieCafe-Terraform-ServiceRole-Policy
CharlieCafe-TF-RDS-SecretsManager-KMS-Policy
Step 7 — Verify Trust relationships

Open:

CharlieCafe-Terraform-ServiceRole → Trust relationships

For GitHub Actions OIDC, you should see:

token.actions.githubusercontent.com

as the federated principal, with:

sts:AssumeRoleWithWebIdentity

You should not see:

"Service": "cloudformation.amazonaws.com"

on the Terraform role.

That belongs to:

CharlieCafe-CloudFormation-ServiceRole
One important issue with our previous policy

Before you actually deploy Terraform, I want to make one correction to the approach from my previous answers.

You told me:

"add all iam policy of this lab for terraform as well"

We shouldn't simply duplicate all three CloudFormation policies.

We need to look at all three CloudFormation policies and your Terraform .tf files together.

For example, your current Terraform policies may still need permissions for resources such as:

VPC
EC2
RDS
S3
CloudFront
Secrets Manager
KMS
IAM
Lambda
API Gateway
DynamoDB
SQS
EFS
WAF
Cognito
CloudWatch
CloudTrail
ECR
ECS

depending on what your Terraform configuration actually creates.

If we add everything blindly, you'll end up with a very broad deployment role. If we omit something, terraform apply will fail with AccessDenied.

Therefore I recommend this structure
CharlieCafe-Terraform-ServiceRole
│
├── CharlieCafe-Terraform-ServiceRole-Policy
│
├── CharlieCafe-TF-RDS-SecretsManager-KMS-Policy
│
├── CharlieCafe-TF-[third-policy]
│
└── possibly additional narrowly scoped policies

And each policy should correspond to actual Terraform resources.

Your immediate next step

Before you create the role, send me your third CloudFormation IAM policy:

CharlieCafe-????????-Policy

Then I'll compare:

CloudFormation Policy #1
CloudFormation Policy #2
CloudFormation Policy #3
             ↓
        Terraform
             ↓
Terraform Policy #1
Terraform Policy #2
Terraform Policy #3

and tell you exactly which policies should be duplicated, which should be rewritten for Terraform, which permissions are duplicates, and which permissions are missing.

After that, we can create the final:

CharlieCafe-Terraform-ServiceRole

with the correct trust policy and complete Terraform permission set.
---
Assuming your AWS CLI is already configured:

1. Verify the role exists
aws iam get-role `
  --role-name CharlieCafe-Terraform-ServiceRole `
  --region us-east-1

You should see something like:

{
    "Role": {
        "Path": "/",
        "RoleName": "CharlieCafe-Terraform-ServiceRole",
        "RoleId": "AROA...",
        "Arn": "arn:aws:iam::537236558357:role/CharlieCafe-Terraform-ServiceRole",
        "CreateDate": "...",
        "AssumeRolePolicyDocument": {...}
    }
}
2. Verify the trust policy specifically

Run:

aws iam get-role `
  --role-name CharlieCafe-Terraform-ServiceRole `
  --query "Role.AssumeRolePolicyDocument" `
  --output json

You should see:

{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::537236558357:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:awsrmmustansarjavaid/CloudFormation-DevOps-Lab:*"
                }
            }
        }
    ]
}

This is the most important command for checking the trust relationship.

3. Verify the attached managed policies

Run:

aws iam list-attached-role-policies `
  --role-name CharlieCafe-Terraform-ServiceRole

You should see your Terraform policies, for example:

CharlieCafe-Terraform-ServiceRole-Policy
CharlieCafe-TF-RDS-SecretsManager-KMS-Policy

You can make the output cleaner:

aws iam list-attached-role-policies `
  --role-name CharlieCafe-Terraform-ServiceRole `
  --query "AttachedPolicies[].PolicyName" `
  --output table

Expected:

---------------------------------------------
|            Attached Policies              |
+-------------------------------------------+
| CharlieCafe-Terraform-ServiceRole-Policy |
| CharlieCafe-TF-RDS-SecretsManager-KMS-Policy |
+-------------------------------------------+
4. Verify the policy ARNs
aws iam list-attached-role-policies `
  --role-name CharlieCafe-Terraform-ServiceRole `
  --query "AttachedPolicies[].PolicyArn" `
  --output table

You should get ARNs similar to:

arn:aws:iam::537236558357:policy/CharlieCafe-Terraform-ServiceRole-Policy
arn:aws:iam::537236558357:policy/CharlieCafe-TF-RDS-SecretsManager-KMS-Policy
5. Verify the actual policy document

This is useful because attaching the correct policy name isn't enough—you want to verify its actual permissions.

First get the policy ARN:

aws iam list-attached-role-policies `
  --role-name CharlieCafe-Terraform-ServiceRole `
  --query "AttachedPolicies[].PolicyArn" `
  --output text

Then for example:

$PolicyArn = "arn:aws:iam::537236558357:policy/CharlieCafe-Terraform-ServiceRole-Policy"

$VersionId = aws iam get-policy `
  --policy-arn $PolicyArn `
  --query "Policy.DefaultVersionId" `
  --output text

aws iam get-policy-version `
  --policy-arn $PolicyArn `
  --version-id $VersionId `
  --query "PolicyVersion.Document" `
  --output json

That lets you verify that the policy currently attached to the role contains the permissions you expect.

6. Check that your GitHub OIDC provider exists

Because your trust policy uses:

token.actions.githubusercontent.com

verify that AWS has the provider:

aws iam list-open-id-connect-providers

You should see:

arn:aws:iam::537236558357:oidc-provider/token.actions.githubusercontent.com

You can also specifically check it:

aws iam get-open-id-connect-provider `
  --open-id-connect-provider-arn "arn:aws:iam::537236558357:oidc-provider/token.actions.githubusercontent.com"

If this command succeeds, the provider exists.

7. Verify the role ARN
aws iam get-role `
  --role-name CharlieCafe-Terraform-ServiceRole `
  --query "Role.Arn" `
  --output text

Expected:

arn:aws:iam::537236558357:role/CharlieCafe-Terraform-ServiceRole
8. Best quick verification

If you just want a quick check, run these four commands:

aws iam get-role `
  --role-name CharlieCafe-Terraform-ServiceRole `
  --query "Role.Arn" `
  --output text
aws iam get-role `
  --role-name CharlieCafe-Terraform-ServiceRole `
  --query "Role.AssumeRolePolicyDocument" `
  --output json
aws iam list-attached-role-policies `
  --role-name CharlieCafe-Terraform-ServiceRole `
  --query "AttachedPolicies[].PolicyName" `
  --output table
aws iam list-open-id-connect-providers

If all four return the expected results, your role, GitHub OIDC trust relationship, attached policies, and OIDC provider are present.

One important distinction

These commands verify that the IAM configuration exists and is configured correctly. They do not prove that GitHub Actions can successfully assume the role.

The real end-to-end test is a GitHub Actions workflow using:

permissions:
  id-token: write
  contents: read

and:

- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::537236558357:role/CharlieCafe-Terraform-ServiceRole
    aws-region: us-east-1

Then:

- name: Verify AWS identity
  run: aws sts get-caller-identity

If that succeeds, you'll know the GitHub → OIDC → STS → CharlieCafe-Terraform-ServiceRole chain is actually working.
---
Yes. You should add CharlieCafe-Terraform-ServiceRole to this workflow, especially because you already created the role specifically for Terraform.

However, there is one important point:

Your current workflow is not using OIDC yet. It is currently authenticating with:

aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

Your new role has a GitHub Actions OIDC trust policy, so simply adding the role ARN as a variable will not make GitHub Actions use the role.

Minimal modification I recommend

Add one global variable:

TERRAFORM_ROLE_ARN: arn:aws:iam::537236558357:role/CharlieCafe-Terraform-ServiceRole

under your existing env: section:

env:

  AWS_REGION: us-east-1

  TERRAFORM_DIR: infrastructure/terraform

  TERRAFORM_VERSION: "1.9.8"

  KEY_PAIR_NAME: Lab-KeyPair

  ECR_REPOSITORY: charlie-cafe-tf

  ECS_CLUSTER: CharlieCafe-TF-Cluster

  ECS_SERVICE: CharlieCafe-TF-Service

  ECS_CONTAINER: charlie-cafe-tf

  IMAGE_TAG: latest

  TF_IN_AUTOMATION: "true"

  ECS_DESIRED_COUNT: "1"

  # Terraform IAM service role
  TERRAFORM_ROLE_ARN: arn:aws:iam::537236558357:role/CharlieCafe-Terraform-ServiceRole

But don't stop there.

Because your role trust policy says:

sts:AssumeRoleWithWebIdentity

you need to change the AWS authentication step from access keys to OIDC.

Your current step

You currently have:

permissions:
  contents: read

Change it to:

permissions:
  id-token: write
  contents: read

Then replace:

- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ env.AWS_REGION }}

with:

- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ env.TERRAFORM_ROLE_ARN }}
    aws-region: ${{ env.AWS_REGION }}
    role-session-name: GitHubActions-Terraform
One important architectural decision

Your workflow has three jobs:

terraform
   ↓
docker
   ↓
ecs-deploy

If you want the new Terraform role to be used for all three jobs, then each job needs OIDC permission and each job needs to configure AWS credentials with:

role-to-assume: ${{ env.TERRAFORM_ROLE_ARN }}

So the minimal changes are:

permissions:
  id-token: write
  contents: read

and replace the AWS credential configuration in terraform, docker, and ecs-deploy.

But there is a second issue

Your Terraform role policy we created earlier was primarily designed for Terraform infrastructure deployment.

Your docker job does:

ECR login
ECR describe repository
ECR push image
ECR describe image

Your ecs-deploy job does:

ECS describe
ECS update-service
ECS wait
ELB describe

Therefore, if you make all three jobs assume CharlieCafe-Terraform-ServiceRole, the role must also have the required ECR write and ECS deployment permissions.

Your current Terraform policy only had ECR read and ECS read permissions.

So I would not blindly change all three jobs to the Terraform role yet.

My recommendation for your lab

Keep the workflow structure exactly as you have it:

terraform job
    ↓
CharlieCafe-Terraform-ServiceRole
    ↓
Terraform

docker job
    ↓
existing/current deployment credentials
    ↓
ECR

ecs-deploy job
    ↓
existing/current deployment credentials
    ↓
ECS

This requires the least modification and keeps your Terraform role focused on Terraform.

If your goal is specifically:

"I want GitHub Actions to use CharlieCafe-Terraform-ServiceRole for the entire Terraform → Docker → ECR → ECS pipeline."

then we can do that too, but we should first add the exact ECR/ECS/ELB permissions required to the Terraform role rather than giving it unnecessary broad permissions.

So yes: add the global variable. But I recommend initially using the new role only in the terraform job, because that's the cleanest and safest change to your existing workflow.
---
## Your AWS account currently has 0 IAM Identity Providers

You need to create one GitHub Actions OIDC provider. Do this first; you do not need to change your IAM role yet.

Step 2 — Add the GitHub OIDC provider

In AWS Console go to:

IAM → Identity providers → Add provider

Choose:

Provider type

OpenID Connect

Provider URL

https://token.actions.githubusercontent.com

Audience

sts.amazonaws.com

Then click Add provider.

After creation, your IAM page should show:

Identity providers (1)

and the provider should be:

OpenID Connect
https://token.actions.githubusercontent.com
Step 3 — Verify it

Click the newly created provider and make sure the details are:

Provider type: OpenID Connect
Provider URL: https://token.actions.githubusercontent.com
Audience: sts.amazonaws.com

The ARN should correspond to:

arn:aws:iam::537236558357:oidc-provider/token.actions.githubusercontent.com
Step 4 — Then your existing trust policy

Your IAM role's trust relationship can then reference:

arn:aws:iam::537236558357:oidc-provider/token.actions.githubusercontent.com

So don't create another provider. You want exactly one GitHub Actions OIDC provider in this AWS account.

After you add it, send me your IAM role Trust relationships JSON, and I'll check it against your GitHub workflow before you run the deployment.


What you should do now

Go back to:

AWS Console → IAM → Identity providers → Add provider

Then enter the values in the AWS Console form, not PowerShell:

AWS field	Enter this
Provider type	OpenID Connect
Provider URL	https://token.actions.githubusercontent.com
Audience	sts.amazonaws.com

Then click Add provider.

After that

Your page should change from:

Identity providers (0)

to:

Identity providers (1)

with:

OpenID Connect
token.actions.githubusercontent.com

Do not run those three lines in PowerShell.

If you prefer to create the provider using AWS CLI instead of the Console, 
I can also give you the exact PowerShell command for your account.

Absolutely. Since your AWS account is 537236558357, run this exact command in PowerShell:

aws iam create-open-id-connect-provider `
  --url "https://token.actions.githubusercontent.com" `
  --client-id-list "sts.amazonaws.com"

This creates the GitHub Actions OIDC provider with the correct URL and audience. AWS documents create-open-id-connect-provider with these parameters, and the current GitHub AWS credentials action also uses this exact URL/audience combination.

1. First, verify you're using the correct AWS account

Run:

aws sts get-caller-identity

You should see:

"Account": "537236558357"
2. Then create the OIDC provider

Run:

aws iam create-open-id-connect-provider `
  --url "https://token.actions.githubusercontent.com" `
  --client-id-list "sts.amazonaws.com"

Important: You don't need to specify the AWS account ID in the create command. AWS automatically creates the provider in the account associated with your current AWS CLI credentials.

3. Verify it was created

Run:

aws iam list-open-id-connect-providers

You should get something similar to:

{
    "OpenIDConnectProviderList": [
        {
            "Arn": "arn:aws:iam::537236558357:oidc-provider/token.actions.githubusercontent.com"
        }
    ]
}

That ARN exactly matches the provider ARN your IAM trust policy is expecting.

4. Verify the audience too

Run:

aws iam get-open-id-connect-provider `
  --open-id-connect-provider-arn "arn:aws:iam::537236558357:oidc-provider/token.actions.githubusercontent.com"

Look for:

ClientIDList:
    sts.amazonaws.com

Once these checks succeed, stop there. Don't change the IAM role or GitHub workflow yet. Send me the output of:

aws iam get-open-id-connect-provider `
  --open-id-connect-provider-arn "arn:aws:iam::537236558357:oidc-provider/token.actions.githubusercontent.com"

and I'll verify the OIDC provider before we move to the trust policy.

your OIDC provider is already correctly configured. The important part is that the first create-open-id-connect-provider command failed because your github-ci-cd-user does not have permission to create providers, but the later list and get commands prove the provider already exists and is correct.

Your current status
Check	Result
AWS Account	537236558357 ✅
OIDC provider exists	✅
Provider URL	token.actions.githubusercontent.com ✅
Audience	sts.amazonaws.com ✅
Provider ARN	Matches your trust policy ✅

Your provider ARN is:

arn:aws:iam::537236558357:oidc-provider/token.actions.githubusercontent.com

And your output confirms:

"Url": "token.actions.githubusercontent.com"
"ClientIDList": [
    "sts.amazonaws.com"
]

So do not try to create the provider again.

Why did create-open-id-connect-provider say AccessDenied?

Because your current CLI identity is:

arn:aws:iam::537236558357:user/github-ci-cd-user

and that IAM user does not have:

iam:CreateOpenIDConnectProvider

But that's irrelevant now because the provider already exists.

What we should check next

The next important piece is your IAM role trust relationship. Your trust policy must reference this existing provider and correctly restrict which GitHub repository/workflow can assume the role.

Please run:

aws iam get-role `
  --role-name YOUR_ROLE_NAME `
  --query "Role.AssumeRolePolicyDocument" `
  --output json

Replace YOUR_ROLE_NAME with the actual IAM role used by your GitHub Actions workflow.

Or, since you've been working on this workflow already, paste your current IAM role Trust Policy JSON here. I'll check it against your GitHub workflow and tell you exactly what, if anything, needs changing.

----
Fix the IAM trust policy

Change only the sub condition to match your actual claim:

"StringLike": {
  "token.actions.githubusercontent.com:sub": "repo:awsrmmustansarjavaid@242676971/CloudFormation-DevOps-Lab@1322851615:*"
}

Your complete trust policy should be:

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::537236558357:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:awsrmmustansarjavaid@242676971/CloudFormation-DevOps-Lab@1322851615:*"
        }
      }
    }
  ]
}

Do not change your GitHub Actions OIDC step. Your workflow is correctly requesting:

aud = sts.amazonaws.com

and your actual claims confirm that.

So the current issue is specifically the IAM role trust policy's sub condition.
---
