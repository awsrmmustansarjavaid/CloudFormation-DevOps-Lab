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
# Outputs are useful for:
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
# IMPORTANT:
#
# Terraform output BLOCK NAMES are Terraform identifiers.
#
# They do not need to contain "-TF".
#
# AWS resource names are controlled separately inside the
# corresponding Terraform resource definitions.
#
# ============================================================


# ============================================================
# 1. VPC OUTPUT
# ============================================================

output "vpc_id" {

  description = "ID of the CharlieCafe-TF-Lab VPC used by the Terraform infrastructure"

  value = aws_vpc.lab.id
}


# ============================================================
# 2. PUBLIC SUBNET OUTPUTS
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

output "private_route_table_id" {

  description = "ID of the CharlieCafe-TF private route table"

  value = aws_route_table.private.id
}


# ============================================================
# 5. ECR REPOSITORY NAME
# ============================================================

output "ecr_repository_name" {

  description = "Name of the CharlieCafe-TF ECR repository"

  value = aws_ecr_repository.charlie_cafe.name
}


# ============================================================
# 6. ECR REPOSITORY URI
# ============================================================

output "ecr_repository_uri" {

  description = "URI of the CharlieCafe-TF ECR repository"

  value = aws_ecr_repository.charlie_cafe.repository_url
}


# ============================================================
# 7. ECR IMAGE URL
# ============================================================

output "ecr_image_url" {

  description = "Full CharlieCafe-TF ECR image URI using the latest image tag"

  value = "${aws_ecr_repository.charlie_cafe.repository_url}:latest"
}


# ============================================================
# 8. ECS CLUSTER NAME
# ============================================================

output "ecs_cluster_name" {

  description = "Name of the CharlieCafe-TF ECS cluster"

  value = aws_ecs_cluster.charlie_cafe.name
}


# ============================================================
# 9. ECS CLUSTER ARN
# ============================================================

output "ecs_cluster_arn" {

  description = "ARN of the CharlieCafe-TF ECS cluster"

  value = aws_ecs_cluster.charlie_cafe.arn
}


# ============================================================
# 10. ECS SERVICE NAME
# ============================================================

output "ecs_service_name" {

  description = "Name of the CharlieCafe-TF ECS Fargate service"

  value = aws_ecs_service.charlie_cafe.name
}


# ============================================================
# 11. ECS SERVICE ARN
# ============================================================

output "ecs_service_arn" {

  description = "ARN or service identifier of the CharlieCafe-TF ECS service"

  value = aws_ecs_service.charlie_cafe.id
}


# ============================================================
# 12. ECS TASK DEFINITION ARN
# ============================================================

output "ecs_task_definition_arn" {

  description = "ARN of the CharlieCafe-TF ECS task definition"

  value = aws_ecs_task_definition.charlie_cafe.arn
}


# ============================================================
# 13. ECS TASK DEFINITION FAMILY
# ============================================================

output "ecs_task_definition_family" {

  description = "Family name of the CharlieCafe-TF ECS task definition"

  value = aws_ecs_task_definition.charlie_cafe.family
}


# ============================================================
# 14. ALB ARN
# ============================================================

output "alb_arn" {

  description = "ARN of the CharlieCafe-TF Application Load Balancer"

  value = aws_lb.charlie_cafe.arn
}


# ============================================================
# 15. ALB DNS NAME
# ============================================================

output "alb_dns_name" {

  description = "DNS name of the CharlieCafe-TF Application Load Balancer"

  value = aws_lb.charlie_cafe.dns_name
}


# ============================================================
# 16. APPLICATION URL
# ============================================================

output "application_url" {

  description = "Public HTTP URL for the CharlieCafe-TF application"

  value = "http://${aws_lb.charlie_cafe.dns_name}"
}


# ============================================================
# 17. TARGET GROUP ARN
# ============================================================

output "target_group_arn" {

  description = "ARN of the CharlieCafe-TF ALB target group"

  value = aws_lb_target_group.charlie_cafe.arn
}


# ============================================================
# 18. TARGET GROUP NAME
# ============================================================

output "target_group_name" {

  description = "Name of the CharlieCafe-TF ALB target group"

  value = aws_lb_target_group.charlie_cafe.name
}


# ============================================================
# 19. ALB SECURITY GROUP ID
# ============================================================

output "alb_security_group_id" {

  description = "Security group ID used by the CharlieCafe-TF ALB"

  value = aws_security_group.alb.id
}


# ============================================================
# 20. ECS TASK SECURITY GROUP ID
# ============================================================

output "ecs_task_security_group_id" {

  description = "Security group ID used by CharlieCafe-TF ECS tasks"

  value = aws_security_group.ecs_task.id
}


# ============================================================
# 21. VPC ENDPOINT SECURITY GROUP ID
# ============================================================

output "vpc_endpoint_security_group_id" {

  description = "Security group ID used by CharlieCafe-TF VPC interface endpoints"

  value = aws_security_group.vpc_endpoint.id
}


# ============================================================
# 22. ECR API VPC ENDPOINT ID
# ============================================================

output "ecr_api_vpc_endpoint_id" {

  description = "ID of the CharlieCafe-TF ECR API VPC interface endpoint"

  value = aws_vpc_endpoint.ecr_api.id
}


# ============================================================
# 23. ECR DKR VPC ENDPOINT ID
# ============================================================

output "ecr_dkr_vpc_endpoint_id" {

  description = "ID of the CharlieCafe-TF ECR Docker Registry VPC interface endpoint"

  value = aws_vpc_endpoint.ecr_dkr.id
}


# ============================================================
# 24. S3 VPC ENDPOINT ID
# ============================================================

output "s3_vpc_endpoint_id" {

  description = "ID of the CharlieCafe-TF S3 Gateway VPC endpoint"

  value = aws_vpc_endpoint.s3.id
}


# ============================================================
# 25. CLOUDWATCH LOGS VPC ENDPOINT ID
# ============================================================

output "cloudwatch_logs_vpc_endpoint_id" {

  description = "ID of the CharlieCafe-TF CloudWatch Logs VPC interface endpoint"

  value = aws_vpc_endpoint.cloudwatch_logs.id
}


# ============================================================
# 26. CLOUDWATCH LOG GROUP
# ============================================================

output "ecs_log_group_name" {

  description = "CloudWatch Log Group used by CharlieCafe-TF ECS containers"

  value = aws_cloudwatch_log_group.ecs.name
}


# ============================================================
# 27. ECS EXECUTION ROLE ARN
# ============================================================

output "ecs_task_execution_role_arn" {

  description = "ARN of the CharlieCafe-TF ECS task execution IAM role"

  value = aws_iam_role.ecs_task_execution.arn
}


# ============================================================
# 28. ECS TASK ROLE ARN
# ============================================================

output "ecs_task_role_arn" {

  description = "ARN of the CharlieCafe-TF ECS application task IAM role"

  value = aws_iam_role.ecs_task.arn
}


# ============================================================
# 29. CONTAINER PORT
# ============================================================

output "container_port" {

  description = "Port exposed by the CharlieCafe-TF Docker container"

  value = var.container_port
}


# ============================================================
# 30. DEPLOYMENT SUMMARY
# ============================================================

output "deployment_summary" {

  description = "Summary of the CharlieCafe-TF Terraform deployment"

  value = {

    application_name = var.application_name

    project_name = var.project_name

    environment = var.environment

    aws_region = data.aws_region.current.region

    vpc_id = aws_vpc.lab.id

    ecr_repository = aws_ecr_repository.charlie_cafe.repository_url

    ecr_image = "${aws_ecr_repository.charlie_cafe.repository_url}:latest"

    ecs_cluster = aws_ecs_cluster.charlie_cafe.name

    ecs_service = aws_ecs_service.charlie_cafe.name

    task_definition = aws_ecs_task_definition.charlie_cafe.arn

    task_family = aws_ecs_task_definition.charlie_cafe.family

    alb_dns_name = aws_lb.charlie_cafe.dns_name

    application_url = "http://${aws_lb.charlie_cafe.dns_name}"

    container_port = var.container_port
  }
}


# ============================================================
# 31. CLOUDFRONT DISTRIBUTION ID
# ============================================================
#
# Equivalent to the CloudFormation output:
#
#   CloudFrontDistributionId
#
# ============================================================

output "distribution_id" {

  description = "ID of the Charlie Cafe CloudFront distribution"

  value = aws_cloudfront_distribution.website.id
}


# ============================================================
# 32. CLOUDFRONT DISTRIBUTION DOMAIN NAME
# ============================================================
#
# Equivalent to the CloudFormation output:
#
#   CloudFrontDomainName
#
# Example:
#
#   d1234567890abc.cloudfront.net
#
# ============================================================

output "distribution_domain_name" {

  description = "Domain name assigned to the Charlie Cafe CloudFront distribution"

  value = aws_cloudfront_distribution.website.domain_name
}


# ============================================================
# 33. CLOUDFRONT WEBSITE URL
# ============================================================
#
# Equivalent to the CloudFormation output:
#
#   CloudFrontWebsiteURL
#
# The distribution redirects HTTP requests to HTTPS.
#
# ============================================================

output "website_url" {

  description = "HTTPS URL for the Charlie Cafe website served through CloudFront"

  value = "https://${aws_cloudfront_distribution.website.domain_name}"
}


# ============================================================
# 34. CLOUDFRONT OAC ID
# ============================================================
#
# Exposes the Origin Access Control ID used by CloudFront
# to securely access the S3 bucket.
#
# ============================================================

output "cloudfront_oac_id" {

  description = "ID of the CloudFront Origin Access Control protecting the S3 origin"

  value = aws_cloudfront_origin_access_control.website.id
}


# ============================================================
# 35. CLOUDFRONT OAC NAME
# ============================================================
#
# Exposes the human-readable OAC name.
#
# ============================================================

output "cloudfront_oac_name" {

  description = "Name of the CloudFront Origin Access Control"

  value = aws_cloudfront_origin_access_control.website.name
}


# ============================================================
# 36. WEBSITE S3 BUCKET NAME
# ============================================================
#
# Equivalent to the CloudFormation output:
#
#   WebsiteBucketName
#
# This is the Terraform-managed S3 bucket used as the
# CloudFront origin.
#
# ============================================================

output "website_bucket_name" {

  description = "Name of the S3 bucket used as the CloudFront website origin"

  value = aws_s3_bucket.lab.id
}


# ============================================================
# 37. WEBSITE S3 BUCKET ARN
# ============================================================
#
# ARN of the S3 bucket protected by the CloudFront bucket
# policy.
#
# ============================================================

output "website_bucket_arn" {

  description = "ARN of the S3 bucket used as the CloudFront website origin"

  value = aws_s3_bucket.lab.arn
}


# ============================================================
# 38. WEBSITE S3 REGIONAL DOMAIN
# ============================================================
#
# Regional S3 endpoint used by CloudFront.
#
# This is preferable to manually constructing:
#
#   bucket.s3.amazonaws.com
#
# because Terraform obtains the correct regional endpoint
# directly from the S3 resource.
#
# ============================================================

output "website_bucket_regional_domain_name" {

  description = "Regional S3 domain name used by the CloudFront origin"

  value = aws_s3_bucket.lab.bucket_regional_domain_name
}


# ============================================================
# END OF outputs.tf
# ============================================================