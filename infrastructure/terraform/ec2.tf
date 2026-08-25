# =======================================================
# EC2 WEB SERVER
# =======================================================
#
# CloudFormation equivalent:
#
# AWS::EC2::Instance
#
# Original architecture:
#
# EC2
#  |
#  └── UserData wrapper
#        |
#        └── downloads ec2-userdata.sh from GitHub
#
# We preserve this behavior in the first Terraform
# version so the migration does not unexpectedly change
# your lab.
# =======================================================


# =======================================================
# EC2 INSTANCE
# =======================================================

resource "aws_instance" "web" {

  # -----------------------------------------------------
  # AMI
  # -----------------------------------------------------
  #
  # CloudFormation:
  #
  # ImageId: !Ref AmiId
  # -----------------------------------------------------

  ami = var.ami_id

  # -----------------------------------------------------
  # Instance type
  # -----------------------------------------------------

  instance_type = var.instance_type

  # -----------------------------------------------------
  # Existing EC2 Key Pair
  # -----------------------------------------------------

  key_name = var.key_pair_name

  # -----------------------------------------------------
  # Public subnet
  # -----------------------------------------------------
  #
  # CloudFormation used PublicSubnet1.
  #
  # Therefore Terraform uses the first public subnet.
  # -----------------------------------------------------

  subnet_id = aws_subnet.public[0].id

  # -----------------------------------------------------
  # Security Group
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
    echo "Starting EC2 UserData Bootstrap"
    echo "==============================================="

    # ---------------------------------------------------
    # Move to temporary directory
    # ---------------------------------------------------

    cd /tmp

    # ---------------------------------------------------
    # Bootstrap script URL
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
    # Make executable
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
    echo "EC2 UserData Bootstrap Completed Successfully"
    echo "==============================================="
  EOF

  # -----------------------------------------------------
  # Tags
  # -----------------------------------------------------

  tags = {
    Name    = "CloudFormation-WebServer"
    Project = "AWS-CloudFormation-Lab"
  }
}