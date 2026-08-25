




## Terraform directory

```
infrastructure/
└── terraform/
    ├── README.md
    ├── versions.tf
    ├── provider.tf
    ├── variables.tf
    ├── locals.tf
    ├── network.tf
    ├── security.tf
    ├── ec2.tf
    ├── rds.tf
    ├── s3.tf
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




