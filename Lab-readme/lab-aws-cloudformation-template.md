
# AWS CloudFormation Template Code Sources


# AWS CloudFormation Templates 

## Main Stack Temaplate 

### lab01.yaml

```
lab01.yaml
```

#### Cloudformation Main Template 


```
# ---------------------------------------------------------
# AWS CloudFormation Beginner Lab
#
# Creates:
#   - VPC
#   - Internet Gateway
#   - 2 Public Subnets
#   - 2 Private Subnets
#   - Public Route Table
#   - Private Route Table
#   - Web Security Group
#   - EC2 Instance through Nested Stack
#   - S3 Bucket through Nested Stack
#   - RDS MySQL through Nested Stack
# ---------------------------------------------------------

AWSTemplateFormatVersion: '2010-09-09'

Description: >
  Beginner AWS CloudFormation Lab - VPC, EC2, S3, and RDS MySQL

# -------------------------------------------------------
# Parameters
# -------------------------------------------------------

Parameters:

  # Existing EC2 Key Pair
  KeyPairName:
    Type: AWS::EC2::KeyPair::KeyName
    Description: Name of an existing EC2 KeyPair to enable SSH access

  # Latest Amazon Linux 2023 AMI
  LatestAmiId:
    Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
    Default: /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64
    Description: >
      Amazon Linux 2023 AMI ID resolved through the AWS public SSM parameter

  # RDS username
  DBMasterUsername:
    Type: String
    Default: admin
    Description: Master username for the RDS MySQL database

  # RDS password
  #DBMasterPassword:
    #Type: String
    #NoEcho: true
    ## MinLength: 8
    #Description: Master password for the RDS MySQL database  

  # -------------------------------------------------------
  # S3 Bucket containing nested CloudFormation templates
  # -------------------------------------------------------

  TemplateBucketName:
    Type: String
    Description: >
      Name of the S3 bucket containing the nested
      CloudFormation templates
  
  
  # -------------------------------------------------------
  # EC2 Nested Stack Template URL
  #
  # This parameter contains the URL of the child
  # CloudFormation template responsible for creating
  # the EC2 web server.
  #
  # Example:
  # https://raw.githubusercontent.com/USERNAME/REPOSITORY/main/templates/ec2-webserver.yaml
  # S3 URL: https://cloudformation-devops-lab-537236558357-us-east-1.s3.amazonaws.com/templates/ec2-webserver.yaml
  # Github URL: https://raw.githubusercontent.com/awsrmmustansarjavaid/CloudFormation-DevOps-Lab/main/templates/ec2-webserver.yaml
  # -------------------------------------------------------

  #EC2TemplateURL:
    #Type: String
    #Default: https://raw.githubusercontent.com/awsrmmustansarjavaid/CloudFormation-DevOps-Lab/main/templates/ec2-webserver.yaml
    #Description: URL of the EC2 nested CloudFormation template

  # -------------------------------------------------------
  # S3 Nested Stack Template URL
  #
  # This parameter contains the URL of the child
  # CloudFormation template responsible for creating
  # the S3 bucket.
  # S3 URL: https://cloudformation-devops-lab-537236558357-us-east-1.s3.amazonaws.com/templates/s3.yaml
  # Github URL: https://raw.githubusercontent.com/awsrmmustansarjavaid/CloudFormation-DevOps-Lab/main/templates/s3.yaml
  # -------------------------------------------------------
  #S3TemplateURL:
    #Type: String
    #Default: https://raw.githubusercontent.com/awsrmmustansarjavaid/CloudFormation-DevOps-Lab/main/templates/s3.yaml"
    #Description: URL of the S3 nested CloudFormation template

  # -------------------------------------------------------
  # RDS Nested Stack Template URL
  #
  # This parameter contains the URL of the child
  # CloudFormation template responsible for creating
  # the RDS MySQL database.
  # S3 URL: https://cloudformation-devops-lab-537236558357-us-east-1.s3.amazonaws.com/templates/s3.yaml
  # Github URL: https://raw.githubusercontent.com/awsrmmustansarjavaid/CloudFormation-DevOps-Lab/main/templates/aws-rds.yaml
  # -------------------------------------------------------
  #RDSTemplateURL:
    #Type: String
    #Default: https://raw.githubusercontent.com/awsrmmustansarjavaid/CloudFormation-DevOps-Lab/main/templates/aws-rds.yaml"
    #Description: URL of the RDS nested CloudFormation template

  # -------------------------------------------------------
  # EC2 UserData Script URL
  #
  # This parameter contains the GitHub Raw URL of the
  # shell script that will be passed to the EC2 instance.
  #
  # The script is NOT a CloudFormation template.
  # It is the EC2 bootstrap/UserData script.
  # Github URL: https://raw.githubusercontent.com/awsrmmustansarjavaid/CloudFormation-DevOps-Lab/main/scripts/ec2-userdata.sh
  # -------------------------------------------------------
  EC2UserDataScriptURL:
    Type: String
    Default: https://raw.githubusercontent.com/awsrmmustansarjavaid/CloudFormation-DevOps-Lab/main/scripts/ec2-userdata.sh
    Description: URL of the EC2 UserData bootstrap shell script  

# -------------------------------------------------------
# Resources
# -------------------------------------------------------

Resources:

  # -------------------------------------------------------
  # VPC
  # -------------------------------------------------------

  MyVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsSupport: true
      EnableDnsHostnames: true

      Tags:
        - Key: Name
          Value: Lab-VPC

  # -------------------------------------------------------
  # Internet Gateway
  # -------------------------------------------------------

  MyInternetGateway:
    Type: AWS::EC2::InternetGateway
    Properties:

      Tags:
        - Key: Name
          Value: Lab-InternetGateway

  # -------------------------------------------------------
  # Attach Internet Gateway to VPC
  # -------------------------------------------------------

  AttachGateway:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      InternetGatewayId: !Ref MyInternetGateway
      VpcId: !Ref MyVPC

  # -------------------------------------------------------
  # Public Subnets Route Association
  # -------------------------------------------------------
  # -------------------------------------------------------
  # Public Subnet 1
  # -------------------------------------------------------

  PublicSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref MyVPC

      # First public subnet
      CidrBlock: 10.0.1.0/24

      # Automatically assign public IPv4 addresses
      MapPublicIpOnLaunch: true

      # Availability Zone 1
      AvailabilityZone: !Select
        - 0
        - !GetAZs ''

      Tags:
        - Key: Name
          Value: Public-Subnet-1


  # -------------------------------------------------------
  # Public Subnet 2
  # -------------------------------------------------------

  PublicSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref MyVPC

      # Second public subnet
      # Must use a different CIDR block
      CidrBlock: 10.0.4.0/24

      # Automatically assign public IPv4 addresses
      MapPublicIpOnLaunch: true

      # Availability Zone 2
      AvailabilityZone: !Select
        - 1
        - !GetAZs ''

      Tags:
        - Key: Name
          Value: Public-Subnet-2

  # -------------------------------------------------------
  # Private Subnet 1
  # -------------------------------------------------------

  PrivateSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref MyVPC
      CidrBlock: 10.0.2.0/24
      MapPublicIpOnLaunch: false

      AvailabilityZone: !Select
        - 0
        - !GetAZs ''

      Tags:
        - Key: Name
          Value: Private-Subnet-1

  # -------------------------------------------------------
  # Private Subnet 2
  # -------------------------------------------------------

  PrivateSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref MyVPC
      CidrBlock: 10.0.3.0/24
      MapPublicIpOnLaunch: false

      AvailabilityZone: !Select
        - 1
        - !GetAZs ''

      Tags:
        - Key: Name
          Value: Private-Subnet-2

  # -------------------------------------------------------
  # Public Route Table
  # -------------------------------------------------------

  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref MyVPC

      Tags:
        - Key: Name
          Value: Public-RouteTable

  # -------------------------------------------------------
  # Default Internet Route
  # -------------------------------------------------------

  DefaultRoute:
    Type: AWS::EC2::Route
    DependsOn: AttachGateway
    Properties:
      RouteTableId: !Ref PublicRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref MyInternetGateway

  # -------------------------------------------------------
  # Public Subnets Route Association
  # -------------------------------------------------------
  # -------------------------------------------------------
  # Public Subnet 1 Route Association
  # -------------------------------------------------------

  PublicSubnet1RouteAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable
      SubnetId: !Ref PublicSubnet1


  # -------------------------------------------------------
  # Public Subnet 2 Route Association
  # -------------------------------------------------------

  PublicSubnet2RouteAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable
      SubnetId: !Ref PublicSubnet2

  # -------------------------------------------------------
  # Private Route Table
  #
  # No NAT Gateway is configured in this lab.
  # Private subnets therefore have no internet access.
  # -------------------------------------------------------

  PrivateRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref MyVPC

      Tags:
        - Key: Name
          Value: Private-RouteTable

  # -------------------------------------------------------
  # Private Subnet 1 Route Association
  # -------------------------------------------------------

  PrivateSubnet1RouteAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PrivateRouteTable
      SubnetId: !Ref PrivateSubnet1

  # -------------------------------------------------------
  # Private Subnet 2 Route Association
  # -------------------------------------------------------

  PrivateSubnet2RouteAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PrivateRouteTable
      SubnetId: !Ref PrivateSubnet2

  # -------------------------------------------------------
  # Web Security Group
  #
  # Allows:
  #   SSH   - 22
  #   HTTP  - 80
  #   HTTPS - 443
  #
  # NOTE:
  # SSH from 0.0.0.0/0 is acceptable for a temporary lab,
  # but should be restricted to your own public IP in
  # a real environment.
  # -------------------------------------------------------

  WebSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Allow SSH, HTTP and HTTPS
      VpcId: !Ref MyVPC

      SecurityGroupIngress:

        # SSH
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: 0.0.0.0/0
          Description: Allow SSH from anywhere

        # HTTP
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
          Description: Allow HTTP from anywhere

        # HTTPS
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0
          Description: Allow HTTPS from anywhere

      Tags:
        - Key: Name
          Value: Lab-Web-SG

  # -------------------------------------------------------
  # Nested Stack - EC2 Web Server
  # -------------------------------------------------------

  EC2WebServerStack:
    Type: AWS::CloudFormation::Stack

    Properties:

      # EC2 child CloudFormation template
      #TemplateURL: !Ref EC2TemplateURL

      # Build the EC2 child-template URL from the S3 bucket name
      TemplateURL: !Sub "https://${TemplateBucketName}.s3.${AWS::Region}.amazonaws.com/templates/ec2-webserver.yaml"

      # Parameters passed to EC2 child stack
      Parameters:

        AmiId: !Ref LatestAmiId

        InstanceType: t3.micro

        KeyPair: !Ref KeyPairName

        PublicSubnetId: !Ref PublicSubnet1

        SecurityGroupId: !Ref WebSecurityGroup

        UserDataScriptUrl: !Ref EC2UserDataScriptURL

  # -------------------------------------------------------
  # Nested Stack - S3
  # -------------------------------------------------------

  S3NestedStack:
    Type: AWS::CloudFormation::Stack

    Properties:

      # S3 child CloudFormation template
      #TemplateURL: !Ref S3TemplateURL

      # Build the S3 child-template URL from the S3 bucket name
      TemplateURL: !Sub "https://${TemplateBucketName}.s3.${AWS::Region}.amazonaws.com/templates/s3.yaml"

  # -------------------------------------------------------
  # Nested Stack - RDS MySQL
  # -------------------------------------------------------

  RDSNestedStack:
    Type: AWS::CloudFormation::Stack

    Properties:

      # RDS child CloudFormation template
      #TemplateURL: !Ref RDSTemplateURL

      # Build the RDS child-template URL from the S3 bucket name
      TemplateURL: !Sub "https://${TemplateBucketName}.s3.${AWS::Region}.amazonaws.com/templates/aws-rds.yaml"

      # Parameters passed to RDS child stack
      Parameters:

        # VPC
        VpcId: !Ref MyVPC

        # Private Subnet 1
        PrivateSubnet1: !Ref PrivateSubnet1

        # Private Subnet 2
        PrivateSubnet2: !Ref PrivateSubnet2

        # Web Security Group
        WebSecurityGroupId: !Ref WebSecurityGroup

        # Database username
        DBUsername: !Ref DBMasterUsername

        # Database password
        # DBPassword: !Ref DBMasterPassword
        

# -------------------------------------------------------
# Outputs
# -------------------------------------------------------

Outputs:

  # -------------------------------------------------------
  # VPC
  # -------------------------------------------------------

  VPCId:
    Description: VPC ID
    Value: !Ref MyVPC

  # -------------------------------------------------------
  # Internet Gateway
  # -------------------------------------------------------
  #
  # Shows the ID of the Internet Gateway attached to the VPC.
  # Useful for learning and troubleshooting network connectivity.
  # -------------------------------------------------------

  InternetGatewayId:
    Description: Internet Gateway ID
    Value: !Ref MyInternetGateway


  # -------------------------------------------------------
  # Route Tables
  # -------------------------------------------------------
  #
  # These outputs show the route tables associated with
  # the public and private subnets.
  #
  # Public Route Table:
  # Provides the route from the public subnet to the Internet
  # through the Internet Gateway.
  #
  # Private Route Table:
  # Used by private subnets and does not provide direct
  # Internet access through the Internet Gateway.
  # -------------------------------------------------------

  PublicRouteTableId:
    Description: Public Route Table ID
    Value: !Ref PublicRouteTable

  PrivateRouteTableId:
    Description: Private Route Table ID
    Value: !Ref PrivateRouteTable


  # -------------------------------------------------------
  # Public Subnets
  # -------------------------------------------------------

  # -------------------------------------------------------
  # Public Subnet 1
  # -------------------------------------------------------

  PublicSubnet1Id:
    Description: Public Subnet 1 ID
    Value: !Ref PublicSubnet1


  # -------------------------------------------------------
  # Public Subnet 2
  # -------------------------------------------------------

  PublicSubnet2Id:
    Description: Public Subnet 2 ID
    Value: !Ref PublicSubnet2


  # -------------------------------------------------------
  # Private Subnet 1
  # -------------------------------------------------------

  PrivateSubnet1Id:
    Description: Private Subnet 1 ID
    Value: !Ref PrivateSubnet1

  # -------------------------------------------------------
  # Private Subnet 2
  # -------------------------------------------------------

  PrivateSubnet2Id:
    Description: Private Subnet 2 ID
    Value: !Ref PrivateSubnet2

  # -------------------------------------------------------
  # Web Security Group
  # -------------------------------------------------------

  SecurityGroupId:
    Description: Web Security Group ID
    Value: !Ref WebSecurityGroup

  # -------------------------------------------------------
  # EC2 Outputs
  # -------------------------------------------------------

  EC2InstanceId:
    Description: EC2 Instance ID
    Value: !GetAtt EC2WebServerStack.Outputs.InstanceId

  EC2PublicIP:
    Description: EC2 Instance Public IP
    Value: !GetAtt EC2WebServerStack.Outputs.PublicIP

  # -------------------------------------------------------
  # S3 Output
  # -------------------------------------------------------

  S3BucketName:
    Description: S3 Bucket Name
    Value: !GetAtt S3NestedStack.Outputs.BucketName

  # -------------------------------------------------------
  # RDS Outputs
  # -------------------------------------------------------

  RDSDatabaseId:
    Description: RDS Database Identifier
    Value: !GetAtt RDSNestedStack.Outputs.RDSDatabaseId

  RDSEndpoint:
    Description: RDS Endpoint Address
    Value: !GetAtt RDSNestedStack.Outputs.RDSEndpoint

  RDSPort:
    Description: RDS MySQL Port
    Value: !GetAtt RDSNestedStack.Outputs.RDSPort

  RDSSecurityGroupId:
    Description: RDS Security Group ID
    Value: !GetAtt RDSNestedStack.Outputs.RDSSecurityGroupId
```

---
## EC2 Nested Stack Temaplate 

### ec2-webserver.yaml

```
lab01.yaml
```

#### Cloudformation Nested Stack Template 

```
AWSTemplateFormatVersion: '2010-09-09'

# =======================================================
# EC2 Web Server CloudFormation Template
# =======================================================
#
# Purpose:
# This template creates an EC2 Web Server and uses
# EC2 UserData to download a separate Bash bootstrap
# script from GitHub.
#
# Architecture:
#
# CloudFormation
#       |
#       v
#      EC2
#       |
#       | First Boot
#       v
#   UserData
#       |
#       | Download
#       v
# GitHub Raw URL
#       |
#       v
# ec2-userdata.sh
#       |
#       v
# LAMP + Docker + Git + AWS CLI + DevOps Tools
#
# =======================================================


# -------------------------------------------------------
# Template Description
# -------------------------------------------------------

Description: >
  CloudFormation template that deploys an EC2 Web Server
  and automatically downloads a separate EC2 UserData
  Bash bootstrap script from GitHub during the first boot.


# =======================================================
# Parameters
# =======================================================

Parameters:


  # -----------------------------------------------------
  # AMI ID
  # -----------------------------------------------------
  # The AMI used to launch the EC2 instance.
  #
  # Example:
  # Amazon Linux 2023 AMI
  #
  # You can provide the AMI ID when creating the stack.
  # -----------------------------------------------------

  AmiId:
    Type: AWS::EC2::Image::Id
    Description: >
      Amazon Machine Image (AMI) ID to use for the
      EC2 Web Server.


  # -----------------------------------------------------
  # EC2 Instance Type
  # -----------------------------------------------------
  # Defines the compute size of the EC2 instance.
  #
  # t2.micro is kept as the default based on your
  # existing lab configuration.
  # -----------------------------------------------------

  InstanceType:
    Type: String
    Default: t3.micro
    Description: >
      EC2 instance type for the Web Server.


  # -----------------------------------------------------
  # EC2 Key Pair
  # -----------------------------------------------------
  # Existing EC2 Key Pair used for SSH access.
  # -----------------------------------------------------

  KeyPair:
    Type: AWS::EC2::KeyPair::KeyName
    Description: >
      Existing EC2 Key Pair used to connect to the
      Web Server through SSH.


  # -----------------------------------------------------
  # Public Subnet
  # -----------------------------------------------------
  # The EC2 instance will be deployed into this subnet.
  #
  # IMPORTANT:
  # The subnet should have a route to an Internet Gateway
  # if the EC2 instance needs to download the UserData
  # script directly from GitHub.
  # -----------------------------------------------------

  PublicSubnetId:
    Type: AWS::EC2::Subnet::Id
    Description: >
      Public Subnet ID where the EC2 Web Server will
      be deployed.


  # -----------------------------------------------------
  # Security Group
  # -----------------------------------------------------
  # Security Group associated with the EC2 instance.
  # -----------------------------------------------------

  SecurityGroupId:
    Type: AWS::EC2::SecurityGroup::Id
    Description: >
      Security Group ID associated with the EC2
      Web Server.


  # -----------------------------------------------------
  # UserData Script URL
  # -----------------------------------------------------
  #
  # This parameter contains the RAW GitHub URL of the
  # separate ec2-userdata.sh file.
  #
  # IMPORTANT:
  #
  # Replace:
  #
  # YOUR_GITHUB_USERNAME
  # YOUR_REPOSITORY
  #
  # with your actual GitHub username and repository.
  #
  # Example:
  #
  # https://raw.githubusercontent.com/
  # charlie/AWS-CloudFormation-Lab/main/scripts/ec2-userdata.sh
  #
  # -----------------------------------------------------

  UserDataScriptUrl:
    Type: String
    Default: https://raw.githubusercontent.com/awsrmmustansarjavaid/CloudFormation-DevOps-Lab/main/scripts/ec2-userdata.sh
    Description: >
      Raw GitHub URL pointing to the separate
      ec2-userdata.sh bootstrap script.


# =======================================================
# Resources
# =======================================================

Resources:


  # -----------------------------------------------------
  # EC2 Web Server
  # -----------------------------------------------------
  #
  # Creates the EC2 instance.
  #
  # The actual server configuration is NOT written here.
  #
  # Instead:
  #
  # 1. EC2 starts.
  # 2. UserData runs.
  # 3. UserData downloads ec2-userdata.sh from GitHub.
  # 4. ec2-userdata.sh configures the server.
  #
  # -----------------------------------------------------

  WebServer:

    Type: AWS::EC2::Instance

    Properties:


      # -------------------------------------------------
      # EC2 Configuration
      # -------------------------------------------------

      # AMI used for the EC2 instance.
      ImageId: !Ref AmiId

      # EC2 instance type.
      InstanceType: !Ref InstanceType

      # Existing EC2 Key Pair.
      KeyName: !Ref KeyPair

      # Public subnet where the EC2 instance will run.
      SubnetId: !Ref PublicSubnetId


      # -------------------------------------------------
      # Security Group
      # -------------------------------------------------
      #
      # Attach the provided Security Group to the
      # EC2 Web Server.
      #
      # -------------------------------------------------

      SecurityGroupIds:
        - !Ref SecurityGroupId


      # -------------------------------------------------
      # EC2 Tags
      # -------------------------------------------------

      Tags:

        - Key: Name
          Value: CloudFormation-WebServer

        - Key: Project
          Value: AWS-CloudFormation-Lab

        - Key: ManagedBy
          Value: CloudFormation


      # =================================================
      # EC2 UserData
      # =================================================
      #
      # IMPORTANT:
      #
      # The complete Bash script is NOT stored here.
      #
      # This small UserData wrapper:
      #
      # 1. Starts during the first EC2 boot.
      # 2. Enables strict Bash error handling.
      # 3. Creates a bootstrap log.
      # 4. Downloads ec2-userdata.sh from GitHub.
      # 5. Makes ec2-userdata.sh executable.
      # 6. Executes ec2-userdata.sh.
      # 7. Creates a completion status file.
      #
      # =================================================

      UserData:
        Fn::Base64: !Sub |

          #!/bin/bash

          # ------------------------------------------------
          # EC2 UserData Wrapper
          # ------------------------------------------------
          #
          # This wrapper downloads the actual EC2 bootstrap
          # script from GitHub.
          #
          # The full server configuration is maintained in:
          #
          # scripts/ec2-userdata.sh
          #
          # ------------------------------------------------


          # ------------------------------------------------
          # Stop execution if a command fails.
          #
          # -e  = exit when a command fails
          # -u  = error when using undefined variables
          # -x  = display commands while executing
          # pipefail = detect failures inside pipelines
          # ------------------------------------------------

          set -euxo pipefail


          # ------------------------------------------------
          # Create a log file for the UserData process.
          #
          # This is useful for troubleshooting.
          # ------------------------------------------------

          exec > >(tee /var/log/bootstrap.log) 2>&1


          # ------------------------------------------------
          # Display start message.
          # ------------------------------------------------

          echo "==============================================="
          echo "Starting EC2 UserData Bootstrap"
          echo "==============================================="


          # ------------------------------------------------
          # Move to temporary directory.
          # ------------------------------------------------

          cd /tmp


          # ------------------------------------------------
          # Display the GitHub script URL.
          # ------------------------------------------------

          echo "Downloading EC2 bootstrap script..."
          echo "Script URL: ${UserDataScriptUrl}"


          # ------------------------------------------------
          # Download the separate Bash script from GitHub.
          #
          # CloudFormation substitutes the value of the
          # UserDataScriptUrl parameter into this command.
          # ------------------------------------------------

          curl -fsSL \
            "${UserDataScriptUrl}" \
            -o ec2-userdata.sh


          # ------------------------------------------------
          # Verify that the script was downloaded.
          # ------------------------------------------------

          if [ ! -s /tmp/ec2-userdata.sh ]; then

            echo "ERROR: ec2-userdata.sh was not downloaded."

            exit 1

          fi


          # ------------------------------------------------
          # Make the Bash script executable.
          # ------------------------------------------------

          chmod +x /tmp/ec2-userdata.sh


          # ------------------------------------------------
          # Display downloaded file information.
          # ------------------------------------------------

          echo "EC2 bootstrap script downloaded successfully."

          ls -lh /tmp/ec2-userdata.sh


          # ------------------------------------------------
          # Execute the actual EC2 bootstrap script.
          #
          # This script contains:
          #
          # - Apache
          # - PHP
          # - MariaDB/MySQL client
          # - Docker
          # - Docker Compose
          # - Git
          # - AWS CLI
          # - DevOps utilities
          #
          # ------------------------------------------------

          echo "Executing ec2-userdata.sh..."

          /bin/bash /tmp/ec2-userdata.sh


          # ------------------------------------------------
          # Create completion status file.
          #
          # This file can be checked after connecting to
          # the EC2 instance.
          # ------------------------------------------------

          echo "Bootstrap completed successfully." \
            > /var/log/bootstrap-status.log


          # ------------------------------------------------
          # Display completion message.
          # ------------------------------------------------

          echo "==============================================="
          echo "EC2 UserData Bootstrap Completed Successfully"
          echo "==============================================="


# =======================================================
# Outputs
# =======================================================

Outputs:


  # -----------------------------------------------------
  # EC2 Instance ID
  # -----------------------------------------------------

  InstanceId:

    Description: >
      EC2 Web Server Instance ID.

    Value: !Ref WebServer


  # -----------------------------------------------------
  # EC2 Public IP
  # -----------------------------------------------------

  PublicIP:

    Description: >
      Public IP address assigned to the EC2 Web Server.

    Value: !GetAtt WebServer.PublicIp


  # -----------------------------------------------------
  # EC2 Public DNS
  # -----------------------------------------------------

  PublicDNS:

    Description: >
      Public DNS name of the EC2 Web Server.

    Value: !GetAtt WebServer.PublicDnsName


  # -----------------------------------------------------
  # UserData Script URL
  # -----------------------------------------------------
  #
  # Displays the GitHub location of the bootstrap script.
  #
  # -----------------------------------------------------

  UserDataScript:

    Description: >
      GitHub Raw URL used by EC2 UserData to download
      the bootstrap script.

    Value: !Ref UserDataScriptUrl
```

---
## AWS RDS Nested Stack Temaplate 

### aws-rds.yaml

```
aws-rds.yaml
```

#### Cloudformation Nested Stack Template 

```
AWSTemplateFormatVersion: '2010-09-09'

# -------------------------------------------------------
# AWS RDS Nested CloudFormation Template
# -------------------------------------------------------
# This template creates the RDS infrastructure separately
# from the main CloudFormation template.
#
# The parent stack will pass:
#
# 1. VPC ID
# 2. Private Subnet 1
# 3. Private Subnet 2
# 4. Web Security Group ID
#
# This makes the RDS template reusable.
# -------------------------------------------------------

Description: >
  Nested CloudFormation stack for Amazon RDS MySQL.
  RDS is deployed separately from the main infrastructure.

# =======================================================
# PARAMETERS
# =======================================================
# These values are received from the parent stack.
# =======================================================

Parameters:

  # -----------------------------------------------------
  # VPC where RDS Security Group will be created
  # -----------------------------------------------------
  VpcId:
    Type: AWS::EC2::VPC::Id
    Description: VPC ID where the RDS security group exists

  # -----------------------------------------------------
  # First private subnet
  # -----------------------------------------------------
  PrivateSubnet1:
    Type: AWS::EC2::Subnet::Id
    Description: First private subnet for RDS

  # -----------------------------------------------------
  # Second private subnet
  # -----------------------------------------------------
  PrivateSubnet2:
    Type: AWS::EC2::Subnet::Id
    Description: Second private subnet for RDS

  # -----------------------------------------------------
  # Web Security Group
  #
  # This is the Security Group attached to the EC2
  # web server.
  #
  # RDS will allow MySQL traffic only from this SG.
  # -----------------------------------------------------
  WebSecurityGroupId:
    Type: AWS::EC2::SecurityGroup::Id
    Description: Security Group ID of the EC2 web server

  # -----------------------------------------------------
  # Database username
  # -----------------------------------------------------
  DBUsername:
    Type: String
    Default: admin
    Description: RDS master username

  # -----------------------------------------------------
  # Database password
  #
  # NoEcho prevents the password from being displayed
  # in CloudFormation console output.
  #
  # For production environments, AWS Secrets Manager
  # is recommended instead of passing a password directly.
  # -----------------------------------------------------
  #DBPassword:
    #NoEcho: true
    #MinLength: 8
    #Description: RDS master password  

# =======================================================
# RESOURCES
# =======================================================

Resources:

  # =====================================================
  # RDS SECURITY GROUP
  # =====================================================
  # Allows MySQL traffic ONLY from the EC2
  # WebSecurityGroup.
  #
  # The database is NOT open to:
  #
  # 0.0.0.0/0
  #
  # This is an important security best practice.
  # =====================================================

  RDSSecurityGroup:
    Type: AWS::EC2::SecurityGroup

    Properties:

      # Description of the security group
      GroupDescription: Allow MySQL from EC2 only

      # Attach the Security Group to the same VPC
      VpcId: !Ref VpcId

      # -------------------------------------------------
      # Inbound Rule
      # -------------------------------------------------
      SecurityGroupIngress:

        - IpProtocol: tcp

          # MySQL port
          FromPort: 3306
          ToPort: 3306

          # Only EC2 instances using WebSecurityGroup
          # can connect to the database.
          SourceSecurityGroupId: !Ref WebSecurityGroupId

          Description: Allow MySQL access only from EC2 Web Security Group

      Tags:

        - Key: Name
          Value: Lab-RDS-SG

  # =====================================================
  # RDS SUBNET GROUP
  # =====================================================
  # RDS requires a DB subnet group when using subnets.
  #
  # We provide two subnets so that RDS can support
  # Multi-AZ configurations when required.
  # =====================================================

  RDSSubnetGroup:
    Type: AWS::RDS::DBSubnetGroup

    Properties:

      DBSubnetGroupDescription: Subnet group for Lab RDS

      # RDS will use these two subnets
      SubnetIds:
        - !Ref PrivateSubnet1
        - !Ref PrivateSubnet2

      Tags:

        - Key: Name
          Value: Lab-RDS-SubnetGroup

  # =====================================================
  # AMAZON RDS MYSQL DATABASE
  # =====================================================

  RDSDatabase:
    Type: AWS::RDS::DBInstance

    Properties:

      # -------------------------------------------------
      # Database Engine
      # -------------------------------------------------
      Engine: mysql

      # -------------------------------------------------
      # MySQL version
      #
      # Verify that this version is available in the
      # AWS region you are using before deployment.
      # -------------------------------------------------
      EngineVersion: '8.0'

      # -------------------------------------------------
      # Free-Tier / Learning Lab instance size
      # -------------------------------------------------
      DBInstanceClass: db.t3.micro

      # -------------------------------------------------
      # Database name
      # -------------------------------------------------
      DBName: labdb

      # -------------------------------------------------
      # Master username
      # -------------------------------------------------
      MasterUsername: !Ref DBUsername

      # -------------------------------------------------
      # Master password
      # -------------------------------------------------
      # MasterUserPassword: !Ref DBPassword

      # -------------------------------------------------
      # AWS SECRETS MANAGER
      #
      # RDS automatically generates and manages the
      # master database password in Secrets Manager.
      # -------------------------------------------------
      ManageMasterUserPassword: true

      # -------------------------------------------------
      # Storage
      # -------------------------------------------------
      AllocatedStorage: 20

      # General Purpose SSD
      StorageType: gp2

      # -------------------------------------------------
      # Disable public access
      #
      # RDS should not receive direct internet traffic.
      # EC2 connects to RDS privately through the VPC.
      # -------------------------------------------------
      PubliclyAccessible: false

      # -------------------------------------------------
      # RDS Security Group
      # -------------------------------------------------
      VPCSecurityGroups:
        - !Ref RDSSecurityGroup

      # -------------------------------------------------
      # RDS Subnet Group
      # -------------------------------------------------
      DBSubnetGroupName: !Ref RDSSubnetGroup

      # -------------------------------------------------
      # Backup retention
      #
      # Set to 0 for a simple learning lab.
      #
      # Production databases should normally use backups.
      # -------------------------------------------------
      BackupRetentionPeriod: 0

      # -------------------------------------------------
      # Encryption
      #
      # Enable this for production workloads.
      # For a basic learning lab, this can remain false.
      # -------------------------------------------------
      StorageEncrypted: false

      # -------------------------------------------------
      # Deletion Policy
      #
      # For a lab, we don't want an old database snapshot
      # left behind after stack deletion.
      # -------------------------------------------------
      DeletionProtection: false

      # -------------------------------------------------
      # Tags
      # -------------------------------------------------
      Tags:

        - Key: Name
          Value: Lab-RDS-MySQL

# =======================================================
# OUTPUTS
# =======================================================
# These values are returned to the parent stack.
# =======================================================

Outputs:

  # -----------------------------------------------------
  # RDS Database ID
  # -----------------------------------------------------
  RDSDatabaseId:
    Description: RDS database identifier
    Value: !Ref RDSDatabase

  # -----------------------------------------------------
  # RDS Endpoint
  #
  # This is the hostname EC2 will use to connect to RDS.
  # -----------------------------------------------------
  RDSEndpoint:
    Description: RDS MySQL endpoint
    Value: !GetAtt RDSDatabase.Endpoint.Address

  # -----------------------------------------------------
  # RDS Port
  # -----------------------------------------------------
  RDSPort:
    Description: RDS MySQL port
    Value: !GetAtt RDSDatabase.Endpoint.Port

  # -----------------------------------------------------
  # RDS Security Group ID
  # -----------------------------------------------------
  RDSSecurityGroupId:
    Description: RDS Security Group ID
    Value: !Ref RDSSecurityGroup

  # -----------------------------------------------------
  # SECRET ARN
  #
  # RDS exposes the ARN of the Secrets Manager secret
  # through the MasterUserSecret attribute.
  # -----------------------------------------------------

  RDSMasterUserSecretArn:
    Description: Secrets Manager ARN containing RDS master credentials
    Value: !GetAtt RDSDatabase.MasterUserSecret.SecretArn  
```

---
## AWS S3 Nested Stack Temaplate 

### s3.yaml

```
s3.yaml
```

#### Cloudformation Nested Stack Template 

```
AWSTemplateFormatVersion: '2010-09-09'

Description: >
  Creates an S3 bucket for the CloudFormation lab
  with versioning enabled.

# =======================================================
# Resources
# =======================================================

Resources:

  # -----------------------------------------------------
  # S3 Bucket
  # -----------------------------------------------------

  LabBucket:
    Type: AWS::S3::Bucket

    Properties:

      # -------------------------------------------------
      # Enable S3 Versioning
      # -------------------------------------------------

      VersioningConfiguration:
        Status: Enabled

      # -------------------------------------------------
      # Add tags to the bucket
      # -------------------------------------------------

      Tags:
        - Key: Name
          Value: Lab-S3-Bucket


# =======================================================
# Outputs
# =======================================================

Outputs:

  # -----------------------------------------------------
  # S3 Bucket Name
  # -----------------------------------------------------

  BucketName:
    Description: >
      Name of the S3 bucket created by the nested stack.

    Value: !Ref LabBucket

  # -----------------------------------------------------
  # S3 Bucket ARN
  # -----------------------------------------------------

  BucketArn:
    Description: >
      ARN of the S3 bucket created by the nested stack.

    Value: !GetAtt LabBucket.Arn
```


---
## S3 Main Stack Temaplate 

### TemplateBucket-MainStack.yaml

```
TemplateBucket-MainStack.yaml
```

#### Cloudformation Main Template 

```
AWSTemplateFormatVersion: '2010-09-09'

Description: >
  Creates an S3 bucket used to store nested
  CloudFormation templates for the AWS DevOps Lab.

# =======================================================
# Resources
# =======================================================

Resources:

  # -----------------------------------------------------
  # S3 Bucket for CloudFormation Templates
  # -----------------------------------------------------

  TemplateBucket:
    Type: AWS::S3::Bucket

    Properties:

      # -------------------------------------------------
      # Enable Versioning
      #
      # This allows previous versions of CloudFormation
      # templates to be retained in S3.
      # -------------------------------------------------

      VersioningConfiguration:
        Status: Enabled

      # -------------------------------------------------
      # Add Tags
      # -------------------------------------------------

      Tags:

        - Key: Name
          Value: Lab-CloudFormation-Templates

        - Key: Purpose
          Value: CloudFormation-Nested-Templates


# =======================================================
# Outputs
# =======================================================

Outputs:

  # -----------------------------------------------------
  # S3 Bucket Name
  # -----------------------------------------------------

  BucketName:

    Description: >
      Name of the S3 bucket used to store nested
      CloudFormation templates.

    Value: !Ref TemplateBucket


  # -----------------------------------------------------
  # S3 Bucket ARN
  # -----------------------------------------------------

  BucketArn:

    Description: >
      ARN of the S3 bucket used to store nested
      CloudFormation templates.

    Value: !GetAtt TemplateBucket.Arn
```

---
## ECS & ECR Main Stack Temaplate 

### aws-ecs-ecr.yaml

```
aws-ecs-ecr.yaml
```

#### Cloudformation Main Template 

```
AWSTemplateFormatVersion: '2010-09-09'

# ============================================================
# Charlie Cafe
# Standalone ECS Fargate + ECR CloudFormation Stack
# ============================================================
#
# IMPORTANT:
#
# This is a COMPLETELY INDEPENDENT CloudFormation stack.
#
# It is NOT a nested stack.
#
# The VPC, public subnets, private subnets and private route
# table are created by your MAIN CloudFormation stack.
#
# This stack consumes those existing networking resources.
#
# ============================================================
#
# THIS STACK CREATES:
#
# 1. ECR Repository
# 2. ECS Cluster
# 3. CloudWatch Log Group
# 4. ECS Task Execution IAM Role
# 5. ECS Task IAM Role
# 6. VPC Endpoint Security Group
# 7. ECR API VPC Endpoint
# 8. ECR Docker Registry VPC Endpoint
# 9. S3 Gateway VPC Endpoint
# 10. CloudWatch Logs VPC Endpoint
# 11. ALB Security Group
# 12. ECS Task Security Group
# 13. Application Load Balancer
# 14. ALB Target Group
# 15. ALB Listener
# 16. ECS Task Definition
# 17. ECS Fargate Service
#
# ============================================================
#
# ACM CERTIFICATE:
#
# NOT INCLUDED.
#
# We are intentionally using HTTP :80 for this beginner lab.
#
# HTTPS + ACM can be added later.
#
# ============================================================


# ============================================================
# HIGH-LEVEL ARCHITECTURE
# ============================================================
#
#
#                         INTERNET
#                             |
#                             |
#                             | HTTP :80
#                             |
#                             v
#                  +----------------------+
#                  | Application Load     |
#                  | Balancer             |
#                  | PUBLIC SUBNETS       |
#                  +----------------------+
#                             |
#                             |
#                             | Container Port
#                             |
#                             v
#                  +----------------------+
#                  | ECS Fargate Service  |
#                  +----------------------+
#                             |
#                             |
#                             v
#                  +----------------------+
#                  | ECS Fargate Task     |
#                  | PRIVATE SUBNET       |
#                  | Docker Container     |
#                  +----------------------+
#                             |
#                             |
#                             v
#                  +----------------------+
#                  | Amazon ECR           |
#                  | Docker Image         |
#                  +----------------------+
#
#
# PRIVATE AWS SERVICE CONNECTIVITY
#
#
# ECS Fargate Task
#        |
#        +------------------> ECR API Endpoint
#        |
#        +------------------> ECR DKR Endpoint
#        |
#        +------------------> S3 Gateway Endpoint
#        |
#        +------------------> CloudWatch Logs Endpoint
#
#
# No NAT Gateway is required for these AWS service connections.
#
# ============================================================


# ============================================================
# IMPORTANT LEARNING NOTE
# ============================================================
#
# CloudFormation creates the infrastructure first.
#
# The ECR repository starts EMPTY.
#
# This is NORMAL.
#
# CloudFormation creates:
#
#     ECR Repository
#           |
#           v
#     Repository exists
#           |
#           v
#     GitHub Actions builds Docker image
#           |
#           v
#     Docker image
#           |
#           v
#     Push image to ECR
#           |
#           v
#     ECS Fargate pulls image
#           |
#           v
#     Container starts
#
# ============================================================


# ============================================================
# PARAMETERS
# ============================================================

Parameters:

  # ----------------------------------------------------------
  # EXISTING VPC
  # ----------------------------------------------------------
  #
  # The VPC is NOT created by this stack.
  #
  # It already exists in your main CloudFormation stack.
  #
  # Example:
  #
  #     vpc-0123456789abcdef
  #
  # ----------------------------------------------------------

  VpcId:
    Type: AWS::EC2::VPC::Id

    Description:
      Existing VPC where ECS and ALB resources will be deployed.


  # ----------------------------------------------------------
  # PUBLIC SUBNET 1
  # ----------------------------------------------------------
  #
  # ALB uses public subnets.
  #
  # ALB requires subnets in at least two Availability Zones.
  #
  # ----------------------------------------------------------

  PublicSubnet1:
    Type: AWS::EC2::Subnet::Id

    Description:
      First public subnet for the Application Load Balancer.


  # ----------------------------------------------------------
  # PUBLIC SUBNET 2
  # ----------------------------------------------------------

  PublicSubnet2:
    Type: AWS::EC2::Subnet::Id

    Description:
      Second public subnet for the Application Load Balancer.


  # ----------------------------------------------------------
  # PRIVATE SUBNET 1
  # ----------------------------------------------------------
  #
  # ECS Fargate tasks will run here.
  #
  # ----------------------------------------------------------

  PrivateSubnet1:
    Type: AWS::EC2::Subnet::Id

    Description:
      First private subnet for ECS Fargate tasks.


  # ----------------------------------------------------------
  # PRIVATE SUBNET 2
  # ----------------------------------------------------------

  PrivateSubnet2:
    Type: AWS::EC2::Subnet::Id

    Description:
      Second private subnet for ECS Fargate tasks.


  # ----------------------------------------------------------
  # PRIVATE ROUTE TABLE
  # ----------------------------------------------------------
  #
  # The S3 Gateway VPC Endpoint must be associated with the
  # route table used by the private subnets.
  #
  # This route table is created by your MAIN stack.
  #
  # We therefore receive its ID as a parameter.
  #
  # ----------------------------------------------------------

  PrivateRouteTableId:
    Type: String

    Description:
      ID of the existing private route table used by the ECS private subnets.


  # ----------------------------------------------------------
  # APPLICATION NAME
  # ----------------------------------------------------------

  ApplicationName:
    Type: String

    Default: CharlieCafe

    Description:
      Application name used for ECS, ECR and ALB resources.


  # ----------------------------------------------------------
  # CONTAINER PORT
  # ----------------------------------------------------------
  #
  # The Docker application must listen on this port.
  #
  # Examples:
  #
  # Nginx       = 80
  # Apache      = 80
  # Node.js     = 3000
  # Python      = 5000
  #
  # ----------------------------------------------------------

  ContainerPort:
    Type: Number

    Default: 80

    Description:
      Port exposed by the Docker container.


  # ----------------------------------------------------------
  # ECS TASK CPU
  # ----------------------------------------------------------
  #
  # 256 CPU units = 0.25 vCPU
  #
  # ----------------------------------------------------------

  TaskCpu:
    Type: String

    Default: '256'

    Description:
      Fargate task CPU units.


  # ----------------------------------------------------------
  # ECS TASK MEMORY
  # ----------------------------------------------------------
  #
  # 512 MB is suitable for a small beginner lab.
  #
  # ----------------------------------------------------------

  TaskMemory:
    Type: String

    Default: '512'

    Description:
      Fargate task memory in MB.


  # ----------------------------------------------------------
  # DESIRED TASK COUNT
  # ----------------------------------------------------------
  #
  # Number of ECS tasks ECS should keep running.
  #
  # ----------------------------------------------------------

  DesiredCount:
    Type: Number

    Default: 0

    Description:
      Number of ECS Fargate tasks.


# ============================================================
# RESOURCES
# ============================================================

Resources:


  # ==========================================================
  # 1. VPC ENDPOINT SECURITY GROUP
  # ==========================================================
  #
  # This security group belongs to the INTERFACE VPC
  # endpoints.
  #
  # Interface endpoints:
  #
  #     ECR API
  #     ECR DKR
  #     CloudWatch Logs
  #
  # The ECS private subnet traffic reaches these endpoints
  # over HTTPS port 443.
  #
  # ==========================================================

  VPCEndpointSecurityGroup:

    Type: AWS::EC2::SecurityGroup

    Properties:

      GroupDescription:
        Allow HTTPS from ECS private subnets to AWS VPC endpoints

      VpcId:
        !Ref VpcId

      SecurityGroupIngress:

        # ----------------------------------------------------
        # HTTPS from Private Subnet 1
        # ----------------------------------------------------

        - IpProtocol: tcp

          FromPort: 443

          ToPort: 443

          CidrIp: 10.0.2.0/24

          Description:
            HTTPS from Private Subnet 1


        # ----------------------------------------------------
        # HTTPS from Private Subnet 2
        # ----------------------------------------------------

        - IpProtocol: tcp

          FromPort: 443

          ToPort: 443

          CidrIp: 10.0.3.0/24

          Description:
            HTTPS from Private Subnet 2

      SecurityGroupEgress:

        # ----------------------------------------------------
        # Allow outbound traffic.
        # ----------------------------------------------------

        - IpProtocol: -1

          CidrIp: 0.0.0.0/0

      Tags:

        - Key: Name
          Value: CharlieCafe-VPC-Endpoint-SG

        - Key: Project
          Value: CharlieCafe


  # ==========================================================
  # 2. ECR API VPC ENDPOINT
  # ==========================================================
  #
  # This allows the ECS task to communicate with the Amazon
  # ECR API privately.
  #
  # Service:
  #
  #     com.amazonaws.<region>.ecr.api
  #
  # ==========================================================

  ECRApiVPCEndpoint:

    Type: AWS::EC2::VPCEndpoint

    Properties:

      VpcId:
        !Ref VpcId

      ServiceName:
        !Sub 'com.amazonaws.${AWS::Region}.ecr.api'

      VpcEndpointType:
        Interface

      PrivateDnsEnabled:
        true

      SubnetIds:

        - !Ref PrivateSubnet1

        - !Ref PrivateSubnet2

      SecurityGroupIds:

        - !Ref VPCEndpointSecurityGroup

      Tags:

        - Key: Name
          Value: CharlieCafe-ECR-API-VPC-Endpoint

        - Key: Project
          Value: CharlieCafe


  # ==========================================================
  # 3. ECR DOCKER REGISTRY VPC ENDPOINT
  # ==========================================================
  #
  # Docker image pull traffic uses the ECR Docker registry
  # endpoint.
  #
  # Service:
  #
  #     com.amazonaws.<region>.ecr.dkr
  #
  # ==========================================================

  ECRDkrVPCEndpoint:

    Type: AWS::EC2::VPCEndpoint

    Properties:

      VpcId:
        !Ref VpcId

      ServiceName:
        !Sub 'com.amazonaws.${AWS::Region}.ecr.dkr'

      VpcEndpointType:
        Interface

      PrivateDnsEnabled:
        true

      SubnetIds:

        - !Ref PrivateSubnet1

        - !Ref PrivateSubnet2

      SecurityGroupIds:

        - !Ref VPCEndpointSecurityGroup

      Tags:

        - Key: Name
          Value: CharlieCafe-ECR-DKR-VPC-Endpoint

        - Key: Project
          Value: CharlieCafe


  # ==========================================================
  # 4. S3 GATEWAY VPC ENDPOINT
  # ==========================================================
  #
  # IMPORTANT:
  #
  # ECR stores Docker image layers in Amazon S3.
  #
  # Therefore the ECS task needs access to S3 when pulling
  # the image layers.
  #
  # Gateway endpoints are different from interface endpoints.
  #
  # This endpoint is attached to the PRIVATE ROUTE TABLE.
  #
  # ==========================================================

  S3VPCEndpoint:

    Type: AWS::EC2::VPCEndpoint

    Properties:

      VpcId:
        !Ref VpcId

      ServiceName:
        !Sub 'com.amazonaws.${AWS::Region}.s3'

      VpcEndpointType:
        Gateway

      RouteTableIds:

        - !Ref PrivateRouteTableId

      Tags:

        - Key: Name
          Value: CharlieCafe-S3-Gateway-VPC-Endpoint

        - Key: Project
          Value: CharlieCafe


  # ==========================================================
  # 5. CLOUDWATCH LOGS VPC ENDPOINT
  # ==========================================================
  #
  # Your ECS task uses:
  #
  #     LogDriver: awslogs
  #
  # Therefore the container sends stdout/stderr to CloudWatch
  # Logs.
  #
  # Because the ECS task is in a private subnet and we are
  # intentionally NOT using a NAT Gateway, the task needs
  # private connectivity to CloudWatch Logs.
  #
  # Service:
  #
  #     com.amazonaws.<region>.logs
  #
  # ==========================================================

  CloudWatchLogsVPCEndpoint:

    Type: AWS::EC2::VPCEndpoint

    Properties:

      VpcId:
        !Ref VpcId

      ServiceName:
        !Sub 'com.amazonaws.${AWS::Region}.logs'

      VpcEndpointType:
        Interface

      PrivateDnsEnabled:
        true

      SubnetIds:

        - !Ref PrivateSubnet1

        - !Ref PrivateSubnet2

      SecurityGroupIds:

        - !Ref VPCEndpointSecurityGroup

      Tags:

        - Key: Name
          Value: CharlieCafe-CloudWatch-Logs-VPC-Endpoint

        - Key: Project
          Value: CharlieCafe


  # ==========================================================
  # 6. ECR REPOSITORY
  # ==========================================================
  #
  # This is the Docker image registry.
  #
  # IMPORTANT:
  #
  # The repository will initially be EMPTY.
  #
  # That is expected.
  #
  # GitHub Actions will later:
  #
  #     docker build
  #          |
  #          v
  #     docker image
  #          |
  #          v
  #     docker push
  #          |
  #          v
  #     ECR
  #
  # ==========================================================

  ECRRepository:

    Type: AWS::ECR::Repository

    Properties:

      RepositoryName:
        charlie-cafe

      # ------------------------------------------------------
      # Scan Docker images when pushed.
      # ------------------------------------------------------

      ImageScanningConfiguration:

        ScanOnPush: true

      # ------------------------------------------------------
      # Server-side encryption.
      # ------------------------------------------------------

      EncryptionConfiguration:

        EncryptionType: AES256

      # ------------------------------------------------------
      # Mutable tags.
      #
      # This allows:
      #
      #     latest
      #
      # to point to a newer image.
      #
      # Later, you can move to immutable version tags.
      # ------------------------------------------------------

      ImageTagMutability:
        MUTABLE

      Tags:

        - Key: Name
          Value: CharlieCafe-ECR

        - Key: Project
          Value: CharlieCafe


  # ==========================================================
  # 7. ECS CLUSTER
  # ==========================================================
  #
  # Fargate does not require us to create EC2 instances.
  #
  # AWS manages the underlying compute infrastructure.
  #
  # ==========================================================

  ECSCluster:

    Type: AWS::ECS::Cluster

    Properties:

      ClusterName:
        CharlieCafe-Cluster

      ClusterSettings:

        - Name: containerInsights

          Value: enabled

      Tags:

        - Key: Name
          Value: CharlieCafe-Cluster

        - Key: Project
          Value: CharlieCafe


  # ==========================================================
  # 8. CLOUDWATCH LOG GROUP
  # ==========================================================
  #
  # ECS sends Docker stdout/stderr here.
  #
  # ==========================================================

  ECSLogGroup:

    Type: AWS::Logs::LogGroup

    Properties:

      LogGroupName:
        /ecs/charlie-cafe

      RetentionInDays:
        30

      Tags:

        - Key: Project
          Value: CharlieCafe


  # ==========================================================
  # 9. ECS TASK EXECUTION ROLE
  # ==========================================================
  #
  # This role is used by ECS/Fargate.
  #
  # It allows ECS to:
  #
  #     Pull the private image from ECR
  #
  #     Send container logs to CloudWatch Logs
  #
  # This is NOT the application role.
  #
  # ==========================================================

  ECSTaskExecutionRole:

    Type: AWS::IAM::Role

    Properties:

      RoleName:
        !Sub '${ApplicationName}-ECSTaskExecutionRole'

      AssumeRolePolicyDocument:

        Version: '2012-10-17'

        Statement:

          - Effect: Allow

            Principal:

              Service:
                ecs-tasks.amazonaws.com

            Action:
              sts:AssumeRole

      ManagedPolicyArns:

        - arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

      Tags:

        - Key: Name
          Value: CharlieCafe-ECSTaskExecutionRole

        - Key: Project
          Value: CharlieCafe


  # ==========================================================
  # 10. ECS TASK ROLE
  # ==========================================================
  #
  # This role belongs to the APPLICATION running inside the
  # container.
  #
  # Initially we give it no additional permissions.
  #
  # Later, if the application needs:
  #
  #     S3
  #     DynamoDB
  #     Secrets Manager
  #     KMS
  #
  # permissions can be added here.
  #
  # ==========================================================

  ECSTaskRole:

    Type: AWS::IAM::Role

    Properties:

      RoleName:
        !Sub '${ApplicationName}-ECSTaskRole'

      AssumeRolePolicyDocument:

        Version: '2012-10-17'

        Statement:

          - Effect: Allow

            Principal:

              Service:
                ecs-tasks.amazonaws.com

            Action:
              sts:AssumeRole

      Tags:

        - Key: Name
          Value: CharlieCafe-ECSTaskRole

        - Key: Project
          Value: CharlieCafe


  # ==========================================================
  # 11. ALB SECURITY GROUP
  # ==========================================================
  #
  # Internet
  #    |
  #    | TCP 80
  #    v
  #   ALB
  #
  # Later, when ACM is added:
  #
  # Internet
  #    |
  #    | TCP 443
  #    v
  #   ALB
  #
  # ==========================================================

  ALBSecurityGroup:

    Type: AWS::EC2::SecurityGroup

    Properties:

      GroupDescription:
        Allow HTTP traffic to Charlie Cafe Application Load Balancer

      VpcId:
        !Ref VpcId

      SecurityGroupIngress:

        - IpProtocol: tcp

          FromPort: 80

          ToPort: 80

          CidrIp: 0.0.0.0/0

          Description:
            Allow HTTP from Internet

      SecurityGroupEgress:

        - IpProtocol: -1

          CidrIp: 0.0.0.0/0

      Tags:

        - Key: Name
          Value: CharlieCafe-ALB-SG

        - Key: Project
          Value: CharlieCafe


  # ==========================================================
  # 12. ECS TASK SECURITY GROUP
  # ==========================================================
  #
  # IMPORTANT SECURITY ARCHITECTURE:
  #
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
  #
  # ECS does NOT allow:
  #
  #     0.0.0.0/0
  #
  # directly to the container.
  #
  # Only the ALB security group can access the container.
  #
  # ==========================================================

  ECSTaskSecurityGroup:

    Type: AWS::EC2::SecurityGroup

    Properties:

      GroupDescription:
        Allow application traffic only from the ALB

      VpcId:
        !Ref VpcId

      SecurityGroupIngress:

        - IpProtocol: tcp

          FromPort:
            !Ref ContainerPort

          ToPort:
            !Ref ContainerPort

          SourceSecurityGroupId:
            !Ref ALBSecurityGroup

          Description:
            Allow application traffic from ALB

      SecurityGroupEgress:

        - IpProtocol: -1

          CidrIp: 0.0.0.0/0

      Tags:

        - Key: Name
          Value: CharlieCafe-ECS-Task-SG

        - Key: Project
          Value: CharlieCafe


  # ==========================================================
  # 13. APPLICATION LOAD BALANCER
  # ==========================================================
  #
  # The ALB is internet-facing.
  #
  # It is deployed into PUBLIC subnets.
  #
  # ECS tasks remain in PRIVATE subnets.
  #
  # ==========================================================

  ApplicationLoadBalancer:

    Type: AWS::ElasticLoadBalancingV2::LoadBalancer

    Properties:

      Name:
        CharlieCafe-ALB

      Scheme:
        internet-facing

      Type:
        application

      SecurityGroups:

        - !Ref ALBSecurityGroup

      Subnets:

        - !Ref PublicSubnet1

        - !Ref PublicSubnet2

      Tags:

        - Key: Name
          Value: CharlieCafe-ALB

        - Key: Project
          Value: CharlieCafe


  # ==========================================================
  # 14. ALB TARGET GROUP
  # ==========================================================
  #
  # Fargate uses awsvpc networking.
  #
  # Therefore:
  #
  #     TargetType = ip
  #
  # ECS automatically registers the task IP address.
  #
  # ==========================================================

  ALBTargetGroup:

    Type: AWS::ElasticLoadBalancingV2::TargetGroup

    Properties:

      Name:
        CharlieCafe-TG

      VpcId:
        !Ref VpcId

      Protocol:
        HTTP

      Port:
        !Ref ContainerPort

      TargetType:
        ip

      # ------------------------------------------------------
      # Health check
      # ------------------------------------------------------
      #
      # ALB requests:
      #
      #     GET /
      #
      # from the container.
      #
      # ------------------------------------------------------

      HealthCheckEnabled:
        true

      HealthCheckProtocol:
        HTTP

      HealthCheckPath:
        /

      HealthCheckPort:
        traffic-port

      HealthCheckIntervalSeconds:
        30

      HealthCheckTimeoutSeconds:
        5

      HealthyThresholdCount:
        2

      UnhealthyThresholdCount:
        3

      Tags:

        - Key: Name
          Value: CharlieCafe-TG

        - Key: Project
          Value: CharlieCafe


  # ==========================================================
  # 15. ALB LISTENER
  # ==========================================================
  #
  # HTTP listener on port 80.
  #
  # ACM/HTTPS intentionally excluded.
  #
  # ==========================================================

  ALBListener:

    Type: AWS::ElasticLoadBalancingV2::Listener

    Properties:

      LoadBalancerArn:
        !Ref ApplicationLoadBalancer

      Port:
        80

      Protocol:
        HTTP

      DefaultActions:

        - Type:
            forward

          TargetGroupArn:
            !Ref ALBTargetGroup


  # ==========================================================
  # 16. ECS TASK DEFINITION
  # ==========================================================
  #
  # This is the blueprint for the Docker container.
  #
  # It defines:
  #
  #     CPU
  #     Memory
  #     Docker image
  #     Container port
  #     IAM roles
  #     CloudWatch logging
  #
  # ==========================================================

  ECSTaskDefinition:

    Type: AWS::ECS::TaskDefinition

    Properties:

      Family:
        CharlieCafe

      # ------------------------------------------------------
      # Fargate requires awsvpc.
      # ------------------------------------------------------

      NetworkMode:
        awsvpc

      RequiresCompatibilities:

        - FARGATE

      Cpu:
        !Ref TaskCpu

      Memory:
        !Ref TaskMemory

      # ------------------------------------------------------
      # ECS/Fargate uses this role to:
      #
      #     Pull ECR image
      #     Send CloudWatch logs
      #
      # ------------------------------------------------------

      ExecutionRoleArn:
        !GetAtt ECSTaskExecutionRole.Arn

      # ------------------------------------------------------
      # Application IAM role.
      # ------------------------------------------------------

      TaskRoleArn:
        !GetAtt ECSTaskRole.Arn

      # ------------------------------------------------------
      # Container definition
      # ------------------------------------------------------

      ContainerDefinitions:

        - Name:
            charlie-cafe

          # --------------------------------------------------
          # IMPORTANT:
          #
          # CloudFormation creates the repository.
          #
          # GitHub Actions pushes the image.
          #
          # ECS pulls:
          #
          #     charlie-cafe:latest
          #
          # --------------------------------------------------

          Image:
            !Sub '${ECRRepository.RepositoryUri}:latest'

          Essential:
            true

          # --------------------------------------------------
          # Container port
          # --------------------------------------------------

          PortMappings:

            - ContainerPort:
                !Ref ContainerPort

              Protocol:
                tcp

          # --------------------------------------------------
          # CloudWatch logging
          # --------------------------------------------------

          LogConfiguration:

            LogDriver:
              awslogs

            Options:

              awslogs-group:
                !Ref ECSLogGroup

              awslogs-region:
                !Ref AWS::Region

              awslogs-stream-prefix:
                ecs


  # ==========================================================
  # 17. ECS FARGATE SERVICE
  # ==========================================================
  #
  # The ECS Service keeps the desired number of tasks running.
  #
  # DesiredCount = 1
  #
  # If a task crashes, ECS attempts to replace it.
  #
  # ==========================================================

  ECSService:

    Type: AWS::ECS::Service

    DependsOn:

      - ALBListener

    Properties:

      ServiceName:
        CharlieCafe-Service

      Cluster:
        !Ref ECSCluster

      LaunchType:
        FARGATE

      DesiredCount:
        !Ref DesiredCount

      TaskDefinition:
        !Ref ECSTaskDefinition

      # ======================================================
      # NETWORK CONFIGURATION
      # ======================================================
      #
      # Tasks run in private subnets.
      #
      # No public IP.
      #
      # ======================================================

      NetworkConfiguration:

        AwsvpcConfiguration:

          AssignPublicIp:
            DISABLED

          SecurityGroups:

            - !Ref ECSTaskSecurityGroup

          Subnets:

            - !Ref PrivateSubnet1

            - !Ref PrivateSubnet2

      # ======================================================
      # LOAD BALANCER CONFIGURATION
      # ======================================================

      LoadBalancers:

        - ContainerName:
            charlie-cafe

          ContainerPort:
            !Ref ContainerPort

          TargetGroupArn:
            !Ref ALBTargetGroup

      # ======================================================
      # DEPLOYMENT CONFIGURATION
      # ======================================================

      DeploymentConfiguration:

        MaximumPercent:
          200

        MinimumHealthyPercent:
          50

      Tags:

        - Key: Name
          Value: CharlieCafe-Service

        - Key: Project
          Value: CharlieCafe


# ============================================================
# OUTPUTS
# ============================================================

Outputs:


  # ==========================================================
  # ECR REPOSITORY NAME
  # ==========================================================

  ECRRepositoryName:

    Description:
      Name of the Charlie Cafe ECR repository.

    Value:
      !Ref ECRRepository


  # ==========================================================
  # ECR REPOSITORY URI
  # ==========================================================
  #
  # GitHub Actions will use this repository URI when pushing
  # the Docker image.
  #
  # ==========================================================

  ECRRepositoryUri:

    Description:
      URI of the Charlie Cafe ECR repository.

    Value:
      !GetAtt ECRRepository.RepositoryUri


  # ==========================================================
  # ECS CLUSTER
  # ==========================================================

  ECSClusterName:

    Description:
      Name of the ECS cluster.

    Value:
      !Ref ECSCluster


  # ==========================================================
  # ECS SERVICE
  # ==========================================================

  ECSServiceName:

    Description:
      Name of the ECS service.

    Value:
      !Ref ECSService


  # ==========================================================
  # ECS TASK DEFINITION
  # ==========================================================

  ECSTaskDefinitionArn:

    Description:
      ARN of the ECS task definition.

    Value:
      !Ref ECSTaskDefinition


  # ==========================================================
  # ALB DNS NAME
  # ==========================================================
  #
  # You can open this address in your browser after:
  #
  #     1. Docker image exists in ECR
  #     2. ECS task starts
  #     3. Target becomes healthy
  #
  # ==========================================================

  ALBDNSName:

    Description:
      DNS name of the Charlie Cafe Application Load Balancer.

    Value:
      !GetAtt ApplicationLoadBalancer.DNSName


  # ==========================================================
  # APPLICATION URL
  # ==========================================================

  ApplicationURL:

    Description:
      Public HTTP URL for the Charlie Cafe ECS application.

    Value:
      !Sub 'http://${ApplicationLoadBalancer.DNSName}'


  # ==========================================================
  # ALB SECURITY GROUP
  # ==========================================================

  ALBSecurityGroupId:

    Description:
      Security group ID used by the Application Load Balancer.

    Value:
      !Ref ALBSecurityGroup


  # ==========================================================
  # ECS TASK SECURITY GROUP
  # ==========================================================

  ECSTaskSecurityGroupId:

    Description:
      Security group ID used by ECS Fargate tasks.

    Value:
      !Ref ECSTaskSecurityGroup


  # ==========================================================
  # VPC ENDPOINT SECURITY GROUP
  # ==========================================================

  VPCEndpointSecurityGroupId:

    Description:
      Security group ID used by the interface VPC endpoints.

    Value:
      !Ref VPCEndpointSecurityGroup
```

---
