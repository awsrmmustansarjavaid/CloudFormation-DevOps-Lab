# ============================================================
# CHARLIE CAFE - TERRAFORM DEVOPS LAB
#
# File:
#   ecs_ecr.tf
#
# Purpose:
#   Creates the ECS Fargate + ECR infrastructure for the
#   Charlie Cafe Terraform application.
#
# ============================================================
#
# TERRAFORM NAMING STANDARD
# ============================================================
#
# This repository contains BOTH:
#
#   1. AWS CloudFormation infrastructure
#   2. AWS Terraform infrastructure
#
# To prevent resource-name confusion and AWS naming conflicts,
# all Terraform-created AWS resources use the "TF" identifier.
#
# Main naming convention:
#
#   CharlieCafe-TF-<Resource>
#
# ECR naming convention:
#
#   charlie-cafe-tf
#
# Examples:
#
#   CharlieCafe-TF-Lab
#   CharlieCafe-TF-Cluster
#   CharlieCafe-TF-Service
#   CharlieCafe-TF
#   charlie-cafe-tf
#
# ============================================================
#
# IMPORTANT:
#
# Terraform resource addresses such as:
#
#   aws_ecs_cluster.charlie_cafe
#   aws_ecs_service.charlie_cafe
#   aws_ecr_repository.charlie_cafe
#
# are INTERNAL Terraform identifiers.
#
# They do NOT need to match the AWS resource name.
#
# Therefore they are intentionally preserved so that existing
# Terraform references and state relationships do not needlessly
# change.
#
# ============================================================
#
# NETWORKING
# ============================================================
#
# Networking resources are NOT created in this file.
#
# They are already created by network.tf:
#
#   - VPC
#   - Public Subnet 1
#   - Public Subnet 2
#   - Private Subnet 1
#   - Private Subnet 2
#   - Private Route Table
#
# Therefore this file directly references those Terraform
# resources.
#
# ============================================================
#
# NETWORK RESOURCE REFERENCES
# ============================================================
#
# VPC:
#
#   aws_vpc.lab.id
#
# Public subnets:
#
#   aws_subnet.public[0].id
#   aws_subnet.public[1].id
#
# Private subnets:
#
#   aws_subnet.private[0].id
#   aws_subnet.private[1].id
#
# Private route table:
#
#   aws_route_table.private.id
#
# Private subnet CIDRs:
#
#   aws_subnet.private[0].cidr_block
#   aws_subnet.private[1].cidr_block
#
# ============================================================
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
#                    |      ECR       |
#                    | Docker Image   |
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
# This allows ECS tasks to communicate with the required
# AWS services without requiring a NAT Gateway for those
# AWS service connections.
#
# ============================================================


# ============================================================
# 1. AWS REGION DATA SOURCE
# ============================================================
#
# The AWS provider determines the active region.
#
# Using aws_region.current.name avoids requiring an additional
# AWS region data source variable.
#
# ============================================================

data "aws_region" "current" {}



# ============================================================
# 2. VPC ENDPOINT SECURITY GROUP
# ============================================================
#
# This security group is attached to the INTERFACE VPC
# endpoints:
#
#   - ECR API
#   - ECR Docker Registry
#   - CloudWatch Logs
#
# ECS tasks communicate with these endpoints over HTTPS
# using TCP port 443.
#
# ============================================================

resource "aws_security_group" "vpc_endpoint" {

  # ----------------------------------------------------------
  # Terraform-specific AWS resource name
  # ----------------------------------------------------------

  name = "${var.application_name}-VPC-Endpoint-SG"

  description = "Allow HTTPS from Charlie Cafe Terraform private subnets to AWS VPC endpoints"

  # Existing VPC from network.tf
  vpc_id = aws_vpc.lab.id


  # ----------------------------------------------------------
  # HTTPS from Private Subnet 1
  # ----------------------------------------------------------

  ingress {

    description = "HTTPS from CharlieCafe-TF Private Subnet 1"

    protocol = "tcp"

    from_port = 443

    to_port = 443

    cidr_blocks = [
      aws_subnet.private[0].cidr_block
    ]
  }


  # ----------------------------------------------------------
  # HTTPS from Private Subnet 2
  # ----------------------------------------------------------

  ingress {

    description = "HTTPS from CharlieCafe-TF Private Subnet 2"

    protocol = "tcp"

    from_port = 443

    to_port = 443

    cidr_blocks = [
      aws_subnet.private[1].cidr_block
    ]
  }


  # ----------------------------------------------------------
  # Outbound traffic
  # ----------------------------------------------------------

  egress {

    description = "Allow outbound traffic"

    protocol = "-1"

    from_port = 0

    to_port = 0

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }


  tags = {

    Name = "${var.application_name}-VPC-Endpoint-SG"

    Project = var.project_name

    Terraform = "true"
  }
}



# ============================================================
# 3. ECR API VPC ENDPOINT
# ============================================================
#
# Allows ECS/Fargate tasks to communicate privately with the
# Amazon ECR API.
#
# AWS service:
#
#   com.amazonaws.<region>.ecr.api
#
# This is an INTERFACE endpoint.
#
# ============================================================

resource "aws_vpc_endpoint" "ecr_api" {

  # Existing VPC from network.tf
  vpc_id = aws_vpc.lab.id

  # Build regional ECR API service name automatically.
  service_name = "com.amazonaws.${data.aws_region.current.name}.ecr.api"

  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  # Existing private subnets from network.tf.
  subnet_ids = [
    aws_subnet.private[0].id,
    aws_subnet.private[1].id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoint.id
  ]

  tags = {

    Name = "${var.application_name}-ECR-API-VPC-Endpoint"

    Project = var.project_name

    Terraform = "true"
  }
}



# ============================================================
# 4. ECR DOCKER REGISTRY VPC ENDPOINT
# ============================================================
#
# ECS/Fargate uses the ECR Docker Registry endpoint when
# communicating with the Docker registry.
#
# AWS service:
#
#   com.amazonaws.<region>.ecr.dkr
#
# This is an INTERFACE endpoint.
#
# ============================================================

resource "aws_vpc_endpoint" "ecr_dkr" {

  # Existing VPC from network.tf
  vpc_id = aws_vpc.lab.id

  service_name = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"

  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  # Existing private subnets from network.tf.
  subnet_ids = [
    aws_subnet.private[0].id,
    aws_subnet.private[1].id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoint.id
  ]

  tags = {

    Name = "${var.application_name}-ECR-DKR-VPC-Endpoint"

    Project = var.project_name

    Terraform = "true"
  }
}



# ============================================================
# 5. S3 GATEWAY VPC ENDPOINT
# ============================================================
#
# ECR stores Docker image layers in Amazon S3.
#
# Therefore private ECS tasks pulling images from ECR also
# require access to S3.
#
# This is a GATEWAY endpoint.
#
# Gateway endpoints are associated with route tables rather
# than subnets.
#
# ============================================================

resource "aws_vpc_endpoint" "s3" {

  # Existing VPC from network.tf
  vpc_id = aws_vpc.lab.id

  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  vpc_endpoint_type = "Gateway"

  # Existing private route table from network.tf.
  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = {

    Name = "${var.application_name}-S3-Gateway-VPC-Endpoint"

    Project = var.project_name

    Terraform = "true"
  }
}



# ============================================================
# 6. CLOUDWATCH LOGS VPC ENDPOINT
# ============================================================
#
# ECS containers use the awslogs logging driver.
#
# Container stdout/stderr is sent to CloudWatch Logs.
#
# Because ECS tasks run in private subnets, a private
# CloudWatch Logs interface endpoint is provided.
#
# ============================================================

resource "aws_vpc_endpoint" "cloudwatch_logs" {

  # Existing VPC from network.tf
  vpc_id = aws_vpc.lab.id

  service_name = "com.amazonaws.${data.aws_region.current.name}.logs"

  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  # Existing private subnets from network.tf.
  subnet_ids = [
    aws_subnet.private[0].id,
    aws_subnet.private[1].id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoint.id
  ]

  tags = {

    Name = "${var.application_name}-CloudWatch-Logs-VPC-Endpoint"

    Project = var.project_name

    Terraform = "true"
  }
}



# ============================================================
# 7. ECR REPOSITORY
# ============================================================
#
# Stores the Charlie Cafe Terraform Docker image.
#
# IMPORTANT:
#
# The variable ecr_repository_name in variables.tf has been
# changed from:
#
#   charlie-cafe
#
# to:
#
#   charlie-cafe-tf
#
# This prevents the Terraform ECR repository from conflicting
# with the CloudFormation ECR repository.
#
# ============================================================

resource "aws_ecr_repository" "charlie_cafe" {

  name = var.ecr_repository_name


  # ----------------------------------------------------------
  # Scan images when pushed
  # ----------------------------------------------------------

  image_scanning_configuration {

    scan_on_push = true
  }


  # ----------------------------------------------------------
  # Mutable image tags
  #
  # Allows:
  #
  #   latest
  #
  # to be updated by the CI/CD pipeline.
  # ----------------------------------------------------------

  image_tag_mutability = "MUTABLE"


  # ----------------------------------------------------------
  # Server-side encryption
  # ----------------------------------------------------------

  encryption_configuration {

    encryption_type = "AES256"
  }


  tags = {

    Name = "${var.application_name}-ECR"

    Project = var.project_name

    Terraform = "true"
  }
}



# ============================================================
# 8. ECS CLUSTER
# ============================================================
#
# Creates the ECS cluster used by the Charlie Cafe Terraform
# application.
#
# New AWS-visible name:
#
#   CharlieCafe-TF-Cluster
#
# ============================================================

resource "aws_ecs_cluster" "charlie_cafe" {

  name = var.ecs_cluster_name


  # ----------------------------------------------------------
  # Enable CloudWatch Container Insights
  # ----------------------------------------------------------

  setting {

    name = "containerInsights"

    value = "enabled"
  }


  tags = {

    Name = var.ecs_cluster_name

    Project = var.project_name

    Terraform = "true"
  }
}



# ============================================================
# 9. CLOUDWATCH LOG GROUP
# ============================================================
#
# ECS container logs are written here.
#
# Terraform-specific log group:
#
#   /ecs/charlie-cafe-tf
#
# This prevents the Terraform ECS deployment from sharing the
# CloudFormation application's CloudWatch log group.
#
# ============================================================

resource "aws_cloudwatch_log_group" "ecs" {

  name = "/ecs/charlie-cafe-tf"

  retention_in_days = 30


  tags = {

    Name = "CharlieCafe-TF-ECS-Logs"

    Project = var.project_name

    Terraform = "true"
  }
}



# ============================================================
# 10. ECS TASK EXECUTION IAM ROLE
# ============================================================
#
# This role is used by the ECS/Fargate platform.
#
# It allows ECS to:
#
#   - Pull container images from ECR
#   - Send container logs to CloudWatch Logs
#
# New AWS-visible role name:
#
#   CharlieCafe-TF-ECSTaskExecutionRole
#
# ============================================================

resource "aws_iam_role" "ecs_task_execution" {

  name = "${var.application_name}-ECSTaskExecutionRole"


  # ----------------------------------------------------------
  # Trust policy
  #
  # Allows ECS tasks to assume this role.
  # ----------------------------------------------------------

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

    Name = "${var.application_name}-ECSTaskExecutionRole"

    Project = var.project_name

    Terraform = "true"
  }
}



# ============================================================
# 11. ECS TASK EXECUTION POLICY ATTACHMENT
# ============================================================
#
# AWS managed policy providing the standard permissions
# required by ECS/Fargate for:
#
#   - ECR image pulling
#   - CloudWatch Logs
#
# IMPORTANT:
#
# The AWS-managed policy ARN is intentionally NOT renamed.
#
# This is an AWS-managed policy:
#
#   arn:aws:iam::aws:policy/service-role/
#   AmazonECSTaskExecutionRolePolicy
#
# We only rename our Terraform-created IAM role.
#
# ============================================================

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {

  role = aws_iam_role.ecs_task_execution.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}



# ============================================================
# 12. ECS TASK IAM ROLE
# ============================================================
#
# This role belongs to the application running INSIDE the
# Docker container.
#
# New AWS-visible role name:
#
#   CharlieCafe-TF-ECSTaskRole
#
# ============================================================

resource "aws_iam_role" "ecs_task" {

  name = "${var.application_name}-ECSTaskRole"


  # ----------------------------------------------------------
  # Trust policy
  # ----------------------------------------------------------

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

    Name = "${var.application_name}-ECSTaskRole"

    Project = var.project_name

    Terraform = "true"
  }
}



# ============================================================
# 13. ALB SECURITY GROUP
# ============================================================
#
# Internet
#     |
#     | TCP 80
#     v
#    ALB
#
# The Application Load Balancer accepts HTTP traffic from
# the internet.
#
# Terraform-specific name:
#
#   CharlieCafe-TF-ALB-SG
#
# ============================================================

resource "aws_security_group" "alb" {

  name = "${var.application_name}-ALB-SG"

  description = "Allow HTTP traffic to CharlieCafe-TF Application Load Balancer"

  # Existing VPC from network.tf.
  vpc_id = aws_vpc.lab.id


  # ----------------------------------------------------------
  # HTTP from Internet
  # ----------------------------------------------------------

  ingress {

    description = "Allow HTTP from Internet"

    protocol = "tcp"

    from_port = 80

    to_port = 80

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }


  # ----------------------------------------------------------
  # Outbound traffic
  # ----------------------------------------------------------

  egress {

    description = "Allow outbound traffic"

    protocol = "-1"

    from_port = 0

    to_port = 0

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }


  tags = {

    Name = "${var.application_name}-ALB-SG"

    Project = var.project_name

    Terraform = "true"
  }
}



# ============================================================
# 14. ECS TASK SECURITY GROUP
# ============================================================
#
# Security flow:
#
# Internet
#     |
#     v
#    ALB
#     |
#     | Container Port
#     v
#    ECS Task
#
# ECS tasks do NOT allow direct inbound internet traffic.
#
# Only the ALB security group can access the ECS task on the
# application container port.
#
# Terraform-specific name:
#
#   CharlieCafe-TF-ECS-Task-SG
#
# ============================================================

resource "aws_security_group" "ecs_task" {

  name = "${var.application_name}-ECS-Task-SG"

  description = "Allow CharlieCafe-TF application traffic only from the ALB"

  # Existing VPC from network.tf.
  vpc_id = aws_vpc.lab.id


  # ----------------------------------------------------------
  # Application traffic from ALB
  # ----------------------------------------------------------

  ingress {

    description = "Allow application traffic from Terraform ALB"

    protocol = "tcp"

    from_port = var.container_port

    to_port = var.container_port

    security_groups = [
      aws_security_group.alb.id
    ]
  }


  # ----------------------------------------------------------
  # Outbound traffic
  # ----------------------------------------------------------

  egress {

    description = "Allow outbound traffic"

    protocol = "-1"

    from_port = 0

    to_port = 0

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }


  tags = {

    Name = "${var.application_name}-ECS-Task-SG"

    Project = var.project_name

    Terraform = "true"
  }
}



# ============================================================
# 15. APPLICATION LOAD BALANCER
# ============================================================
#
# Creates an internet-facing Application Load Balancer.
#
# Terraform-specific name:
#
#   CharlieCafe-TF-ALB
#
# ============================================================

resource "aws_lb" "charlie_cafe" {

  name = "${var.application_name}-ALB"

  internal = false

  load_balancer_type = "application"


  # ALB security group.
  security_groups = [
    aws_security_group.alb.id
  ]


  # Existing public subnets from network.tf.
  subnets = [
    aws_subnet.public[0].id,
    aws_subnet.public[1].id
  ]


  tags = {

    Name = "${var.application_name}-ALB"

    Project = var.project_name

    Terraform = "true"
  }
}



# ============================================================
# 16. ALB TARGET GROUP
# ============================================================
#
# Fargate uses awsvpc networking.
#
# Therefore ECS tasks receive their own ENI/private IP.
#
# The target group must therefore use:
#
#   target_type = "ip"
#
# Terraform-specific name:
#
#   CharlieCafe-TF-TG
#
# ============================================================

resource "aws_lb_target_group" "charlie_cafe" {

  name = "${var.application_name}-TG"

  port = var.container_port

  protocol = "HTTP"

  # Existing VPC from network.tf.
  vpc_id = aws_vpc.lab.id

  target_type = "ip"


  # ----------------------------------------------------------
  # Health check
  # ----------------------------------------------------------

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

    Name = "${var.application_name}-TG"

    Project = var.project_name

    Terraform = "true"
  }
}



# ============================================================
# 17. ALB HTTP LISTENER
# ============================================================
#
# HTTP:
#
#   Port 80
#
# The listener forwards requests to the Terraform ECS target
# group.
#
# ============================================================

resource "aws_lb_listener" "http" {

  load_balancer_arn = aws_lb.charlie_cafe.arn

  port = 80

  protocol = "HTTP"


  # ----------------------------------------------------------
  # Forward requests to ECS target group
  # ----------------------------------------------------------

  default_action {

    type = "forward"

    target_group_arn = aws_lb_target_group.charlie_cafe.arn
  }
}



# ============================================================
# 18. ECS TASK DEFINITION
# ============================================================
#
# Defines the Docker container configuration.
#
# Terraform-specific ECS task family:
#
#   CharlieCafe-TF
#
# ============================================================

resource "aws_ecs_task_definition" "charlie_cafe" {

  family = var.ecs_task_family


  # ----------------------------------------------------------
  # Fargate networking mode
  # ----------------------------------------------------------

  network_mode = "awsvpc"


  # ----------------------------------------------------------
  # Fargate launch type
  # ----------------------------------------------------------

  requires_compatibilities = [
    "FARGATE"
  ]


  # ----------------------------------------------------------
  # CPU
  # ----------------------------------------------------------

  cpu = var.task_cpu


  # ----------------------------------------------------------
  # Memory
  # ----------------------------------------------------------

  memory = var.task_memory


  # ----------------------------------------------------------
  # ECS execution role
  # ----------------------------------------------------------

  execution_role_arn = aws_iam_role.ecs_task_execution.arn


  # ----------------------------------------------------------
  # Application task role
  # ----------------------------------------------------------

  task_role_arn = aws_iam_role.ecs_task.arn


  # ==========================================================
  # CONTAINER DEFINITION
  # ==========================================================
  #
  # IMPORTANT:
  #
  # The old container name:
  #
  #   charlie-cafe
  #
  # has been changed to:
  #
  #   charlie-cafe-tf
  #
  # This is important because the ECS service's
  # load_balancer.container_name must match this value.
  #
  # ==========================================================

  container_definitions = jsonencode([

    {

      name = "charlie-cafe-tf"


      # ------------------------------------------------------
      # Docker image
      #
      # GitHub Actions will push the Terraform application
      # image to:
      #
      #   charlie-cafe-tf
      #
      # with the:
      #
      #   latest
      #
      # tag.
      # ------------------------------------------------------

      image = "${aws_ecr_repository.charlie_cafe.repository_url}:latest"

      essential = true


      # ------------------------------------------------------
      # Container port
      # ------------------------------------------------------

      portMappings = [

        {

          containerPort = var.container_port

          protocol = "tcp"
        }
      ]


      # ------------------------------------------------------
      # CloudWatch Logs
      #
      # Terraform-specific log group:
      #
      #   /ecs/charlie-cafe-tf
      #
      # ------------------------------------------------------

      logConfiguration = {

        logDriver = "awslogs"

        options = {

          "awslogs-group" = aws_cloudwatch_log_group.ecs.name

          "awslogs-region" = data.aws_region.current.name

          "awslogs-stream-prefix" = "ecs-tf"
        }
      }
    }
  ])


  tags = {

    Name = var.ecs_task_family

    Project = var.project_name

    Terraform = "true"
  }
}



# ============================================================
# 19. ECS FARGATE SERVICE
# ============================================================
#
# The ECS service maintains the desired number of running
# tasks.
#
# New AWS-visible service name:
#
#   CharlieCafe-TF-Service
#
# ============================================================

resource "aws_ecs_service" "charlie_cafe" {

  name = var.ecs_service_name

  cluster = aws_ecs_cluster.charlie_cafe.id

  launch_type = "FARGATE"

  desired_count = var.ecs_desired_count

  task_definition = aws_ecs_task_definition.charlie_cafe.arn


  # ----------------------------------------------------------
  # Network configuration
  # ----------------------------------------------------------
  #
  # ECS tasks run inside the existing private subnets.
  #
  # Public IP is disabled because the application is accessed
  # through the public ALB.
  #
  # ----------------------------------------------------------

  network_configuration {

    assign_public_ip = false

    security_groups = [
      aws_security_group.ecs_task.id
    ]

    subnets = [
      aws_subnet.private[0].id,
      aws_subnet.private[1].id
    ]
  }


  # ----------------------------------------------------------
  # Connect ECS container to ALB target group
  # ----------------------------------------------------------
  #
  # IMPORTANT:
  #
  # This container_name MUST match the container definition:
  #
  #   charlie-cafe-tf
  #
  # ----------------------------------------------------------

  load_balancer {

    target_group_arn = aws_lb_target_group.charlie_cafe.arn

    container_name = "charlie-cafe-tf"

    container_port = var.container_port
  }


  # ----------------------------------------------------------
  # Deployment configuration
  # ----------------------------------------------------------
  #
  # Maximum 200%:
  #
  # ECS can temporarily run additional tasks during deployment.
  #
  # Minimum 50%:
  #
  # ECS attempts to keep at least half of the desired tasks
  # healthy during deployment.
  #
  # ----------------------------------------------------------

  deployment_maximum_percent = 200

  deployment_minimum_healthy_percent = 50


  # ----------------------------------------------------------
  # Ensure the ALB listener exists before the ECS service.
  # ----------------------------------------------------------

  depends_on = [
    aws_lb_listener.http
  ]


  tags = {

    Name = var.ecs_service_name

    Project = var.project_name

    Terraform = "true"
  }
}



# ============================================================
# END OF ecs_ecr.tf
# ============================================================
#
# TERRAFORM NAMING SUMMARY
# ============================================================
#
# ECR:
#
#   charlie-cafe-tf
#
# ECS Cluster:
#
#   CharlieCafe-TF-Cluster
#
# ECS Service:
#
#   CharlieCafe-TF-Service
#
# ECS Task Family:
#
#   CharlieCafe-TF
#
# ECS Container:
#
#   charlie-cafe-tf
#
# CloudWatch Log Group:
#
#   /ecs/charlie-cafe-tf
#
# ECS Execution Role:
#
#   CharlieCafe-TF-ECSTaskExecutionRole
#
# ECS Task Role:
#
#   CharlieCafe-TF-ECSTaskRole
#
# ALB:
#
#   CharlieCafe-TF-ALB
#
# ALB Target Group:
#
#   CharlieCafe-TF-TG
#
# ALB Security Group:
#
#   CharlieCafe-TF-ALB-SG
#
# ECS Task Security Group:
#
#   CharlieCafe-TF-ECS-Task-SG
#
# VPC Endpoint Security Group:
#
#   CharlieCafe-TF-VPC-Endpoint-SG
#
# ============================================================
#
# IMPORTANT:
#
# The Terraform resource addresses remain unchanged:
#
#   aws_ecr_repository.charlie_cafe
#   aws_ecs_cluster.charlie_cafe
#   aws_ecs_task_definition.charlie_cafe
#   aws_ecs_service.charlie_cafe
#   aws_lb.charlie_cafe
#   aws_lb_target_group.charlie_cafe
#
# These are Terraform INTERNAL identifiers and are not AWS
# resource names.
#
# ============================================================
#
# Outputs should remain in:
#
#   outputs.tf
#
# Do NOT duplicate output blocks here.
#
# ============================================================
