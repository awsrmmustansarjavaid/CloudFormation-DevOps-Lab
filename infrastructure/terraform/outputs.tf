# =======================================================
# TERRAFORM OUTPUTS
# =======================================================
#
# These outputs replace the Outputs section of the
# CloudFormation templates.
# =======================================================


# =======================================================
# VPC
# =======================================================

output "vpc_id" {
  description = "ID of the Lab VPC."
  value       = aws_vpc.lab.id
}


# =======================================================
# INTERNET GATEWAY
# =======================================================

output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = aws_internet_gateway.lab.id
}


# =======================================================
# ROUTE TABLES
# =======================================================

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table."
  value       = aws_route_table.private.id
}


# =======================================================
# PUBLIC SUBNETS
# =======================================================

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}


# =======================================================
# PRIVATE SUBNETS
# =======================================================

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = aws_subnet.private[*].id
}


# =======================================================
# WEB SECURITY GROUP
# =======================================================

output "web_security_group_id" {
  description = "ID of the EC2 Web Security Group."
  value       = aws_security_group.web.id
}


# =======================================================
# RDS SECURITY GROUP
# =======================================================

output "rds_security_group_id" {
  description = "ID of the RDS Security Group."
  value       = aws_security_group.rds.id
}


# =======================================================
# EC2 INSTANCE
# =======================================================

output "ec2_instance_id" {
  description = "ID of the EC2 Web Server."
  value       = aws_instance.web.id
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 Web Server."
  value       = aws_instance.web.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS name of the EC2 Web Server."
  value       = aws_instance.web.public_dns
}


# =======================================================
# EC2 USERDATA SCRIPT
# =======================================================

output "ec2_userdata_script_url" {
  description = "GitHub URL used by EC2 to download the bootstrap script."
  value       = var.userdata_script_url
}


# =======================================================
# S3
# =======================================================

output "s3_bucket_name" {
  description = "Name of the S3 Lab bucket."
  value       = aws_s3_bucket.lab.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 Lab bucket."
  value       = aws_s3_bucket.lab.arn
}


# =======================================================
# RDS
# =======================================================

output "rds_database_id" {
  description = "RDS database identifier."
  value       = aws_db_instance.mysql.identifier
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint address."
  value       = aws_db_instance.mysql.address
}

output "rds_port" {
  description = "RDS MySQL port."
  value       = aws_db_instance.mysql.port
}

output "rds_master_user_secret_arn" {
  description = "Secrets Manager ARN containing the RDS master credentials."
  value       = aws_db_instance.mysql.master_user_secret[0].secret_arn
}

# =========================================================
# TEMPLATE BUCKET OUTPUTS
# =========================================================
#
# These outputs replace the CloudFormation outputs:
#
#   BucketName
#   BucketArn
#
# =========================================================


# ---------------------------------------------------------
# Template S3 Bucket Name
# ---------------------------------------------------------

output "template_bucket_name" {

  description = "Name of the S3 bucket used to store CloudFormation nested templates"

  value = aws_s3_bucket.template_bucket.bucket
}


# ---------------------------------------------------------
# Template S3 Bucket ARN
# ---------------------------------------------------------

output "template_bucket_arn" {

  description = "ARN of the S3 bucket used to store CloudFormation nested templates"

  value = aws_s3_bucket.template_bucket.arn
}