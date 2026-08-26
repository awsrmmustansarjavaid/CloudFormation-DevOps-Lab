# =========================================================
# Charlie Cafe
# Terraform Infrastructure
#
# File:
#   ecs_ecr.tf
#
# CloudFormation equivalent:
#   aws-ecs-ecr.yaml
#
# Purpose:
#   Creates the standalone ECS Fargate + ECR infrastructure
#   for the Charlie Cafe application.
#
# IMPORTANT:
#
# This Terraform configuration assumes that the following
# networking resources already exist:
#
#   - VPC
#   - Public Subnet 1
#   - Public Subnet 2
#   - Private Subnet 1
#   - Private Subnet 2
#   - Private Route Table
#
# These resources can be created by your Terraform network
# configuration.
#
# =========================================================
#
# ARCHITECTURE
#
#                         INTERNET
#                             |
#                             | HTTP :80
#                             v
#                    +----------------+
#                    |      ALB       |
#                    | Public Subnets |
#                    +----------------+
#                             |
#                             | HTTP
#                             v
#                    +----------------+
#                    | ECS Fargate    |
#                    | Private Subnet |
#                    +----------------+
#                             |
#                             v
#                    +----------------+
#                    | Docker Image   |
#                    |      ECR       |
#                    +----------------+
#
#
# PRIVATE AWS SERVICE CONNECTIVITY
#
# ECS Task
#    |
#    +---- ECR API VPC Endpoint
#    |
#    +---- ECR DKR VPC Endpoint
#    |
#    +---- S3 Gateway Endpoint
#    |
#    +---- CloudWatch Logs Endpoint
#
# No NAT Gateway is required for these AWS service
# connections.
#
# =========================================================


# =========================================================
# 1. VPC ENDPOINT SECURITY GROUP
# =========================================================
#
# This security group is attached to the INTERFACE VPC
# endpoints:
#
#   - ECR API
#   - ECR Docker Registry
#   - CloudWatch Logs
#
# ECS tasks communicate with these endpoints using HTTPS
# on TCP port 443.
#
# =========================================================

resource "aws_security_group" "vpc_endpoint" {

  name = "${var.application_name}-VPC-Endpoint-SG"

  description = "Allow HTTPS from ECS private subnets to AWS VPC endpoints"

  vpc_id = var.vpc_id


  # -------------------------------------------------------
  # HTTPS from Private Subnet 1
  # -------------------------------------------------------

  ingress {
    description = "HTTPS from Private Subnet 1"

    protocol = "tcp"

    from_port = 443

    to_port = 443

    cidr_blocks = [var.private_subnet_1_cidr]
  }


  # -------------------------------------------------------
  # HTTPS from Private Subnet 2
  # -------------------------------------------------------

  ingress {
    description = "HTTPS from Private Subnet 2"

    protocol = "tcp"

    from_port = 443

    to_port = 443

    cidr_blocks = [var.private_subnet_2_cidr]
  }


  # -------------------------------------------------------
  # Allow outbound traffic
  # -------------------------------------------------------

  egress {
    description = "Allow outbound traffic"

    protocol = "-1"

    from_port = 0

    to_port = 0

    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name    = "${var.application_name}-VPC-Endpoint-SG"
    Project = var.application_name
  }
}


# =========================================================
# 2. ECR API VPC ENDPOINT
# =========================================================
#
# Allows ECS tasks to communicate privately with the
# Amazon ECR API.
#
# CloudFormation:
#
#   com.amazonaws.${AWS::Region}.ecr.api
#
# Terraform automatically builds the regional endpoint
# using the current AWS provider region.
#
# =========================================================

resource "aws_vpc_endpoint" "ecr_api" {

  vpc_id = var.vpc_id

  service_name = "com.amazonaws.${var.aws_region}.ecr.api"

  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  subnet_ids = [
    var.private_subnet_1_id,
    var.private_subnet_2_id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoint.id
  ]

  tags = {
    Name    = "${var.application_name}-ECR-API-VPC-Endpoint"
    Project = var.application_name
  }
}


# =========================================================
# 3. ECR DOCKER REGISTRY VPC ENDPOINT
# =========================================================
#
# ECS/Fargate uses this endpoint when communicating with
# the ECR Docker registry.
#
# =========================================================

resource "aws_vpc_endpoint" "ecr_dkr" {

  vpc_id = var.vpc_id

  service_name = "com.amazonaws.${var.aws_region}.ecr.dkr"

  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  subnet_ids = [
    var.private_subnet_1_id,
    var.private_subnet_2_id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoint.id
  ]

  tags = {
    Name    = "${var.application_name}-ECR-DKR-VPC-Endpoint"
    Project = var.application_name
  }
}


# =========================================================
# 4. S3 GATEWAY VPC ENDPOINT
# =========================================================
#
# ECR uses Amazon S3 for Docker image layers.
#
# Therefore ECS tasks pulling images from ECR also require
# access to S3.
#
# This is a GATEWAY endpoint rather than an interface
# endpoint.
#
# The endpoint is associated with the private route table.
#
# =========================================================

resource "aws_vpc_endpoint" "s3" {

  vpc_id = var.vpc_id

  service_name = "com.amazonaws.${var.aws_region}.s3"

  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    var.private_route_table_id
  ]

  tags = {
    Name    = "${var.application_name}-S3-Gateway-VPC-Endpoint"
    Project = var.application_name
  }
}


# =========================================================
# 5. CLOUDWATCH LOGS VPC ENDPOINT
# =========================================================
#
# ECS uses the awslogs logging driver.
#
# Container stdout/stderr is sent to CloudWatch Logs.
#
# Because the ECS tasks run in private subnets and this lab
# intentionally does not use a NAT Gateway, we provide a
# private interface endpoint for CloudWatch Logs.
#
# =========================================================

resource "aws_vpc_endpoint" "cloudwatch_logs" {

  vpc_id = var.vpc_id

  service_name = "com.amazonaws.${var.aws_region}.logs"

  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  subnet_ids = [
    var.private_subnet_1_id,
    var.private_subnet_2_id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoint.id
  ]

  tags = {
    Name    = "${var.application_name}-CloudWatch-Logs-VPC-Endpoint"
    Project = var.application_name
  }
}


# =========================================================
# 6. ECR REPOSITORY
# =========================================================
#
# This repository stores the Charlie Cafe Docker image.
#
# IMPORTANT:
#
# Terraform creates the repository.
#
# Terraform does NOT need to build the Docker image.
#
# Your GitHub Actions pipeline will later:
#
#   1. Build Docker image
#   2. Authenticate with ECR
#   3. Tag image
#   4. Push image to ECR
#   5. ECS pulls the image
#
# =========================================================

resource "aws_ecr_repository" "charlie_cafe" {

  name = var.ecr_repository_name


  # -------------------------------------------------------
  # Scan images when they are pushed
  # -------------------------------------------------------

  image_scanning_configuration {
    scan_on_push = true
  }


  # -------------------------------------------------------
  # Mutable image tags
  #
  # This preserves the current CloudFormation behavior:
  #
  #   latest
  #
  # can point to a newer image.
  #
  # -------------------------------------------------------

  image_tag_mutability = "MUTABLE"


  # -------------------------------------------------------
  # Server-side encryption
  # -------------------------------------------------------

  encryption_configuration {
    encryption_type = "AES256"
  }


  tags = {
    Name    = "${var.application_name}-ECR"
    Project = var.application_name
  }
}


# =========================================================
# 7. ECS CLUSTER
# =========================================================
#
# ECS Fargate is serverless container infrastructure.
#
# We do not create EC2 instances for the cluster.
#
# AWS manages the underlying compute infrastructure.
#
# =========================================================

resource "aws_ecs_cluster" "charlie_cafe" {

  name = var.ecs_cluster_name


  # -------------------------------------------------------
  # Enable CloudWatch Container Insights
  # -------------------------------------------------------

  setting {
    name  = "containerInsights"
    value = "enabled"
  }


  tags = {
    Name    = var.ecs_cluster_name
    Project = var.application_name
  }
}


# =========================================================
# 8. CLOUDWATCH LOG GROUP
# =========================================================
#
# ECS container logs are written to this log group.
#
# CloudFormation equivalent:
#
#   /ecs/charlie-cafe
#
# =========================================================

resource "aws_cloudwatch_log_group" "ecs" {

  name = "/ecs/charlie-cafe"

  retention_in_days = 30

  tags = {
    Project = var.application_name
  }
}


# =========================================================
# 9. ECS TASK EXECUTION IAM ROLE
# =========================================================
#
# This role is used by the ECS/Fargate platform.
#
# It allows ECS to:
#
#   - Pull images from ECR
#   - Send container logs to CloudWatch Logs
#
# IMPORTANT:
#
# This is different from the ECS TASK ROLE.
#
# =========================================================

resource "aws_iam_role" "ecs_task_execution" {

  name = "${var.application_name}-ECSTaskExecutionRole"


  # -------------------------------------------------------
  # Trust policy
  #
  # Allows ECS tasks service to assume this role.
  # -------------------------------------------------------

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }

    ]
  })


  tags = {
    Name    = "${var.application_name}-ECSTaskExecutionRole"
    Project = var.application_name
  }
}


# ---------------------------------------------------------
# Attach AWS managed ECS execution policy
# ---------------------------------------------------------

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {

  role = aws_iam_role.ecs_task_execution.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# =========================================================
# 10. ECS TASK IAM ROLE
# =========================================================
#
# This role belongs to the application running INSIDE the
# Docker container.
#
# Currently it has no additional permissions.
#
# Later this can be extended for:
#
#   - S3
#   - DynamoDB
#   - Secrets Manager
#   - KMS
#
# =========================================================

resource "aws_iam_role" "ecs_task" {

  name = "${var.application_name}-ECSTaskRole"


  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }

    ]
  })


  tags = {
    Name    = "${var.application_name}-ECSTaskRole"
    Project = var.application_name
  }
}


# =========================================================
# 11. ALB SECURITY GROUP
# =========================================================
#
# Internet
#    |
#    | TCP 80
#    v
#   ALB
#
# =========================================================

resource "aws_security_group" "alb" {

  name = "${var.application_name}-ALB-SG"

  description = "Allow HTTP traffic to Charlie Cafe Application Load Balancer"

  vpc_id = var.vpc_id


  ingress {

    description = "Allow HTTP from Internet"

    protocol = "tcp"

    from_port = 80

    to_port = 80

    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {

    description = "Allow outbound traffic"

    protocol = "-1"

    from_port = 0

    to_port = 0

    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name    = "${var.application_name}-ALB-SG"
    Project = var.application_name
  }
}


# =========================================================
# 12. ECS TASK SECURITY GROUP
# =========================================================
#
# IMPORTANT SECURITY DESIGN:
#
# Internet
#     |
#     v
#    ALB
#     |
#     | Container Port
#     v
#    ECS
#
# ECS does NOT allow direct internet access.
#
# Only the ALB security group can access the ECS task.
#
# =========================================================

resource "aws_security_group" "ecs_task" {

  name = "${var.application_name}-ECS-Task-SG"

  description = "Allow application traffic only from the ALB"

  vpc_id = var.vpc_id


  ingress {

    description = "Allow application traffic from ALB"

    protocol = "tcp"

    from_port = var.container_port

    to_port = var.container_port

    security_groups = [
      aws_security_group.alb.id
    ]
  }


  egress {

    description = "Allow outbound traffic"

    protocol = "-1"

    from_port = 0

    to_port = 0

    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name    = "${var.application_name}-ECS-Task-SG"
    Project = var.application_name
  }
}


# =========================================================
# 13. APPLICATION LOAD BALANCER
# =========================================================
#
# Internet-facing ALB.
#
# ALB is deployed into PUBLIC subnets.
#
# ECS tasks remain in PRIVATE subnets.
#
# =========================================================

resource "aws_lb" "charlie_cafe" {

  name = "${var.application_name}-ALB"

  internal = false

  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    var.public_subnet_1_id,
    var.public_subnet_2_id
  ]


  tags = {
    Name    = "${var.application_name}-ALB"
    Project = var.application_name
  }
}


# =========================================================
# 14. ALB TARGET GROUP
# =========================================================
#
# Fargate uses awsvpc networking.
#
# Therefore:
#
#   target_type = "ip"
#
# ECS registers the private IP address of each task.
#
# =========================================================

resource "aws_lb_target_group" "charlie_cafe" {

  name = "${var.application_name}-TG"

  port = var.container_port

  protocol = "HTTP"

  vpc_id = var.vpc_id

  target_type = "ip"


  # -------------------------------------------------------
  # Health check
  # -------------------------------------------------------

  health_check {

    enabled = true

    protocol = "HTTP"

    path = "/"

    port = "traffic-port"

    interval = 30

    timeout = 5

    healthy_threshold = 2

    unhealthy_threshold = 3
  }


  tags = {
    Name    = "${var.application_name}-TG"
    Project = var.application_name
  }
}


# =========================================================
# 15. ALB HTTP LISTENER
# =========================================================
#
# HTTP :80
#
# HTTPS + ACM intentionally remain outside this beginner
# configuration.
#
# =========================================================

resource "aws_lb_listener" "http" {

  load_balancer_arn = aws_lb.charlie_cafe.arn

  port = 80

  protocol = "HTTP"


  default_action {

    type = "forward"

    target_group_arn = aws_lb_target_group.charlie_cafe.arn
  }
}


# =========================================================
# 16. ECS TASK DEFINITION
# =========================================================
#
# Defines the Docker container configuration.
#
# Includes:
#
#   - CPU
#   - Memory
#   - Docker image
#   - Container port
#   - Execution role
#   - Task role
#   - CloudWatch logging
#
# =========================================================

resource "aws_ecs_task_definition" "charlie_cafe" {

  family = var.ecs_task_family


  # -------------------------------------------------------
  # Fargate networking
  # -------------------------------------------------------

  network_mode = "awsvpc"


  # -------------------------------------------------------
  # Fargate launch type
  # -------------------------------------------------------

  requires_compatibilities = [
    "FARGATE"
  ]


  # -------------------------------------------------------
  # CPU and memory
  # -------------------------------------------------------

  cpu = var.task_cpu

  memory = var.task_memory


  # -------------------------------------------------------
  # ECS execution role
  # -------------------------------------------------------

  execution_role_arn = aws_iam_role.ecs_task_execution.arn


  # -------------------------------------------------------
  # Application task role
  # -------------------------------------------------------

  task_role_arn = aws_iam_role.ecs_task.arn


  # -------------------------------------------------------
  # Container definition
  # -------------------------------------------------------
  #
  # Terraform requires container_definitions as JSON.
  #
  # jsonencode() converts the Terraform object into the
  # JSON format expected by ECS.
  #
  # -------------------------------------------------------

  container_definitions = jsonencode([

    {

      name = "charlie-cafe"

      # ---------------------------------------------------
      # Docker image
      #
      # GitHub Actions will push:
      #
      #   charlie-cafe:latest
      #
      # ECS will pull that image from ECR.
      # ---------------------------------------------------

      image = "${aws_ecr_repository.charlie_cafe.repository_url}:latest"

      essential = true


      # ---------------------------------------------------
      # Container port
      # ---------------------------------------------------

      portMappings = [

        {
          containerPort = var.container_port

          protocol = "tcp"
        }

      ]


      # ---------------------------------------------------
      # CloudWatch Logs
      # ---------------------------------------------------

      logConfiguration = {

        logDriver = "awslogs"

        options = {

          "awslogs-group" = aws_cloudwatch_log_group.ecs.name

          "awslogs-region" = var.aws_region

          "awslogs-stream-prefix" = "ecs"
        }
      }
    }

  ])


  tags = {
    Name    = var.ecs_task_family
    Project = var.application_name
  }
}


# =========================================================
# 17. ECS FARGATE SERVICE
# =========================================================
#
# The ECS service maintains the desired number of running
# tasks.
#
# If a task fails, ECS attempts to replace it.
#
# =========================================================

resource "aws_ecs_service" "charlie_cafe" {

  name = var.ecs_service_name

  cluster = aws_ecs_cluster.charlie_cafe.id

  launch_type = "FARGATE"

  desired_count = var.ecs_desired_count

  task_definition = aws_ecs_task_definition.charlie_cafe.arn


  # -------------------------------------------------------
  # Network configuration
  # -------------------------------------------------------
  #
  # Tasks run in private subnets.
  #
  # Public IP is disabled.
  #
  # -------------------------------------------------------

  network_configuration {

    assign_public_ip = false

    security_groups = [
      aws_security_group.ecs_task.id
    ]

    subnets = [
      var.private_subnet_1_id,
      var.private_subnet_2_id
    ]
  }


  # -------------------------------------------------------
  # Connect ECS container to ALB target group
  # -------------------------------------------------------

  load_balancer {

    target_group_arn = aws_lb_target_group.charlie_cafe.arn

    container_name = "charlie-cafe"

    container_port = var.container_port
  }


  # -------------------------------------------------------
  # Deployment configuration
  # -------------------------------------------------------

  deployment_maximum_percent = 200

  deployment_minimum_healthy_percent = 50


  # -------------------------------------------------------
  # Ensure ALB listener exists before ECS service creation.
  # -------------------------------------------------------

  depends_on = [
    aws_lb_listener.http
  ]


  tags = {
    Name    = var.ecs_service_name
    Project = var.application_name
  }
}


# =========================================================
# OPTIONAL / USEFUL OUTPUTS
# =========================================================
#
# These outputs correspond to the important CloudFormation
# stack outputs.
#
# If you already have outputs.tf, move these blocks there.
#
# =========================================================


# ---------------------------------------------------------
# ECR Repository Name
# ---------------------------------------------------------

output "ecr_repository_name" {

  description = "Name of the Charlie Cafe ECR repository"

  value = aws_ecr_repository.charlie_cafe.name
}


# ---------------------------------------------------------
# ECR Repository URI
# ---------------------------------------------------------

output "ecr_repository_uri" {

  description = "URI of the Charlie Cafe ECR repository"

  value = aws_ecr_repository.charlie_cafe.repository_url
}


# ---------------------------------------------------------
# ECS Cluster Name
# ---------------------------------------------------------

output "ecs_cluster_name" {

  description = "Name of the Charlie Cafe ECS cluster"

  value = aws_ecs_cluster.charlie_cafe.name
}


# ---------------------------------------------------------
# ECS Service Name
# ---------------------------------------------------------

output "ecs_service_name" {

  description = "Name of the Charlie Cafe ECS service"

  value = aws_ecs_service.charlie_cafe.name
}


# ---------------------------------------------------------
# ECS Task Definition ARN
# ---------------------------------------------------------

output "ecs_task_definition_arn" {

  description = "ARN of the Charlie Cafe ECS task definition"

  value = aws_ecs_task_definition.charlie_cafe.arn
}


# ---------------------------------------------------------
# ALB DNS Name
# ---------------------------------------------------------

output "alb_dns_name" {

  description = "DNS name of the Charlie Cafe Application Load Balancer"

  value = aws_lb.charlie_cafe.dns_name
}


# ---------------------------------------------------------
# Application URL
# ---------------------------------------------------------

output "application_url" {

  description = "Public HTTP URL for the Charlie Cafe ECS application"

  value = "http://${aws_lb.charlie_cafe.dns_name}"
}


# ---------------------------------------------------------
# ALB Security Group ID
# ---------------------------------------------------------

output "alb_security_group_id" {

  description = "Security group ID used by the Application Load Balancer"

  value = aws_security_group.alb.id
}


# ---------------------------------------------------------
# ECS Task Security Group ID
# ---------------------------------------------------------

output "ecs_task_security_group_id" {

  description = "Security group ID used by ECS Fargate tasks"

  value = aws_security_group.ecs_task.id
}


# ---------------------------------------------------------
# VPC Endpoint Security Group ID
# ---------------------------------------------------------

output "vpc_endpoint_security_group_id" {

  description = "Security group ID used by interface VPC endpoints"

  value = aws_security_group.vpc_endpoint.id
}