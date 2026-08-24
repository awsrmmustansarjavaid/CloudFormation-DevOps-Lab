# CloudFormation-DevOps-Lab

### Your current repository is already growing into a real DevOps portfolio project:

```
CloudFormation-DevOps-Lab/
├── .github/
├── Doc/
├── application/
├── docker/
├── images/
├── lab-configuration-guideline/
├── notes/
├── scripts/
├── templates/
├── .dockerignore
├── .gitignore
├── README.md
└── docker-compose.yml
```

### Recommended professional structure

I would move toward this:

```
CloudFormation-DevOps-Lab/
│
├── .github/
│   └── workflows/
│       ├── cloudformation-deploy.yml
│       ├── cloudformation-delete.yml
│       ├── terraform-deploy.yml
│       └── terraform-delete.yml
│
├── application/
│   ├── ...
│   └── ...
│
├── docker/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── ...
│
├── infrastructure/
│   │
│   ├── aws-cloudformation/
│   │   ├── templates/
│   │   │   ├── main.yaml
│   │   │   ├── network.yaml
│   │   │   ├── web.yaml
│   │   │   ├── app.yaml
│   │   │   ├── database.yaml
│   │   │   └── ...
│   │   │
│   │   ├── parameters/
│   │   │   └── ...
│   │   │
│   │   └── README.md
│   │
│   └── terraform/
│       ├── modules/
│       │   ├── vpc/
│       │   ├── ecs/
│       │   ├── ecr/
│       │   ├── rds/
│       │   └── ...
│       │
│       ├── environments/
│       │   └── dev/
│       │       ├── main.tf
│       │       ├── variables.tf
│       │       ├── outputs.tf
│       │       └── terraform.tfvars.example
│       │
│       └── README.md
│
├── scripts/
│   ├── cloudformation/
│   │   ├── deploy.sh
│   │   ├── delete.sh
│   │   └── verify.sh
│   │
│   └── terraform/
│       ├── deploy.sh
│       ├── destroy.sh
│       └── verify.sh
│
├── docs/
│   ├── cloudformation/
│   ├── terraform/
│   ├── architecture/
│   └── troubleshooting/
│
├── images/
├── notes/
│
├── .gitignore
├── .dockerignore
└── README.md
```

### Why I prefer infrastructure/

Instead of:

```
aws-cloudformation/
terraform/
```

at the root, I would use:

```
infrastructure/
├── aws-cloudformation/
└── terraform/
```

This gives you a very clear architectural meaning:

Infrastructure as Code implementations live under infrastructure/.

Then you can eventually add another implementation without making the root messy:

```
infrastructure/
├── aws-cloudformation/
├── terraform/
└── pulumi/
```

That's a structure you can comfortably show in a portfolio or interview.
---
### Your existing templates/ directory

Currently you have:

```
templates/
```
I would move it to:

```
infrastructure/
└── aws-cloudformation/
    └── templates/
```

For example:

```
templates/
├── aws-ecs-ecr.yaml
├── ...
```

becomes:

```
infrastructure/
└── aws-cloudformation/
    └── templates/
        ├── aws-ecs-ecr.yaml
        └── ...
```

This is important because your GitHub Actions currently reference paths such as:

```
templates/aws-ecs-ecr.yaml
```

After moving the file, they need to become something like:

```
infrastructure/aws-cloudformation/templates/aws-ecs-ecr.yaml
```

---
### Your GitHub Actions need modification

This is one area where you should not move files without updating paths.

For example, if you currently have:

```
ECS_TEMPLATE_FILE: templates/aws-ecs-ecr.yaml
```

change it to:

```
ECS_TEMPLATE_FILE: infrastructure/aws-cloudformation/templates/aws-ecs-ecr.yaml
```

And if you have:

```
aws cloudformation validate-template \
  --template-body file://templates/aws-ecs-ecr.yaml
```

change it to:

```
aws cloudformation validate-template \
  --template-body file://infrastructure/aws-cloudformation/templates/aws-ecs-ecr.yaml
```

The same applies to:

```
aws cloudformation deploy
```

and:

```
aws cloudformation delete-stack
```

if they reference template paths.

---
### Your Terraform implementation can mirror the architecture

This is where your project becomes particularly valuable.

For example, CloudFormation:

```
infrastructure/
└── aws-cloudformation/
    └── templates/
        ├── main.yaml
        ├── network.yaml
        ├── ecs.yaml
        ├── ecr.yaml
        ├── rds.yaml
        └── ...
```

Terraform:

```
infrastructure/
└── terraform/
    ├── modules/
    │   ├── network/
    │   ├── ecs/
    │   ├── ecr/
    │   ├── rds/
    │   └── ...
    │
    └── environments/
        └── dev/
            ├── main.tf
            ├── variables.tf
            ├── outputs.tf
            └── terraform.tfvars.example
```

Notice that the AWS architecture can remain conceptually identical, even though the implementation is different.

That's excellent for learning.

---
### docs

I recommend:

```
docs/
```

because lowercase directory names are more common in Linux/DevOps repositories.

For example:

```
docs/
├── cloudformation/
│   ├── deployment.md
│   ├── verification.md
│   └── troubleshooting.md
│
├── terraform/
│   ├── deployment.md
│   ├── verification.md
│   └── troubleshooting.md
│
└── architecture/
    └── architecture.md
```

---
### Your final architecture would look very clean

Something like:

```
CloudFormation-DevOps-Lab/
│
├── .github/
│   └── workflows/
│
├── application/
│
├── docker/
│
├── infrastructure/
│   ├── aws-cloudformation/
│   │   ├── templates/
│   │   ├── parameters/
│   │   └── README.md
│   │
│   └── terraform/
│       ├── modules/
│       ├── environments/
│       └── README.md
│
├── scripts/
│   ├── cloudformation/
│   └── terraform/
│
├── docs/
│   ├── cloudformation/
│   ├── terraform/
│   ├── architecture/
│   └── troubleshooting/
│
├── images/
├── notes/
│
├── .dockerignore
├── .gitignore
├── docker-compose.yml
└── README.md
```

---




