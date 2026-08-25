# =======================================================
# AMAZON RDS MYSQL
# =======================================================
#
# CloudFormation resources converted:
#
# AWS::EC2::SecurityGroup
# AWS::RDS::DBSubnetGroup
# AWS::RDS::DBInstance
#
# Architecture:
#
# Private Subnet 1 ──┐
#                    ├── RDS Subnet Group
# Private Subnet 2 ──┘
#                           |
#                           v
#                      RDS MySQL
#                           ^
#                           |
#                    RDS Security Group
#                           ^
#                           |
#                    EC2 Web Security Group
#
# RDS is NOT publicly accessible.
# =======================================================


# =======================================================
# RDS DB SUBNET GROUP
# =======================================================

resource "aws_db_subnet_group" "mysql" {

  name = "lab-rds-subnet-group"

  description = "Subnet group for Lab RDS"

  # -----------------------------------------------------
  # Use both private subnets.
  # -----------------------------------------------------

  subnet_ids = [
    aws_subnet.private[0].id,
    aws_subnet.private[1].id
  ]

  tags = {
    Name = "Lab-RDS-SubnetGroup"
  }
}


# =======================================================
# RDS MYSQL DATABASE
# =======================================================

resource "aws_db_instance" "mysql" {

  # -----------------------------------------------------
  # Database engine
  # -----------------------------------------------------

  engine = "mysql"

  # -----------------------------------------------------
  # MySQL version
  # -----------------------------------------------------

  engine_version = var.db_engine_version

  # -----------------------------------------------------
  # Instance class
  # -----------------------------------------------------

  instance_class = var.db_instance_class

  # -----------------------------------------------------
  # Database name
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
  # AWS creates and manages the database password through
  # Secrets Manager.
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

  publicly_accessible = false

  # -----------------------------------------------------
  # Security Group
  # -----------------------------------------------------

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  # -----------------------------------------------------
  # DB subnet group
  # -----------------------------------------------------

  db_subnet_group_name = aws_db_subnet_group.mysql.name

  # -----------------------------------------------------
  # Backup retention
  # -----------------------------------------------------
  #
  # 0 matches the original learning lab.
  # Production databases should normally use backups.
  # -----------------------------------------------------

  backup_retention_period = var.db_backup_retention_period

  # -----------------------------------------------------
  # Storage encryption
  # -----------------------------------------------------

  storage_encrypted = var.db_storage_encrypted

  # -----------------------------------------------------
  # Deletion protection
  # -----------------------------------------------------

  deletion_protection = var.db_deletion_protection

  # -----------------------------------------------------
  # Skip final snapshot
  # -----------------------------------------------------
  #
  # This matches the learning-lab approach where we do not
  # want a database snapshot left behind after destroying
  # the lab.
  # -----------------------------------------------------

  skip_final_snapshot = true

  # -----------------------------------------------------
  # Tags
  # -----------------------------------------------------

  tags = {
    Name = "Lab-RDS-MySQL"
  }
}