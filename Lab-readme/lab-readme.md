


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

# GITHUB WorkFlow 

## 1. deploy.yml

```
# ==========================================================
# AWS CloudFormation DevOps Lab
# GitHub Actions Deployment Workflow
# ==========================================================
#
# File:
# .github/workflows/deploy.yml
#
# Purpose:
# ----------------------------------------------------------
# This workflow automatically validates and deploys the
# CloudFormation infrastructure defined in:
#
# templates/lab01.yaml
#
# The workflow performs the following tasks:
#
# 1. Checkout GitHub repository
# 2. Configure AWS credentials
# 3. Verify AWS CLI and AWS identity
# 4. Check required deployment values
# 5. Create/update the template bucket stack
# 6. Get the template S3 bucket name
# 7. Upload nested CloudFormation templates to S3
# 8. Display repository/deployment information
# 9. Verify CloudFormation templates exist
# 10. Validate the main CloudFormation template
# 11. Check whether the main stack exists
# 12. Display existing stack status
# 13. Create the main stack if it does not exist
# 14. Wait for stack creation
# 15. Update the main stack if it already exists
# 16. Wait for stack update
# 17. Display final stack information
# 18. Display stack resources
# 19. Display stack outputs
# 20. Display deployment completion message
#
# ==========================================================
#
# IMPORTANT RDS SECURITY DESIGN
# ==========================================================
#
# This workflow DOES NOT contain:
#
# DB_MASTER_PASSWORD
# DBMasterPassword
#
# The RDS nested CloudFormation template uses:
#
# ManageMasterUserPassword: true
#
# Therefore:
#
# GitHub Actions
#       |
#       v
# CloudFormation
#       |
#       v
# Amazon RDS
#       |
#       v
# AWS Secrets Manager
#
# RDS automatically creates and manages the master database
# password in AWS Secrets Manager.
#
# GitHub Actions never receives or stores the RDS password.
#
# ==========================================================


# ----------------------------------------------------------
# Workflow Name
# ----------------------------------------------------------

name: AWS CloudFormation Deployment


# ----------------------------------------------------------
# Workflow Triggers
# ----------------------------------------------------------
#
# The workflow runs:
#
# 1. Automatically when code is pushed to main
# 2. Manually from GitHub Actions
#
# ----------------------------------------------------------

on:

  push:
    branches:
      - main

  workflow_dispatch:


# ----------------------------------------------------------
# Global Environment Variables
# ----------------------------------------------------------

env:

  # ========================================================
  # AWS Region
  # ========================================================

  AWS_REGION: us-east-1


  # ========================================================
  # Main CloudFormation Stack
  # ========================================================
  #
  # This is the main infrastructure stack.
  #
  # It creates:
  #
  # - VPC
  # - Internet Gateway
  # - Subnets
  # - Route Tables
  # - Security Groups
  # - EC2 nested stack
  # - S3 nested stack
  # - RDS nested stack
  #
  # ========================================================

  STACK_NAME: Lab01-CloudFormation


  # ========================================================
  # EC2 Key Pair
  # ========================================================

  KEY_PAIR_NAME: Lab-KeyPair


  # ========================================================
  # Template Bucket CloudFormation Stack
  # ========================================================
  #
  # This separate stack creates the S3 bucket used to store
  # nested CloudFormation templates.
  #
  # ========================================================

  TEMPLATE_BUCKET_STACK: Lab01-CloudFormation-TemplateBucket


  # ========================================================
  # Template Bucket CloudFormation Template
  # ========================================================

  TEMPLATE_BUCKET_FILE: templates/TemplateBucket-MainStack.yaml


  # ========================================================
  # Main CloudFormation Template
  # ========================================================

  TEMPLATE_FILE: templates/lab01.yaml


# ==========================================================
# JOBS
# ==========================================================

jobs:

  deploy:

    # --------------------------------------------------------
    # GitHub-hosted runner
    # --------------------------------------------------------

    runs-on: ubuntu-latest

    name: Validate and Deploy CloudFormation Stack


    # ========================================================
    # STEPS
    # ========================================================

    steps:


      # ======================================================
      # Step 1 - Checkout Repository
      # ======================================================
      #
      # Downloads the GitHub repository onto the GitHub
      # Actions runner.
      #
      # This makes files such as:
      #
      # templates/lab01.yaml
      # templates/aws-rds.yaml
      # templates/ec2-webserver.yaml
      #
      # available to the workflow.
      #
      # ======================================================

      - name: Checkout Repository

        uses: actions/checkout@v4


      # ======================================================
      # Step 2 - Configure AWS Credentials
      # ======================================================
      #
      # Required GitHub Secrets:
      #
      # AWS_ACCESS_KEY_ID
      # AWS_SECRET_ACCESS_KEY
      #
      # IMPORTANT:
      #
      # DB_MASTER_PASSWORD is NOT required anymore.
      #
      # RDS generates and manages the master password using
      # AWS Secrets Manager.
      #
      # ======================================================

      - name: Configure AWS Credentials

        uses: aws-actions/configure-aws-credentials@v4

        with:

          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}

          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

          aws-region: ${{ env.AWS_REGION }}


      # ======================================================
      # Step 3 - Verify AWS CLI
      # ======================================================
      #
      # Confirms:
      #
      # 1. AWS CLI is available
      # 2. GitHub Actions can authenticate with AWS
      # 3. The expected AWS account is being used
      #
      # ======================================================

      - name: Verify AWS CLI

        shell: bash

        run: |

          echo "======================================"
          echo "AWS CLI Version"
          echo "======================================"

          aws --version

          echo ""

          echo "======================================"
          echo "AWS Account Information"
          echo "======================================"

          aws sts get-caller-identity \
            --no-cli-pager


      # ======================================================
      # Step 4 - Check Required Deployment Values
      # ======================================================
      #
      # Checks the values required by the main CloudFormation
      # template.
      #
      # Required values:
      #
      # - AWS Region
      # - Stack name
      # - Main template
      # - Template bucket stack
      # - Template bucket template
      # - EC2 Key Pair
      #
      # There is intentionally NO database password check.
      #
      # RDS uses AWS Secrets Manager automatically.
      #
      # ======================================================

      - name: Check Required Deployment Values

        shell: bash

        run: |

          echo "======================================"
          echo "Checking Required Deployment Values"
          echo "======================================"

          echo "AWS Region:"
          echo "$AWS_REGION"

          echo ""

          echo "CloudFormation Stack:"
          echo "$STACK_NAME"

          echo ""

          echo "Main Template:"
          echo "$TEMPLATE_FILE"

          echo ""

          echo "Template Bucket Stack:"
          echo "$TEMPLATE_BUCKET_STACK"

          echo ""

          echo "Template Bucket Template:"
          echo "$TEMPLATE_BUCKET_FILE"

          echo ""

          echo "Key Pair:"
          echo "$KEY_PAIR_NAME"

          echo ""

          # --------------------------------------------------
          # Validate Key Pair
          # --------------------------------------------------

          if [ -z "$KEY_PAIR_NAME" ]; then

            echo "ERROR: KEY_PAIR_NAME is empty."

            exit 1

          fi


          # --------------------------------------------------
          # Validate main template path
          # --------------------------------------------------

          if [ ! -f "$TEMPLATE_FILE" ]; then

            echo "ERROR: Main CloudFormation template does not exist."

            echo "$TEMPLATE_FILE"

            exit 1

          fi


          # --------------------------------------------------
          # Validate template bucket template path
          # --------------------------------------------------

          if [ ! -f "$TEMPLATE_BUCKET_FILE" ]; then

            echo "ERROR: Template bucket CloudFormation template does not exist."

            echo "$TEMPLATE_BUCKET_FILE"

            exit 1

          fi


          echo ""
          echo "All required deployment values are available."


      # ======================================================
      # Step 5 - Create or Update Template Bucket Stack
      # ======================================================
      #
      # This CloudFormation stack creates the S3 bucket that
      # stores the nested CloudFormation templates.
      #
      # Architecture:
      #
      # GitHub Actions
      #       |
      #       v
      # Template Bucket Stack
      #       |
      #       v
      # S3 Template Bucket
      #
      # ======================================================

      - name: Create or Update Template Bucket Stack

        shell: bash

        run: |

          echo "======================================"
          echo "Template Bucket CloudFormation Stack"
          echo "======================================"

          echo "Stack Name:"
          echo "$TEMPLATE_BUCKET_STACK"

          echo ""

          echo "Template:"
          echo "$TEMPLATE_BUCKET_FILE"

          echo ""


          # --------------------------------------------------
          # Validate template bucket template
          # --------------------------------------------------

          echo "Validating template bucket template..."

          aws cloudformation validate-template \
            --template-body "file://$TEMPLATE_BUCKET_FILE" \
            --region "$AWS_REGION" \
            --no-cli-pager


          echo ""

          echo "Template bucket template validation completed."


          # --------------------------------------------------
          # Check whether the template bucket stack exists
          # --------------------------------------------------

          if aws cloudformation describe-stacks \
            --stack-name "$TEMPLATE_BUCKET_STACK" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            > /dev/null 2>&1
          then

            echo ""
            echo "Template bucket stack already exists."


            # ------------------------------------------------
            # Get current stack status
            # ------------------------------------------------

            TEMPLATE_BUCKET_STATUS=$(aws cloudformation describe-stacks \
              --stack-name "$TEMPLATE_BUCKET_STACK" \
              --region "$AWS_REGION" \
              --query "Stacks[0].StackStatus" \
              --output text \
              --no-cli-pager)


            echo ""
            echo "Current Template Bucket Stack Status:"
            echo "$TEMPLATE_BUCKET_STATUS"


            # ------------------------------------------------
            # Do not update a stack that is currently busy.
            # ------------------------------------------------

            case "$TEMPLATE_BUCKET_STATUS" in

              CREATE_IN_PROGRESS|UPDATE_IN_PROGRESS|UPDATE_COMPLETE_CLEANUP_IN_PROGRESS|DELETE_IN_PROGRESS)

                echo ""
                echo "ERROR: Template bucket stack is currently busy."
                echo "Current status: $TEMPLATE_BUCKET_STATUS"

                exit 1

                ;;

            esac


            # ------------------------------------------------
            # Remove old update output
            # ------------------------------------------------

            rm -f /tmp/template-bucket-update.txt


            # ------------------------------------------------
            # Attempt CloudFormation update.
            #
            # 'set +e' allows us to inspect the AWS CLI error
            # and correctly handle "No updates are to be
            # performed."
            # ------------------------------------------------

            set +e

            aws cloudformation update-stack \
              --stack-name "$TEMPLATE_BUCKET_STACK" \
              --template-body "file://$TEMPLATE_BUCKET_FILE" \
              --region "$AWS_REGION" \
              --no-cli-pager \
              2>&1 | tee /tmp/template-bucket-update.txt

            UPDATE_EXIT_CODE=${PIPESTATUS[0]}

            set -e


            # ------------------------------------------------
            # Update started successfully
            # ------------------------------------------------

            if [ "$UPDATE_EXIT_CODE" -eq 0 ]; then

              echo ""
              echo "Template bucket stack update started."

              echo ""
              echo "Waiting for template bucket stack update..."

              aws cloudformation wait stack-update-complete \
                --stack-name "$TEMPLATE_BUCKET_STACK" \
                --region "$AWS_REGION"

              echo ""
              echo "Template bucket stack update completed."


            # ------------------------------------------------
            # No changes detected
            # ------------------------------------------------

            elif grep -qi "No updates are to be performed" \
              /tmp/template-bucket-update.txt
            then

              echo ""
              echo "No template bucket changes detected."

              echo "Existing template bucket will be used."


            # ------------------------------------------------
            # Real error
            # ------------------------------------------------

            else

              echo ""
              echo "ERROR: Template bucket stack update failed."

              echo ""
              echo "AWS CloudFormation Error:"

              cat /tmp/template-bucket-update.txt

              exit "$UPDATE_EXIT_CODE"

            fi


          else

            # ------------------------------------------------
            # Template bucket stack does not exist.
            # ------------------------------------------------

            echo ""
            echo "Template bucket stack does not exist."

            echo ""
            echo "Creating template bucket stack..."


            aws cloudformation create-stack \
              --stack-name "$TEMPLATE_BUCKET_STACK" \
              --template-body "file://$TEMPLATE_BUCKET_FILE" \
              --region "$AWS_REGION" \
              --no-cli-pager


            echo ""
            echo "Template bucket stack creation started."


            echo ""
            echo "Waiting for template bucket stack creation..."


            aws cloudformation wait stack-create-complete \
              --stack-name "$TEMPLATE_BUCKET_STACK" \
              --region "$AWS_REGION"


            echo ""
            echo "Template bucket stack creation completed."

          fi


          echo ""
          echo "======================================"
          echo "Template Bucket Stack Ready"
          echo "======================================"


      # ======================================================
      # Step 6 - Get Template S3 Bucket Name
      # ======================================================
      #
      # Retrieves the bucket name from the template bucket
      # CloudFormation stack output.
      #
      # The value is saved into GITHUB_ENV so later steps
      # can use:
      #
      # $TEMPLATE_BUCKET
      #
      # ======================================================

      - name: Get Template Bucket Name

        shell: bash

        run: |

          echo "======================================"
          echo "Getting Template S3 Bucket Name"
          echo "======================================"


          TEMPLATE_BUCKET=$(aws cloudformation describe-stacks \
            --stack-name "$TEMPLATE_BUCKET_STACK" \
            --region "$AWS_REGION" \
            --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" \
            --output text \
            --no-cli-pager)


          # --------------------------------------------------
          # Verify bucket name
          # --------------------------------------------------

          if [ -z "$TEMPLATE_BUCKET" ] || [ "$TEMPLATE_BUCKET" = "None" ]; then

            echo "ERROR: Could not retrieve S3 template bucket name."

            echo ""
            echo "Check the template bucket CloudFormation Outputs."

            exit 1

          fi


          # --------------------------------------------------
          # Save bucket name for later steps
          # --------------------------------------------------

          echo "TEMPLATE_BUCKET=$TEMPLATE_BUCKET" >> "$GITHUB_ENV"


          echo ""

          echo "Template S3 Bucket:"
          echo "$TEMPLATE_BUCKET"


      # ======================================================
      # Step 7 - Upload Nested CloudFormation Templates
      # ======================================================
      #
      # Uploads the nested CloudFormation templates to S3.
      #
      # The main template references these files using:
      #
      # https://${TemplateBucketName}.s3.amazonaws.com/
      # templates/<template>.yaml
      #
      # IMPORTANT:
      #
      # The template that creates the bucket itself is excluded.
      #
      # ======================================================

      - name: Upload Nested Templates to S3

        shell: bash

        run: |

          echo "======================================"
          echo "Uploading CloudFormation Templates"
          echo "======================================"

          echo "S3 Bucket:"
          echo "$TEMPLATE_BUCKET"

          echo ""


          # --------------------------------------------------
          # Upload templates.
          #
          # TemplateBucket-MainStack.yaml is excluded because
          # it creates the template bucket itself.
          #
          # lab01.yaml is uploaded as well because it is part
          # of the repository's CloudFormation templates.
          # --------------------------------------------------

          aws s3 sync \
            templates/ \
            "s3://$TEMPLATE_BUCKET/templates/" \
            --exclude "TemplateBucket-MainStack.yaml" \
            --region "$AWS_REGION"


          echo ""

          echo "CloudFormation templates uploaded successfully."


          echo ""
          echo "S3 Template Files:"


          aws s3 ls \
            "s3://$TEMPLATE_BUCKET/templates/" \
            --recursive \
            --region "$AWS_REGION"


      # ======================================================
      # Step 8 - Display Repository Information
      # ======================================================

      - name: Display Environment

        shell: bash

        run: |

          echo "======================================"
          echo "GitHub Runner Information"
          echo "======================================"

          echo "Current Directory:"
          pwd

          echo ""

          echo "Repository Files:"
          ls -la

          echo ""

          echo "Main CloudFormation Template:"
          echo "$TEMPLATE_FILE"

          echo ""

          echo "AWS Region:"
          echo "$AWS_REGION"

          echo ""

          echo "CloudFormation Stack:"
          echo "$STACK_NAME"

          echo ""

          echo "Template Bucket Stack:"
          echo "$TEMPLATE_BUCKET_STACK"

          echo ""

          echo "Template Bucket:"
          echo "$TEMPLATE_BUCKET"


      # ======================================================
      # Step 9 - Verify CloudFormation Templates Exist
      # ======================================================
      #
      # Checks that both local templates required by this
      # workflow are available.
      #
      # ======================================================

      - name: Check CloudFormation Templates

        shell: bash

        run: |

          echo "======================================"
          echo "Checking CloudFormation Templates"
          echo "======================================"


          # --------------------------------------------------
          # Check template bucket template
          # --------------------------------------------------

          if [ ! -f "$TEMPLATE_BUCKET_FILE" ]; then

            echo "ERROR: Template bucket template not found:"
            echo "$TEMPLATE_BUCKET_FILE"

            exit 1

          fi


          echo "Template bucket template found:"
          echo "$TEMPLATE_BUCKET_FILE"


          echo ""


          # --------------------------------------------------
          # Check main template
          # --------------------------------------------------

          if [ ! -f "$TEMPLATE_FILE" ]; then

            echo "ERROR: Main CloudFormation template not found:"
            echo "$TEMPLATE_FILE"

            exit 1

          fi


          echo "Main CloudFormation template found:"
          echo "$TEMPLATE_FILE"


      # ======================================================
      # Step 10 - Validate Main CloudFormation Template
      # ======================================================
      #
      # Validates the main CloudFormation template before
      # attempting deployment.
      #
      # The template now contains:
      #
      # - VPC
      # - EC2 nested stack
      # - S3 nested stack
      # - RDS nested stack
      # - AWS Secrets Manager-managed RDS password
      #
      # ======================================================

      - name: Validate CloudFormation Template

        shell: bash

        run: |

          echo "======================================"
          echo "Validating CloudFormation Template"
          echo "======================================"


          aws cloudformation validate-template \
            --template-body "file://$TEMPLATE_FILE" \
            --region "$AWS_REGION" \
            --no-cli-pager


          echo ""

          echo "CloudFormation template validation completed successfully."


      # ======================================================
      # Step 11 - Check Whether Main Stack Exists
      # ======================================================
      #
      # Stores:
      #
      # exists=true
      #
      # or:
      #
      # exists=false
      #
      # in GitHub Actions output.
      #
      # ======================================================

      - name: Check Stack Status

        id: stack

        shell: bash

        run: |

          echo "======================================"
          echo "Checking CloudFormation Stack"
          echo "======================================"


          if aws cloudformation describe-stacks \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            > /dev/null 2>&1
          then

            echo "CloudFormation stack already exists."

            echo "exists=true" >> "$GITHUB_OUTPUT"

          else

            echo "CloudFormation stack does not exist."

            echo "exists=false" >> "$GITHUB_OUTPUT"

          fi


      # ======================================================
      # Step 12 - Display Existing Stack Status
      # ======================================================

      - name: Display Existing Stack Status

        if: steps.stack.outputs.exists == 'true'

        shell: bash

        run: |

          echo "======================================"
          echo "Existing Stack Status"
          echo "======================================"


          STACK_STATUS=$(aws cloudformation describe-stacks \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION" \
            --query "Stacks[0].StackStatus" \
            --output text \
            --no-cli-pager)


          echo "Current Stack Status:"
          echo "$STACK_STATUS"


      # ======================================================
      # Step 13 - Debug Deployment Environment
      # ======================================================
      #
      # This step confirms the deployment configuration.
      #
      # IMPORTANT:
      #
      # There is NO DB_MASTER_PASSWORD here.
      #
      # The RDS password is managed by AWS Secrets Manager.
      #
      # ======================================================

      - name: Debug Deployment Environment

        shell: bash

        run: |

          echo "======================================"
          echo "DEPLOYMENT ENVIRONMENT"
          echo "======================================"

          echo "AWS_REGION=$AWS_REGION"

          echo "STACK_NAME=$STACK_NAME"

          echo "KEY_PAIR_NAME=$KEY_PAIR_NAME"

          echo "TEMPLATE_FILE=$TEMPLATE_FILE"

          echo "TEMPLATE_BUCKET=$TEMPLATE_BUCKET"

          echo ""

          if [ -z "$KEY_PAIR_NAME" ]; then

            echo "KEY_PAIR_NAME: EMPTY"

            exit 1

          else

            echo "KEY_PAIR_NAME: SET"

          fi

          echo ""

          echo "RDS Password Management:"
          echo "AWS Secrets Manager"

          echo ""

          echo "RDS password is NOT stored in GitHub Actions."

          echo ""

          echo "======================================"
          echo "END DEPLOYMENT ENVIRONMENT"
          echo "======================================"


      # ======================================================
      # Step 14 - Create New Main CloudFormation Stack
      # ======================================================
      #
      # Runs only when the main stack does not exist.
      #
      # Parameters passed to the main template:
      #
      # 1. TemplateBucketName
      # 2. KeyPairName
      #
      # DBMasterPassword is NOT passed.
      #
      # RDS creates/manages its password through Secrets Manager.
      #
      # ======================================================

      - name: Create CloudFormation Stack

        if: steps.stack.outputs.exists == 'false'

        shell: bash

        run: |

          echo "======================================"
          echo "Creating CloudFormation Stack"
          echo "======================================"

          echo "Stack Name       : $STACK_NAME"
          echo "Template         : $TEMPLATE_FILE"
          echo "Region           : $AWS_REGION"
          echo "Key Pair         : $KEY_PAIR_NAME"
          echo "Template Bucket  : $TEMPLATE_BUCKET"

          echo ""


          # --------------------------------------------------
          # Validate KeyPairName
          # --------------------------------------------------

          if [ -z "$KEY_PAIR_NAME" ]; then

            echo "ERROR: KEY_PAIR_NAME is empty."

            exit 1

          fi


          # --------------------------------------------------
          # Display deployment parameters.
          #
          # There is intentionally no database password.
          # --------------------------------------------------

          echo "CloudFormation Parameters:"
          echo "  TemplateBucketName = $TEMPLATE_BUCKET"
          echo "  KeyPairName        = $KEY_PAIR_NAME"
          echo "  RDS Password       = Managed by AWS Secrets Manager"

          echo ""


          # --------------------------------------------------
          # Create CloudFormation stack
          # --------------------------------------------------

          echo "Starting CloudFormation stack creation..."


          aws cloudformation create-stack \
            --stack-name "$STACK_NAME" \
            --template-body "file://$TEMPLATE_FILE" \
            --parameters \
              "ParameterKey=TemplateBucketName,ParameterValue=$TEMPLATE_BUCKET" \
              "ParameterKey=KeyPairName,ParameterValue=$KEY_PAIR_NAME" \
            --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
            --region "$AWS_REGION" \
            --no-cli-pager


          echo ""

          echo "Main CloudFormation stack creation started."


      # ======================================================
      # Step 15 - Wait for Stack Creation
      # ======================================================

      - name: Wait for Stack Creation

        if: steps.stack.outputs.exists == 'false'

        shell: bash

        run: |

          echo "======================================"
          echo "Waiting for Stack Creation"
          echo "======================================"


          aws cloudformation wait stack-create-complete \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION"


          echo ""

          echo "Stack creation completed successfully."


      # ======================================================
      # Step 16 - Update Existing Main CloudFormation Stack
      # ======================================================
      #
      # Runs when the main stack already exists.
      #
      # Only these parameters are supplied:
      #
      # - TemplateBucketName
      # - KeyPairName
      #
      # The RDS password is managed independently by RDS and
      # Secrets Manager.
      #
      # ======================================================

      - name: Update CloudFormation Stack

        if: steps.stack.outputs.exists == 'true'

        shell: bash

        run: |

          echo "======================================"
          echo "Updating CloudFormation Stack"
          echo "======================================"

          echo "Stack Name       : $STACK_NAME"
          echo "Template         : $TEMPLATE_FILE"
          echo "Region           : $AWS_REGION"
          echo "Key Pair         : $KEY_PAIR_NAME"
          echo "Template Bucket  : $TEMPLATE_BUCKET"

          echo ""


          # --------------------------------------------------
          # Get current stack status
          # --------------------------------------------------

          STACK_STATUS=$(aws cloudformation describe-stacks \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION" \
            --query "Stacks[0].StackStatus" \
            --output text \
            --no-cli-pager)


          echo "Current Stack Status:"
          echo "$STACK_STATUS"


          # --------------------------------------------------
          # Do not update a stack that is currently busy.
          # --------------------------------------------------

          case "$STACK_STATUS" in

            CREATE_IN_PROGRESS|UPDATE_IN_PROGRESS|UPDATE_COMPLETE_CLEANUP_IN_PROGRESS|DELETE_IN_PROGRESS)

              echo ""
              echo "ERROR: Main CloudFormation stack is currently busy."
              echo "Current status: $STACK_STATUS"

              exit 1

              ;;
          ROLLBACK_COMPLETE)

              echo ""
              echo "ERROR: Main CloudFormation stack is in ROLLBACK_COMPLETE."
              echo "The stack must be deleted before it can be recreated."

              exit 1

              ;;    

          esac


          # --------------------------------------------------
          # Remove old update output
          # --------------------------------------------------

          rm -f /tmp/main-stack-update.txt


          # --------------------------------------------------
          # Execute CloudFormation update.
          # --------------------------------------------------

          set +e


          aws cloudformation update-stack \
            --stack-name "$STACK_NAME" \
            --template-body "file://$TEMPLATE_FILE" \
            --parameters \
              "ParameterKey=TemplateBucketName,ParameterValue=$TEMPLATE_BUCKET,UsePreviousValue=false" \
              "ParameterKey=KeyPairName,ParameterValue=$KEY_PAIR_NAME,UsePreviousValue=false" \
            --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
            --region "$AWS_REGION" \
            --no-cli-pager \
            2>&1 | tee /tmp/main-stack-update.txt


          UPDATE_EXIT_CODE=${PIPESTATUS[0]}


          set -e


          # --------------------------------------------------
          # Successful update
          # --------------------------------------------------

          if [ "$UPDATE_EXIT_CODE" -eq 0 ]; then

            echo ""
            echo "CloudFormation stack update started."


          # --------------------------------------------------
          # No changes detected
          # --------------------------------------------------

          elif grep -qi "No updates are to be performed" \
            /tmp/main-stack-update.txt
          then

            echo ""
            echo "No main stack changes detected."

            echo "Existing CloudFormation infrastructure will be used."


          # --------------------------------------------------
          # Real error
          # --------------------------------------------------

          else

            echo ""
            echo "ERROR: Main CloudFormation stack update failed."

            echo ""
            echo "AWS CloudFormation Error:"

            cat /tmp/main-stack-update.txt

            exit "$UPDATE_EXIT_CODE"

          fi


      # ======================================================
      # Step 17 - Wait for Existing Stack Update
      # ======================================================

      - name: Wait for Stack Update

        if: steps.stack.outputs.exists == 'true'

        shell: bash

        run: |

          echo "======================================"
          echo "Checking Main Stack Update Status"
          echo "======================================"


          CURRENT_STATUS=$(aws cloudformation describe-stacks \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION" \
            --query "Stacks[0].StackStatus" \
            --output text \
            --no-cli-pager)


          echo "Current Stack Status:"
          echo "$CURRENT_STATUS"


          # --------------------------------------------------
          # Wait when an update is actually in progress.
          # --------------------------------------------------

          if [ "$CURRENT_STATUS" = "UPDATE_IN_PROGRESS" ]; then

            echo ""
            echo "Stack update is in progress."

            echo ""
            echo "Waiting for Stack Update..."


            aws cloudformation wait stack-update-complete \
              --stack-name "$STACK_NAME" \
              --region "$AWS_REGION"


            echo ""
            echo "Stack update completed successfully."


          elif [ "$CURRENT_STATUS" = "UPDATE_COMPLETE" ]; then

            echo ""
            echo "Stack is already in UPDATE_COMPLETE state."

            echo "No additional stack update wait is required."


          elif [ "$CURRENT_STATUS" = "CREATE_COMPLETE" ]; then

            echo ""
            echo "Stack is in CREATE_COMPLETE state."

            echo "No update was required."


          else

            echo ""
            echo "ERROR: Unexpected CloudFormation stack status:"
            echo "$CURRENT_STATUS"

            exit 1

          fi


      # ======================================================
      # Step 18 - Display Final Stack Information
      # ======================================================

      - name: Display Stack Information

        shell: bash

        run: |

          echo "======================================"
          echo "CloudFormation Stack Details"
          echo "======================================"


          aws cloudformation describe-stacks \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION" \
            --no-cli-pager


      # ======================================================
      # Step 19 - Display Stack Resources
      # ======================================================

      - name: List Stack Resources

        shell: bash

        run: |

          echo "======================================"
          echo "CloudFormation Stack Resources"
          echo "======================================"


          aws cloudformation list-stack-resources \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION" \
            --no-cli-pager


      # ======================================================
      # Step 20 - Display Stack Outputs
      # ======================================================
      #
      # Expected outputs include:
      #
      # - VPC
      # - Public subnet
      # - Private subnets
      # - Web security group
      # - EC2 instance
      # - EC2 public IP
      # - S3 bucket
      # - RDS database
      # - RDS endpoint
      # - RDS port
      # - RDS security group
      # - RDS Secrets Manager ARN
      #
      # IMPORTANT:
      #
      # The secret ARN is safe to display.
      #
      # The secret VALUE/password is never displayed.
      #
      # ======================================================

      - name: Display Stack Outputs

        shell: bash

        run: |

          echo "======================================"
          echo "CloudFormation Stack Outputs"
          echo "======================================"


          aws cloudformation describe-stacks \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION" \
            --query "Stacks[0].Outputs" \
            --output table \
            --no-cli-pager


      # ======================================================
      # Step 21 - Deployment Complete
      # ======================================================

      - name: Deployment Complete

        shell: bash

        run: |

          echo ""

          echo "======================================"
          echo "CloudFormation Deployment Completed"
          echo "======================================"

          echo ""

          echo "Stack Name      : $STACK_NAME"

          echo "Region          : $AWS_REGION"

          echo "Template        : $TEMPLATE_FILE"

          echo "Template Bucket : $TEMPLATE_BUCKET"

          echo ""

          echo "RDS Password Management:"
          echo "AWS Secrets Manager"

          echo ""

          echo "The RDS master password was NOT stored"
          echo "in GitHub Actions."

          echo ""

          echo "Deployment completed successfully."

          echo "======================================"

# ==========================================================
# DOCKER JOB
# ==========================================================
#
# This is a separate job from the CloudFormation deployment.
#
# Purpose:
#
# 1. Checkout the repository
# 2. Verify Docker
# 3. Verify Dockerfile
# 4. Verify docker-compose.yml
# 5. Build Docker image
# 6. Verify Docker image
# 7. Start Docker container
# 8. Verify container status
# 9. Wait for application startup
# 10. Test application using HTTP
# 11. Display container logs
# 12. Stop and remove Docker resources
#
# IMPORTANT:
#
# This stage currently does NOT deploy to:
#
# - Amazon ECR
# - Amazon ECS
# - ECS Fargate
# - Application Load Balancer
#
# This stage is only for learning and testing Docker.
#
# ==========================================================

  docker:

    # --------------------------------------------------------
    # Run Docker only after CloudFormation deployment succeeds.
    # --------------------------------------------------------
    needs: deploy

    # --------------------------------------------------------
    # GitHub-hosted Ubuntu runner
    # --------------------------------------------------------
    runs-on: ubuntu-latest

    name: Build and Test Docker

    # ========================================================
    # DOCKER STEPS
    # ========================================================

    steps:

      # ======================================================
      # Docker Step 1 - Checkout Repository
      # ======================================================
      #
      # Every GitHub Actions job gets its own fresh runner.
      #
      # Therefore the Docker job must checkout the repository
      # independently.
      #
      # ======================================================

      - name: Checkout Repository
        uses: actions/checkout@v4


      # ======================================================
      # Docker Step 2 - Verify Docker
      # ======================================================
      #
      # GitHub's Ubuntu runner already contains Docker.
      #
      # We verify:
      #
      # - Docker
      # - Docker Compose
      #
      # ======================================================

      - name: Verify Docker
        shell: bash
        run: |

          echo "======================================"
          echo "Docker Version"
          echo "======================================"

          docker --version

          echo ""

          echo "======================================"
          echo "Docker Compose Version"
          echo "======================================"

          docker compose version


      # ======================================================
      # Docker Step 3 - Check Docker Files
      # ======================================================
      #
      # Verify that the files required by the Docker build
      # actually exist.
      #
      # Expected:
      #
      # docker/Dockerfile
      # docker-compose.yml
      #
      # ======================================================

      - name: Check Docker Files
        shell: bash
        run: |

          echo "======================================"
          echo "Checking Docker Files"
          echo "======================================"

          echo ""

          # --------------------------------------------------
          # Check Dockerfile
          # --------------------------------------------------

          if [ ! -f "docker/Dockerfile" ]; then

            echo "ERROR: Dockerfile was not found."

            echo ""
            echo "Expected:"
            echo "docker/Dockerfile"

            exit 1

          fi

          echo "Dockerfile found:"
          echo "docker/Dockerfile"

          echo ""

          # --------------------------------------------------
          # Check docker-compose.yml
          # --------------------------------------------------

          if [ ! -f "docker-compose.yml" ]; then

            echo "ERROR: docker-compose.yml was not found."

            echo ""
            echo "Expected:"
            echo "docker-compose.yml"

            exit 1

          fi

          echo "docker-compose.yml found."

          echo ""

          echo "Docker files are ready."


      # ======================================================
      # Docker Step 4 - Validate Docker Compose
      # ======================================================
      #
      # docker compose config checks the Compose YAML before
      # attempting to start the container.
      #
      # This is useful because it catches:
      #
      # - YAML errors
      # - invalid Compose syntax
      # - incorrect configuration
      #
      # ======================================================

      - name: Validate Docker Compose
        shell: bash
        run: |

          echo "======================================"
          echo "Validating Docker Compose"
          echo "======================================"

          docker compose config

          echo ""

          echo "Docker Compose configuration is valid."


      # ======================================================
      # Docker Step 5 - Build Docker Image
      # ======================================================
      #
      # docker compose build reads:
      #
      # docker-compose.yml
      #
      # and uses the Dockerfile configured there.
      #
      # ======================================================

      - name: Build Docker Image
        shell: bash
        run: |

          echo "======================================"
          echo "Building Docker Image"
          echo "======================================"

          docker compose build

          echo ""

          echo "Docker image build completed."


      # ======================================================
      # Docker Step 6 - Display Docker Images
      # ======================================================
      #
      # Display all images created by the build.
      #
      # ======================================================

      - name: Verify Docker Image
        shell: bash
        run: |

          echo "======================================"
          echo "Docker Images"
          echo "======================================"

          docker images

          echo ""

          echo "Docker image verification completed."


      # ======================================================
      # Docker Step 7 - Start Docker Container
      # ======================================================
      #
      # Start the application in detached mode.
      #
      # -d
      #
      # means detached mode.
      #
      # ======================================================

      - name: Start Docker Container
        shell: bash
        run: |

          echo "======================================"
          echo "Starting Docker Container"
          echo "======================================"

          docker compose up -d

          echo ""

          echo "======================================"
          echo "Docker Compose Status"
          echo "======================================"

          docker compose ps -a

          echo ""

          echo "======================================"
          echo "Docker Container Status"
          echo "======================================"

          docker ps -a

          echo ""

          echo "Docker container startup command completed."


      # ======================================================
      # Docker Step 8 - Check Container Status
      # ======================================================
      #
      # Instead of assuming a hard-coded container name,
      # obtain the actual container ID from Docker Compose.
      #
      # This makes the workflow more reliable.
      #
      # ======================================================

      - name: Check Docker Container
        shell: bash
        run: |

          echo "======================================"
          echo "Checking Docker Container"
          echo "======================================"

          echo ""

          docker compose ps -a

          echo ""

          # --------------------------------------------------
          # Get the container ID created by Compose.
          # --------------------------------------------------

          CONTAINER_ID=$(docker compose ps -q)

          if [ -z "$CONTAINER_ID" ]; then

            echo "ERROR: Docker Compose did not create a container."

            echo ""

            echo "Docker Compose status:"
            docker compose ps -a

            echo ""

            echo "Docker containers:"
            docker ps -a

            exit 1

          fi

          echo "Container ID:"
          echo "$CONTAINER_ID"

          echo ""

          # --------------------------------------------------
          # Get container status.
          # --------------------------------------------------

          CONTAINER_STATUS=$(docker inspect \
            --format='{{.State.Status}}' \
            "$CONTAINER_ID")

          echo "Container status:"
          echo "$CONTAINER_STATUS"

          echo ""

          # --------------------------------------------------
          # Container must be running.
          # --------------------------------------------------

          if [ "$CONTAINER_STATUS" = "running" ]; then

            echo "Docker container is running."

          else

            echo "ERROR: Docker container is not running."

            echo ""

            echo "======================================"
            echo "Container Logs"
            echo "======================================"

            docker logs "$CONTAINER_ID" || true

            echo ""

            echo "======================================"
            echo "Container Inspection"
            echo "======================================"

            docker inspect "$CONTAINER_ID"

            exit 1

          fi


      # ======================================================
      # Docker Step 9 - Wait for Application
      # ======================================================
      #
      # Give Nginx/PHP-FPM/application processes time to start.
      #
      # ======================================================

      - name: Wait for Application
        shell: bash
        run: |

          echo "======================================"
          echo "Waiting for Application"
          echo "======================================"

          sleep 5

          echo ""

          echo "Application startup wait completed."


      # ======================================================
      # Docker Step 10 - Test Application
      # ======================================================
      #
      # Your docker-compose.yml should expose:
      #
      # Host port:      8080
      # Container port: 80
      #
      # Therefore we test:
      #
      # http://localhost:8080
      #
      # ======================================================

      - name: Test Docker Container
        shell: bash
        run: |

          echo "======================================"
          echo "Testing Docker Application"
          echo "======================================"

          echo ""

          echo "Testing:"
          echo "http://localhost:8080"

          echo ""

          # --------------------------------------------------
          # HTTP test
          # --------------------------------------------------

          curl \
            --fail \
            --silent \
            --show-error \
            --retry 5 \
            --retry-delay 2 \
            http://localhost:8080

          echo ""

          echo "======================================"
          echo "Docker Container Test PASSED"
          echo "======================================"


      # ======================================================
      # Docker Step 11 - Display Container Logs
      # ======================================================
      #
      # Always display logs.
      #
      # This is extremely useful if the HTTP test fails.
      #
      # ======================================================

      - name: Display Container Logs
        if: always()
        shell: bash
        run: |

          echo "======================================"
          echo "Docker Container Logs"
          echo "======================================"

          docker compose logs --no-color || true


      # ======================================================
      # Docker Step 12 - Display Final Docker Status
      # ======================================================
      #
      # Always show the final state before cleanup.
      #
      # ======================================================

      - name: Display Final Docker Status
        if: always()
        shell: bash
        run: |

          echo "======================================"
          echo "Final Docker Status"
          echo "======================================"

          docker compose ps -a || true

          echo ""

          docker ps -a || true

          echo ""

          docker images || true


      # ======================================================
      # Docker Step 13 - Stop and Remove Docker Container
      # ======================================================
      #
      # Always clean up the Docker environment.
      #
      # --remove-orphans
      #
      # also removes containers that are no longer defined
      # in the Compose file.
      #
      # ======================================================

      - name: Stop Docker Container
        if: always()
        shell: bash
        run: |

          echo "======================================"
          echo "Stopping Docker Container"
          echo "======================================"

          docker compose down --remove-orphans || true

          echo ""

          echo "Docker container and Compose network cleaned up."


      # ======================================================
      # Docker Step 14 - Docker Job Complete
      # ======================================================

      - name: Docker Job Complete
        shell: bash
        run: |

          echo ""
          echo "======================================"
          echo "Docker Build and Test Completed"
          echo "======================================"

          echo ""

          echo "Docker build:"
          echo "SUCCESS"

          echo ""

          echo "Docker container:"
          echo "STARTED"

          echo ""

          echo "Docker HTTP test:"
          echo "PASSED"

          echo ""

          echo "Docker job completed successfully."

          echo "======================================"  

  # ============================================================
  # FINAL JOB - TRIGGER ECS + ECR DEPLOYMENT
  # ============================================================
  #
  # This is the FINAL stage of the Charlie Cafe CI/CD pipeline.
  #
  # The workflow now becomes:
  #
  # CloudFormation
  #       |
  #       v
  # AWS Infrastructure
  #       |
  #       v
  # Docker
  #       |
  #       v
  # Docker Image
  #       |
  #       v
  # ECR
  #       |
  #       v
  # ECS Deployment
  #
  # IMPORTANT:
  #
  # This job does NOT build the Docker image itself.
  #
  # The Docker job has already completed that work.
  #
  # This job simply calls:
  #
  # .github/workflows/ecs-deploy.yml
  #
  # ============================================================

  ecs-deploy:

    name: Trigger ECS Deployment


    # ==========================================================
    # IMPORTANT
    #
    # ECS deployment will NOT start until the Docker job
    # successfully completes.
    #
    # Replace "docker" below with the EXACT job ID of your
    # existing Docker job.
    #
    # Example:
    #
    # jobs:
    #
    #   cloudformation:
    #
    #   docker:
    #
    #   ecs-deploy:
    #
    # ==========================================================

    needs:
      - docker


    # ==========================================================
    # CALL THE SEPARATE ECS WORKFLOW
    # ==========================================================
    #
    # This calls:
    #
    # .github/workflows/ecs-deploy.yml
    #
    # Because ecs-deploy.yml contains:
    #
    # on:
    #   workflow_call:
    #
    # GitHub allows this workflow to call it.
    #
    # ==========================================================

    uses: ./.github/workflows/ecs-deploy.yml


    # ==========================================================
    # IMPORTANT SECURITY NOTE
    # ==========================================================
    #
    # The called workflow needs access to your GitHub Secrets:
    #
    # AWS_ACCESS_KEY_ID
    # AWS_SECRET_ACCESS_KEY
    # AWS_REGION
    #
    # secrets: inherit
    #
    # passes the caller workflow's secrets to the reusable
    # workflow.
    #
    # ==========================================================

    secrets: inherit
```

---
## 2. ecs-deploy.yml

```
# ============================================================
# Charlie Cafe - ECS Deployment Workflow
# ============================================================
#
# File:
#   .github/workflows/ecs-deploy.yml
#
# PURPOSE
# ------------------------------------------------------------
#
# This reusable workflow performs the COMPLETE Charlie Cafe
# ECS deployment process.
#
# Deployment flow:
#
#   1.  Checkout repository
#   2.  Configure AWS credentials
#   3.  Verify AWS identity
#   4.  Verify required GitHub secrets
#   5.  Get network outputs from main CloudFormation stack
#   6.  Verify ECS CloudFormation template
#   7.  Validate ECS CloudFormation template
#   8.  Verify VPC
#   9.  Verify ECS subnets
#   10. Verify private route table
#   11. Create / update ECS + ECR CloudFormation stack
#   12. Verify ECS CloudFormation stack
#   13. Display CloudFormation outputs
#   14. Verify ECR repository
#   15. Login to Amazon ECR
#   16. Get ECR repository URI
#   17. Verify Docker build files
#   18. Build Docker image
#   19. Push Docker image to ECR
#   20. Verify ECR latest image
#   21. Verify ECS cluster
#   22. Verify ECS service
#   23. Start ECS service
#   24. Force new ECS deployment
#   25. Wait for ECS service stabilization
#   26. Display final ECS service status
#   27. Display running ECS tasks
#   28. Get ALB information
#   29. Verify ALB target health
#   30. Test application URL
#   31. Verify CloudWatch log group
#   32. Display final deployment summary
#
# ============================================================


name: Charlie Cafe - ECS Deployment


# ============================================================
# WORKFLOW TRIGGERS
# ============================================================

on:

  # ----------------------------------------------------------
  # Reusable workflow trigger
  # ----------------------------------------------------------
  #
  # IMPORTANT:
  #
  # "secrets: inherit" belongs in the CALLER workflow.
  #
  # Example:
  #
  # jobs:
  #   ecs-deploy:
  #     uses: ./.github/workflows/ecs-deploy.yml
  #     secrets: inherit
  #
  # DO NOT put:
  #
  # workflow_call:
  #   secrets: inherit
  #
  # inside this workflow.
  # ----------------------------------------------------------

  workflow_call:

  # ----------------------------------------------------------
  # Manual execution
  # ----------------------------------------------------------
  #
  # GitHub:
  #
  # Actions
  #   ->
  # Charlie Cafe - ECS Deployment
  #   ->
  # Run workflow
  #
  # ----------------------------------------------------------

  workflow_dispatch:


# ============================================================
# GLOBAL ENVIRONMENT VARIABLES
# ============================================================

env:

  # ----------------------------------------------------------
  # AWS REGION
  # ----------------------------------------------------------
  AWS_REGION: ${{ secrets.AWS_REGION }}

  # ----------------------------------------------------------
  # MAIN NETWORK CLOUDFORMATION STACK
  # ----------------------------------------------------------
  #
  # This stack creates the VPC, subnets, route tables, etc.
  #
  # The ECS workflow reads the network outputs from this stack.
  #
  # ----------------------------------------------------------
  MAIN_STACK_NAME: Lab01-CloudFormation

  # ----------------------------------------------------------
  # ECS CLOUDFORMATION STACK
  # ----------------------------------------------------------
  ECS_STACK_NAME: CharlieCafe-ECS-Stack

  # ----------------------------------------------------------
  # ECS CLOUDFORMATION TEMPLATE
  # ----------------------------------------------------------
  ECS_TEMPLATE_FILE: templates/aws-ecs-ecr.yaml

  # ----------------------------------------------------------
  # APPLICATION NAME
  # ----------------------------------------------------------
  APPLICATION_NAME: CharlieCafe

  # ----------------------------------------------------------
  # ECR REPOSITORY
  # ----------------------------------------------------------
  ECR_REPOSITORY: charlie-cafe

  # ----------------------------------------------------------
  # ECS CLUSTER
  # ----------------------------------------------------------
  ECS_CLUSTER: CharlieCafe-Cluster

  # ----------------------------------------------------------
  # ECS SERVICE
  # ----------------------------------------------------------
  ECS_SERVICE: CharlieCafe-Service

  # ----------------------------------------------------------
  # CONTAINER PORT
  # ----------------------------------------------------------
  CONTAINER_PORT: 80

  # ----------------------------------------------------------
  # ECS TASK CPU
  # ----------------------------------------------------------
  TASK_CPU: 256

  # ----------------------------------------------------------
  # ECS TASK MEMORY
  # ----------------------------------------------------------
  TASK_MEMORY: 512

  # ----------------------------------------------------------
  # FINAL ECS DESIRED COUNT
  # ----------------------------------------------------------
  #
  # CloudFormation initially creates the ECS service with:
  #
  #   DesiredCount = 0
  #
  # Later the workflow changes the service to:
  #
  #   DesiredCount = 1
  #
  # ----------------------------------------------------------
  ECS_DESIRED_COUNT: 1

  # ----------------------------------------------------------
  # DOCKER IMAGE TAG
  # ----------------------------------------------------------
  IMAGE_TAG: latest


# ============================================================
# JOBS
# ============================================================

jobs:

  # ==========================================================
  # ECS DEPLOYMENT JOB
  # ==========================================================

  deploy:

    name: Create ECS Infrastructure and Deploy Application

    runs-on: ubuntu-latest

    # --------------------------------------------------------
    # Maximum runtime for the complete deployment.
    # --------------------------------------------------------
    timeout-minutes: 30

    # ========================================================
    # STEPS
    # ========================================================

    steps:

      # ======================================================
      # STEP 1
      # CHECKOUT REPOSITORY
      # ======================================================

      - name: Checkout repository
        uses: actions/checkout@v4


      # ======================================================
      # STEP 2
      # CONFIGURE AWS CREDENTIALS
      # ======================================================
      #
      # GitHub Actions uses the AWS credentials stored in
      # GitHub repository secrets.
      #
      # ======================================================

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}


      # ======================================================
      # STEP 3
      # VERIFY AWS IDENTITY
      # ======================================================

      - name: Verify AWS identity
        shell: bash
        run: |

          echo "=================================================="
          echo "AWS IDENTITY"
          echo "=================================================="

          aws sts get-caller-identity

          echo ""
          echo "AWS Region:"
          echo "$AWS_REGION"

          echo ""
          echo "AWS CLI:"
          aws --version


      # ======================================================
      # STEP 4
      # VERIFY REQUIRED GITHUB SECRETS
      # ======================================================
      #
      # Secret values are NEVER printed.
      #
      # We only verify that required secrets exist.
      #
      # ======================================================

      - name: Verify required GitHub secrets
        shell: bash
        run: |

          echo "=================================================="
          echo "VERIFYING REQUIRED GITHUB SECRETS"
          echo "=================================================="

          if [ -z "${{ secrets.AWS_ACCESS_KEY_ID }}" ]; then
            echo "ERROR: AWS_ACCESS_KEY_ID is missing."
            exit 1
          fi

          if [ -z "${{ secrets.AWS_SECRET_ACCESS_KEY }}" ]; then
            echo "ERROR: AWS_SECRET_ACCESS_KEY is missing."
            exit 1
          fi

          if [ -z "${{ secrets.AWS_REGION }}" ]; then
            echo "ERROR: AWS_REGION is missing."
            exit 1
          fi

          echo ""
          echo "All required GitHub secrets are available."


      # ======================================================
      # STEP 5
      # GET NETWORK OUTPUTS FROM MAIN CLOUDFORMATION STACK
      # ======================================================
      #
      # The main CloudFormation stack creates the networking.
      #
      # This workflow does NOT create another VPC.
      #
      # It reads:
      #
      #   VPC
      #   Public Subnet 1
      #   Public Subnet 2
      #   Private Subnet 1
      #   Private Subnet 2
      #   Private Route Table
      #
      # from the main stack outputs.
      #
      # ======================================================

      - name: Get network outputs from main CloudFormation stack
        shell: bash
        run: |

          echo "=================================================="
          echo "GETTING NETWORK OUTPUTS"
          echo "=================================================="

          echo ""
          echo "Main CloudFormation stack:"
          echo "$MAIN_STACK_NAME"

          # --------------------------------------------------
          # Get main stack status
          # --------------------------------------------------

          STACK_STATUS=$(aws cloudformation describe-stacks \
            --region "$AWS_REGION" \
            --stack-name "$MAIN_STACK_NAME" \
            --query 'Stacks[0].StackStatus' \
            --output text)

          echo ""
          echo "Main stack status:"
          echo "$STACK_STATUS"

          # --------------------------------------------------
          # Verify main stack is ready
          # --------------------------------------------------

          case "$STACK_STATUS" in

            CREATE_COMPLETE|UPDATE_COMPLETE)

              echo ""
              echo "Main stack is ready."

              ;;

            *)

              echo ""
              echo "ERROR: Main CloudFormation stack is not ready."
              echo "Expected CREATE_COMPLETE or UPDATE_COMPLETE."

              exit 1

              ;;

          esac

          # --------------------------------------------------
          # Get VPC ID
          # --------------------------------------------------

          VPC_ID=$(aws cloudformation describe-stacks \
            --region "$AWS_REGION" \
            --stack-name "$MAIN_STACK_NAME" \
            --query "Stacks[0].Outputs[?OutputKey=='VPCId'].OutputValue" \
            --output text)

          # --------------------------------------------------
          # Get Public Subnet 1
          # --------------------------------------------------

          PUBLIC_SUBNET_1=$(aws cloudformation describe-stacks \
            --region "$AWS_REGION" \
            --stack-name "$MAIN_STACK_NAME" \
            --query "Stacks[0].Outputs[?OutputKey=='PublicSubnet1Id'].OutputValue" \
            --output text)

          # --------------------------------------------------
          # Get Public Subnet 2
          # --------------------------------------------------

          PUBLIC_SUBNET_2=$(aws cloudformation describe-stacks \
            --region "$AWS_REGION" \
            --stack-name "$MAIN_STACK_NAME" \
            --query "Stacks[0].Outputs[?OutputKey=='PublicSubnet2Id'].OutputValue" \
            --output text)

          # --------------------------------------------------
          # Get Private Subnet 1
          # --------------------------------------------------

          PRIVATE_SUBNET_1=$(aws cloudformation describe-stacks \
            --region "$AWS_REGION" \
            --stack-name "$MAIN_STACK_NAME" \
            --query "Stacks[0].Outputs[?OutputKey=='PrivateSubnet1Id'].OutputValue" \
            --output text)

          # --------------------------------------------------
          # Get Private Subnet 2
          # --------------------------------------------------

          PRIVATE_SUBNET_2=$(aws cloudformation describe-stacks \
            --region "$AWS_REGION" \
            --stack-name "$MAIN_STACK_NAME" \
            --query "Stacks[0].Outputs[?OutputKey=='PrivateSubnet2Id'].OutputValue" \
            --output text)

          # --------------------------------------------------
          # Get Private Route Table
          # --------------------------------------------------

          PRIVATE_ROUTE_TABLE_ID=$(aws cloudformation describe-stacks \
            --region "$AWS_REGION" \
            --stack-name "$MAIN_STACK_NAME" \
            --query "Stacks[0].Outputs[?OutputKey=='PrivateRouteTableId'].OutputValue" \
            --output text)

          # --------------------------------------------------
          # Display retrieved values
          # --------------------------------------------------

          echo ""
          echo "VPC:"
          echo "$VPC_ID"

          echo ""
          echo "Public Subnet 1:"
          echo "$PUBLIC_SUBNET_1"

          echo ""
          echo "Public Subnet 2:"
          echo "$PUBLIC_SUBNET_2"

          echo ""
          echo "Private Subnet 1:"
          echo "$PRIVATE_SUBNET_1"

          echo ""
          echo "Private Subnet 2:"
          echo "$PRIVATE_SUBNET_2"

          echo ""
          echo "Private Route Table:"
          echo "$PRIVATE_ROUTE_TABLE_ID"

          # --------------------------------------------------
          # Verify that every required network output exists.
          # --------------------------------------------------

          if [ -z "$VPC_ID" ] || \
             [ "$VPC_ID" = "None" ] || \
             [ -z "$PUBLIC_SUBNET_1" ] || \
             [ "$PUBLIC_SUBNET_1" = "None" ] || \
             [ -z "$PUBLIC_SUBNET_2" ] || \
             [ "$PUBLIC_SUBNET_2" = "None" ] || \
             [ -z "$PRIVATE_SUBNET_1" ] || \
             [ "$PRIVATE_SUBNET_1" = "None" ] || \
             [ -z "$PRIVATE_SUBNET_2" ] || \
             [ "$PRIVATE_SUBNET_2" = "None" ] || \
             [ -z "$PRIVATE_ROUTE_TABLE_ID" ] || \
             [ "$PRIVATE_ROUTE_TABLE_ID" = "None" ]; then

            echo ""
            echo "ERROR: One or more CloudFormation network outputs are missing."

            exit 1

          fi

          # --------------------------------------------------
          # Export network values for later workflow steps.
          #
          # GITHUB_ENV makes these variables available to all
          # subsequent steps in this job.
          # --------------------------------------------------

          {
            echo "VPC_ID=$VPC_ID"
            echo "PUBLIC_SUBNET_1=$PUBLIC_SUBNET_1"
            echo "PUBLIC_SUBNET_2=$PUBLIC_SUBNET_2"
            echo "PRIVATE_SUBNET_1=$PRIVATE_SUBNET_1"
            echo "PRIVATE_SUBNET_2=$PRIVATE_SUBNET_2"
            echo "PRIVATE_ROUTE_TABLE_ID=$PRIVATE_ROUTE_TABLE_ID"
          } >> "$GITHUB_ENV"

          echo ""
          echo "=================================================="
          echo "NETWORK OUTPUTS RETRIEVED SUCCESSFULLY"
          echo "=================================================="


      # ======================================================
      # STEP 6
      # VERIFY CLOUDFORMATION TEMPLATE
      # ======================================================

      - name: Verify CloudFormation template
        shell: bash
        run: |

          echo "=================================================="
          echo "VERIFYING CLOUDFORMATION TEMPLATE"
          echo "=================================================="

          if [ ! -f "$ECS_TEMPLATE_FILE" ]; then

            echo ""
            echo "ERROR: CloudFormation template was not found."
            echo ""
            echo "Expected:"
            echo "$ECS_TEMPLATE_FILE"

            echo ""
            echo "Available template files:"

            find templates \
              -maxdepth 2 \
              -type f \
              -print 2>/dev/null || true

            exit 1

          fi

          echo ""
          echo "Template found:"
          echo "$ECS_TEMPLATE_FILE"


      # ======================================================
      # STEP 7
      # VALIDATE ECS CLOUDFORMATION TEMPLATE
      # ======================================================

      - name: Validate ECS CloudFormation template
        shell: bash
        run: |

          echo "=================================================="
          echo "VALIDATING CLOUDFORMATION TEMPLATE"
          echo "=================================================="

          aws cloudformation validate-template \
            --region "$AWS_REGION" \
            --template-body "file://$ECS_TEMPLATE_FILE"

          echo ""
          echo "CloudFormation template validation SUCCESS."


      # ======================================================
      # STEP 8
      # VERIFY VPC
      # ======================================================

      - name: Verify VPC
        shell: bash
        run: |

          echo "=================================================="
          echo "VERIFYING VPC"
          echo "=================================================="

          aws ec2 describe-vpcs \
            --region "$AWS_REGION" \
            --vpc-ids "$VPC_ID" \
            --query 'Vpcs[0].[VpcId,State,CidrBlock]' \
            --output table

          echo ""
          echo "VPC verification SUCCESS."


      # ======================================================
      # STEP 9
      # VERIFY ECS SUBNETS
      # ======================================================

      - name: Verify ECS subnets
        shell: bash
        run: |

          echo "=================================================="
          echo "VERIFYING ECS SUBNETS"
          echo "=================================================="

          aws ec2 describe-subnets \
            --region "$AWS_REGION" \
            --subnet-ids \
              "$PUBLIC_SUBNET_1" \
              "$PUBLIC_SUBNET_2" \
              "$PRIVATE_SUBNET_1" \
              "$PRIVATE_SUBNET_2" \
            --query 'Subnets[].[SubnetId,VpcId,AvailabilityZone,CidrBlock,MapPublicIpOnLaunch]' \
            --output table

          echo ""
          echo "Subnet verification SUCCESS."


      # ======================================================
      # STEP 10
      # VERIFY PRIVATE ROUTE TABLE
      # ======================================================

      - name: Verify private route table
        shell: bash
        run: |

          echo "=================================================="
          echo "VERIFYING PRIVATE ROUTE TABLE"
          echo "=================================================="

          aws ec2 describe-route-tables \
            --region "$AWS_REGION" \
            --route-table-ids "$PRIVATE_ROUTE_TABLE_ID" \
            --query 'RouteTables[0].[RouteTableId,VpcId]' \
            --output table

          echo ""
          echo "Private route table verification SUCCESS."


      # ======================================================
      # STEP 11
      # CREATE / UPDATE ECS + ECR CLOUDFORMATION STACK
      # ======================================================
      #
      # DesiredCount is intentionally set to 0.
      #
      # After infrastructure creation:
      #
      #   Step 23 -> desired count = 1
      #
      #   Step 24 -> force new deployment
      #
      # ======================================================

      - name: Create or update ECS CloudFormation stack
        shell: bash
        run: |

          echo "=================================================="
          echo "CREATING / UPDATING ECS CLOUDFORMATION STACK"
          echo "=================================================="

          echo ""
          echo "AWS Region:"
          echo "$AWS_REGION"

          echo ""
          echo "ECS Stack:"
          echo "$ECS_STACK_NAME"

          echo ""
          echo "VPC:"
          echo "$VPC_ID"

          echo ""
          echo "Starting CloudFormation deployment..."

          aws cloudformation deploy \
            --region "$AWS_REGION" \
            --stack-name "$ECS_STACK_NAME" \
            --template-file "$ECS_TEMPLATE_FILE" \
            --capabilities CAPABILITY_NAMED_IAM \
            --parameter-overrides \
              VpcId="$VPC_ID" \
              PublicSubnet1="$PUBLIC_SUBNET_1" \
              PublicSubnet2="$PUBLIC_SUBNET_2" \
              PrivateSubnet1="$PRIVATE_SUBNET_1" \
              PrivateSubnet2="$PRIVATE_SUBNET_2" \
              PrivateRouteTableId="$PRIVATE_ROUTE_TABLE_ID" \
              ApplicationName="$APPLICATION_NAME" \
              ContainerPort="$CONTAINER_PORT" \
              TaskCpu="$TASK_CPU" \
              TaskMemory="$TASK_MEMORY" \
              DesiredCount="0"

          echo ""
          echo "=================================================="
          echo "ECS CLOUDFORMATION DEPLOYMENT SUCCESS"
          echo "=================================================="


      # ======================================================
      # STEP 12
      # VERIFY ECS CLOUDFORMATION STACK
      # ======================================================

      - name: Verify ECS CloudFormation stack
        shell: bash
        run: |

          echo "=================================================="
          echo "VERIFYING ECS CLOUDFORMATION STACK"
          echo "=================================================="

          STACK_STATUS=$(aws cloudformation describe-stacks \
            --region "$AWS_REGION" \
            --stack-name "$ECS_STACK_NAME" \
            --query 'Stacks[0].StackStatus' \
            --output text)

          echo ""
          echo "Stack:"
          echo "$ECS_STACK_NAME"

          echo ""
          echo "Status:"
          echo "$STACK_STATUS"

          case "$STACK_STATUS" in

            CREATE_COMPLETE)

              echo ""
              echo "ECS stack CREATED successfully."

              ;;

            UPDATE_COMPLETE)

              echo ""
              echo "ECS stack UPDATED successfully."

              ;;

            *)

              echo ""
              echo "ERROR: Unexpected CloudFormation status."
              echo "$STACK_STATUS"

              echo ""
              echo "CloudFormation events:"

              aws cloudformation describe-stack-events \
                --region "$AWS_REGION" \
                --stack-name "$ECS_STACK_NAME" \
                --query 'StackEvents[0:20].[Timestamp,LogicalResourceId,ResourceStatus,ResourceStatusReason]' \
                --output table

              exit 1

              ;;

          esac


      # ======================================================
      # STEP 13
      # DISPLAY CLOUDFORMATION OUTPUTS
      # ======================================================

      - name: Display CloudFormation outputs
        shell: bash
        run: |

          echo "=================================================="
          echo "CLOUDFORMATION OUTPUTS"
          echo "=================================================="

          aws cloudformation describe-stacks \
            --region "$AWS_REGION" \
            --stack-name "$ECS_STACK_NAME" \
            --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
            --output table


      # ======================================================
      # STEP 14
      # VERIFY ECR REPOSITORY
      # ======================================================

      - name: Verify ECR repository
        shell: bash
        run: |

          echo "=================================================="
          echo "VERIFYING ECR REPOSITORY"
          echo "=================================================="

          aws ecr describe-repositories \
            --region "$AWS_REGION" \
            --repository-names "$ECR_REPOSITORY" \
            --query 'repositories[0].[repositoryName,repositoryUri,imageTagMutability]' \
            --output table

          echo ""
          echo "ECR repository verification SUCCESS."


      # ======================================================
      # STEP 15
      # LOGIN TO AMAZON ECR
      # ======================================================

      - name: Login to Amazon ECR
        uses: aws-actions/amazon-ecr-login@v2


      # ======================================================
      # STEP 16
      # GET ECR REPOSITORY URI
      # ======================================================

      - name: Get ECR repository URI
        id: ecr
        shell: bash
        run: |

          echo "=================================================="
          echo "GETTING ECR REPOSITORY URI"
          echo "=================================================="

          ECR_URI=$(aws ecr describe-repositories \
            --region "$AWS_REGION" \
            --repository-names "$ECR_REPOSITORY" \
            --query 'repositories[0].repositoryUri' \
            --output text)

          if [ -z "$ECR_URI" ] || [ "$ECR_URI" = "None" ]; then

            echo ""
            echo "ERROR: ECR repository URI was not found."

            exit 1

          fi

          echo ""
          echo "ECR URI:"
          echo "$ECR_URI"

          # --------------------------------------------------
          # Export ECR URI for subsequent steps.
          # --------------------------------------------------

          echo "ECR_URI=$ECR_URI" >> "$GITHUB_ENV"

          # --------------------------------------------------
          # Also create a step output.
          # --------------------------------------------------

          echo "repository_uri=$ECR_URI" >> "$GITHUB_OUTPUT"


      # ======================================================
      # STEP 17
      # VERIFY DOCKER BUILD FILES
      # ======================================================
      #
      # Expected project structure:
      #
      #   docker/
      #     Dockerfile
      #
      #   application/
      #     application files
      #
      # The Dockerfile is expected to copy:
      #
      #   application/
      #
      # into the container.
      #
      # ======================================================

      - name: Verify Docker build files
        shell: bash
        run: |

          echo "=================================================="
          echo "VERIFYING DOCKER BUILD FILES"
          echo "=================================================="

          echo ""
          echo "Current directory:"
          pwd

          echo ""
          echo "Repository root:"
          ls -la

          # --------------------------------------------------
          # Verify Dockerfile
          # --------------------------------------------------

          echo ""
          echo "Checking Dockerfile..."

          if [ ! -f "docker/Dockerfile" ]; then

            echo "ERROR: docker/Dockerfile was not found."

            echo ""
            echo "Repository structure:"

            find . \
              -maxdepth 3 \
              -type f \
              -print \
              | sort

            exit 1

          fi

          echo "Dockerfile found:"
          echo "docker/Dockerfile"

          # --------------------------------------------------
          # Verify application directory
          # --------------------------------------------------

          echo ""
          echo "Checking application directory..."

          if [ ! -d "application" ]; then

            echo "ERROR: application directory was not found."

            echo ""
            echo "The Docker build expects:"
            echo "application/"

            exit 1

          fi

          echo "application directory found."

          echo ""
          echo "Application files:"

          find application \
            -maxdepth 2 \
            -type f \
            | head -50

          echo ""
          echo "=================================================="
          echo "DOCKER BUILD FILE VERIFICATION SUCCESS"
          echo "=================================================="


      # ======================================================
      # STEP 18
      # BUILD DOCKER IMAGE
      # ======================================================

      - name: Build Docker image
        shell: bash
        run: |

          echo "=================================================="
          echo "BUILDING DOCKER IMAGE"
          echo "=================================================="

          docker --version

          echo ""
          echo "Dockerfile:"
          echo "docker/Dockerfile"

          echo ""
          echo "Build context:"
          echo "."

          echo ""
          echo "ECR image:"
          echo "$ECR_URI:$IMAGE_TAG"

          # --------------------------------------------------
          # Build Docker image.
          #
          # The image is tagged directly with the ECR URI.
          # --------------------------------------------------

          docker build \
            --file docker/Dockerfile \
            --tag "$ECR_URI:$IMAGE_TAG" \
            .

          echo ""

          echo "=================================================="
          echo "DOCKER IMAGE BUILD SUCCESS"
          echo "=================================================="

          docker images

          echo ""
          echo "Docker image build SUCCESS."


      # ======================================================
      # STEP 19
      # PUSH DOCKER IMAGE TO ECR
      # ======================================================

      - name: Push Docker image to ECR
        shell: bash
        run: |

          echo "=================================================="
          echo "PUSHING DOCKER IMAGE TO ECR"
          echo "=================================================="

          echo ""
          echo "Image:"
          echo "$ECR_URI:$IMAGE_TAG"

          docker push "$ECR_URI:$IMAGE_TAG"

          echo ""
          echo "=================================================="
          echo "ECR IMAGE PUSH SUCCESS"
          echo "=================================================="


      # ======================================================
      # STEP 20
      # VERIFY ECR LATEST IMAGE
      # ======================================================

      - name: Verify ECR latest image
        shell: bash
        run: |

          echo "=================================================="
          echo "VERIFYING ECR IMAGE"
          echo "=================================================="

          IMAGE_COUNT=$(aws ecr describe-images \
            --region "$AWS_REGION" \
            --repository-name "$ECR_REPOSITORY" \
            --filter tagStatus=TAGGED \
            --query 'imageDetails[?contains(imageTags, `latest`)] | length(@)' \
            --output text)

          echo ""
          echo "Latest image count:"
          echo "$IMAGE_COUNT"

          if [ "$IMAGE_COUNT" -eq 0 ]; then

            echo ""
            echo "ERROR: latest image was not found in ECR."

            exit 1

          fi

          echo ""
          echo "ECR image verification SUCCESS."


      # ======================================================
      # STEP 21
      # VERIFY ECS CLUSTER
      # ======================================================

      - name: Verify ECS cluster
        shell: bash
        run: |

          echo "=================================================="
          echo "VERIFYING ECS CLUSTER"
          echo "=================================================="

          CLUSTER_STATUS=$(aws ecs describe-clusters \
            --region "$AWS_REGION" \
            --clusters "$ECS_CLUSTER" \
            --query 'clusters[0].status' \
            --output text)

          echo ""
          echo "Cluster status:"
          echo "$CLUSTER_STATUS"

          if [ "$CLUSTER_STATUS" != "ACTIVE" ]; then

            echo ""
            echo "ERROR: ECS cluster is not ACTIVE."

            exit 1

          fi

          aws ecs describe-clusters \
            --region "$AWS_REGION" \
            --clusters "$ECS_CLUSTER" \
            --query 'clusters[0].[clusterName,status,activeServicesCount,runningTasksCount]' \
            --output table

          echo ""
          echo "ECS cluster verification SUCCESS."


      # ======================================================
      # STEP 22
      # VERIFY ECS SERVICE
      # ======================================================

      - name: Verify ECS service
        shell: bash
        run: |

          echo "=================================================="
          echo "VERIFYING ECS SERVICE"
          echo "=================================================="

          SERVICE_STATUS=$(aws ecs describe-services \
            --region "$AWS_REGION" \
            --cluster "$ECS_CLUSTER" \
            --services "$ECS_SERVICE" \
            --query 'services[0].status' \
            --output text)

          echo ""
          echo "Service status:"
          echo "$SERVICE_STATUS"

          if [ "$SERVICE_STATUS" = "None" ] || [ -z "$SERVICE_STATUS" ]; then

            echo ""
            echo "ERROR: ECS service was not found."

            exit 1

          fi

          aws ecs describe-services \
            --region "$AWS_REGION" \
            --cluster "$ECS_CLUSTER" \
            --services "$ECS_SERVICE" \
            --query 'services[0].[serviceName,status,desiredCount,runningCount,pendingCount]' \
            --output table

          echo ""
          echo "ECS service verification SUCCESS."


      # ======================================================
      # STEP 23
      # START ECS SERVICE
      # ======================================================
      #
      # CloudFormation created the service with:
      #
      #   DesiredCount = 0
      #
      # Now change it to:
      #
      #   DesiredCount = 1
      #
      # ======================================================

      - name: Start ECS service
        shell: bash
        run: |

          echo "=================================================="
          echo "STARTING ECS FARGATE SERVICE"
          echo "=================================================="

          aws ecs update-service \
            --region "$AWS_REGION" \
            --cluster "$ECS_CLUSTER" \
            --service "$ECS_SERVICE" \
            --desired-count "$ECS_DESIRED_COUNT"

          echo ""
          echo "ECS desired count:"
          echo "$ECS_DESIRED_COUNT"


      # ======================================================
      # STEP 24
      # FORCE NEW ECS DEPLOYMENT
      # ======================================================
      #
      # The Docker image uses the "latest" tag.
      #
      # ECS therefore needs a new deployment so that the task
      # pulls the latest image from ECR.
      #
      # ======================================================

      - name: Force new ECS deployment
        shell: bash
        run: |

          echo "=================================================="
          echo "FORCING NEW ECS DEPLOYMENT"
          echo "=================================================="

          aws ecs update-service \
            --region "$AWS_REGION" \
            --cluster "$ECS_CLUSTER" \
            --service "$ECS_SERVICE" \
            --desired-count "$ECS_DESIRED_COUNT" \
            --force-new-deployment

          echo ""
          echo "New ECS deployment started."


      # ======================================================
      # STEP 25
      # WAIT FOR ECS SERVICE TO STABILIZE
      # ======================================================

      - name: Wait for ECS service to stabilize
        shell: bash
        run: |

          echo "=================================================="
          echo "WAITING FOR ECS SERVICE TO STABILIZE"
          echo "=================================================="

          aws ecs wait services-stable \
            --region "$AWS_REGION" \
            --cluster "$ECS_CLUSTER" \
            --services "$ECS_SERVICE"

          echo ""
          echo "=================================================="
          echo "ECS SERVICE IS STABLE"
          echo "=================================================="


      # ======================================================
      # STEP 26
      # SHOW FINAL ECS SERVICE STATUS
      # ======================================================

      - name: Show final ECS service status
        shell: bash
        run: |

          echo "=================================================="
          echo "FINAL ECS SERVICE STATUS"
          echo "=================================================="

          aws ecs describe-services \
            --region "$AWS_REGION" \
            --cluster "$ECS_CLUSTER" \
            --services "$ECS_SERVICE" \
            --query 'services[0].[serviceName,status,desiredCount,runningCount,pendingCount]' \
            --output table


      # ======================================================
      # STEP 27
      # SHOW RUNNING ECS TASKS
      # ======================================================

      - name: Show running ECS tasks
        shell: bash
        run: |

          echo "=================================================="
          echo "RUNNING ECS TASKS"
          echo "=================================================="

          TASK_ARNS=$(aws ecs list-tasks \
            --region "$AWS_REGION" \
            --cluster "$ECS_CLUSTER" \
            --service-name "$ECS_SERVICE" \
            --desired-status RUNNING \
            --query 'taskArns' \
            --output text)

          if [ -z "$TASK_ARNS" ] || [ "$TASK_ARNS" = "None" ]; then

            echo ""
            echo "ERROR: No running ECS tasks found."

            exit 1

          fi

          aws ecs describe-tasks \
            --region "$AWS_REGION" \
            --cluster "$ECS_CLUSTER" \
            --tasks $TASK_ARNS \
            --query 'tasks[*].[taskArn,lastStatus,healthStatus,taskDefinition]' \
            --output table

          echo ""
          echo "Running ECS task verification SUCCESS."


      # ======================================================
      # STEP 28
      # GET ALB INFORMATION
      # ======================================================

      - name: Get ALB information
        id: alb
        shell: bash
        run: |

          echo "=================================================="
          echo "GETTING APPLICATION LOAD BALANCER"
          echo "=================================================="

          ALB_DNS=$(aws cloudformation describe-stacks \
            --region "$AWS_REGION" \
            --stack-name "$ECS_STACK_NAME" \
            --query "Stacks[0].Outputs[?OutputKey=='ALBDNSName'].OutputValue" \
            --output text)

          APPLICATION_URL=$(aws cloudformation describe-stacks \
            --region "$AWS_REGION" \
            --stack-name "$ECS_STACK_NAME" \
            --query "Stacks[0].Outputs[?OutputKey=='ApplicationURL'].OutputValue" \
            --output text)

          echo ""
          echo "ALB DNS:"
          echo "$ALB_DNS"

          echo ""
          echo "Application URL:"
          echo "$APPLICATION_URL"

          if [ -z "$ALB_DNS" ] || [ "$ALB_DNS" = "None" ]; then

            echo ""
            echo "ERROR: ALBDNSName CloudFormation output was not found."

            exit 1

          fi

          if [ -z "$APPLICATION_URL" ] || [ "$APPLICATION_URL" = "None" ]; then

            echo ""
            echo "ERROR: ApplicationURL CloudFormation output was not found."

            exit 1

          fi

          # --------------------------------------------------
          # Export application URL to later steps.
          # --------------------------------------------------

          echo "application_url=$APPLICATION_URL" >> "$GITHUB_OUTPUT"


      # ======================================================
      # STEP 29
      # VERIFY ALB TARGET HEALTH
      # ======================================================
      #
      # This verifies that at least one target is HEALTHY.
      #
      # ======================================================

      - name: Verify ALB target health
        shell: bash
        run: |

          echo "=================================================="
          echo "VERIFYING ALB TARGET HEALTH"
          echo "=================================================="

          TARGET_GROUP_ARN=$(aws cloudformation describe-stack-resources \
            --region "$AWS_REGION" \
            --stack-name "$ECS_STACK_NAME" \
            --logical-resource-id ALBTargetGroup \
            --query 'StackResources[0].PhysicalResourceId' \
            --output text)

          echo ""
          echo "Target Group:"
          echo "$TARGET_GROUP_ARN"

          if [ -z "$TARGET_GROUP_ARN" ] || [ "$TARGET_GROUP_ARN" = "None" ]; then

            echo ""
            echo "ERROR: ALB target group was not found."

            exit 1

          fi

          echo ""
          echo "Target health:"

          aws elbv2 describe-target-health \
            --region "$AWS_REGION" \
            --target-group-arn "$TARGET_GROUP_ARN" \
            --query 'TargetHealthDescriptions[*].[Target.Id,Target.Port,TargetHealth.State,TargetHealth.Reason]' \
            --output table

          HEALTHY_TARGET_COUNT=$(aws elbv2 describe-target-health \
            --region "$AWS_REGION" \
            --target-group-arn "$TARGET_GROUP_ARN" \
            --query 'TargetHealthDescriptions[?TargetHealth.State==`healthy`] | length(@)' \
            --output text)

          echo ""
          echo "Healthy target count:"
          echo "$HEALTHY_TARGET_COUNT"

          if [ "$HEALTHY_TARGET_COUNT" -lt 1 ]; then

            echo ""
            echo "ERROR: No healthy ALB targets were found."

            exit 1

          fi

          echo ""
          echo "ALB target health verification SUCCESS."


      # ======================================================
      # STEP 30
      # TEST APPLICATION URL
      # ======================================================
      #
      # The workflow performs up to 10 HTTP tests.
      #
      # Each attempt waits 15 seconds before retrying.
      #
      # HTTP 200-399 is considered successful.
      #
      # ======================================================

      - name: Test application URL
        shell: bash
        run: |

          echo "=================================================="
          echo "TESTING APPLICATION URL"
          echo "=================================================="

          APPLICATION_URL="${{ steps.alb.outputs.application_url }}"

          echo ""
          echo "URL:"
          echo "$APPLICATION_URL"

          if [ -z "$APPLICATION_URL" ] || [ "$APPLICATION_URL" = "None" ]; then

            echo ""
            echo "ERROR: ApplicationURL was not found."

            exit 1

          fi

          echo ""
          echo "Waiting for application..."

          for attempt in {1..10}; do

            echo ""
            echo "HTTP test attempt: $attempt/10"

            HTTP_CODE=$(curl \
              --silent \
              --show-error \
              --output /tmp/application-response.txt \
              --write-out "%{http_code}" \
              --max-time 15 \
              "$APPLICATION_URL" 2>/dev/null || true)

            echo "HTTP status:"
            echo "$HTTP_CODE"

            if [[ "$HTTP_CODE" =~ ^[0-9]+$ ]] && \
               [ "$HTTP_CODE" -ge 200 ] && \
               [ "$HTTP_CODE" -lt 400 ]; then

              echo ""
              echo "Application HTTP test SUCCESS."

              exit 0

            fi

            if [ "$attempt" -lt 10 ]; then

              echo ""
              echo "Application is not ready yet."
              echo "Waiting 15 seconds before retry..."

              sleep 15

            fi

          done

          echo ""
          echo "ERROR: Application did not return a successful HTTP response."

          exit 1


      # ======================================================
      # STEP 31
      # VERIFY CLOUDWATCH LOG GROUP
      # ======================================================

      - name: Verify CloudWatch log group
        shell: bash
        run: |

          echo "=================================================="
          echo "VERIFYING CLOUDWATCH LOG GROUP"
          echo "=================================================="

          LOG_GROUP_COUNT=$(aws logs describe-log-groups \
            --region "$AWS_REGION" \
            --log-group-name-prefix "/ecs/charlie-cafe" \
            --query 'length(logGroups)' \
            --output text)

          echo ""
          echo "Matching CloudWatch log groups:"
          echo "$LOG_GROUP_COUNT"

          if [ "$LOG_GROUP_COUNT" -lt 1 ]; then

            echo ""
            echo "ERROR: Expected CloudWatch log group was not found."

            exit 1

          fi

          aws logs describe-log-groups \
            --region "$AWS_REGION" \
            --log-group-name-prefix "/ecs/charlie-cafe" \
            --query 'logGroups[*].[logGroupName,retentionInDays]' \
            --output table

          echo ""
          echo "CloudWatch Logs verification SUCCESS."


      # ======================================================
      # STEP 32
      # FINAL DEPLOYMENT SUMMARY
      # ======================================================

      - name: Deployment complete
        shell: bash
        run: |

          echo ""
          echo ""
          echo "======================================================"
          echo "       CHARLIE CAFE ECS DEPLOYMENT COMPLETE"
          echo "======================================================"

          echo ""
          echo "AWS Region:"
          echo "$AWS_REGION"

          echo ""
          echo "CloudFormation Stack:"
          echo "$ECS_STACK_NAME"

          echo ""
          echo "ECR Repository:"
          echo "$ECR_REPOSITORY"

          echo ""
          echo "ECS Cluster:"
          echo "$ECS_CLUSTER"

          echo ""
          echo "ECS Service:"
          echo "$ECS_SERVICE"

          echo ""
          echo "Desired Tasks:"
          echo "$ECS_DESIRED_COUNT"

          echo ""
          echo "Container Port:"
          echo "$CONTAINER_PORT"

          echo ""
          echo "Application URL:"
          echo "${{ steps.alb.outputs.application_url }}"

          echo ""
          echo "======================================================"
          echo "                DEPLOYMENT STATUS"
          echo "======================================================"

          echo ""
          echo "CloudFormation     : SUCCESS"
          echo "ECR Repository     : SUCCESS"
          echo "Docker Image       : SUCCESS"
          echo "ECS Cluster        : SUCCESS"
          echo "ECS Service        : SUCCESS"
          echo "Task Definition    : SUCCESS"
          echo "Fargate Task       : SUCCESS"
          echo "Application LB     : SUCCESS"
          echo "ALB Target Health  : SUCCESS"
          echo "CloudWatch Logs    : SUCCESS"
          echo "Application HTTP   : SUCCESS"

          echo ""
          echo "======================================================"
          echo "Charlie Cafe is now running on ECS Fargate."
          echo "======================================================"
```

---
## 3. delete.yml

```
# ==========================================================
# AWS CloudFormation DevOps Lab
# GitHub Actions - Complete Stack Delete Workflow
# ==========================================================
#
# File:
#   .github/workflows/delete.yml
#
# Purpose:
# ----------------------------------------------------------
# Completely cleans up the AWS CloudFormation DevOps Lab.
#
#
# ROOT CLOUDFORMATION ARCHITECTURE:
#
#   Lab01-CloudFormation
#          |
#          +---- EC2WebServerStack
#          |
#          +---- S3NestedStack
#          |
#          +---- RDSNestedStack
#          |          |
#          |          +---- RDSDatabase
#          |          +---- RDSSecurityGroup
#          |          +---- RDSSubnetGroup
#          |
#          +---- ECSStack
#                     |
#                     +---- ECRRepository
#                     +---- ECSCluster
#                     +---- ECSService
#                     +---- ECSTaskDefinition
#                     +---- ECSTaskExecutionRole
#                     +---- ECSTaskRole
#                     +---- ApplicationLoadBalancer
#                     +---- ALBTargetGroup
#                     +---- ALBListener
#
#
# SEPARATE CLOUDFORMATION STACK:
#
#   Lab01-CloudFormation-TemplateBucket
#          |
#          +---- TemplateBucket
#
#
# IMPORTANT:
# ----------------------------------------------------------
#
# Lab01-CloudFormation-TemplateBucket is a SEPARATE stack.
#
# It is NOT a nested stack of:
#
#   Lab01-CloudFormation
#
# Therefore deleting:
#
#   Lab01-CloudFormation
#
# does NOT automatically delete:
#
#   Lab01-CloudFormation-TemplateBucket
#
#
# ==========================================================
# CLEANUP STRATEGY
# ==========================================================
#
# The workflow performs cleanup in the following order:
#
# 1. Checkout repository.
#
# 2. Configure AWS credentials.
#
# 3. Verify AWS CLI and AWS account.
#
# 4. Check whether the root stack exists.
#
# 5. Display root stack status.
#
# 6. Display root stack information.
#
# 7. Display root stack resources.
#
# 8. Discover RDS nested stack.
#
# 9. Discover RDS database.
#
# 10. Check RDS deletion protection.
#
# 11. Start normal root CloudFormation deletion.
#
# 12. Wait for normal root deletion.
#
# 13. Display DELETE_FAILED resources if required.
#
# 14. Recover RDS if required.
#
# 15. Wait for RDS deletion if required.
#
# 16. Force-delete root stack if required.
#
# 17. Wait for final root stack deletion.
#
# 18. Verify root stack.
#
# 19. Check separate Template Bucket stack.
#
# 20. Display Template Bucket resources.
#
# 21. Discover Template S3 bucket.
#
# 22. Empty all S3 object versions.
#
# 23. Delete all S3 delete markers.
#
# 24. Verify Template S3 bucket is empty.
#
# 25. Delete Template Bucket CloudFormation stack.
#
# 26. Wait for Template Bucket stack deletion.
#
# 27. Verify Template Bucket stack deletion.
#
# 28. Discover ECS nested stack.
#
# 29. Discover ECS cluster.
#
# 30. Discover ECS service.
#
# 31. Discover ECR repository.
#
# 32. Stop ECS service.
#
# 33. Wait for ECS tasks to stop.
#
# 34. Delete all ECR images.
#
# 35. Verify ECR repository is empty.
#
# 36. Delete ECS service directly if still present.
#
# 37. Delete ECS cluster directly if still present.
#
# 38. Delete ECR repository directly if still present.
#
# 39. Verify ECS cleanup.
#
# 40. Verify ECR cleanup.
#
# 41. Verify RDS cleanup.
#
# 42. Final CloudFormation check.
#
# 43. Final AWS resource check.
#
# 44. Final cleanup summary.
#
#
# ==========================================================
# IMPORTANT S3 VERSIONING INFORMATION
# ==========================================================
#
# A normal command such as:
#
#   aws s3 rm s3://bucket --recursive
#
# is NOT enough for a versioned bucket.
#
# A versioned bucket can still contain:
#
#   - old object versions
#   - delete markers
#
# CloudFormation can then fail with:
#
#   The bucket you tried to delete is not empty.
#
# Therefore this workflow explicitly deletes:
#
#   - object versions
#   - delete markers
#
#
# ==========================================================
# IMPORTANT ECS / ECR INFORMATION
# ==========================================================
#
# ECS and ECR are part of the CloudFormation infrastructure.
#
# CloudFormation is normally responsible for deleting:
#
#   - ECS Service
#   - ECS Cluster
#   - ECS Task Definition
#   - IAM Roles
#   - ALB
#   - Target Group
#   - Listener
#   - ECR Repository
#
# However, an ECR repository containing images can prevent
# CloudFormation from deleting the repository.
#
# ECS services can also have running Fargate tasks.
#
# Therefore this workflow performs explicit ECS/ECR cleanup
# after the Template Bucket stack cleanup.
#
# If CloudFormation already deleted the resources, the
# cleanup steps simply report that the resources no longer
# exist.
#
#
# ==========================================================
# REQUIRED GITHUB SECRETS
# ==========================================================
#
# GitHub Repository
#   ->
# Settings
#   ->
# Secrets and variables
#   ->
# Actions
#
# Required secrets:
#
#   AWS_ACCESS_KEY_ID
#   AWS_SECRET_ACCESS_KEY
#
# ==========================================================


# ==========================================================
# WORKFLOW NAME
# ==========================================================

name: Delete AWS CloudFormation Lab


# ==========================================================
# WORKFLOW TRIGGER
# ==========================================================
#
# Manual execution only.
#
# GitHub:
#
#   Actions
#      ->
#   Delete AWS CloudFormation Lab
#      ->
#   Run workflow
#
# ==========================================================

on:
  workflow_dispatch:


# ==========================================================
# GLOBAL ENVIRONMENT VARIABLES
# ==========================================================

env:

  # AWS region containing the lab resources.
  AWS_REGION: us-east-1

  # Root CloudFormation stack.
  STACK_NAME: Lab01-CloudFormation

  # Separate stack containing the template S3 bucket.
  TEMPLATE_BUCKET_STACK: Lab01-CloudFormation-TemplateBucket


# ==========================================================
# JOB
# ==========================================================

jobs:

  delete-stack:

    # GitHub hosted Ubuntu runner.
    runs-on: ubuntu-latest

    name: Delete AWS CloudFormation Lab


    # ======================================================
    # STEPS
    # ======================================================

    steps:


      # ====================================================
      # STEP 1
      # Checkout Repository
      # ====================================================

      - name: "Step 1 - Checkout Repository"
        uses: actions/checkout@v4


      # ====================================================
      # STEP 2
      # Configure AWS Credentials
      # ====================================================

      - name: "Step 2 - Configure AWS Credentials"
        uses: aws-actions/configure-aws-credentials@v4

        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}


      # ====================================================
      # STEP 3
      # Verify AWS CLI and Account
      # ====================================================

      - name: "Step 3 - Verify AWS CLI and Account"
        shell: bash

        run: |

          echo "=============================================="
          echo "AWS CLI INFORMATION"
          echo "=============================================="

          aws --version

          echo ""

          echo "=============================================="
          echo "AWS ACCOUNT"
          echo "=============================================="

          aws sts get-caller-identity

          echo ""

          echo "=============================================="
          echo "LAB CONFIGURATION"
          echo "=============================================="

          echo "AWS Region             : $AWS_REGION"
          echo "Root Stack             : $STACK_NAME"
          echo "Template Bucket Stack  : $TEMPLATE_BUCKET_STACK"

          echo ""


      # ====================================================
      # STEP 4
      # Check Root Stack
      # ====================================================

      - name: "Step 4 - Check Root Stack"
        id: stack
        shell: bash

        run: |

          echo "=============================================="
          echo "CHECKING ROOT CLOUDFORMATION STACK"
          echo "=============================================="

          if aws cloudformation describe-stacks \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            > /dev/null 2>&1
          then

            echo "exists=true" >> "$GITHUB_OUTPUT"

            echo ""
            echo "Root stack exists."

          else

            echo "exists=false" >> "$GITHUB_OUTPUT"

            echo ""
            echo "Root stack does not exist."

          fi


      # ====================================================
      # STEP 5
      # Get Root Stack Status
      # ====================================================

      - name: "Step 5 - Get Root Stack Status"
        if: steps.stack.outputs.exists == 'true'
        id: status
        shell: bash

        run: |

          echo "=============================================="
          echo "ROOT STACK STATUS"
          echo "=============================================="

          STACK_STATUS=$(aws cloudformation describe-stacks \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION" \
            --query "Stacks[0].StackStatus" \
            --output text \
            --no-cli-pager)

          echo ""

          echo "Stack Name   : $STACK_NAME"
          echo "Stack Status : $STACK_STATUS"

          echo ""

          echo "stack_status=$STACK_STATUS" >> "$GITHUB_OUTPUT"


      # ====================================================
      # STEP 6
      # Display Root Stack Information
      # ====================================================

      - name: "Step 6 - Display Root Stack Information"
        if: steps.stack.outputs.exists == 'true'
        shell: bash

        run: |

          echo "=============================================="
          echo "ROOT STACK INFORMATION"
          echo "=============================================="

          aws cloudformation describe-stacks \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION" \
            --output table \
            --no-cli-pager


      # ====================================================
      # STEP 7
      # Display Root Stack Resources
      # ====================================================

      - name: "Step 7 - Display Root Stack Resources"
        if: steps.stack.outputs.exists == 'true'
        shell: bash

        run: |

          echo "=============================================="
          echo "ROOT STACK RESOURCES"
          echo "=============================================="

          aws cloudformation list-stack-resources \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION" \
            --query "StackResourceSummaries[].[LogicalResourceId,ResourceType,ResourceStatus,PhysicalResourceId]" \
            --output table \
            --no-cli-pager \
            || true


      # ====================================================
      # STEP 8
      # Discover RDS Nested Stack
      # ====================================================

      - name: "Step 8 - Discover RDS Nested Stack"
        if: steps.stack.outputs.exists == 'true'
        id: rds_nested
        shell: bash

        run: |

          echo "=============================================="
          echo "DISCOVERING RDS NESTED STACK"
          echo "=============================================="

          RDS_NESTED_STACK_ID=$(aws cloudformation list-stack-resources \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION" \
            --query "StackResourceSummaries[?LogicalResourceId=='RDSNestedStack'].PhysicalResourceId" \
            --output text \
            --no-cli-pager)

          echo ""

          echo "RDS Nested Stack:"
          echo "$RDS_NESTED_STACK_ID"

          echo ""

          if [ -n "$RDS_NESTED_STACK_ID" ] &&
             [ "$RDS_NESTED_STACK_ID" != "None" ]
          then

            echo "rds_nested_stack=$RDS_NESTED_STACK_ID" >> "$GITHUB_OUTPUT"

            echo "RDS nested stack found."

          else

            echo "rds_nested_stack=" >> "$GITHUB_OUTPUT"

            echo "RDS nested stack was not found."

          fi


      # ====================================================
      # STEP 9
      # Discover RDS Database
      # ====================================================

      - name: "Step 9 - Discover RDS Database"
        if: |
          steps.stack.outputs.exists == 'true' &&
          steps.rds_nested.outputs.rds_nested_stack != ''
        id: rds
        shell: bash

        run: |

          echo "=============================================="
          echo "DISCOVERING RDS DATABASE"
          echo "=============================================="

          RDS_NESTED_STACK_ID="${{ steps.rds_nested.outputs.rds_nested_stack }}"

          RDS_INSTANCE=$(aws cloudformation describe-stack-resources \
            --stack-name "$RDS_NESTED_STACK_ID" \
            --region "$AWS_REGION" \
            --logical-resource-id RDSDatabase \
            --query "StackResources[0].PhysicalResourceId" \
            --output text \
            --no-cli-pager \
            2>/dev/null || true)

          echo ""

          echo "RDS Physical Resource ID:"
          echo "$RDS_INSTANCE"

          echo ""

          if [ -n "$RDS_INSTANCE" ] &&
             [ "$RDS_INSTANCE" != "None" ]
          then

            echo "rds_instance=$RDS_INSTANCE" >> "$GITHUB_OUTPUT"

            echo "RDS database found."

          else

            echo "rds_instance=" >> "$GITHUB_OUTPUT"

            echo "RDS database was not found."

          fi


      # ====================================================
      # STEP 10
      # Check RDS Deletion Protection
      # ====================================================

      - name: "Step 10 - Check RDS Deletion Protection"
        if: steps.rds.outputs.rds_instance != ''
        shell: bash

        run: |

          echo "=============================================="
          echo "CHECKING RDS DELETION PROTECTION"
          echo "=============================================="

          RDS_INSTANCE="${{ steps.rds.outputs.rds_instance }}"

          DELETE_PROTECTION=$(aws rds describe-db-instances \
            --db-instance-identifier "$RDS_INSTANCE" \
            --region "$AWS_REGION" \
            --query "DBInstances[0].DeletionProtection" \
            --output text \
            --no-cli-pager \
            2>/dev/null || true)

          echo ""

          echo "RDS Instance        : $RDS_INSTANCE"
          echo "Deletion Protection : $DELETE_PROTECTION"

          echo ""

          if [ "$DELETE_PROTECTION" = "True" ]
          then

            echo "Disabling RDS deletion protection..."

            aws rds modify-db-instance \
              --db-instance-identifier "$RDS_INSTANCE" \
              --region "$AWS_REGION" \
              --no-deletion-protection \
              --apply-immediately \
              --no-cli-pager

            echo ""
            echo "Deletion protection disable request submitted."

          else

            echo "RDS deletion protection is already disabled."

          fi


      # ====================================================
      # STEP 11
      # Start Root Stack Deletion
      # ====================================================

      - name: "Step 11 - Start Root Stack Deletion"
        if: steps.stack.outputs.exists == 'true'
        id: delete
        shell: bash

        run: |

          echo "=============================================="
          echo "STARTING ROOT STACK DELETION"
          echo "=============================================="

          CURRENT_STATUS="${{ steps.status.outputs.stack_status }}"

          echo ""

          echo "Stack Name : $STACK_NAME"
          echo "Region     : $AWS_REGION"
          echo "Status     : $CURRENT_STATUS"

          echo ""

          if [ "$CURRENT_STATUS" = "DELETE_FAILED" ]
          then

            echo "Root stack is already DELETE_FAILED."

            echo ""
            echo "Starting FORCE_DELETE_STACK..."

            aws cloudformation delete-stack \
              --stack-name "$STACK_NAME" \
              --region "$AWS_REGION" \
              --deletion-mode FORCE_DELETE_STACK \
              --no-cli-pager

            echo "mode=force" >> "$GITHUB_OUTPUT"

            echo ""
            echo "Force deletion started."

          else

            echo "Starting normal CloudFormation deletion..."

            aws cloudformation delete-stack \
              --stack-name "$STACK_NAME" \
              --region "$AWS_REGION" \
              --no-cli-pager

            echo "mode=standard" >> "$GITHUB_OUTPUT"

            echo ""
            echo "Normal deletion started."

          fi


      # ====================================================
      # STEP 12
      # Wait for Normal Root Stack Deletion
      # ====================================================

      - name: "Step 12 - Wait for Normal Root Stack Deletion"
        if: |
          steps.stack.outputs.exists == 'true' &&
          steps.delete.outputs.mode == 'standard'
        id: normal_wait
        continue-on-error: true
        shell: bash

        run: |

          echo "=============================================="
          echo "WAITING FOR NORMAL ROOT DELETION"
          echo "=============================================="

          if aws cloudformation wait stack-delete-complete \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION"
          then

            echo "deleted=true" >> "$GITHUB_OUTPUT"

            echo ""
            echo "Root stack deleted successfully."

          else

            echo "deleted=false" >> "$GITHUB_OUTPUT"

            echo ""
            echo "Root stack deletion did not complete."

          fi


      # ====================================================
      # STEP 13
      # Display Root DELETE_FAILED Resources
      # ====================================================

      - name: "Step 13 - Display Root DELETE_FAILED Resources"
        if: |
          steps.stack.outputs.exists == 'true' &&
          steps.delete.outputs.mode == 'standard' &&
          steps.normal_wait.outputs.deleted == 'false'
        shell: bash

        run: |

          echo "=============================================="
          echo "ROOT STACK DELETE_FAILED RESOURCES"
          echo "=============================================="

          aws cloudformation describe-stack-events \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION" \
            --query "StackEvents[?ResourceStatus=='DELETE_FAILED'].[Timestamp,LogicalResourceId,ResourceType,ResourceStatusReason]" \
            --output table \
            --no-cli-pager \
            || true


      # ====================================================
      # STEP 14
      # Direct RDS Cleanup
      # ====================================================

      - name: "Step 14 - Direct RDS Cleanup"
        if: |
          steps.stack.outputs.exists == 'true' &&
          (
            steps.delete.outputs.mode == 'force' ||
            steps.normal_wait.outputs.deleted == 'false'
          ) &&
          steps.rds.outputs.rds_instance != ''
        shell: bash

        run: |

          echo "=============================================="
          echo "DIRECT RDS CLEANUP"
          echo "=============================================="

          RDS_INSTANCE="${{ steps.rds.outputs.rds_instance }}"

          if aws rds describe-db-instances \
            --db-instance-identifier "$RDS_INSTANCE" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            > /dev/null 2>&1
          then

            echo "RDS instance still exists."
            echo ""
            echo "Requesting RDS deletion..."

            aws rds delete-db-instance \
              --db-instance-identifier "$RDS_INSTANCE" \
              --region "$AWS_REGION" \
              --skip-final-snapshot \
              --delete-automated-backups \
              --no-cli-pager \
              || true

            echo ""
            echo "RDS deletion request submitted."

          else

            echo "RDS instance no longer exists."

          fi


      # ====================================================
      # STEP 15
      # Wait for RDS Deletion
      # ====================================================

      - name: "Step 15 - Wait for RDS Deletion"
        if: |
          steps.stack.outputs.exists == 'true' &&
          (
            steps.delete.outputs.mode == 'force' ||
            steps.normal_wait.outputs.deleted == 'false'
          ) &&
          steps.rds.outputs.rds_instance != ''
        shell: bash

        run: |

          echo "=============================================="
          echo "WAITING FOR RDS DELETION"
          echo "=============================================="

          RDS_INSTANCE="${{ steps.rds.outputs.rds_instance }}"

          for ATTEMPT in $(seq 1 60)
          do

            RDS_STATUS=$(aws rds describe-db-instances \
              --db-instance-identifier "$RDS_INSTANCE" \
              --region "$AWS_REGION" \
              --query "DBInstances[0].DBInstanceStatus" \
              --output text \
              --no-cli-pager \
              2>/dev/null || echo "NOT_FOUND")

            echo ""
            echo "Attempt: $ATTEMPT / 60"
            echo "RDS Status: $RDS_STATUS"

            if [ "$RDS_STATUS" = "NOT_FOUND" ]
            then

              echo ""
              echo "RDS instance has been deleted."

              break

            fi

            if [ "$ATTEMPT" -eq 60 ]
            then

              echo ""
              echo "RDS deletion is still in progress."

              break

            fi

            sleep 30

          done


      # ====================================================
      # STEP 16
      # Force Delete Root Stack
      # ====================================================

      - name: "Step 16 - Force Delete Root Stack"
        if: |
          steps.stack.outputs.exists == 'true' &&
          (
            steps.delete.outputs.mode == 'force' ||
            steps.normal_wait.outputs.deleted == 'false'
          )
        shell: bash

        run: |

          echo "=============================================="
          echo "FORCE DELETE ROOT CLOUDFORMATION STACK"
          echo "=============================================="

          echo ""
          echo "Stack Name : $STACK_NAME"
          echo "Region     : $AWS_REGION"
          echo "Mode       : FORCE_DELETE_STACK"
          echo ""

          aws cloudformation delete-stack \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION" \
            --deletion-mode FORCE_DELETE_STACK \
            --no-cli-pager

          echo ""
          echo "Force deletion request submitted."


      # ====================================================
      # STEP 17
      # Wait for Final Root Deletion
      # ====================================================

      - name: "Step 17 - Wait for Final Root Deletion"
        if: |
          steps.stack.outputs.exists == 'true' &&
          (
            steps.delete.outputs.mode == 'force' ||
            steps.normal_wait.outputs.deleted == 'false'
          )
        continue-on-error: true
        shell: bash

        run: |

          echo "=============================================="
          echo "WAITING FOR FINAL ROOT DELETION"
          echo "=============================================="

          if aws cloudformation wait stack-delete-complete \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION"
          then

            echo ""
            echo "Final root stack deletion completed."

          else

            echo ""
            echo "Root stack still has resources requiring cleanup."

            aws cloudformation describe-stack-events \
              --stack-name "$STACK_NAME" \
              --region "$AWS_REGION" \
              --query "StackEvents[?ResourceStatus=='DELETE_FAILED'].[Timestamp,LogicalResourceId,ResourceType,ResourceStatusReason]" \
              --output table \
              --no-cli-pager \
              || true

          fi


      # ====================================================
      # STEP 18
      # Verify Root Stack
      # ====================================================

      - name: "Step 18 - Verify Root Stack"
        id: root_verify
        shell: bash

        run: |

          echo "=============================================="
          echo "VERIFYING ROOT STACK"
          echo "=============================================="

          if aws cloudformation describe-stacks \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            > /dev/null 2>&1
          then

            echo "exists=true" >> "$GITHUB_OUTPUT"

            echo ""
            echo "Root stack still exists."

          else

            echo "exists=false" >> "$GITHUB_OUTPUT"

            echo ""
            echo "Root stack no longer exists."

          fi


      # ====================================================
      # STEP 19
      # Check Template Bucket Stack
      # ====================================================

      - name: "Step 19 - Check Template Bucket Stack"
        id: template_bucket
        shell: bash

        run: |

          echo "=============================================="
          echo "CHECKING TEMPLATE BUCKET STACK"
          echo "=============================================="

          if aws cloudformation describe-stacks \
            --stack-name "$TEMPLATE_BUCKET_STACK" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            > /dev/null 2>&1
          then

            echo "exists=true" >> "$GITHUB_OUTPUT"

            echo ""
            echo "Template Bucket stack exists."

          else

            echo "exists=false" >> "$GITHUB_OUTPUT"

            echo ""
            echo "Template Bucket stack does not exist."

          fi


      # ====================================================
      # STEP 20
      # Display Template Bucket Resources
      # ====================================================

      - name: "Step 20 - Display Template Bucket Resources"
        if: steps.template_bucket.outputs.exists == 'true'
        shell: bash

        run: |

          echo "=============================================="
          echo "TEMPLATE BUCKET STACK RESOURCES"
          echo "=============================================="

          aws cloudformation list-stack-resources \
            --stack-name "$TEMPLATE_BUCKET_STACK" \
            --region "$AWS_REGION" \
            --query "StackResourceSummaries[].[LogicalResourceId,ResourceType,ResourceStatus,PhysicalResourceId]" \
            --output table \
            --no-cli-pager \
            || true


      # ====================================================
      # STEP 21
      # Find Template S3 Bucket
      # ====================================================

      - name: "Step 21 - Find Template S3 Bucket"
        if: steps.template_bucket.outputs.exists == 'true'
        id: template_s3
        shell: bash

        run: |

          echo "=============================================="
          echo "FINDING TEMPLATE S3 BUCKET"
          echo "=============================================="

          TEMPLATE_BUCKET=$(aws cloudformation list-stack-resources \
            --stack-name "$TEMPLATE_BUCKET_STACK" \
            --region "$AWS_REGION" \
            --query "StackResourceSummaries[?LogicalResourceId=='TemplateBucket'].PhysicalResourceId" \
            --output text \
            --no-cli-pager)

          echo ""
          echo "Template Bucket:"
          echo "$TEMPLATE_BUCKET"
          echo ""

          if [ -n "$TEMPLATE_BUCKET" ] &&
             [ "$TEMPLATE_BUCKET" != "None" ]
          then

            echo "template_bucket=$TEMPLATE_BUCKET" >> "$GITHUB_OUTPUT"

            echo "Template S3 bucket found."

          else

            echo "template_bucket=" >> "$GITHUB_OUTPUT"

            echo "Template S3 bucket was not found."

          fi


      # ====================================================
      # STEP 22
      # Empty Versioned Template Bucket
      # ====================================================

      - name: "Step 22 - Empty Versioned Template Bucket"
        if: |
          steps.template_bucket.outputs.exists == 'true' &&
          steps.template_s3.outputs.template_bucket != ''
        shell: bash

        run: |

          echo "=============================================="
          echo "EMPTYING VERSIONED TEMPLATE BUCKET"
          echo "=============================================="

          TEMPLATE_BUCKET="${{ steps.template_s3.outputs.template_bucket }}"

          echo ""
          echo "Bucket:"
          echo "$TEMPLATE_BUCKET"
          echo ""

          echo "Checking bucket versioning..."

          aws s3api get-bucket-versioning \
            --bucket "$TEMPLATE_BUCKET" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            || true

          echo ""

          while true
          do

            VERSION_DATA=$(aws s3api list-object-versions \
              --bucket "$TEMPLATE_BUCKET" \
              --region "$AWS_REGION" \
              --output json \
              --no-cli-pager)

            VERSION_COUNT=$(echo "$VERSION_DATA" |
              jq '(.Versions // []) | length')

            DELETE_MARKER_COUNT=$(echo "$VERSION_DATA" |
              jq '(.DeleteMarkers // []) | length')

            TOTAL_COUNT=$((VERSION_COUNT + DELETE_MARKER_COUNT))

            echo ""
            echo "Object versions     : $VERSION_COUNT"
            echo "Delete markers      : $DELETE_MARKER_COUNT"
            echo "Total remaining     : $TOTAL_COUNT"
            echo ""

            if [ "$TOTAL_COUNT" -eq 0 ]
            then

              echo "Template bucket is completely empty."

              break

            fi

            echo "$VERSION_DATA" |
              jq '{
                Objects:
                  (
                    ((.Versions // []) + (.DeleteMarkers // []))
                    | map({
                        Key: .Key,
                        VersionId: .VersionId
                      })
                    | .[0:1000]
                  ),
                Quiet: true
              }' > /tmp/s3-delete.json

            DELETE_COUNT=$(jq '.Objects | length' /tmp/s3-delete.json)

            echo "Deleting $DELETE_COUNT S3 versions/delete markers..."

            aws s3api delete-objects \
              --bucket "$TEMPLATE_BUCKET" \
              --delete file:///tmp/s3-delete.json \
              --region "$AWS_REGION" \
              --no-cli-pager

            echo ""
            echo "Delete request completed."

          done


      # ====================================================
      # STEP 23
      # Verify Template S3 Bucket Is Empty
      # ====================================================

      - name: "Step 23 - Verify Template S3 Bucket Is Empty"
        if: |
          steps.template_bucket.outputs.exists == 'true' &&
          steps.template_s3.outputs.template_bucket != ''
        shell: bash

        run: |

          echo "=============================================="
          echo "VERIFYING TEMPLATE BUCKET IS EMPTY"
          echo "=============================================="

          TEMPLATE_BUCKET="${{ steps.template_s3.outputs.template_bucket }}"

          FINAL_VERSION_DATA=$(aws s3api list-object-versions \
            --bucket "$TEMPLATE_BUCKET" \
            --region "$AWS_REGION" \
            --output json \
            --no-cli-pager)

          FINAL_VERSION_COUNT=$(echo "$FINAL_VERSION_DATA" |
            jq '(.Versions // []) | length')

          FINAL_DELETE_MARKER_COUNT=$(echo "$FINAL_VERSION_DATA" |
            jq '(.DeleteMarkers // []) | length')

          FINAL_TOTAL=$((FINAL_VERSION_COUNT + FINAL_DELETE_MARKER_COUNT))

          echo ""
          echo "Remaining object versions : $FINAL_VERSION_COUNT"
          echo "Remaining delete markers  : $FINAL_DELETE_MARKER_COUNT"
          echo "Remaining total          : $FINAL_TOTAL"
          echo ""

          if [ "$FINAL_TOTAL" -eq 0 ]
          then

            echo "SUCCESS:"
            echo "Template S3 bucket is completely empty."

          else

            echo "ERROR:"
            echo "Template S3 bucket still contains objects."

            exit 1

          fi


      # ====================================================
      # STEP 24
      # Delete Template Bucket Stack
      # ====================================================

      - name: "Step 24 - Delete Template Bucket Stack"
        if: steps.template_bucket.outputs.exists == 'true'
        id: template_delete
        shell: bash

        run: |

          echo "=============================================="
          echo "DELETING TEMPLATE BUCKET STACK"
          echo "=============================================="

          TEMPLATE_STATUS=$(aws cloudformation describe-stacks \
            --stack-name "$TEMPLATE_BUCKET_STACK" \
            --region "$AWS_REGION" \
            --query "Stacks[0].StackStatus" \
            --output text \
            --no-cli-pager)

          echo ""
          echo "Stack Name : $TEMPLATE_BUCKET_STACK"
          echo "Region     : $AWS_REGION"
          echo "Status     : $TEMPLATE_STATUS"
          echo ""

          case "$TEMPLATE_STATUS" in

            CREATE_IN_PROGRESS|UPDATE_IN_PROGRESS|UPDATE_COMPLETE_CLEANUP_IN_PROGRESS|DELETE_IN_PROGRESS)

              echo "ERROR:"
              echo "Template Bucket stack is currently busy."
              echo ""
              echo "Current status:"
              echo "$TEMPLATE_STATUS"

              exit 1
              ;;

          esac

          echo "Starting Template Bucket stack deletion..."

          aws cloudformation delete-stack \
            --stack-name "$TEMPLATE_BUCKET_STACK" \
            --region "$AWS_REGION" \
            --no-cli-pager

          echo ""
          echo "Template Bucket stack deletion request submitted."


      # ====================================================
      # STEP 25
      # Wait for Template Bucket Stack Deletion
      # ====================================================

      - name: "Step 25 - Wait for Template Bucket Stack Deletion"
        if: steps.template_delete.outcome == 'success'
        shell: bash

        run: |

          echo "=============================================="
          echo "WAITING FOR TEMPLATE BUCKET DELETION"
          echo "=============================================="

          if aws cloudformation wait stack-delete-complete \
            --stack-name "$TEMPLATE_BUCKET_STACK" \
            --region "$AWS_REGION"
          then

            echo ""
            echo "Template Bucket stack deletion completed."

          else

            echo ""
            echo "ERROR:"
            echo "Template Bucket stack deletion failed."

            echo ""

            aws cloudformation describe-stack-events \
              --stack-name "$TEMPLATE_BUCKET_STACK" \
              --region "$AWS_REGION" \
              --query "StackEvents[?ResourceStatus=='DELETE_FAILED'].[Timestamp,LogicalResourceId,ResourceType,ResourceStatusReason]" \
              --output table \
              --no-cli-pager \
              || true

            exit 1

          fi


      # ====================================================
      # STEP 26
      # Verify Template Bucket Stack Deletion
      # ====================================================

      - name: "Step 26 - Verify Template Bucket Stack Deletion"
        shell: bash

        run: |

          echo "=============================================="
          echo "VERIFYING TEMPLATE BUCKET STACK"
          echo "=============================================="

          if aws cloudformation describe-stacks \
            --stack-name "$TEMPLATE_BUCKET_STACK" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            > /dev/null 2>&1
          then

            echo ""
            echo "ERROR:"
            echo "Template Bucket stack still exists."

            exit 1

          else

            echo ""
            echo "Template Bucket stack no longer exists."

          fi


      # ====================================================
      # STEP 27
      # Discover ECS Nested Stack
      # ====================================================

      - name: "Step 27 - Discover ECS Nested Stack"
        if: steps.stack.outputs.exists == 'true'
        id: ecs_nested
        shell: bash

        run: |

          echo "=============================================="
          echo "DISCOVERING ECS NESTED STACK"
          echo "=============================================="

          ECS_NESTED_STACK_ID=$(aws cloudformation list-stack-resources \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION" \
            --query "StackResourceSummaries[?LogicalResourceId=='ECSStack'].PhysicalResourceId" \
            --output text \
            --no-cli-pager \
            2>/dev/null || true)

          echo ""
          echo "ECS Nested Stack:"
          echo "$ECS_NESTED_STACK_ID"
          echo ""

          if [ -n "$ECS_NESTED_STACK_ID" ] &&
             [ "$ECS_NESTED_STACK_ID" != "None" ]
          then

            echo "ecs_nested_stack=$ECS_NESTED_STACK_ID" >> "$GITHUB_OUTPUT"

            echo "ECS nested stack found."

          else

            echo "ecs_nested_stack=" >> "$GITHUB_OUTPUT"

            echo "ECS nested stack was not found."

          fi


      # ====================================================
      # STEP 28
      # Discover ECS Cluster
      # ====================================================

      - name: "Step 28 - Discover ECS Cluster"
        if: steps.ecs_nested.outputs.ecs_nested_stack != ''
        id: ecs_cluster
        shell: bash

        run: |

          echo "=============================================="
          echo "DISCOVERING ECS CLUSTER"
          echo "=============================================="

          ECS_NESTED_STACK_ID="${{ steps.ecs_nested.outputs.ecs_nested_stack }}"

          ECS_CLUSTER=$(aws cloudformation list-stack-resources \
            --stack-name "$ECS_NESTED_STACK_ID" \
            --region "$AWS_REGION" \
            --query "StackResourceSummaries[?ResourceType=='AWS::ECS::Cluster'].PhysicalResourceId" \
            --output text \
            --no-cli-pager \
            2>/dev/null || true)

          echo ""
          echo "ECS Cluster:"
          echo "$ECS_CLUSTER"
          echo ""

          if [ -n "$ECS_CLUSTER" ] &&
             [ "$ECS_CLUSTER" != "None" ]
          then

            echo "ecs_cluster=$ECS_CLUSTER" >> "$GITHUB_OUTPUT"

            echo "ECS cluster found."

          else

            echo "ecs_cluster=" >> "$GITHUB_OUTPUT"

            echo "ECS cluster was not found."

          fi


      # ====================================================
      # STEP 29
      # Discover ECS Service
      # ====================================================

      - name: "Step 29 - Discover ECS Service"
        if: |
          steps.ecs_nested.outputs.ecs_nested_stack != '' &&
          steps.ecs_cluster.outputs.ecs_cluster != ''
        id: ecs_service
        shell: bash

        run: |

          echo "=============================================="
          echo "DISCOVERING ECS SERVICE"
          echo "=============================================="

          ECS_NESTED_STACK_ID="${{ steps.ecs_nested.outputs.ecs_nested_stack }}"

          ECS_SERVICE=$(aws cloudformation list-stack-resources \
            --stack-name "$ECS_NESTED_STACK_ID" \
            --region "$AWS_REGION" \
            --query "StackResourceSummaries[?ResourceType=='AWS::ECS::Service'].PhysicalResourceId" \
            --output text \
            --no-cli-pager \
            2>/dev/null || true)

          echo ""
          echo "ECS Service:"
          echo "$ECS_SERVICE"
          echo ""

          if [ -n "$ECS_SERVICE" ] &&
             [ "$ECS_SERVICE" != "None" ]
          then

            echo "ecs_service=$ECS_SERVICE" >> "$GITHUB_OUTPUT"

            echo "ECS service found."

          else

            echo "ecs_service=" >> "$GITHUB_OUTPUT"

            echo "ECS service was not found."

          fi


      # ====================================================
      # STEP 30
      # Discover ECR Repository
      # ====================================================

      - name: "Step 30 - Discover ECR Repository"
        if: steps.ecs_nested.outputs.ecs_nested_stack != ''
        id: ecr
        shell: bash

        run: |

          echo "=============================================="
          echo "DISCOVERING ECR REPOSITORY"
          echo "=============================================="

          ECS_NESTED_STACK_ID="${{ steps.ecs_nested.outputs.ecs_nested_stack }}"

          ECR_REPOSITORY=$(aws cloudformation list-stack-resources \
            --stack-name "$ECS_NESTED_STACK_ID" \
            --region "$AWS_REGION" \
            --query "StackResourceSummaries[?ResourceType=='AWS::ECR::Repository'].PhysicalResourceId" \
            --output text \
            --no-cli-pager \
            2>/dev/null || true)

          echo ""
          echo "ECR Repository:"
          echo "$ECR_REPOSITORY"
          echo ""

          if [ -n "$ECR_REPOSITORY" ] &&
             [ "$ECR_REPOSITORY" != "None" ]
          then

            echo "ecr_repository=$ECR_REPOSITORY" >> "$GITHUB_OUTPUT"

            echo "ECR repository found."

          else

            echo "ecr_repository=" >> "$GITHUB_OUTPUT"

            echo "ECR repository was not found."

          fi


      # ====================================================
      # STEP 31
      # Stop ECS Service
      # ====================================================
      #
      # IMPORTANT:
      #
      # The service is scaled to zero so Fargate tasks can
      # terminate before the ECS service is removed.
      #
      # ====================================================

      - name: "Step 31 - Stop ECS Service"
        if: |
          steps.ecs_cluster.outputs.ecs_cluster != '' &&
          steps.ecs_service.outputs.ecs_service != ''
        shell: bash

        run: |

          echo "=============================================="
          echo "STOPPING ECS SERVICE"
          echo "=============================================="

          ECS_CLUSTER="${{ steps.ecs_cluster.outputs.ecs_cluster }}"
          ECS_SERVICE="${{ steps.ecs_service.outputs.ecs_service }}"

          if aws ecs describe-services \
            --cluster "$ECS_CLUSTER" \
            --services "$ECS_SERVICE" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            > /dev/null 2>&1
          then

            echo "ECS service exists."

            echo ""
            echo "Setting desired count to zero..."

            aws ecs update-service \
              --cluster "$ECS_CLUSTER" \
              --service "$ECS_SERVICE" \
              --desired-count 0 \
              --region "$AWS_REGION" \
              --no-cli-pager

            echo ""
            echo "ECS service desired count set to zero."

          else

            echo "ECS service no longer exists."

          fi


      # ====================================================
      # STEP 32
      # Wait for ECS Tasks to Stop
      # ====================================================

      - name: "Step 32 - Wait for ECS Tasks to Stop"
        if: |
          steps.ecs_cluster.outputs.ecs_cluster != '' &&
          steps.ecs_service.outputs.ecs_service != ''
        shell: bash

        run: |

          echo "=============================================="
          echo "WAITING FOR ECS TASKS TO STOP"
          echo "=============================================="

          ECS_CLUSTER="${{ steps.ecs_cluster.outputs.ecs_cluster }}"
          ECS_SERVICE="${{ steps.ecs_service.outputs.ecs_service }}"

          if aws ecs describe-services \
            --cluster "$ECS_CLUSTER" \
            --services "$ECS_SERVICE" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            > /dev/null 2>&1
          then

            echo "Waiting for ECS service to become stable..."

            aws ecs wait services-stable \
              --cluster "$ECS_CLUSTER" \
              --services "$ECS_SERVICE" \
              --region "$AWS_REGION" \
              || true

            echo ""
            echo "ECS service has reached a stable state."

          else

            echo "ECS service no longer exists."

          fi


      # ====================================================
      # STEP 33
      # Empty ECR Repository
      # ====================================================
      #
      # IMPORTANT:
      #
      # CloudFormation cannot always delete an ECR repository
      # when Docker images remain inside it.
      #
      # This step deletes all image IDs.
      #
      # The repository itself is NOT deleted here.
      #
      # ====================================================

      - name: "Step 33 - Empty ECR Repository"
        if: steps.ecr.outputs.ecr_repository != ''
        shell: bash

        run: |

          echo "=============================================="
          echo "EMPTYING ECR REPOSITORY"
          echo "=============================================="

          ECR_REPOSITORY="${{ steps.ecr.outputs.ecr_repository }}"

          echo ""
          echo "Repository:"
          echo "$ECR_REPOSITORY"
          echo ""

          if ! aws ecr describe-repositories \
            --repository-names "$ECR_REPOSITORY" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            > /dev/null 2>&1
          then

            echo "ECR repository does not exist."

            exit 0

          fi

          echo "ECR repository exists."

          while true
          do

            IMAGE_IDS=$(aws ecr list-images \
              --repository-name "$ECR_REPOSITORY" \
              --region "$AWS_REGION" \
              --query "imageIds[*]" \
              --output json \
              --no-cli-pager)

            IMAGE_COUNT=$(echo "$IMAGE_IDS" | jq 'length')

            echo ""
            echo "Images remaining: $IMAGE_COUNT"

            if [ "$IMAGE_COUNT" -eq 0 ]
            then

              echo ""
              echo "ECR repository is empty."

              break

            fi

            echo "$IMAGE_IDS" > /tmp/ecr-image-ids.json

            echo ""
            echo "Deleting ECR images..."

            aws ecr batch-delete-image \
              --repository-name "$ECR_REPOSITORY" \
              --image-ids file:///tmp/ecr-image-ids.json \
              --region "$AWS_REGION" \
              --no-cli-pager

            echo ""
            echo "ECR image deletion completed."

          done


      # ====================================================
      # STEP 34
      # Verify ECR Repository Is Empty
      # ====================================================

      - name: "Step 34 - Verify ECR Repository Is Empty"
        if: steps.ecr.outputs.ecr_repository != ''
        shell: bash

        run: |

          echo "=============================================="
          echo "VERIFYING ECR REPOSITORY"
          echo "=============================================="

          ECR_REPOSITORY="${{ steps.ecr.outputs.ecr_repository }}"

          if ! aws ecr describe-repositories \
            --repository-names "$ECR_REPOSITORY" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            > /dev/null 2>&1
          then

            echo "ECR repository no longer exists."

            exit 0

          fi

          IMAGE_COUNT=$(aws ecr list-images \
            --repository-name "$ECR_REPOSITORY" \
            --region "$AWS_REGION" \
            --query "length(imageIds)" \
            --output text \
            --no-cli-pager)

          echo ""
          echo "ECR Repository  : $ECR_REPOSITORY"
          echo "Images Remaining: $IMAGE_COUNT"
          echo ""

          if [ "$IMAGE_COUNT" -eq 0 ]
          then

            echo "SUCCESS:"
            echo "ECR repository is empty."

          else

            echo "ERROR:"
            echo "ECR repository still contains images."

            exit 1

          fi


      # ====================================================
      # STEP 35
      # Delete ECS Service Directly If Required
      # ====================================================
      #
      # This is a recovery step.
      #
      # CloudFormation should normally delete the ECS service.
      #
      # If it remains after the stack cleanup, this step removes
      # it directly.
      #
      # ====================================================

      - name: "Step 35 - Delete ECS Service Directly"
        if: |
          steps.ecs_cluster.outputs.ecs_cluster != '' &&
          steps.ecs_service.outputs.ecs_service != ''
        shell: bash

        run: |

          echo "=============================================="
          echo "DELETING ECS SERVICE IF STILL PRESENT"
          echo "=============================================="

          ECS_CLUSTER="${{ steps.ecs_cluster.outputs.ecs_cluster }}"
          ECS_SERVICE="${{ steps.ecs_service.outputs.ecs_service }}"

          if aws ecs describe-services \
            --cluster "$ECS_CLUSTER" \
            --services "$ECS_SERVICE" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            > /dev/null 2>&1
          then

            echo "ECS service still exists."

            echo ""
            echo "Deleting ECS service..."

            aws ecs delete-service \
              --cluster "$ECS_CLUSTER" \
              --service "$ECS_SERVICE" \
              --force \
              --region "$AWS_REGION" \
              --no-cli-pager \
              || true

            echo ""
            echo "ECS service deletion request submitted."

          else

            echo "ECS service does not exist."

          fi


      # ====================================================
      # STEP 36
      # Wait for ECS Service Deletion
      # ====================================================

      - name: "Step 36 - Wait for ECS Service Deletion"
        if: |
          steps.ecs_cluster.outputs.ecs_cluster != '' &&
          steps.ecs_service.outputs.ecs_service != ''
        shell: bash

        run: |

          echo "=============================================="
          echo "WAITING FOR ECS SERVICE DELETION"
          echo "=============================================="

          ECS_CLUSTER="${{ steps.ecs_cluster.outputs.ecs_cluster }}"
          ECS_SERVICE="${{ steps.ecs_service.outputs.ecs_service }}"

          for ATTEMPT in $(seq 1 30)
          do

            if aws ecs describe-services \
              --cluster "$ECS_CLUSTER" \
              --services "$ECS_SERVICE" \
              --region "$AWS_REGION" \
              --no-cli-pager \
              > /dev/null 2>&1
            then

              echo ""
              echo "Attempt: $ATTEMPT / 30"
              echo "ECS service still exists."

              sleep 10

            else

              echo ""
              echo "ECS service has been deleted."

              break

            fi

          done


      # ====================================================
      # STEP 37
      # Delete ECS Cluster Directly If Required
      # ====================================================

      - name: "Step 37 - Delete ECS Cluster Directly"
        if: steps.ecs_cluster.outputs.ecs_cluster != ''
        shell: bash

        run: |

          echo "=============================================="
          echo "DELETING ECS CLUSTER IF STILL PRESENT"
          echo "=============================================="

          ECS_CLUSTER="${{ steps.ecs_cluster.outputs.ecs_cluster }}"

          if aws ecs describe-clusters \
            --clusters "$ECS_CLUSTER" \
            --region "$AWS_REGION" \
            --query "clusters[0].status" \
            --output text \
            --no-cli-pager \
            2>/dev/null |
            grep -q "ACTIVE"
          then

            echo "ECS cluster still exists."

            echo ""
            echo "Deleting ECS cluster..."

            aws ecs delete-cluster \
              --cluster "$ECS_CLUSTER" \
              --region "$AWS_REGION" \
              --no-cli-pager \
              || true

            echo ""
            echo "ECS cluster deletion request submitted."

          else

            echo "ECS cluster does not require deletion."

          fi


      # ====================================================
      # STEP 38
      # Delete ECR Repository Directly If Required
      # ====================================================
      #
      # The repository has already been emptied.
      #
      # Now it can safely be deleted directly if CloudFormation
      # did not remove it.
      #
      # ====================================================

      - name: "Step 38 - Delete ECR Repository Directly"
        if: steps.ecr.outputs.ecr_repository != ''
        shell: bash

        run: |

          echo "=============================================="
          echo "DELETING ECR REPOSITORY IF STILL PRESENT"
          echo "=============================================="

          ECR_REPOSITORY="${{ steps.ecr.outputs.ecr_repository }}"

          if aws ecr describe-repositories \
            --repository-names "$ECR_REPOSITORY" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            > /dev/null 2>&1
          then

            echo "ECR repository still exists."

            echo ""
            echo "Deleting ECR repository..."

            aws ecr delete-repository \
              --repository-name "$ECR_REPOSITORY" \
              --region "$AWS_REGION" \
              --no-cli-pager \
              || true

            echo ""
            echo "ECR repository deletion request submitted."

          else

            echo "ECR repository no longer exists."

          fi


      # ====================================================
      # STEP 39
      # Verify ECS Cleanup
      # ====================================================

      - name: "Step 39 - Verify ECS Cleanup"
        if: steps.ecs_cluster.outputs.ecs_cluster != ''
        shell: bash

        run: |

          echo "=============================================="
          echo "VERIFYING ECS CLEANUP"
          echo "=============================================="

          ECS_CLUSTER="${{ steps.ecs_cluster.outputs.ecs_cluster }}"

          ECS_STATUS=$(aws ecs describe-clusters \
            --clusters "$ECS_CLUSTER" \
            --region "$AWS_REGION" \
            --query "clusters[0].status" \
            --output text \
            --no-cli-pager \
            2>/dev/null || echo "NOT_FOUND")

          echo ""
          echo "ECS Cluster: $ECS_CLUSTER"
          echo "ECS Status : $ECS_STATUS"
          echo ""

          if [ "$ECS_STATUS" = "NOT_FOUND" ] ||
             [ "$ECS_STATUS" = "None" ]
          then

            echo "SUCCESS:"
            echo "ECS cluster no longer exists."

          else

            echo "WARNING:"
            echo "ECS cluster still exists."

          fi


      # ====================================================
      # STEP 40
      # Verify ECR Cleanup
      # ====================================================

      - name: "Step 40 - Verify ECR Cleanup"
        if: steps.ecr.outputs.ecr_repository != ''
        shell: bash

        run: |

          echo "=============================================="
          echo "VERIFYING ECR CLEANUP"
          echo "=============================================="

          ECR_REPOSITORY="${{ steps.ecr.outputs.ecr_repository }}"

          if aws ecr describe-repositories \
            --repository-names "$ECR_REPOSITORY" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            > /dev/null 2>&1
          then

            echo ""
            echo "WARNING:"
            echo "ECR repository still exists."

          else

            echo ""
            echo "SUCCESS:"
            echo "ECR repository no longer exists."

          fi


      # ====================================================
      # STEP 41
      # Verify RDS Cleanup
      # ====================================================

      - name: "Step 41 - Verify RDS Cleanup"
        shell: bash

        run: |

          echo "=============================================="
          echo "VERIFYING RDS CLEANUP"
          echo "=============================================="

          RDS_COUNT=$(aws rds describe-db-instances \
            --region "$AWS_REGION" \
            --query "length(DBInstances)" \
            --output text \
            --no-cli-pager)

          echo ""
          echo "RDS instances currently visible:"
          echo "$RDS_COUNT"
          echo ""

          if [ "$RDS_COUNT" = "0" ]
          then

            echo "SUCCESS:"
            echo "No RDS DB instances remain."

          else

            echo "WARNING:"
            echo "RDS DB instances still exist."

            aws rds describe-db-instances \
              --region "$AWS_REGION" \
              --query "DBInstances[].[DBInstanceIdentifier,DBInstanceStatus,DeletionProtection]" \
              --output table \
              --no-cli-pager

          fi


      # ====================================================
      # STEP 42
      # Final CloudFormation Check
      # ====================================================

      - name: "Step 42 - Final CloudFormation Check"
        shell: bash

        run: |

          echo "=============================================="
          echo "FINAL CLOUDFORMATION CHECK"
          echo "=============================================="

          echo ""
          echo "Checking root stack..."

          if aws cloudformation describe-stacks \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            > /dev/null 2>&1
          then

            echo "WARNING:"
            echo "$STACK_NAME still exists."

          else

            echo "OK:"
            echo "$STACK_NAME does not exist."

          fi

          echo ""
          echo "Checking Template Bucket stack..."

          if aws cloudformation describe-stacks \
            --stack-name "$TEMPLATE_BUCKET_STACK" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            > /dev/null 2>&1
          then

            echo "WARNING:"
            echo "$TEMPLATE_BUCKET_STACK still exists."

          else

            echo "OK:"
            echo "$TEMPLATE_BUCKET_STACK does not exist."

          fi


      # ====================================================
      # STEP 43
      # Final AWS Resource Check
      # ====================================================

      - name: "Step 43 - Final AWS Resource Check"
        shell: bash

        run: |

          echo "=============================================="
          echo "FINAL AWS RESOURCE CHECK"
          echo "=============================================="

          echo ""
          echo "RDS INSTANCES"
          echo "----------------------------------------------"

          aws rds describe-db-instances \
            --region "$AWS_REGION" \
            --query "DBInstances[].[DBInstanceIdentifier,DBInstanceStatus,DeletionProtection]" \
            --output table \
            --no-cli-pager \
            || true

          echo ""
          echo "ECS CLUSTERS"
          echo "----------------------------------------------"

          aws ecs list-clusters \
            --region "$AWS_REGION" \
            --output table \
            --no-cli-pager \
            || true

          echo ""
          echo "ECR REPOSITORIES"
          echo "----------------------------------------------"

          aws ecr describe-repositories \
            --region "$AWS_REGION" \
            --query "repositories[].[repositoryName,repositoryUri]" \
            --output table \
            --no-cli-pager \
            || true

          echo ""
          echo "CLOUDFORMATION LAB STACKS"
          echo "----------------------------------------------"

          aws cloudformation list-stacks \
            --region "$AWS_REGION" \
            --stack-status-filter \
              CREATE_IN_PROGRESS \
              CREATE_FAILED \
              CREATE_COMPLETE \
              ROLLBACK_IN_PROGRESS \
              ROLLBACK_FAILED \
              ROLLBACK_COMPLETE \
              DELETE_IN_PROGRESS \
              DELETE_FAILED \
              UPDATE_IN_PROGRESS \
              UPDATE_COMPLETE \
              UPDATE_ROLLBACK_IN_PROGRESS \
              UPDATE_ROLLBACK_FAILED \
              UPDATE_ROLLBACK_COMPLETE \
            --query "StackSummaries[?contains(StackName, 'Lab01-CloudFormation')].[StackName,StackStatus]" \
            --output table \
            --no-cli-pager \
            || true


      # ====================================================
      # STEP 44
      # Final Cleanup Summary
      # ====================================================

      - name: "Step 44 - Final Cleanup Summary"
        shell: bash

        run: |

          echo ""

          echo "=========================================================="
          echo "AWS CLOUDFORMATION LAB CLEANUP COMPLETE"
          echo "=========================================================="

          echo ""

          echo "Root Stack:"
          echo "  $STACK_NAME"

          echo ""

          echo "Template Bucket Stack:"
          echo "  $TEMPLATE_BUCKET_STACK"

          echo ""

          echo "AWS Region:"
          echo "  $AWS_REGION"

          echo ""

          echo "Cleanup operations:"
          echo ""

          echo "  [01] AWS credentials configured"
          echo "  [02] AWS CLI and account verified"
          echo "  [03] Root stack checked"
          echo "  [04] Root stack status inspected"
          echo "  [05] Root stack resources inspected"
          echo "  [06] RDS nested stack discovered"
          echo "  [07] RDS database discovered"
          echo "  [08] RDS deletion protection checked"
          echo "  [09] Normal root stack deletion attempted"
          echo "  [10] Normal root deletion monitored"
          echo "  [11] DELETE_FAILED resources inspected"
          echo "  [12] RDS recovery attempted if required"
          echo "  [13] RDS deletion monitored"
          echo "  [14] FORCE_DELETE_STACK used if required"
          echo "  [15] Final root deletion monitored"
          echo "  [16] Root stack verified"
          echo "  [17] Template Bucket stack checked"
          echo "  [18] Template Bucket resources inspected"
          echo "  [19] Template S3 bucket discovered"
          echo "  [20] S3 object versions deleted"
          echo "  [21] S3 delete markers deleted"
          echo "  [22] Template S3 bucket verified empty"
          echo "  [23] Template Bucket stack deleted"
          echo "  [24] Template Bucket stack deletion verified"
          echo "  [25] ECS nested stack discovered"
          echo "  [26] ECS cluster discovered"
          echo "  [27] ECS service discovered"
          echo "  [28] ECR repository discovered"
          echo "  [29] ECS service stopped"
          echo "  [30] ECS tasks monitored"
          echo "  [31] ECR images deleted"
          echo "  [32] ECR repository verified empty"
          echo "  [33] ECS service deleted if required"
          echo "  [34] ECS service deletion monitored"
          echo "  [35] ECS cluster deleted if required"
          echo "  [36] ECR repository deleted if required"
          echo "  [37] ECS cleanup verified"
          echo "  [38] ECR cleanup verified"
          echo "  [39] RDS cleanup verified"
          echo "  [40] Final CloudFormation check completed"
          echo "  [41] Final AWS resource check completed"

          echo ""

          echo "=========================================================="
          echo "LAB CLEANUP FINISHED"
          echo "=========================================================="

          echo ""
```

---
# Docker 

## 1. Dockerfile

```
# ==========================================================
# Charlie Cafe Docker Image
# ==========================================================
#
# Purpose:
# This Dockerfile creates the Docker image used to run
# the Charlie Cafe application.
#
# Current lab objective:
#
# Application
#      ↓
# Dockerfile
#      ↓
# Docker Image
#      ↓
# Docker Container
#
# At this stage we are NOT deploying the image to:
#
# - Amazon ECR
# - Amazon ECS
# - Application Load Balancer
#
# Those services will be introduced later.
# ==========================================================


# ==========================================================
# 1. Base Image
# ==========================================================
#
# Ubuntu 24.04 provides the base operating system
# environment for the container.
#
# The application dependencies will be installed
# on top of this image.
# ==========================================================

FROM ubuntu:24.04


# ==========================================================
# 2. Prevent Interactive Package Installation
# ==========================================================
#
# Some Ubuntu packages ask questions during installation.
#
# Setting DEBIAN_FRONTEND to noninteractive prevents
# interactive prompts during Docker image creation.
# ==========================================================

ENV DEBIAN_FRONTEND=noninteractive


# ==========================================================
# 3. Install Required Packages
# ==========================================================
#
# Install the basic tools required by the lab.
#
# bash      -> shell environment
# curl      -> download/test HTTP resources
# wget      -> download files
# git       -> Git repository operations
# unzip     -> extract ZIP files
# ca-certificates -> HTTPS certificate support
#
# nginx     -> web server
# php       -> PHP runtime
# php-fpm   -> PHP FastCGI process manager
#
# The exact PHP packages can be expanded later depending
# on the Charlie Cafe application requirements.
# ==========================================================

RUN apt-get update && \
    apt-get install -y \
        bash \
        curl \
        wget \
        git \
        unzip \
        ca-certificates \
        nginx \
        php \
        php-fpm \
        php-mysql \
        php-curl \
        php-json \
        php-mbstring \
        php-xml \
        php-zip \
    && rm -rf /var/lib/apt/lists/*


# ==========================================================
# 4. Set Working Directory
# ==========================================================
#
# All application-related commands will run from:
#
# /var/www/html
#
# This is a common directory for web applications.
# ==========================================================

WORKDIR /var/www/html


# ==========================================================
# 5. Copy Application Files
# ==========================================================
#
# Copy the Charlie Cafe application into the container.
#
# IMPORTANT:
#
# This assumes your Docker build context contains the
# application files.
#
# If your application is located in another directory,
# adjust the Docker build context or COPY instruction.
# ==========================================================

COPY application/ /var/www/html/


# ==========================================================
# 6. Configure Nginx
# ==========================================================
#
# Remove the default Nginx configuration.
# ==========================================================

RUN rm -f /etc/nginx/sites-enabled/default


# ==========================================================
# 7. Create Charlie Cafe Nginx Configuration
# ==========================================================
#
# Nginx listens on port 80 inside the container.
#
# PHP requests are forwarded to PHP-FPM.
# ==========================================================

RUN printf '%s\n' \
'server {' \
'    listen 80;' \
'    listen [::]:80;' \
'' \
'    root /var/www/html;' \
'    index index.php index.html;' \
'' \
'    server_name _;' \
'' \
'    location / {' \
'        try_files $uri $uri/ /index.php?$query_string;' \
'    }' \
'' \
'    location ~ \.php$ {' \
'        include snippets/fastcgi-php.conf;' \
'        fastcgi_pass unix:/run/php/php8.3-fpm.sock;' \
'    }' \
'}' \
> /etc/nginx/sites-available/charlie-cafe


# ==========================================================
# 8. Enable Charlie Cafe Nginx Configuration
# ==========================================================

RUN ln -s \
    /etc/nginx/sites-available/charlie-cafe \
    /etc/nginx/sites-enabled/charlie-cafe


# ==========================================================
# 9. Verify PHP Installation
# ==========================================================
#
# Confirm that Ubuntu installed the expected PHP version.
#
# Ubuntu 24.04 should provide PHP 8.3.
#
# ==========================================================

RUN php --version && \
    php-fpm8.3 --version

# ==========================================================
# 10. Validate Nginx Configuration
# ==========================================================
#
# nginx -t checks the configuration before the container
# is started.
#
# If the configuration contains an error, Docker image
# building will fail instead of discovering the problem
# later when the container starts.
#
# ==========================================================

RUN nginx -t    



# ==========================================================
# 11. Expose Container Port
# ==========================================================
#
# EXPOSE does NOT publish the port to the host.
#
# It documents that the application listens on port 80.
#
# The actual host-to-container port mapping is configured
# when the container is started.
# ==========================================================

EXPOSE 80


# ==========================================================
# 12. Start PHP-FPM + Nginx
# ==========================================================
#
# The container needs two processes:
#
# 1. PHP-FPM
#    Handles PHP execution.
#
# 2. Nginx
#    Handles HTTP requests.
#
# PHP-FPM runs in the background.
#
# Nginx runs in the foreground.
#
# Nginx must remain in the foreground because Docker
# considers the main process as the life of the container.
#
# If Nginx exits, the container exits.
#
# CMD ["bash", "-c", "php-fpm8.3 -D && nginx -g 'daemon off;'"]
# ==========================================================

CMD ["bash", "-c", "\
    echo '======================================'; \
    echo 'Starting PHP-FPM'; \
    echo '======================================'; \
    php-fpm8.3 -D; \
    echo 'PHP-FPM started'; \
    echo ''; \
    echo '======================================'; \
    echo 'Starting Nginx'; \
    echo '======================================'; \
    exec nginx -g 'daemon off;' \
"]
```

---
## 2. docker-compose.yml

```
# ==========================================================
# Charlie Cafe Docker Compose
# ==========================================================
#
# Purpose:
# Run the Charlie Cafe Docker container locally.
#
# Current lab:
#
# Docker only
#
# NOT using:
#
# - ECS
# - ECR
# - ALB
# - NAT Gateway
# - API Gateway
#
# Those services can be introduced later.
# ==========================================================


services:

  # ========================================================
  # Charlie Cafe Application
  # ========================================================

  charlie-cafe:

    # ------------------------------------------------------
    # Container name
    # ------------------------------------------------------

    container_name: charlie-cafe-container


    # ------------------------------------------------------
    # Build Docker image
    # ------------------------------------------------------
    #
    # The build context is the project root.
    #
    # Docker will use:
    #
    # docker/Dockerfile
    #
    # ------------------------------------------------------

    build:

      context: .

      dockerfile: docker/Dockerfile


    # ------------------------------------------------------
    # Image name
    # ------------------------------------------------------
    #
    # After building, the image will be available as:
    #
    # charlie-cafe:latest
    # ------------------------------------------------------

    image: charlie-cafe:latest


    # ------------------------------------------------------
    # Port Mapping
    # ------------------------------------------------------
    #
    # Host:
    #
    # localhost:8080
    #
    # Container:
    #
    # port 80
    #
    # Therefore:
    #
    # Browser
    #    ↓
    # localhost:8080
    #    ↓
    # Docker
    #    ↓
    # Container port 80
    #    ↓
    # Nginx
    # ------------------------------------------------------

    ports:

      - "8080:80"


    # ------------------------------------------------------
    # Restart Policy
    # ------------------------------------------------------
    #
    # Automatically restart the container if it stops
    # unexpectedly.
    # ------------------------------------------------------

    restart: unless-stopped
```

---