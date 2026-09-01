# s3-website-cloudfront.yaml

So your structure becomes:

```
Resources
│
├── MyVPC
├── MyInternetGateway
├── AttachGateway
│
├── PublicSubnet1
├── PublicSubnet2
├── PrivateSubnet1
├── PrivateSubnet2
│
├── PublicRouteTable
├── DefaultRoute
├── PublicSubnet1RouteAssociation
├── PublicSubnet2RouteAssociation
│
├── PrivateRouteTable
├── PrivateSubnet1RouteAssociation
├── PrivateSubnet2RouteAssociation
│
├── WebSecurityGroup
│
├── EC2WebServerStack
│
├── S3NestedStack
│
│   └── creates your existing S3 bucket
│
├── S3WebsiteCloudFrontNestedStack   ← NEW
│
│   ├── uses existing S3 bucket
│   ├── CloudFront OAC
│   ├── S3 bucket policy
│   └── CloudFront Distribution
│
└── RDSNestedStack
```

### 3. Why DependsOn is useful here

You have:

```
DependsOn:
  - S3NestedStack
```

This makes the relationship explicit:

```
S3NestedStack
      │
      │ creates bucket
      ▼
Existing S3 Bucket
      │
      │ BucketName / BucketArn
      ▼
S3WebsiteCloudFrontNestedStack
      │
      ├── OAC
      ├── Bucket Policy
      └── CloudFront
```

The new stack receives:


```
WebsiteBucketName:
  !GetAtt S3NestedStack.Outputs.BucketName
```

and:

```
WebsiteBucketArn:
  !GetAtt S3NestedStack.Outputs.BucketArn
```

So your new CloudFront stack does not create a second bucket.

### CloudFront Outputs on Main Template

Add these under your existing Outputs: section:

```
  # -------------------------------------------------------
  # CloudFront Outputs
  # -------------------------------------------------------

  CloudFrontDistributionId:
    Description: CloudFront Distribution ID
    Value: !GetAtt S3WebsiteCloudFrontNestedStack.Outputs.CloudFrontDistributionId

  CloudFrontDomainName:
    Description: CloudFront Distribution Domain Name
    Value: !GetAtt S3WebsiteCloudFrontNestedStack.Outputs.CloudFrontDomainName
```

Then your architecture becomes:

```
                         Internet
                            │
                            ▼
                     CloudFront
                            │
                         OAC │
                            ▼
                ┌─────────────────────┐
                │ Existing S3 Bucket  │
                │                     │
                │ index.html          │
                │ CSS                 │
                │ JS                  │
                │ images              │
                └─────────────────────┘
```

And CloudFormation becomes:

```
                    MAIN STACK
                        │
          ┌─────────────┼─────────────┐
          │             │             │
          ▼             ▼             ▼
      EC2 Stack      S3 Stack      RDS Stack
                         │
                         │
                         ▼
                 Existing S3 Bucket
                         │
                         │ BucketName
                         │ BucketArn
                         ▼
             S3 Website + CloudFront
                     Stack
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
          CloudFront               OAC
              │                     │
              └──────────┬──────────┘
                         ▼
                  Existing S3 Bucket
```

---

### 5. Your index.html is a separate deployment

You have:

```
CloudFormation-DevOps-Lab
└── application
    └── index.html
```

That file should eventually be uploaded into the existing:

```
LabBucket
```

so the final bucket becomes:

```
LabBucket
│
├── index.html
│
├── css/
│
├── js/
│
└── images/
```

CloudFormation creates the infrastructure.

Your CI/CD workflow deploys the application.

So:

```
                 GitHub
                   │
          ┌────────┴────────┐
          │                 │
          ▼                 ▼
 CloudFormation          Application
 Infrastructure           Files
          │                 │
          ▼                 ▼
     LabBucket        application/
          │             index.html
          │                 │
          └────────┬────────┘
                   ▼
               S3 Bucket
                   │
                   ▼
              CloudFront
                   │
                   ▼
              HTTPS Website
```

### 6. Final file relationship

You will have:

```
CloudFormation-DevOps-Lab
│
├── application
│   └── index.html
│
└── infrastructure
    └── aws-cloudformation
        │
        └── templates
            │
            ├── s3.yaml
            │     │
            │     └── Creates LabBucket
            │
            └── s3-website-cloudfront.yaml
                  │
                  ├── Uses LabBucket
                  ├── Creates OAC
                  ├── Creates Bucket Policy
                  └── Creates CloudFront
```

And the data flow is:

```
s3.yaml
   │
   ├── BucketName
   │
   └── BucketArn
          │
          ▼
s3-website-cloudfront.yaml
          │
          ├── S3 Bucket Policy
          │
          ├── CloudFront OAC
          │
          └── CloudFront Distribution
```

---
