# =======================================================

# CHARLIE CAFE - TERRAFORM DEVOPS LAB

# AMAZON RDS MYSQL

# =======================================================

#

# File:

# rds.tf

#

# Purpose:

# Creates the Amazon RDS MySQL infrastructure for the

# CharlieCafe Terraform DevOps Lab.

#

# CloudFormation resources converted:

#

# AWS::EC2::SecurityGroup

# AWS::RDS::DBSubnetGroup

# AWS::RDS::DBInstance

#

# =======================================================

#

# TERRAFORM NAMING CONVENTION

#

# This Terraform implementation intentionally uses names

# that are different from the existing CloudFormation

# implementation.

#

# Terraform project:

#

# CharlieCafe-TF-Lab

#

# Application:

#

# CharlieCafe-TF

#

# Database:

#

# tflabdb

#

# RDS Subnet Group:

#

# charliecafe-tf-rds-subnet-group

#

# RDS resource name/tag:

#

# CharlieCafe-TF-RDS-MySQL

#

# =======================================================

#

# ARCHITECTURE

#

# Private Subnet 1 ──┐

# ├── RDS Subnet Group

# Private Subnet 2 ──┘

# |

# v

# RDS MySQL

# ^

# |

# RDS Security Group

# ^

# |

# EC2 Web Security Group

#

# RDS is NOT publicly accessible.

#

# =======================================================

# =======================================================

# RDS DB SUBNET GROUP

# =======================================================

#

# The RDS subnet group contains both private subnets.

#

# RDS uses these subnets to provide database networking

# across the configured Availability Zones.

#

# =======================================================

resource "aws_db_subnet_group" "mysql" {

# -----------------------------------------------------

# RDS subnet group name

# -----------------------------------------------------

#

# Terraform-specific name.

#

# This is intentionally different from any CloudFormation

# RDS subnet group name to avoid conflicts.

#

# -----------------------------------------------------

name = "charliecafe-tf-rds-subnet-group"

# -----------------------------------------------------

# Description

# -----------------------------------------------------

#

# Clearly identifies this subnet group as belonging to

# the CharlieCafe Terraform implementation.

#

# -----------------------------------------------------

description = "Subnet group for CharlieCafe Terraform RDS MySQL"

# -----------------------------------------------------

# Private subnets

# -----------------------------------------------------

#

# RDS is deployed into both private subnets.

#

# Private subnet 1:

#

# aws_subnet.private[0]

#

# Private subnet 2:

#

# aws_subnet.private[1]

#

# -----------------------------------------------------

subnet_ids = [
aws_subnet.private[0].id,
aws_subnet.private[1].id
]

# -----------------------------------------------------

# Tags

# -----------------------------------------------------

tags = {

```
# Terraform-specific RDS subnet group name.

Name = "CharlieCafe-TF-RDS-SubnetGroup"

# Project identification.

Project = "CharlieCafe-TF-Lab"

# Environment identification.

Environment = var.environment

# Infrastructure management tool.

ManagedBy = "Terraform"
```

}
}

# =======================================================

# RDS MYSQL DATABASE

# =======================================================

#

# Creates the MySQL database used by the CharlieCafe

# Terraform DevOps Lab.

#

# The database remains private and is not directly

# accessible from the public internet.

#

# =======================================================

resource "aws_db_instance" "mysql" {

# -----------------------------------------------------

# Database engine

# -----------------------------------------------------

engine = "mysql"

# -----------------------------------------------------

# MySQL version

# -----------------------------------------------------

#

# Controlled through variables.tf.

#

# -----------------------------------------------------

engine_version = var.db_engine_version

# -----------------------------------------------------

# RDS instance class

# -----------------------------------------------------

#

# Example:

#

# db.t3.micro

#

# -----------------------------------------------------

instance_class = var.db_instance_class

# -----------------------------------------------------

# Database name

# -----------------------------------------------------

#

# Terraform naming convention:

#

# tflabdb

#

# This value is controlled through:

#

# var.db_name

#

# -----------------------------------------------------

db_name = var.db_name

# -----------------------------------------------------

# Master username

# -----------------------------------------------------

username = var.db_username

# -----------------------------------------------------

# AWS-managed master password

# -----------------------------------------------------

#

# This corresponds to:

#

# ManageMasterUserPassword: true

#

# AWS automatically creates and manages the master

# password through AWS Secrets Manager.

#

# The password is therefore NOT stored in Terraform

# variables or source code.

#

# -----------------------------------------------------

manage_master_user_password = true

# -----------------------------------------------------

# Storage

# -----------------------------------------------------

allocated_storage = var.db_allocated_storage

storage_type = "gp2"

# -----------------------------------------------------

# Public access

# -----------------------------------------------------

#

# The database is private.

#

# Internet users cannot directly connect to the RDS

# instance.

#

# -----------------------------------------------------

publicly_accessible = false

# -----------------------------------------------------

# RDS Security Group

# -----------------------------------------------------

#

# Only resources permitted by the RDS security group

# can connect to the database.

#

# -----------------------------------------------------

vpc_security_group_ids = [
aws_security_group.rds.id
]

# -----------------------------------------------------

# RDS DB Subnet Group

# -----------------------------------------------------

#

# Uses the Terraform-created private subnet group above.

#

# -----------------------------------------------------

db_subnet_group_name = aws_db_subnet_group.mysql.name

# -----------------------------------------------------

# Backup retention

# -----------------------------------------------------

#

# Controlled through variables.tf.

#

# Default for this learning lab:

#

# 0 days

#

# Production databases should normally use automated

# backups.

#

# -----------------------------------------------------

backup_retention_period = var.db_backup_retention_period

# -----------------------------------------------------

# Storage encryption

# -----------------------------------------------------

#

# Controlled through:

#

# var.db_storage_encrypted

#

# -----------------------------------------------------

storage_encrypted = var.db_storage_encrypted

# -----------------------------------------------------

# Deletion protection

# -----------------------------------------------------

#

# Controlled through:

#

# var.db_deletion_protection

#

# For a disposable Terraform lab this is normally false.

#

# -----------------------------------------------------

deletion_protection = var.db_deletion_protection

# -----------------------------------------------------

# Skip final snapshot

# -----------------------------------------------------

#

# This is appropriate for the disposable learning lab.

#

# When Terraform destroys the database, AWS will not

# create a final snapshot.

#

# IMPORTANT:

#

# Do NOT use this approach for production databases

# where the final snapshot may be required for recovery.

#

# -----------------------------------------------------

skip_final_snapshot = true

# -----------------------------------------------------

# Tags

# -----------------------------------------------------

tags = {

```
# Terraform-specific database name.

Name = "CharlieCafe-TF-RDS-MySQL"

# Project identification.

Project = "CharlieCafe-TF-Lab"

# Environment identification.

Environment = var.environment

# Infrastructure management tool.

ManagedBy = "Terraform"
```

}
}

# =======================================================

# END OF rds.tf

# =======================================================

#

# TERRAFORM RESOURCE NAMES

#

# AWS DB Subnet Group:

#

# charliecafe-tf-rds-subnet-group

#

# AWS RDS database:

#

# Database name = tflabdb

#

# AWS RDS tag:

#

# CharlieCafe-TF-RDS-MySQL

#

# =======================================================

#

# IMPORTANT:

#

# The Terraform resource addresses have intentionally NOT

# been renamed:

#

# aws_db_subnet_group.mysql

# aws_db_instance.mysql

#

# These are Terraform configuration addresses rather than

# AWS resource names. Keeping them unchanged avoids an

# unnecessary Terraform state migration.

#

# =======================================================
