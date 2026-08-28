# ============================================================
# CHARLIE CAFE - TERRAFORM INFRASTRUCTURE OUTPUTS
# ============================================================
#
# File:
#   outputs.tf
#
# Purpose:
#   Exposes important information about the Charlie Cafe
#   Terraform AWS infrastructure after deployment.
#
# These outputs are useful for:
#
#   - Terraform users
#   - GitHub Actions
#   - CI/CD pipelines
#   - AWS CLI verification
#   - Application testing
#   - Troubleshooting
#   - Deployment automation
#
# ============================================================
#
# TERRAFORM NAMING CONVENTION
# ============================================================
#
# This Terraform lab exists alongside the CloudFormation
# implementation of the same Charlie Cafe infrastructure.
#
# Therefore Terraform-managed AWS resources use the following
# naming convention:
#
#   Project:
#     CharlieCafe-TF-Lab
#
#   Application:
#     CharlieCafe-TF
#
#   ECR:
#     charlie-cafe-tf
#
#   ECS Cluster:
#     CharlieCafe-TF-Cluster
#
#   ECS Service:
#     CharlieCafe-TF-Service
#
#   ECS Task Definition Family:
#     CharlieCafe-TF
#
#   Database:
#     tflabdb
#
# ============================================================
#
# IMPORTANT:
#
# Networking resources are created in:
#
#   network.tf
#
# ECS/ECR/ALB resources are created in:
#
#   ecs_ecr.tf
#
# This file ONLY contains Terraform output blocks.
#
# ============================================================
#
# IMPORTANT DESIGN DECISION:
#
# Terraform output BLOCK NAMES such as:
#
#   vpc_id
#   ecs_cluster_name
#   ecs_service_name
#   ecr_repository_name
#
# have NOT been renamed to include "-TF".
#
# These are Terraform configuration identifiers rather than
# AWS resource names.
#
# Keeping them stable prevents unnecessary changes to:
#
#   - GitHub Actions
#   - Terraform references
#   - CI/CD scripts
#   - Automation
#   - Existing deployment commands
#
# The AWS-visible resource names are controlled by the
# corresponding resource definitions in the other Terraform
# files.
#
# ============================================================



# ============================================================
# 1. VPC OUTPUT
# ============================================================
#
# Displays the ID of the Terraform-managed VPC.
#
# AWS Name:
#
#   CharlieCafe-TF-Lab-VPC
#
# The VPC itself is created in network.tf.
#
# ============================================================

output "vpc_id" {

  description = "ID of the CharlieCafe-TF-Lab VPC used by the Terraform infrastructure"

  value = aws_vpc.lab.id
}



# ============================================================
# 2. PUBLIC SUBNET OUTPUTS
# ============================================================
#
# These are the public subnets used by the Terraform-managed
# Application Load Balancer.
#
# AWS names:
#
#   CharlieCafe-TF-Public-Subnet-1
#   CharlieCafe-TF-Public-Subnet-2
#
# Architecture:
#
#   Internet
#       |
#       v
#      ALB
#       |
#       v
#   Public Subnets
#
# ============================================================

output "public_subnet_ids" {

  description = "IDs of the CharlieCafe-TF public subnets used by the ALB"

  value = [
    aws_subnet.public[0].id,
    aws_subnet.public[1].id
  ]
}



# ============================================================
# 3. PRIVATE SUBNET OUTPUTS
# ============================================================
#
# These are the private subnets used by the Terraform-managed
# ECS Fargate tasks.
#
# AWS names:
#
#   CharlieCafe-TF-Private-Subnet-1
#   CharlieCafe-TF-Private-Subnet-2
#
# ECS tasks do not receive public IP addresses.
#
# ============================================================

output "private_subnet_ids" {

  description = "IDs of the CharlieCafe-TF private subnets used by ECS Fargate tasks"

  value = [
    aws_subnet.private[0].id,
    aws_subnet.private[1].id
  ]
}



# ============================================================
# 4. PRIVATE ROUTE TABLE OUTPUT
# ============================================================
#
# This route table is associated with the Terraform-managed
# private subnets.
#
# It is also used by the S3 Gateway VPC endpoint.
#
# AWS Name:
#
#   CharlieCafe-TF-Private-RouteTable
#
# ============================================================

output "private_route_table_id" {

  description = "ID of the CharlieCafe-TF private route table"

  value = aws_route_table.private.id
}



# ============================================================
# 5. ECR REPOSITORY NAME
# ============================================================
#
# Name of the ECR repository where the Terraform version of
# the Charlie Cafe Docker image is stored.
#
# New ECR name:
#
#   charlie-cafe-tf
#
# This separates the Terraform ECR repository from the
# CloudFormation ECR repository.
#
# ============================================================

output "ecr_repository_name" {

  description = "Name of the CharlieCafe-TF ECR repository"

  value = aws_ecr_repository.charlie_cafe.name
}



# ============================================================
# 6. ECR REPOSITORY URI
# ============================================================
#
# Full URI of the Terraform-managed ECR repository.
#
# Example:
#
#   <account>.dkr.ecr.<region>.amazonaws.com/charlie-cafe-tf
#
# GitHub Actions can use this URI when tagging and pushing
# Docker images.
#
# ============================================================

output "ecr_repository_uri" {

  description = "URI of the CharlieCafe-TF ECR repository"

  value = aws_ecr_repository.charlie_cafe.repository_url
}



# ============================================================
# 7. ECR IMAGE URL
# ============================================================
#
# Full URI for the latest Docker image.
#
# New image naming:
#
#   charlie-cafe-tf:latest
#
# ECS pulls the image from the Terraform-managed ECR
# repository.
#
# ============================================================

output "ecr_image_url" {

  description = "Full CharlieCafe-TF ECR image URI using the latest image tag"

  value = "${aws_ecr_repository.charlie_cafe.repository_url}:latest"
}



# ============================================================
# 8. ECS CLUSTER NAME
# ============================================================
#
# Name of the Terraform-managed ECS cluster.
#
# New AWS name:
#
#   CharlieCafe-TF-Cluster
#
# ============================================================

output "ecs_cluster_name" {

  description = "Name of the CharlieCafe-TF ECS cluster"

  value = aws_ecs_cluster.charlie_cafe.name
}



# ============================================================
# 9. ECS CLUSTER ARN
# ============================================================
#
# ARN of the Terraform-managed ECS cluster.
#
# Useful for:
#
#   - AWS CLI commands
#   - GitHub Actions
#   - CI/CD automation
#   - Troubleshooting
#
# ============================================================

output "ecs_cluster_arn" {

  description = "ARN of the CharlieCafe-TF ECS cluster"

  value = aws_ecs_cluster.charlie_cafe.arn
}



# ============================================================
# 10. ECS SERVICE NAME
# ============================================================
#
# Name of the Terraform-managed ECS Fargate service.
#
# New AWS name:
#
#   CharlieCafe-TF-Service
#
# ============================================================

output "ecs_service_name" {

  description = "Name of the CharlieCafe-TF ECS Fargate service"

  value = aws_ecs_service.charlie_cafe.name
}



# ============================================================
# 11. ECS SERVICE ARN
# ============================================================
#
# ARN/ID of the Terraform-managed ECS service.
#
# ============================================================

output "ecs_service_arn" {

  description = "ARN or service identifier of the CharlieCafe-TF ECS service"

  value = aws_ecs_service.charlie_cafe.id
}



# ============================================================
# 12. ECS TASK DEFINITION ARN
# ============================================================
#
# ARN of the currently configured Terraform-managed ECS task
# definition.
#
# ============================================================

output "ecs_task_definition_arn" {

  description = "ARN of the CharlieCafe-TF ECS task definition"

  value = aws_ecs_task_definition.charlie_cafe.arn
}



# ============================================================
# 13. ECS TASK DEFINITION FAMILY
# ============================================================
#
# Task definition family name.
#
# New family name:
#
#   CharlieCafe-TF
#
# This separates the Terraform ECS task definition family
# from the CloudFormation task definition family.
#
# ============================================================

output "ecs_task_definition_family" {

  description = "Family name of the CharlieCafe-TF ECS task definition"

  value = aws_ecs_task_definition.charlie_cafe.family
}



# ============================================================
# 14. ALB ARN
# ============================================================
#
# ARN of the Terraform-managed Application Load Balancer.
#
# ============================================================

output "alb_arn" {

  description = "ARN of the CharlieCafe-TF Application Load Balancer"

  value = aws_lb.charlie_cafe.arn
}



# ============================================================
# 15. ALB DNS NAME
# ============================================================
#
# DNS hostname automatically assigned to the Terraform-managed
# Application Load Balancer.
#
# ============================================================

output "alb_dns_name" {

  description = "DNS name of the CharlieCafe-TF Application Load Balancer"

  value = aws_lb.charlie_cafe.dns_name
}



# ============================================================
# 16. APPLICATION URL
# ============================================================
#
# Public HTTP URL for the Terraform-managed Charlie Cafe
# application.
#
# Current configuration:
#
#   HTTP
#   Port 80
#
# HTTPS/ACM can be added later.
#
# ============================================================

output "application_url" {

  description = "Public HTTP URL for the CharlieCafe-TF application"

  value = "http://${aws_lb.charlie_cafe.dns_name}"
}



# ============================================================
# 17. TARGET GROUP ARN
# ============================================================
#
# ARN of the Terraform-managed ALB target group used by ECS.
#
# ============================================================

output "target_group_arn" {

  description = "ARN of the CharlieCafe-TF ALB target group"

  value = aws_lb_target_group.charlie_cafe.arn
}



# ============================================================
# 18. TARGET GROUP NAME
# ============================================================
#
# Name of the Terraform-managed ALB target group.
#
# Expected AWS naming pattern:
#
#   CharlieCafe-TF-TG
#
# ============================================================

output "target_group_name" {

  description = "Name of the CharlieCafe-TF ALB target group"

  value = aws_lb_target_group.charlie_cafe.name
}



# ============================================================
# 19. ALB SECURITY GROUP ID
# ============================================================
#
# Security group attached to the Terraform-managed public
# Application Load Balancer.
#
# ============================================================

output "alb_security_group_id" {

  description = "Security group ID used by the CharlieCafe-TF ALB"

  value = aws_security_group.alb.id
}



# ============================================================
# 20. ECS TASK SECURITY GROUP ID
# ============================================================
#
# Security group attached to Terraform-managed ECS Fargate
# tasks.
#
# Only traffic originating from the ALB security group is
# allowed on the application container port.
#
# ============================================================

output "ecs_task_security_group_id" {

  description = "Security group ID used by CharlieCafe-TF ECS tasks"

  value = aws_security_group.ecs_task.id
}



# ============================================================
# 21. VPC ENDPOINT SECURITY GROUP ID
# ============================================================
#
# Security group used by the Terraform-managed interface
# VPC endpoints:
#
#   - ECR API
#   - ECR DKR
#   - CloudWatch Logs
#
# ============================================================

output "vpc_endpoint_security_group_id" {

  description = "Security group ID used by CharlieCafe-TF VPC interface endpoints"

  value = aws_security_group.vpc_endpoint.id
}



# ============================================================
# 22. ECR API VPC ENDPOINT ID
# ============================================================
#
# Interface endpoint for the Amazon ECR API.
#
# ============================================================

output "ecr_api_vpc_endpoint_id" {

  description = "ID of the CharlieCafe-TF ECR API VPC interface endpoint"

  value = aws_vpc_endpoint.ecr_api.id
}



# ============================================================
# 23. ECR DKR VPC ENDPOINT ID
# ============================================================
#
# Interface endpoint for the Amazon ECR Docker Registry.
#
# ============================================================

output "ecr_dkr_vpc_endpoint_id" {

  description = "ID of the CharlieCafe-TF ECR Docker Registry VPC interface endpoint"

  value = aws_vpc_endpoint.ecr_dkr.id
}



# ============================================================
# 24. S3 VPC ENDPOINT ID
# ============================================================
#
# Gateway endpoint allowing private Terraform-managed ECS
# tasks to communicate with Amazon S3.
#
# ============================================================

output "s3_vpc_endpoint_id" {

  description = "ID of the CharlieCafe-TF S3 Gateway VPC endpoint"

  value = aws_vpc_endpoint.s3.id
}



# ============================================================
# 25. CLOUDWATCH LOGS VPC ENDPOINT ID
# ============================================================
#
# Interface endpoint used for private CloudWatch Logs
# connectivity.
#
# ============================================================

output "cloudwatch_logs_vpc_endpoint_id" {

  description = "ID of the CharlieCafe-TF CloudWatch Logs VPC interface endpoint"

  value = aws_vpc_endpoint.cloudwatch_logs.id
}



# ============================================================
# 26. CLOUDWATCH LOG GROUP
# ============================================================
#
# ECS container logs are stored in this CloudWatch log group.
#
# This log group should use the Terraform-specific naming
# convention.
#
# Expected name:
#
#   /ecs/charlie-cafe-tf
#
# ============================================================

output "ecs_log_group_name" {

  description = "CloudWatch Log Group used by CharlieCafe-TF ECS containers"

  value = aws_cloudwatch_log_group.ecs.name
}



# ============================================================
# 27. ECS EXECUTION ROLE ARN
# ============================================================
#
# IAM role used by Terraform-managed ECS/Fargate to:
#
#   - Pull images from ECR
#   - Send logs to CloudWatch Logs
#
# Expected Terraform naming pattern:
#
#   CharlieCafe-TF-ECSTaskExecutionRole
#
# ============================================================

output "ecs_task_execution_role_arn" {

  description = "ARN of the CharlieCafe-TF ECS task execution IAM role"

  value = aws_iam_role.ecs_task_execution.arn
}



# ============================================================
# 28. ECS TASK ROLE ARN
# ============================================================
#
# IAM role assigned to the application container itself.
#
# Expected Terraform naming pattern:
#
#   CharlieCafe-TF-ECSTaskRole
#
# ============================================================

output "ecs_task_role_arn" {

  description = "ARN of the CharlieCafe-TF ECS application task IAM role"

  value = aws_iam_role.ecs_task.arn
}



# ============================================================
# 29. CONTAINER PORT
# ============================================================
#
# Displays the application container port.
#
# ============================================================

output "container_port" {

  description = "Port exposed by the CharlieCafe-TF Docker container"

  value = var.container_port
}



# ============================================================
# 30. DEPLOYMENT SUMMARY
# ============================================================
#
# Provides a convenient structured output containing the most
# important information about the Terraform deployment.
#
# Useful command:
#
#   terraform output deployment_summary
#
# ============================================================

output "deployment_summary" {

  description = "Summary of the CharlieCafe-TF Terraform deployment"

  value = {

    # --------------------------------------------------------
    # Application
    # --------------------------------------------------------

    application_name = var.application_name


    # --------------------------------------------------------
    # Terraform project
    # --------------------------------------------------------

    project_name = var.project_name


    # --------------------------------------------------------
    # Environment
    # --------------------------------------------------------

    environment = var.environment


    # --------------------------------------------------------
    # AWS region
    # --------------------------------------------------------

    aws_region = data.aws_region.current.region


    # --------------------------------------------------------
    # VPC
    # --------------------------------------------------------

    vpc_id = aws_vpc.lab.id


    # --------------------------------------------------------
    # ECR
    # --------------------------------------------------------

    ecr_repository = aws_ecr_repository.charlie_cafe.repository_url

    ecr_image = "${aws_ecr_repository.charlie_cafe.repository_url}:latest"


    # --------------------------------------------------------
    # ECS
    # --------------------------------------------------------

    ecs_cluster = aws_ecs_cluster.charlie_cafe.name

    ecs_service = aws_ecs_service.charlie_cafe.name

    task_definition = aws_ecs_task_definition.charlie_cafe.arn

    task_family = aws_ecs_task_definition.charlie_cafe.family


    # --------------------------------------------------------
    # ALB
    # --------------------------------------------------------

    alb_dns_name = aws_lb.charlie_cafe.dns_name

    application_url = "http://${aws_lb.charlie_cafe.dns_name}"


    # --------------------------------------------------------
    # Container
    # --------------------------------------------------------

    container_port = var.container_port

  }
}


# ============================================================
# END OF outputs.tf
# ============================================================
#
# TERRAFORM NAMING SUMMARY
# ============================================================
#
# Project:
#   CharlieCafe-TF-Lab
#
# Application:
#   CharlieCafe-TF
#
# ECR:
#   charlie-cafe-tf
#
# ECS Cluster:
#   CharlieCafe-TF-Cluster
#
# ECS Service:
#   CharlieCafe-TF-Service
#
# ECS Task Family:
#   CharlieCafe-TF
#
# Database:
#   tflabdb
#
# ============================================================
#
# OUTPUT BLOCK NAMES REMAIN STABLE:
#
#   vpc_id
#   public_subnet_ids
#   private_subnet_ids
#   private_route_table_id
#   ecr_repository_name
#   ecr_repository_uri
#   ecr_image_url
#   ecs_cluster_name
#   ecs_cluster_arn
#   ecs_service_name
#   ecs_service_arn
#   ecs_task_definition_arn
#   ecs_task_definition_family
#   alb_arn
#   alb_dns_name
#   application_url
#   target_group_arn
#   target_group_name
#   alb_security_group_id
#   ecs_task_security_group_id
#   vpc_endpoint_security_group_id
#   ecr_api_vpc_endpoint_id
#   ecr_dkr_vpc_endpoint_id
#   s3_vpc_endpoint_id
#   cloudwatch_logs_vpc_endpoint_id
#   ecs_log_group_name
#   ecs_task_execution_role_arn
#   ecs_task_role_arn
#   container_port
#   deployment_summary
#
# Keeping these output names unchanged helps preserve
# compatibility with GitHub Actions and existing Terraform
# automation.
#
# ============================================================
