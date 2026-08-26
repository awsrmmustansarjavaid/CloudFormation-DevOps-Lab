# ============================================================
# Charlie Cafe
# Terraform Infrastructure
#
# File:
#   outputs.tf
#
# Purpose:
#   Exposes important information about the Charlie Cafe
#   AWS infrastructure after Terraform deployment.
#
# These outputs are useful for:
#
#   - Terraform users
#   - GitHub Actions
#   - CI/CD pipelines
#   - AWS verification
#   - Application testing
#   - Troubleshooting
#
# ============================================================
#
# IMPORTANT:
#
# Networking resources are created in network.tf.
#
# ECS/ECR/ALB resources are created in ecs_ecr.tf.
#
# This file ONLY contains Terraform output blocks.
#
# ============================================================



# ============================================================
# 1. VPC OUTPUT
# ============================================================
#
# Displays the ID of the VPC used by Charlie Cafe.
#
# The VPC itself is created in network.tf.
#
# ============================================================

output "vpc_id" {

  description = "ID of the VPC used by the Charlie Cafe infrastructure"

  value = aws_vpc.lab.id
}



# ============================================================
# 2. PUBLIC SUBNET OUTPUTS
# ============================================================
#
# These are the public subnets used by the Application Load
# Balancer.
#
# ALB:
#
#   Internet
#       |
#       v
#   Public Subnets
#
# ============================================================

output "public_subnet_ids" {

  description = "IDs of the public subnets used by the Charlie Cafe ALB"

  value = [
    aws_subnet.public[0].id,
    aws_subnet.public[1].id
  ]
}



# ============================================================
# 3. PRIVATE SUBNET OUTPUTS
# ============================================================
#
# These are the private subnets used by ECS Fargate tasks.
#
# ECS tasks do not receive public IP addresses.
#
# ============================================================

output "private_subnet_ids" {

  description = "IDs of the private subnets used by Charlie Cafe ECS tasks"

  value = [
    aws_subnet.private[0].id,
    aws_subnet.private[1].id
  ]
}



# ============================================================
# 4. PRIVATE ROUTE TABLE OUTPUT
# ============================================================
#
# This route table is associated with the private subnets and
# is also used by the S3 Gateway VPC endpoint.
#
# ============================================================

output "private_route_table_id" {

  description = "ID of the private route table used by Charlie Cafe"

  value = aws_route_table.private.id
}



# ============================================================
# 5. ECR REPOSITORY NAME
# ============================================================
#
# Name of the ECR repository where the Charlie Cafe Docker
# image is stored.
#
# Example:
#
#   charlie-cafe
#
# ============================================================

output "ecr_repository_name" {

  description = "Name of the Charlie Cafe ECR repository"

  value = aws_ecr_repository.charlie_cafe.name
}



# ============================================================
# 6. ECR REPOSITORY URI
# ============================================================
#
# Full URI of the ECR repository.
#
# GitHub Actions can use this URI when tagging and pushing
# Docker images.
#
# Example:
#
#   <account>.dkr.ecr.<region>.amazonaws.com/charlie-cafe
#
# ============================================================

output "ecr_repository_uri" {

  description = "URI of the Charlie Cafe ECR repository"

  value = aws_ecr_repository.charlie_cafe.repository_url
}



# ============================================================
# 7. ECR IMAGE URL
# ============================================================
#
# Full URI for the latest Docker image.
#
# GitHub Actions can push:
#
#   charlie-cafe:latest
#
# ECS can then pull:
#
#   <repository-uri>:latest
#
# ============================================================

output "ecr_image_url" {

  description = "Full ECR image URI using the latest image tag"

  value = "${aws_ecr_repository.charlie_cafe.repository_url}:latest"
}



# ============================================================
# 8. ECS CLUSTER NAME
# ============================================================
#
# Name of the ECS cluster.
#
# ============================================================

output "ecs_cluster_name" {

  description = "Name of the Charlie Cafe ECS cluster"

  value = aws_ecs_cluster.charlie_cafe.name
}



# ============================================================
# 9. ECS CLUSTER ARN
# ============================================================
#
# ARN of the ECS cluster.
#
# Useful for AWS CLI commands and CI/CD automation.
#
# ============================================================

output "ecs_cluster_arn" {

  description = "ARN of the Charlie Cafe ECS cluster"

  value = aws_ecs_cluster.charlie_cafe.arn
}



# ============================================================
# 10. ECS SERVICE NAME
# ============================================================
#
# Name of the ECS Fargate service.
#
# ============================================================

output "ecs_service_name" {

  description = "Name of the Charlie Cafe ECS service"

  value = aws_ecs_service.charlie_cafe.name
}



# ============================================================
# 11. ECS SERVICE ARN
# ============================================================
#
# ARN of the ECS service.
#
# ============================================================

output "ecs_service_arn" {

  description = "ARN of the Charlie Cafe ECS service"

  value = aws_ecs_service.charlie_cafe.id
}



# ============================================================
# 12. ECS TASK DEFINITION ARN
# ============================================================
#
# ARN of the currently deployed ECS task definition.
#
# ============================================================

output "ecs_task_definition_arn" {

  description = "ARN of the Charlie Cafe ECS task definition"

  value = aws_ecs_task_definition.charlie_cafe.arn
}



# ============================================================
# 13. ECS TASK DEFINITION FAMILY
# ============================================================
#
# Task definition family name.
#
# Example:
#
#   charlie-cafe
#
# ============================================================

output "ecs_task_definition_family" {

  description = "Family name of the Charlie Cafe ECS task definition"

  value = aws_ecs_task_definition.charlie_cafe.family
}



# ============================================================
# 14. ALB ARN
# ============================================================
#
# ARN of the Application Load Balancer.
#
# ============================================================

output "alb_arn" {

  description = "ARN of the Charlie Cafe Application Load Balancer"

  value = aws_lb.charlie_cafe.arn
}



# ============================================================
# 15. ALB DNS NAME
# ============================================================
#
# DNS hostname automatically assigned to the Application
# Load Balancer.
#
# ============================================================

output "alb_dns_name" {

  description = "DNS name of the Charlie Cafe Application Load Balancer"

  value = aws_lb.charlie_cafe.dns_name
}



# ============================================================
# 16. APPLICATION URL
# ============================================================
#
# Public HTTP URL for the Charlie Cafe application.
#
# Current configuration uses HTTP port 80.
#
# HTTPS/ACM can be added later.
#
# ============================================================

output "application_url" {

  description = "Public HTTP URL for the Charlie Cafe application"

  value = "http://${aws_lb.charlie_cafe.dns_name}"
}



# ============================================================
# 17. TARGET GROUP ARN
# ============================================================
#
# ARN of the ALB target group used by ECS.
#
# ============================================================

output "target_group_arn" {

  description = "ARN of the Charlie Cafe ALB target group"

  value = aws_lb_target_group.charlie_cafe.arn
}



# ============================================================
# 18. TARGET GROUP NAME
# ============================================================
#
# Name of the ALB target group.
#
# ============================================================

output "target_group_name" {

  description = "Name of the Charlie Cafe ALB target group"

  value = aws_lb_target_group.charlie_cafe.name
}



# ============================================================
# 19. ALB SECURITY GROUP ID
# ============================================================
#
# Security group attached to the public Application Load
# Balancer.
#
# ============================================================

output "alb_security_group_id" {

  description = "Security group ID used by the Charlie Cafe ALB"

  value = aws_security_group.alb.id
}



# ============================================================
# 20. ECS TASK SECURITY GROUP ID
# ============================================================
#
# Security group attached to ECS Fargate tasks.
#
# Only traffic originating from the ALB security group is
# allowed on the application container port.
#
# ============================================================

output "ecs_task_security_group_id" {

  description = "Security group ID used by Charlie Cafe ECS tasks"

  value = aws_security_group.ecs_task.id
}



# ============================================================
# 21. VPC ENDPOINT SECURITY GROUP ID
# ============================================================
#
# Security group used by the interface VPC endpoints:
#
#   - ECR API
#   - ECR DKR
#   - CloudWatch Logs
#
# ============================================================

output "vpc_endpoint_security_group_id" {

  description = "Security group ID used by Charlie Cafe VPC interface endpoints"

  value = aws_security_group.vpc_endpoint.id
}



# ============================================================
# 22. ECR API VPC ENDPOINT ID
# ============================================================
#
# Interface endpoint for Amazon ECR API.
#
# ============================================================

output "ecr_api_vpc_endpoint_id" {

  description = "ID of the ECR API VPC interface endpoint"

  value = aws_vpc_endpoint.ecr_api.id
}



# ============================================================
# 23. ECR DKR VPC ENDPOINT ID
# ============================================================
#
# Interface endpoint for the ECR Docker Registry.
#
# ============================================================

output "ecr_dkr_vpc_endpoint_id" {

  description = "ID of the ECR Docker Registry VPC interface endpoint"

  value = aws_vpc_endpoint.ecr_dkr.id
}



# ============================================================
# 24. S3 VPC ENDPOINT ID
# ============================================================
#
# Gateway endpoint allowing private ECS tasks to communicate
# with Amazon S3.
#
# ============================================================

output "s3_vpc_endpoint_id" {

  description = "ID of the S3 Gateway VPC endpoint"

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

  description = "ID of the CloudWatch Logs VPC interface endpoint"

  value = aws_vpc_endpoint.cloudwatch_logs.id
}



# ============================================================
# 26. CLOUDWATCH LOG GROUP
# ============================================================
#
# ECS container logs are stored in this CloudWatch log group.
#
# ============================================================

output "ecs_log_group_name" {

  description = "CloudWatch Log Group used by Charlie Cafe ECS containers"

  value = aws_cloudwatch_log_group.ecs.name
}



# ============================================================
# 27. ECS EXECUTION ROLE ARN
# ============================================================
#
# IAM role used by ECS/Fargate to:
#
#   - Pull images from ECR
#   - Send logs to CloudWatch Logs
#
# ============================================================

output "ecs_task_execution_role_arn" {

  description = "ARN of the ECS task execution IAM role"

  value = aws_iam_role.ecs_task_execution.arn
}



# ============================================================
# 28. ECS TASK ROLE ARN
# ============================================================
#
# IAM role assigned to the application container itself.
#
# ============================================================

output "ecs_task_role_arn" {

  description = "ARN of the ECS application task IAM role"

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

  description = "Port exposed by the Charlie Cafe Docker container"

  value = var.container_port
}



# ============================================================
# 30. DEPLOYMENT SUMMARY
# ============================================================
#
# A convenient structured output containing the most important
# deployment information.
#
# This is especially useful when inspecting:
#
#   terraform output deployment_summary
#
# ============================================================

output "deployment_summary" {

  description = "Summary of the Charlie Cafe ECS deployment"

  value = {

    application_name = var.application_name

    aws_region = data.aws_region.current.name

    vpc_id = aws_vpc.lab.id

    ecr_repository = aws_ecr_repository.charlie_cafe.repository_url

    ecs_cluster = aws_ecs_cluster.charlie_cafe.name

    ecs_service = aws_ecs_service.charlie_cafe.name

    task_definition = aws_ecs_task_definition.charlie_cafe.arn

    alb_dns_name = aws_lb.charlie_cafe.dns_name

    application_url = "http://${aws_lb.charlie_cafe.dns_name}"

    container_port = var.container_port

  }
}