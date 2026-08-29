# =======================================================
# CHARLIE CAFE - TERRAFORM DEVOPS LAB
# EC2 WEB SERVER
# =======================================================
#
# Terraform-managed EC2 web server.
#
# CloudFormation equivalent:
#
#   AWS::EC2::Instance
#
# =======================================================
#
# TERRAFORM RESOURCE NAMING CONVENTION
# =======================================================
#
# This lab has both:
#
#   1. CloudFormation infrastructure
#   2. Terraform infrastructure
#
# To prevent confusion and naming conflicts, Terraform-created
# resources use the "TF" identifier.
#
# Standard:
#
#   CharlieCafe-TF-<Resource>
#
# This EC2 instance therefore uses:
#
#   CharlieCafe-TF-WebServer
#
# The Terraform resource address remains:
#
#   aws_instance.web
#
# because that is an internal Terraform identifier and does not
# create a naming conflict with the AWS CloudFormation stack.
#
# =======================================================
#
# Original architecture:
#
# EC2
#  |
#  └── UserData wrapper
#        |
#        └── downloads ec2-userdata.sh from GitHub
#
# We preserve this behavior so the Terraform migration does not
# unexpectedly change the existing Charlie Cafe lab.
#
# =======================================================

# =======================================================
# AMAZON LINUX 2023 AMI
# =======================================================
#
# Dynamically retrieves the latest Amazon Linux 2023 AMI
# for the AWS region selected by the Terraform provider.
#
# This avoids hard-coding a region-specific AMI ID.
#
# =======================================================

data "aws_ssm_parameter" "amazon_linux_2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# =======================================================
# EC2 INSTANCE
# =======================================================

resource "aws_instance" "web" {

  # -----------------------------------------------------
  # AMI
  # -----------------------------------------------------
  #
  # CloudFormation equivalent:
  #
  #   ImageId: !Ref AmiId
  #
  # The AMI ID is provided through variables.tf.
  # -----------------------------------------------------

  ami = data.aws_ssm_parameter.amazon_linux_2023_ami.value


  # -----------------------------------------------------
  # INSTANCE TYPE
  # -----------------------------------------------------
  #
  # Example:
  #
  #   t3.micro
  #
  # The instance type remains configurable through
  # variables.tf.
  # -----------------------------------------------------

  instance_type = var.instance_type


  # -----------------------------------------------------
  # EXISTING EC2 KEY PAIR
  # -----------------------------------------------------
  #
  # Existing EC2 Key Pair used for SSH access.
  # -----------------------------------------------------

  key_name = var.key_pair_name


  # -----------------------------------------------------
  # PUBLIC SUBNET
  # -----------------------------------------------------
  #
  # CloudFormation used:
  #
  #   PublicSubnet1
  #
  # Therefore Terraform uses the first public subnet.
  # -----------------------------------------------------

  subnet_id = aws_subnet.public[0].id


  # -----------------------------------------------------
  # SECURITY GROUP
  # -----------------------------------------------------
  #
  # Uses the Terraform-managed web security group.
  # -----------------------------------------------------

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]


  # =====================================================
  # USER DATA
  # =====================================================
  #
  # This is the Terraform equivalent of the CloudFormation
  # Fn::Base64 UserData wrapper.
  #
  # Terraform/AWS handles the required encoding for the
  # EC2 user_data property.
  #
  # IMPORTANT:
  #
  # The existing bootstrap behavior is intentionally preserved.
  #
  # The instance downloads:
  #
  #   ec2-userdata.sh
  #
  # from the configured GitHub URL and executes it.
  # =====================================================

  user_data = <<-EOF
    #!/bin/bash

    # ---------------------------------------------------
    # Enable strict Bash error handling
    # ---------------------------------------------------

    set -euxo pipefail


    # ---------------------------------------------------
    # Create bootstrap log
    # ---------------------------------------------------

    exec > >(tee /var/log/bootstrap.log) 2>&1


    echo "==============================================="
    echo "Starting Charlie Cafe Terraform EC2 Bootstrap"
    echo "==============================================="


    # ---------------------------------------------------
    # Move to temporary directory
    # ---------------------------------------------------

    cd /tmp


    # ---------------------------------------------------
    # Bootstrap script URL
    # ---------------------------------------------------
    #
    # The URL is provided through Terraform variable:
    #
    #   userdata_script_url
    #
    # ---------------------------------------------------

    SCRIPT_URL="${var.userdata_script_url}"


    echo "Downloading EC2 bootstrap script..."
    echo "Script URL: $SCRIPT_URL"


    # ---------------------------------------------------
    # Download the actual bootstrap script
    # ---------------------------------------------------

    curl -fsSL "$SCRIPT_URL" -o ec2-userdata.sh


    # ---------------------------------------------------
    # Verify download
    # ---------------------------------------------------

    if [ ! -s /tmp/ec2-userdata.sh ]; then
      echo "ERROR: ec2-userdata.sh was not downloaded."
      exit 1
    fi


    # ---------------------------------------------------
    # Make bootstrap script executable
    # ---------------------------------------------------

    chmod +x /tmp/ec2-userdata.sh


    # ---------------------------------------------------
    # Display file information
    # ---------------------------------------------------

    echo "EC2 bootstrap script downloaded successfully."

    ls -lh /tmp/ec2-userdata.sh


    # ---------------------------------------------------
    # Execute bootstrap script
    # ---------------------------------------------------

    echo "Executing ec2-userdata.sh..."

    /bin/bash /tmp/ec2-userdata.sh


    # ---------------------------------------------------
    # Create completion status file
    # ---------------------------------------------------

    echo "Bootstrap completed successfully." > /var/log/bootstrap-status.log


    echo "==============================================="
    echo "Charlie Cafe Terraform EC2 Bootstrap Completed"
    echo "==============================================="

  EOF


  # =====================================================
  # TAGS
  # =====================================================
  #
  # IMPORTANT:
  #
  # These are AWS-visible resource tags.
  #
  # The previous CloudFormation-oriented values:
  #
  #   CloudFormation-WebServer
  #   AWS-CloudFormation-Lab
  #
  # have been replaced with Terraform-specific values:
  #
  #   CharlieCafe-TF-WebServer
  #   CharlieCafe-TF-Lab
  #
  # This makes the EC2 instance immediately identifiable
  # as belonging to the Terraform implementation.
  #
  # =====================================================

  tags = {
    Name    = "CharlieCafe-TF-WebServer"
    Project = "CharlieCafe-TF-Lab"
  }
}
