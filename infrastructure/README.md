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

### Most important point: don't duplicate your application

Your idea should be:

```
                    Charlie Cafe Application
                            │
             ┌──────────────┴──────────────┐
             │                             │
      CloudFormation                   Terraform
             │                             │
             ▼                             ▼
      AWS Infrastructure            AWS Infrastructure
```




