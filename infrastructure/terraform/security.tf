# =======================================================
# SECURITY GROUPS
# =======================================================
#
# CloudFormation resources converted:
#
# Main template:
#   AWS::EC2::SecurityGroup
#
# RDS nested stack:
#   AWS::EC2::SecurityGroup
#
# =======================================================


# =======================================================
# WEB SECURITY GROUP
# =======================================================
#
# Allows:
#
# TCP 22  -> SSH
# TCP 80  -> HTTP
# TCP 443 -> HTTPS
#
# WARNING:
# SSH is intentionally open to the internet because this
# matches the original beginner lab.
#
# In production, restrict port 22 to your trusted IP.
# =======================================================

resource "aws_security_group" "web" {

  name        = "Lab-Web-SG"
  description = "Allow SSH, HTTP and HTTPS"
  vpc_id      = aws_vpc.lab.id

  # -----------------------------------------------------
  # SSH
  # -----------------------------------------------------

  ingress {
    description = "Allow SSH from anywhere"

    protocol = "tcp"

    from_port = 22
    to_port   = 22

    cidr_blocks = ["0.0.0.0/0"]
  }

  # -----------------------------------------------------
  # HTTP
  # -----------------------------------------------------

  ingress {
    description = "Allow HTTP from anywhere"

    protocol = "tcp"

    from_port = 80
    to_port   = 80

    cidr_blocks = ["0.0.0.0/0"]
  }

  # -----------------------------------------------------
  # HTTPS
  # -----------------------------------------------------

  ingress {
    description = "Allow HTTPS from anywhere"

    protocol = "tcp"

    from_port = 443
    to_port   = 443

    cidr_blocks = ["0.0.0.0/0"]
  }

  # -----------------------------------------------------
  # Outbound traffic
  # -----------------------------------------------------
  #
  # The original CloudFormation template did not define
  # explicit egress rules.
  #
  # AWS Security Groups allow all outbound traffic by
  # default.
  # -----------------------------------------------------

  egress {
    description = "Allow all outbound traffic"

    protocol = "-1"

    from_port = 0
    to_port   = 0

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Lab-Web-SG"
  }
}


# =======================================================
# RDS SECURITY GROUP
# =======================================================
#
# RDS accepts MySQL traffic ONLY from the Web Security
# Group.
#
# Traffic:
#
# EC2
#  |
#  | TCP 3306
#  v
# RDS
#
# No public internet access is allowed.
# =======================================================

resource "aws_security_group" "rds" {

  name        = "Lab-RDS-SG"
  description = "Allow MySQL from EC2 only"
  vpc_id      = aws_vpc.lab.id

  # -----------------------------------------------------
  # MySQL inbound rule
  # -----------------------------------------------------

  ingress {
    description = "Allow MySQL access only from EC2 Web Security Group"

    protocol = "tcp"

    from_port = 3306
    to_port   = 3306

    security_groups = [
      aws_security_group.web.id
    ]
  }

  # -----------------------------------------------------
  # Outbound traffic
  # -----------------------------------------------------

  egress {
    description = "Allow all outbound traffic"

    protocol = "-1"

    from_port = 0
    to_port   = 0

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Lab-RDS-SG"
  }
}