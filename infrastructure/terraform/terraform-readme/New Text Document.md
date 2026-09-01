Now Terraform

You asked for the same configuration in Terraform.

I recommend making a Terraform module equivalent to your CloudFormation nested stack.

Your structure could be:

```
infrastructure/
└── terraform/
    │
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    │
    └── modules/
        │
        ├── s3/
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        │
        └── s3-cloudfront/
            ├── main.tf
            ├── variables.tf
            └── outputs.tf
```

Conceptually:

```
Terraform Root
│
├── module.s3
│      │
│      └── Existing S3 Bucket
│
└── module.s3_cloudfront
       │
       ├── OAC
       ├── S3 Bucket Policy
       └── CloudFront
```

### Create a NEW file cloudfront.tf 

Create a NEW file

Create:

```
infrastructure/terraform/cloudfront.tf
```

Your structure will become:

```
infrastructure/
└── terraform/
    ├── cloudfront.tf       ← CREATE THIS
    ├── ec2.tf
    ├── ecs_ecr.tf
    ├── locals.tf
    ├── network.tf
    ├── outputs.tf
    ├── provider.tf
    ├── rds.tf
    ├── s3.tf
    ├── security.tf
    ├── template_bucket.tf
    ├── terraform.tfvars.example
    ├── variables.tf
    └── versions.tf
```
### Terraform S3 bucket policy

Now we need:

```
CloudFront
     │
     │ GetObject
     ▼
S3
```

For your current flat Terraform structure, Step 17 should be a new Terraform file:

infrastructure/
└── terraform/
    ├── cloudfront.tf
    ├── s3.tf
    ├── s3-cloudfront-policy.tf    ← CREATE THIS FILE
    ├── variables.tf
    ├── outputs.tf
    └── ...
Why?

This policy is an S3 bucket policy, not a standalone IAM user/role policy.

Terraform will create the AWS S3 bucket policy for you:

```
CloudFront
    │
    │ GetObject
    ▼
S3 Bucket
    ▲
    │
    │ Bucket Policy
    │ allows CloudFront
    │ to read objects
```

Also, because your project already has s3_bucket_name, do not use the old var.bucket_name / var.bucket_arn variables from the module example.

The exact resource references should come from your existing s3.tf. Since I haven't seen that file yet, I don't want to invent the S3 resource name.


