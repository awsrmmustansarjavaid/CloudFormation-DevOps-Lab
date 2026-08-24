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
# AWS CLOUDFORMATION DEVOPS LAB
# COMPLETE AWS DELETE / CLEANUP WORKFLOW
# ==========================================================
#
# File:
#   .github/workflows/delete.yml
#
# PURPOSE
# ----------------------------------------------------------
# Completely remove the Charlie Cafe / AWS DevOps Lab.
#
# IMPORTANT DELETION ORDER
# ----------------------------------------------------------
#
# 1. Discover root stack
# 2. Discover standalone ECS/ECR stack
# 3. Stop standalone ECS service
# 4. Wait for ECS tasks
# 5. Delete ECR images
# 6. Delete standalone ECS/ECR CloudFormation stack
# 7. Clean Docker containers/images on EC2 through SSM
# 8. Empty Template S3 bucket
# 9. Delete Template Bucket stack
# 10. Delete ROOT CloudFormation stack
# 11. CloudFormation deletes nested stacks
# 12. Wait for root deletion
# 13. If DELETE_FAILED:
#       - inspect failed resources
#       - retry ECS cleanup
#       - retry ALB cleanup
#       - retry Target Group cleanup
#       - retry root deletion
# 14. Final verification
#
#
# IMPORTANT:
# ----------------------------------------------------------
# There are TWO possible ECS architectures:
#
# A) Standalone ECS stack:
#      CharlieCafe-ECS-Stack
#
#    This workflow deletes it FIRST.
#
# B) Nested ECS stack:
#      ECSStack
#
#    If ECSStack is a true nested stack under the root stack,
#    DO NOT delete it directly.
#
#    CloudFormation will delete it when the ROOT stack is deleted.
#
#
# ECR:
# ----------------------------------------------------------
# ECR images are deleted BEFORE deleting the ECS/ECR stack.
# This is important because an ECR repository containing images
# can prevent CloudFormation from deleting the repository.
#
#
# DOCKER:
# ----------------------------------------------------------
# Docker cleanup is performed on EC2 through AWS SSM.
#
# The GitHub Actions runner is NOT the EC2 Docker host.
#
#
# ==========================================================


name: Complete AWS Lab Cleanup


# ==========================================================
# MANUAL TRIGGER ONLY
# ==========================================================

on:
  workflow_dispatch:


# ==========================================================
# GLOBAL VARIABLES
# ==========================================================

env:

  # --------------------------------------------------------
  # AWS REGION
  # --------------------------------------------------------
  AWS_REGION: us-east-1

  # --------------------------------------------------------
  # MAIN / ROOT CLOUDFORMATION STACK
  # --------------------------------------------------------
  STACK_NAME: Lab01-CloudFormation

  # --------------------------------------------------------
  # STANDALONE ECS + ECR STACK
  #
  # This is the stack created by your ECS deployment workflow.
  # --------------------------------------------------------
  ECS_STACK_NAME: CharlieCafe-ECS-Stack

  # --------------------------------------------------------
  # SEPARATE S3 TEMPLATE BUCKET STACK
  # --------------------------------------------------------
  TEMPLATE_BUCKET_STACK: Lab01-CloudFormation-TemplateBucket

  # --------------------------------------------------------
  # MAX ROOT STACK DELETE WAIT
  # 20 minutes
  # --------------------------------------------------------
  ROOT_DELETE_WAIT_SECONDS: 1200


# ==========================================================
# JOB
# ==========================================================

jobs:

  delete-lab:

    name: Complete AWS Lab Cleanup

    runs-on: ubuntu-latest

    steps:


      # ======================================================
      # STEP 1
      # CHECKOUT REPOSITORY
      # ======================================================

      - name: "Step 1 - Checkout Repository"

        uses: actions/checkout@v4


      # ======================================================
      # STEP 2
      # CONFIGURE AWS CREDENTIALS
      # ======================================================

      - name: "Step 2 - Configure AWS Credentials"

        uses: aws-actions/configure-aws-credentials@v4

        with:

          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}

          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

          aws-region: ${{ env.AWS_REGION }}


      # ======================================================
      # STEP 3
      # VERIFY AWS ACCOUNT
      # ======================================================

      - name: "Step 3 - Verify AWS Account"

        shell: bash

        run: |

          set -euo pipefail

          echo "=================================================="
          echo "AWS ACCOUNT VERIFICATION"
          echo "=================================================="

          aws --version

          echo ""

          aws sts get-caller-identity

          echo ""

          echo "AWS Region:"
          echo "  $AWS_REGION"

          echo ""

          echo "Root Stack:"
          echo "  $STACK_NAME"

          echo ""

          echo "Standalone ECS/ECR Stack:"
          echo "  $ECS_STACK_NAME"

          echo ""

          echo "Template Bucket Stack:"
          echo "  $TEMPLATE_BUCKET_STACK"


      # ======================================================
      # STEP 4
      # DISCOVER ROOT STACK
      # ======================================================

      - name: "Step 4 - Discover Root Stack"

        id: root

        shell: bash

        run: |

          set -euo pipefail

          echo "=================================================="
          echo "DISCOVER ROOT STACK"
          echo "=================================================="

          if aws cloudformation describe-stacks \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            >/dev/null 2>&1
          then

            STATUS=$(
              aws cloudformation describe-stacks \
                --stack-name "$STACK_NAME" \
                --region "$AWS_REGION" \
                --query "Stacks[0].StackStatus" \
                --output text \
                --no-cli-pager
            )

            echo "exists=true" >> "$GITHUB_OUTPUT"

            echo "status=$STATUS" >> "$GITHUB_OUTPUT"

            echo ""

            echo "Root stack exists."

            echo "Status: $STATUS"

          else

            echo "exists=false" >> "$GITHUB_OUTPUT"

            echo "status=NOT_FOUND" >> "$GITHUB_OUTPUT"

            echo ""

            echo "Root stack does not exist."

          fi


      # ======================================================
      # STEP 5
      # DISPLAY ROOT RESOURCES
      # ======================================================

      - name: "Step 5 - Display Root Resources"

        if: steps.root.outputs.exists == 'true'

        shell: bash

        run: |

          set -euo pipefail

          echo "=================================================="
          echo "ROOT STACK RESOURCES"
          echo "=================================================="

          aws cloudformation list-stack-resources \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION" \
            --query "StackResourceSummaries[].[LogicalResourceId,ResourceType,ResourceStatus,PhysicalResourceId]" \
            --output table \
            --no-cli-pager \
            || true


      # ======================================================
      # STEP 6
      # DISCOVER STANDALONE ECS/ECR STACK
      # ======================================================
      #
      # THIS IS THE IMPORTANT FIX.
      #
      # Your previous workflow only discovered ECSStack as a
      # nested resource inside the root stack.
      #
      # Your Charlie Cafe ECS workflow creates:
      #
      #   CharlieCafe-ECS-Stack
      #
      # Therefore we explicitly discover it here.
      # ======================================================

      - name: "Step 6 - Discover Standalone ECS ECR Stack"

        id: ecs_stack

        shell: bash

        run: |

          set -euo pipefail

          echo "=================================================="
          echo "DISCOVER STANDALONE ECS/ECR STACK"
          echo "=================================================="

          if aws cloudformation describe-stacks \
            --stack-name "$ECS_STACK_NAME" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            >/dev/null 2>&1
          then

            STATUS=$(
              aws cloudformation describe-stacks \
                --stack-name "$ECS_STACK_NAME" \
                --region "$AWS_REGION" \
                --query "Stacks[0].StackStatus" \
                --output text \
                --no-cli-pager
            )

            echo "exists=true" >> "$GITHUB_OUTPUT"

            echo "status=$STATUS" >> "$GITHUB_OUTPUT"

            echo ""

            echo "Standalone ECS/ECR stack FOUND."

            echo "Stack : $ECS_STACK_NAME"

            echo "Status: $STATUS"

          else

            echo "exists=false" >> "$GITHUB_OUTPUT"

            echo "status=NOT_FOUND" >> "$GITHUB_OUTPUT"

            echo ""

            echo "Standalone ECS/ECR stack does not exist."

          fi


      # ======================================================
      # STEP 7
      # DISPLAY ECS STACK RESOURCES
      # ======================================================

      - name: "Step 7 - Display ECS Stack Resources"

        if: steps.ecs_stack.outputs.exists == 'true'

        shell: bash

        run: |

          set -euo pipefail

          echo "=================================================="
          echo "ECS/ECR STACK RESOURCES"
          echo "=================================================="

          aws cloudformation list-stack-resources \
            --stack-name "$ECS_STACK_NAME" \
            --region "$AWS_REGION" \
            --query "StackResourceSummaries[].[LogicalResourceId,ResourceType,ResourceStatus,PhysicalResourceId]" \
            --output table \
            --no-cli-pager \
            || true


      # ======================================================
      # STEP 8
      # DISCOVER ECS CLUSTER FROM STANDALONE STACK
      # ======================================================

      - name: "Step 8 - Discover ECS Cluster"

        if: steps.ecs_stack.outputs.exists == 'true'

        id: standalone_ecs_cluster

        shell: bash

        run: |

          set -euo pipefail

          ECS_CLUSTER=$(
            aws cloudformation list-stack-resources \
              --stack-name "$ECS_STACK_NAME" \
              --region "$AWS_REGION" \
              --query "StackResourceSummaries[?ResourceType=='AWS::ECS::Cluster'].PhysicalResourceId | [0]" \
              --output text \
              --no-cli-pager \
              2>/dev/null || true
          )

          echo "ECS Cluster: $ECS_CLUSTER"

          if [[ -n "$ECS_CLUSTER" && "$ECS_CLUSTER" != "None" ]]
          then

            echo "cluster=$ECS_CLUSTER" >> "$GITHUB_OUTPUT"

          else

            echo "cluster=" >> "$GITHUB_OUTPUT"

          fi


      # ======================================================
      # STEP 9
      # DISCOVER ECS SERVICE
      # ======================================================

      - name: "Step 9 - Discover ECS Service"

        if: steps.ecs_stack.outputs.exists == 'true'

        id: standalone_ecs_service

        shell: bash

        run: |

          set -euo pipefail

          ECS_SERVICE=$(
            aws cloudformation list-stack-resources \
              --stack-name "$ECS_STACK_NAME" \
              --region "$AWS_REGION" \
              --query "StackResourceSummaries[?ResourceType=='AWS::ECS::Service'].PhysicalResourceId | [0]" \
              --output text \
              --no-cli-pager \
              2>/dev/null || true
          )

          echo "ECS Service: $ECS_SERVICE"

          if [[ -n "$ECS_SERVICE" && "$ECS_SERVICE" != "None" ]]
          then

            echo "service=$ECS_SERVICE" >> "$GITHUB_OUTPUT"

          else

            echo "service=" >> "$GITHUB_OUTPUT"

          fi


      # ======================================================
      # STEP 10
      # DISCOVER ECR REPOSITORY
      # ======================================================

      - name: "Step 10 - Discover ECR Repository"

        if: steps.ecs_stack.outputs.exists == 'true'

        id: standalone_ecr

        shell: bash

        run: |

          set -euo pipefail

          ECR_REPOSITORY=$(
            aws cloudformation list-stack-resources \
              --stack-name "$ECS_STACK_NAME" \
              --region "$AWS_REGION" \
              --query "StackResourceSummaries[?ResourceType=='AWS::ECR::Repository'].PhysicalResourceId | [0]" \
              --output text \
              --no-cli-pager \
              2>/dev/null || true
          )

          echo "ECR Repository: $ECR_REPOSITORY"

          if [[ -n "$ECR_REPOSITORY" && "$ECR_REPOSITORY" != "None" ]]
          then

            echo "repository=$ECR_REPOSITORY" >> "$GITHUB_OUTPUT"

          else

            echo "repository=" >> "$GITHUB_OUTPUT"

          fi


      # ======================================================
      # STEP 11
      # STOP ECS SERVICE
      # ======================================================
      #
      # IMPORTANT:
      # We do NOT manually delete the CloudFormation-owned ECS
      # service here.
      #
      # We simply scale it to zero.
      #
      # Then CloudFormation can safely delete it when the stack
      # is deleted.
      # ======================================================

      - name: "Step 11 - Stop ECS Service"

        if: |
          steps.standalone_ecs_cluster.outputs.cluster != '' &&
          steps.standalone_ecs_service.outputs.service != ''

        shell: bash

        run: |

          set -euo pipefail

          ECS_CLUSTER="${{ steps.standalone_ecs_cluster.outputs.cluster }}"

          ECS_SERVICE="${{ steps.standalone_ecs_service.outputs.service }}"

          echo "=================================================="
          echo "STOP ECS SERVICE"
          echo "=================================================="

          if aws ecs describe-services \
            --cluster "$ECS_CLUSTER" \
            --services "$ECS_SERVICE" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            >/dev/null 2>&1
          then

            aws ecs update-service \
              --cluster "$ECS_CLUSTER" \
              --service "$ECS_SERVICE" \
              --desired-count 0 \
              --region "$AWS_REGION" \
              --no-cli-pager \
              || true

            echo "ECS desired count set to 0."

          else

            echo "ECS service already absent."

          fi


      # ======================================================
      # STEP 12
      # WAIT FOR ECS TASKS
      # ======================================================

      - name: "Step 12 - Wait For ECS Tasks"

        if: |
          steps.standalone_ecs_cluster.outputs.cluster != '' &&
          steps.standalone_ecs_service.outputs.service != ''

        shell: bash

        run: |

          set -u

          ECS_CLUSTER="${{ steps.standalone_ecs_cluster.outputs.cluster }}"

          ECS_SERVICE="${{ steps.standalone_ecs_service.outputs.service }}"

          echo "=================================================="
          echo "WAIT FOR ECS TASKS"
          echo "=================================================="

          for ATTEMPT in $(seq 1 36)
          do

            RUNNING=$(
              aws ecs describe-services \
                --cluster "$ECS_CLUSTER" \
                --services "$ECS_SERVICE" \
                --region "$AWS_REGION" \
                --query "services[0].runningCount" \
                --output text \
                --no-cli-pager \
                2>/dev/null || echo "0"
            )

            echo "Attempt $ATTEMPT / 36"

            echo "Running tasks: $RUNNING"

            if [[ "$RUNNING" == "0" ]]
            then

              echo "All ECS tasks stopped."

              exit 0

            fi

            sleep 10

          done

          echo ""

          echo "WARNING: ECS tasks did not reach zero."

          echo "Continuing cleanup."


      # ======================================================
      # STEP 13
      # EMPTY ECR REPOSITORY
      # ======================================================
      #
      # THIS IS REQUIRED BEFORE ECS/ECR STACK DELETION.
      #
      # CloudFormation cannot normally delete an ECR repository
      # that still contains images unless the repository was
      # explicitly configured with:
      #
      #   EmptyOnDelete: true
      #
      # Therefore we remove the images first.
      # ======================================================

      - name: "Step 13 - Delete All ECR Images"

        if: steps.standalone_ecr.outputs.repository != ''

        shell: bash

        run: |

          set -euo pipefail

          ECR_REPOSITORY="${{ steps.standalone_ecr.outputs.repository }}"

          echo "=================================================="
          echo "DELETE ALL ECR IMAGES"
          echo "=================================================="

          if ! aws ecr describe-repositories \
            --repository-names "$ECR_REPOSITORY" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            >/dev/null 2>&1
          then

            echo "ECR repository already absent."

            exit 0

          fi

          while true
          do

            IMAGE_IDS=$(
              aws ecr list-images \
                --repository-name "$ECR_REPOSITORY" \
                --region "$AWS_REGION" \
                --query "imageIds[*]" \
                --output json \
                --no-cli-pager
            )

            COUNT=$(echo "$IMAGE_IDS" | jq 'length')

            echo "Images remaining: $COUNT"

            if [[ "$COUNT" -eq 0 ]]
            then

              echo "ECR repository is empty."

              break

            fi

            echo "$IMAGE_IDS" > /tmp/ecr-images.json

            aws ecr batch-delete-image \
              --repository-name "$ECR_REPOSITORY" \
              --image-ids file:///tmp/ecr-images.json \
              --region "$AWS_REGION" \
              --no-cli-pager \
              || true

          done


      # ======================================================
      # STEP 14
      # DELETE STANDALONE ECS/ECR STACK
      # ======================================================
      #
      # THIS IS THE OTHER MAJOR FIX.
      #
      # Your old workflow never explicitly deleted:
      #
      #   CharlieCafe-ECS-Stack
      #
      # This step does.
      #
      # CloudFormation will now delete:
      #
      #   ECS Service
      #   ECS Cluster
      #   ALB
      #   Target Group
      #   ECR Repository
      #   Task Definition
      #   Security Groups
      #   other resources owned by this stack
      # ======================================================

      - name: "Step 14 - Delete Standalone ECS ECR Stack"

        if: steps.ecs_stack.outputs.exists == 'true'

        id: delete_ecs_stack

        shell: bash

        run: |

          set -euo pipefail

          echo "=================================================="
          echo "DELETE STANDALONE ECS/ECR STACK"
          echo "=================================================="

          echo "Stack:"
          echo "  $ECS_STACK_NAME"

          STATUS=$(
            aws cloudformation describe-stacks \
              --stack-name "$ECS_STACK_NAME" \
              --region "$AWS_REGION" \
              --query "Stacks[0].StackStatus" \
              --output text \
              --no-cli-pager \
              2>/dev/null || echo "NOT_FOUND"
          )

          echo "Current status: $STATUS"

          if [[ "$STATUS" == "NOT_FOUND" ]]
          then

            echo "ECS/ECR stack already deleted."

            exit 0

          fi

          if [[ "$STATUS" == "DELETE_COMPLETE" ]]
          then

            echo "ECS/ECR stack already deleted."

            exit 0

          fi

          if [[ "$STATUS" == "DELETE_FAILED" ]]
          then

            echo "Stack is already DELETE_FAILED."

            echo "Retrying normal deletion first."

          fi

          aws cloudformation delete-stack \
            --stack-name "$ECS_STACK_NAME" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            || true

          echo ""

          echo "Waiting for ECS/ECR stack deletion..."

          for ATTEMPT in $(seq 1 80)
          do

            STATUS=$(
              aws cloudformation describe-stacks \
                --stack-name "$ECS_STACK_NAME" \
                --region "$AWS_REGION" \
                --query "Stacks[0].StackStatus" \
                --output text \
                --no-cli-pager \
                2>/dev/null || echo "NOT_FOUND"
            )

            echo "Attempt $ATTEMPT / 80"

            echo "Status: $STATUS"

            if [[ "$STATUS" == "NOT_FOUND" ]]
            then

              echo "ECS/ECR stack successfully deleted."

              exit 0

            fi

            if [[ "$STATUS" == "DELETE_COMPLETE" ]]
            then

              echo "ECS/ECR stack successfully deleted."

              exit 0

            fi

            if [[ "$STATUS" == "DELETE_FAILED" ]]
            then

              echo ""

              echo "WARNING: ECS/ECR stack DELETE_FAILED."

              break

            fi

            sleep 15

          done

          echo ""

          echo "ECS/ECR stack deletion requires further cleanup."


      # ======================================================
      # STEP 15
      # DISCOVER EC2 INSTANCES FROM ROOT STACK
      # ======================================================

      - name: "Step 15 - Discover EC2 Instances"

        if: steps.root.outputs.exists == 'true'

        id: ec2

        shell: bash

        run: |

          set -euo pipefail

          echo "=================================================="
          echo "DISCOVER EC2 INSTANCES"
          echo "=================================================="

          INSTANCE_IDS=$(
            aws cloudformation list-stack-resources \
              --stack-name "$STACK_NAME" \
              --region "$AWS_REGION" \
              --query "StackResourceSummaries[?ResourceType=='AWS::EC2::Instance'].PhysicalResourceId" \
              --output text \
              --no-cli-pager \
              2>/dev/null || true
          )

          echo "EC2 Instances:"

          echo "$INSTANCE_IDS"

          {
            echo "instances<<EOF"
            echo "$INSTANCE_IDS"
            echo "EOF"
          } >> "$GITHUB_OUTPUT"


      # ======================================================
      # STEP 16
      # CLEAN DOCKER ON EC2
      # ======================================================

      - name: "Step 16 - Clean Docker Containers And Images On EC2"

        if: steps.ec2.outputs.instances != ''

        shell: bash

        run: |

          set -euo pipefail

          echo "=================================================="
          echo "DOCKER CLEANUP ON EC2"
          echo "=================================================="

          INSTANCE_IDS="${{ steps.ec2.outputs.instances }}"

          for INSTANCE_ID in $INSTANCE_IDS
          do

            [[ -z "$INSTANCE_ID" || "$INSTANCE_ID" == "None" ]] && continue

            echo ""

            echo "EC2 Instance: $INSTANCE_ID"

            PING_STATUS=$(
              aws ssm describe-instance-information \
                --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
                --region "$AWS_REGION" \
                --query "InstanceInformationList[0].PingStatus" \
                --output text \
                --no-cli-pager \
                2>/dev/null || echo "NOT_FOUND"
            )

            echo "SSM status: $PING_STATUS"

            if [[ "$PING_STATUS" != "Online" ]]
            then

              echo "Instance is not SSM Online."

              echo "Skipping Docker cleanup."

              continue

            fi

            COMMAND_ID=$(
              aws ssm send-command \
                --instance-ids "$INSTANCE_ID" \
                --document-name "AWS-RunShellScript" \
                --comment "Charlie Cafe complete Docker cleanup" \
                --parameters 'commands=[
                  "echo === DOCKER CLEANUP START ===",
                  "if command -v docker >/dev/null 2>&1; then",
                  "  echo Docker detected.",
                  "  echo Stopping containers...",
                  "  docker stop $(docker ps -q) 2>/dev/null || true",
                  "  echo Removing containers...",
                  "  docker rm -f $(docker ps -aq) 2>/dev/null || true",
                  "  echo Removing images...",
                  "  docker image prune -af || true",
                  "  echo Removing containers...",
                  "  docker container prune -f || true",
                  "  echo Removing volumes...",
                  "  docker volume prune -f || true",
                  "  echo Removing networks...",
                  "  docker network prune -f || true",
                  "  echo Removing build cache...",
                  "  docker builder prune -af || true",
                  "  echo === DOCKER CLEANUP COMPLETE ===",
                  "else",
                  "  echo Docker is not installed.",
                  "fi"
                ]' \
                --region "$AWS_REGION" \
                --query "Command.CommandId" \
                --output text \
                --no-cli-pager
            )

            echo "SSM Command ID: $COMMAND_ID"

            for ATTEMPT in $(seq 1 30)
            do

              COMMAND_STATUS=$(
                aws ssm get-command-invocation \
                  --command-id "$COMMAND_ID" \
                  --instance-id "$INSTANCE_ID" \
                  --region "$AWS_REGION" \
                  --query "Status" \
                  --output text \
                  --no-cli-pager \
                  2>/dev/null || echo "Pending"
              )

              echo "Attempt $ATTEMPT / 30"

              echo "SSM status: $COMMAND_STATUS"

              case "$COMMAND_STATUS" in

                Success)

                  echo "Docker cleanup succeeded."

                  break

                  ;;

                Failed|Cancelled|TimedOut|Cancelling)

                  echo "WARNING: Docker cleanup failed."

                  break

                  ;;

                *)

                  sleep 5

                  ;;

              esac

            done

          done


      # ======================================================
      # STEP 17
      # DISCOVER TEMPLATE S3 BUCKET STACK
      # ======================================================

      - name: "Step 17 - Discover Template Bucket"

        id: template_s3

        shell: bash

        run: |

          set -euo pipefail

          echo "=================================================="
          echo "DISCOVER TEMPLATE S3 BUCKET"
          echo "=================================================="

          if ! aws cloudformation describe-stacks \
            --stack-name "$TEMPLATE_BUCKET_STACK" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            >/dev/null 2>&1
          then

            echo "exists=false" >> "$GITHUB_OUTPUT"

            echo "bucket=" >> "$GITHUB_OUTPUT"

            echo "Template bucket stack does not exist."

            exit 0

          fi

          BUCKET=$(
            aws cloudformation list-stack-resources \
              --stack-name "$TEMPLATE_BUCKET_STACK" \
              --region "$AWS_REGION" \
              --query "StackResourceSummaries[?ResourceType=='AWS::S3::Bucket'].PhysicalResourceId | [0]" \
              --output text \
              --no-cli-pager \
              2>/dev/null || true
          )

          echo "exists=true" >> "$GITHUB_OUTPUT"

          echo "bucket=$BUCKET" >> "$GITHUB_OUTPUT"

          echo "Template bucket: $BUCKET"


      # ======================================================
      # STEP 18
      # EMPTY VERSIONED S3 BUCKET
      # ======================================================

      - name: "Step 18 - Empty Versioned S3 Bucket"

        if: steps.template_s3.outputs.bucket != ''

        shell: bash

        run: |

          set -euo pipefail

          BUCKET="${{ steps.template_s3.outputs.bucket }}"

          echo "=================================================="
          echo "EMPTY S3 BUCKET"
          echo "=================================================="

          while true
          do

            DATA=$(
              aws s3api list-object-versions \
                --bucket "$BUCKET" \
                --region "$AWS_REGION" \
                --output json \
                --no-cli-pager
            )

            VERSION_COUNT=$(echo "$DATA" | jq '(.Versions // []) | length')

            MARKER_COUNT=$(echo "$DATA" | jq '(.DeleteMarkers // []) | length')

            TOTAL=$((VERSION_COUNT + MARKER_COUNT))

            echo "Versions       : $VERSION_COUNT"

            echo "Delete markers : $MARKER_COUNT"

            echo "Total          : $TOTAL"

            if [[ "$TOTAL" -eq 0 ]]
            then

              echo "S3 bucket is empty."

              break

            fi

            echo "$DATA" |
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

            aws s3api delete-objects \
              --bucket "$BUCKET" \
              --delete file:///tmp/s3-delete.json \
              --region "$AWS_REGION" \
              --no-cli-pager

          done


      # ======================================================
      # STEP 19
      # DELETE TEMPLATE BUCKET STACK
      # ======================================================

      - name: "Step 19 - Delete Template Bucket Stack"

        if: steps.template_s3.outputs.exists == 'true'

        shell: bash

        run: |

          set -euo pipefail

          echo "=================================================="
          echo "DELETE TEMPLATE BUCKET STACK"
          echo "=================================================="

          aws cloudformation delete-stack \
            --stack-name "$TEMPLATE_BUCKET_STACK" \
            --region "$AWS_REGION" \
            --no-cli-pager

          echo "Waiting for Template Bucket stack deletion..."

          aws cloudformation wait stack-delete-complete \
            --stack-name "$TEMPLATE_BUCKET_STACK" \
            --region "$AWS_REGION"

          echo "Template Bucket stack deleted."


      # ======================================================
      # STEP 20
      # DISCOVER RDS NESTED STACK
      # ======================================================

      - name: "Step 20 - Discover RDS Nested Stack"

        if: steps.root.outputs.exists == 'true'

        id: rds_nested

        shell: bash

        run: |

          set -euo pipefail

          RDS_NESTED_STACK_ID=$(
            aws cloudformation list-stack-resources \
              --stack-name "$STACK_NAME" \
              --region "$AWS_REGION" \
              --query "StackResourceSummaries[?LogicalResourceId=='RDSNestedStack'].PhysicalResourceId | [0]" \
              --output text \
              --no-cli-pager \
              2>/dev/null || true
          )

          echo "RDS nested stack: $RDS_NESTED_STACK_ID"

          if [[ -n "$RDS_NESTED_STACK_ID" &&
                "$RDS_NESTED_STACK_ID" != "None" ]]
          then

            echo "nested=$RDS_NESTED_STACK_ID" >> "$GITHUB_OUTPUT"

          else

            echo "nested=" >> "$GITHUB_OUTPUT"

          fi


      # ======================================================
      # STEP 21
      # DISCOVER RDS INSTANCE
      # ======================================================

      - name: "Step 21 - Discover RDS Instance"

        if: steps.rds_nested.outputs.nested != ''

        id: rds

        shell: bash

        run: |

          set -euo pipefail

          RDS_INSTANCE=$(
            aws cloudformation describe-stack-resources \
              --stack-name "${{ steps.rds_nested.outputs.nested }}" \
              --region "$AWS_REGION" \
              --logical-resource-id RDSDatabase \
              --query "StackResources[0].PhysicalResourceId" \
              --output text \
              --no-cli-pager \
              2>/dev/null || true
          )

          echo "RDS instance: $RDS_INSTANCE"

          if [[ -n "$RDS_INSTANCE" &&
                "$RDS_INSTANCE" != "None" ]]
          then

            echo "instance=$RDS_INSTANCE" >> "$GITHUB_OUTPUT"

          else

            echo "instance=" >> "$GITHUB_OUTPUT"

          fi


      # ======================================================
      # STEP 22
      # DISABLE RDS DELETION PROTECTION
      # ======================================================

      - name: "Step 22 - Disable RDS Deletion Protection"

        if: steps.rds.outputs.instance != ''

        shell: bash

        run: |

          set -euo pipefail

          RDS_INSTANCE="${{ steps.rds.outputs.instance }}"

          echo "=================================================="
          echo "RDS DELETION PROTECTION"
          echo "=================================================="

          PROTECTION=$(
            aws rds describe-db-instances \
              --db-instance-identifier "$RDS_INSTANCE" \
              --region "$AWS_REGION" \
              --query "DBInstances[0].DeletionProtection" \
              --output text \
              --no-cli-pager \
              2>/dev/null || echo "NOT_FOUND"
          )

          echo "RDS instance: $RDS_INSTANCE"

          echo "Deletion protection: $PROTECTION"

          if [[ "$PROTECTION" == "True" ]]
          then

            echo "Disabling deletion protection..."

            aws rds modify-db-instance \
              --db-instance-identifier "$RDS_INSTANCE" \
              --no-deletion-protection \
              --apply-immediately \
              --region "$AWS_REGION" \
              --no-cli-pager

          else

            echo "RDS deletion protection already disabled."

          fi


      # ======================================================
      # STEP 23
      # DISCOVER NESTED ECS STACK
      # ======================================================
      #
      # IMPORTANT:
      #
      # We ONLY discover it.
      #
      # We do NOT directly delete it.
      #
      # If ECSStack is genuinely nested under the root stack,
      # CloudFormation will delete it as part of root deletion.
      # ======================================================

      - name: "Step 23 - Discover Nested ECS Stack"

        if: steps.root.outputs.exists == 'true'

        id: nested_ecs

        shell: bash

        run: |

          set -euo pipefail

          ECS_NESTED_STACK_ID=$(
            aws cloudformation list-stack-resources \
              --stack-name "$STACK_NAME" \
              --region "$AWS_REGION" \
              --query "StackResourceSummaries[?LogicalResourceId=='ECSStack'].PhysicalResourceId | [0]" \
              --output text \
              --no-cli-pager \
              2>/dev/null || true
          )

          echo "Nested ECS stack: $ECS_NESTED_STACK_ID"

          if [[ -n "$ECS_NESTED_STACK_ID" &&
                "$ECS_NESTED_STACK_ID" != "None" ]]
          then

            echo "nested=$ECS_NESTED_STACK_ID" >> "$GITHUB_OUTPUT"

            echo ""
            echo "Nested ECS stack detected."

            echo "It will be deleted by the ROOT stack."

          else

            echo "nested=" >> "$GITHUB_OUTPUT"

            echo "No nested ECS stack found."

          fi


      # ======================================================
      # STEP 24
      # DISABLE ROOT TERMINATION PROTECTION
      # ======================================================

      - name: "Step 24 - Disable Root Termination Protection"

        if: steps.root.outputs.exists == 'true'

        shell: bash

        run: |

          set -euo pipefail

          echo "=================================================="
          echo "DISABLE ROOT TERMINATION PROTECTION"
          echo "=================================================="

          aws cloudformation update-termination-protection \
            --stack-name "$STACK_NAME" \
            --no-enable-termination-protection \
            --region "$AWS_REGION" \
            --no-cli-pager \
            2>/dev/null \
            || true

          echo "Root termination protection disabled or already disabled."


      # ======================================================
      # STEP 25
      # DELETE ROOT STACK
      # ======================================================
      #
      # At this point:
      #
      # - Standalone ECS/ECR stack was deleted
      # - ECR images were deleted
      # - Docker was cleaned
      # - Template S3 stack was deleted
      # - RDS deletion protection was disabled
      #
      # NOW the root stack can delete its nested stacks.
      # ======================================================

      - name: "Step 25 - Delete Root CloudFormation Stack"

        if: steps.root.outputs.exists == 'true'

        id: root_delete

        shell: bash

        run: |

          set -euo pipefail

          echo "=================================================="
          echo "DELETE ROOT CLOUDFORMATION STACK"
          echo "=================================================="

          STATUS=$(
            aws cloudformation describe-stacks \
              --stack-name "$STACK_NAME" \
              --region "$AWS_REGION" \
              --query "Stacks[0].StackStatus" \
              --output text \
              --no-cli-pager \
              2>/dev/null || echo "NOT_FOUND"
          )

          echo "Current root status: $STATUS"

          if [[ "$STATUS" == "NOT_FOUND" ]]
          then

            echo "Root stack already deleted."

            exit 0

          fi

          if [[ "$STATUS" == "DELETE_IN_PROGRESS" ]]
          then

            echo "Root stack deletion already in progress."

            exit 0

          fi

          if [[ "$STATUS" == "DELETE_FAILED" ]]
          then

            echo "Root stack is DELETE_FAILED."

            echo "Attempting FORCE_DELETE_STACK."

            aws cloudformation delete-stack \
              --stack-name "$STACK_NAME" \
              --deletion-mode FORCE_DELETE_STACK \
              --region "$AWS_REGION" \
              --no-cli-pager

          else

            aws cloudformation delete-stack \
              --stack-name "$STACK_NAME" \
              --region "$AWS_REGION" \
              --no-cli-pager

            echo "Root deletion started."

          fi


      # ======================================================
      # STEP 26
      # MONITOR ROOT DELETION
      # ======================================================

      - name: "Step 26 - Monitor Root Stack Deletion"

        if: steps.root.outputs.exists == 'true'

        id: root_wait

        shell: bash

        run: |

          set -u

          echo "=================================================="
          echo "MONITOR ROOT STACK DELETION"
          echo "=================================================="

          MAX_SECONDS="$ROOT_DELETE_WAIT_SECONDS"

          ELAPSED=0

          while [[ "$ELAPSED" -lt "$MAX_SECONDS" ]]
          do

            STATUS=$(
              aws cloudformation describe-stacks \
                --stack-name "$STACK_NAME" \
                --region "$AWS_REGION" \
                --query "Stacks[0].StackStatus" \
                --output text \
                --no-cli-pager \
                2>/dev/null || echo "NOT_FOUND"
            )

            echo ""

            echo "Elapsed: ${ELAPSED}s"

            echo "Status : $STATUS"

            if [[ "$STATUS" == "NOT_FOUND" ]]
            then

              echo "deleted=true" >> "$GITHUB_OUTPUT"

              echo "status=NOT_FOUND" >> "$GITHUB_OUTPUT"

              echo "ROOT STACK DELETED."

              exit 0

            fi

            case "$STATUS" in

              DELETE_COMPLETE)

                echo "deleted=true" >> "$GITHUB_OUTPUT"

                echo "status=$STATUS" >> "$GITHUB_OUTPUT"

                echo "ROOT STACK DELETED."

                exit 0

                ;;

              DELETE_FAILED)

                echo "deleted=false" >> "$GITHUB_OUTPUT"

                echo "status=$STATUS" >> "$GITHUB_OUTPUT"

                echo "ROOT STACK DELETE_FAILED."

                exit 0

                ;;

            esac

            sleep 15

            ELAPSED=$((ELAPSED + 15))

          done

          echo "deleted=false" >> "$GITHUB_OUTPUT"

          echo "status=TIMEOUT" >> "$GITHUB_OUTPUT"

          echo ""

          echo "Root deletion timed out."


      # ======================================================
      # STEP 27
      # INSPECT DELETE FAILED RESOURCES
      # ======================================================

      - name: "Step 27 - Inspect DELETE_FAILED Resources"

        if: |
          steps.root.outputs.exists == 'true' &&
          steps.root_wait.outputs.deleted == 'false'

        shell: bash

        run: |

          set +e

          echo "=================================================="
          echo "ROOT DELETE FAILED RESOURCES"
          echo "=================================================="

          aws cloudformation describe-stack-events \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION" \
            --query "StackEvents[?ResourceStatus=='DELETE_FAILED'].[Timestamp,LogicalResourceId,ResourceType,ResourceStatusReason]" \
            --output table \
            --no-cli-pager

          echo ""

          echo "CURRENT ROOT RESOURCES"

          aws cloudformation list-stack-resources \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION" \
            --query "StackResourceSummaries[].[LogicalResourceId,ResourceType,ResourceStatus,PhysicalResourceId]" \
            --output table \
            --no-cli-pager


      # ======================================================
      # STEP 28
      # RETRY ECS SERVICE CLEANUP
      # ======================================================

      - name: "Step 28 - Retry Nested ECS Service Cleanup"

        if: |
          steps.root.outputs.exists == 'true' &&
          steps.root_wait.outputs.deleted == 'false'

        shell: bash

        run: |

          set -u

          echo "=================================================="
          echo "RETRY NESTED ECS CLEANUP"
          echo "=================================================="

          if [[ -z "${{ steps.nested_ecs.outputs.nested }}" ]]
          then

            echo "No nested ECS stack."

            exit 0

          fi

          NESTED_STACK="${{ steps.nested_ecs.outputs.nested }}"

          ECS_CLUSTER=$(
            aws cloudformation list-stack-resources \
              --stack-name "$NESTED_STACK" \
              --region "$AWS_REGION" \
              --query "StackResourceSummaries[?ResourceType=='AWS::ECS::Cluster'].PhysicalResourceId | [0]" \
              --output text \
              --no-cli-pager \
              2>/dev/null || true
          )

          ECS_SERVICE=$(
            aws cloudformation list-stack-resources \
              --stack-name "$NESTED_STACK" \
              --region "$AWS_REGION" \
              --query "StackResourceSummaries[?ResourceType=='AWS::ECS::Service'].PhysicalResourceId | [0]" \
              --output text \
              --no-cli-pager \
              2>/dev/null || true
          )

          echo "Cluster: $ECS_CLUSTER"

          echo "Service: $ECS_SERVICE"

          if [[ -n "$ECS_CLUSTER" &&
                "$ECS_CLUSTER" != "None" &&
                -n "$ECS_SERVICE" &&
                "$ECS_SERVICE" != "None" ]]
          then

            aws ecs update-service \
              --cluster "$ECS_CLUSTER" \
              --service "$ECS_SERVICE" \
              --desired-count 0 \
              --region "$AWS_REGION" \
              --no-cli-pager \
              || true

            sleep 20

          fi


      # ======================================================
      # STEP 29
      # RETRY ALB CLEANUP
      # ======================================================

      - name: "Step 29 - Retry ALB Cleanup"

        if: |
          steps.root.outputs.exists == 'true' &&
          steps.root_wait.outputs.deleted == 'false'

        shell: bash

        run: |

          set -u

          echo "=================================================="
          echo "RETRY ALB CLEANUP"
          echo "=================================================="

          ALB_ARN=""

          if [[ -n "${{ steps.nested_ecs.outputs.nested }}" ]]
          then

            ALB_ARN=$(
              aws cloudformation list-stack-resources \
                --stack-name "${{ steps.nested_ecs.outputs.nested }}" \
                --region "$AWS_REGION" \
                --query "StackResourceSummaries[?ResourceType=='AWS::ElasticLoadBalancingV2::LoadBalancer'].PhysicalResourceId | [0]" \
                --output text \
                --no-cli-pager \
                2>/dev/null || true
            )

          fi

          echo "ALB: $ALB_ARN"

          if [[ -n "$ALB_ARN" && "$ALB_ARN" != "None" ]]
          then

            aws elbv2 delete-load-balancer \
              --load-balancer-arn "$ALB_ARN" \
              --region "$AWS_REGION" \
              --no-cli-pager \
              || true

          else

            echo "No ALB found."

          fi


      # ======================================================
      # STEP 30
      # RETRY TARGET GROUP CLEANUP
      # ======================================================

      - name: "Step 30 - Retry Target Group Cleanup"

        if: |
          steps.root.outputs.exists == 'true' &&
          steps.root_wait.outputs.deleted == 'false'

        shell: bash

        run: |

          set -u

          echo "=================================================="
          echo "RETRY TARGET GROUP CLEANUP"
          echo "=================================================="

          TARGET_GROUP_ARN=""

          if [[ -n "${{ steps.nested_ecs.outputs.nested }}" ]]
          then

            TARGET_GROUP_ARN=$(
              aws cloudformation list-stack-resources \
                --stack-name "${{ steps.nested_ecs.outputs.nested }}" \
                --region "$AWS_REGION" \
                --query "StackResourceSummaries[?ResourceType=='AWS::ElasticLoadBalancingV2::TargetGroup'].PhysicalResourceId | [0]" \
                --output text \
                --no-cli-pager \
                2>/dev/null || true
            )

          fi

          echo "Target Group: $TARGET_GROUP_ARN"

          if [[ -n "$TARGET_GROUP_ARN" &&
                "$TARGET_GROUP_ARN" != "None" ]]
          then

            aws elbv2 delete-target-group \
              --target-group-arn "$TARGET_GROUP_ARN" \
              --region "$AWS_REGION" \
              --no-cli-pager \
              || true

          else

            echo "No target group found."

          fi


      # ======================================================
      # STEP 31
      # RETRY ROOT STACK DELETION
      # ======================================================

      - name: "Step 31 - Retry Root Stack Deletion"

        if: |
          steps.root.outputs.exists == 'true' &&
          steps.root_wait.outputs.deleted == 'false'

        shell: bash

        run: |

          set -u

          echo "=================================================="
          echo "RETRY ROOT STACK DELETION"
          echo "=================================================="

          STATUS=$(
            aws cloudformation describe-stacks \
              --stack-name "$STACK_NAME" \
              --region "$AWS_REGION" \
              --query "Stacks[0].StackStatus" \
              --output text \
              --no-cli-pager \
              2>/dev/null || echo "NOT_FOUND"
          )

          echo "Current status: $STATUS"

          if [[ "$STATUS" == "NOT_FOUND" ]]
          then

            echo "Root stack already deleted."

            exit 0

          fi

          if [[ "$STATUS" == "DELETE_FAILED" ]]
          then

            echo "Retrying with FORCE_DELETE_STACK."

            aws cloudformation delete-stack \
              --stack-name "$STACK_NAME" \
              --deletion-mode FORCE_DELETE_STACK \
              --region "$AWS_REGION" \
              --no-cli-pager \
              || true

          elif [[ "$STATUS" == "DELETE_IN_PROGRESS" ]]
          then

            echo "Deletion already in progress."

          else

            aws cloudformation delete-stack \
              --stack-name "$STACK_NAME" \
              --region "$AWS_REGION" \
              --no-cli-pager \
              || true

          fi


      # ======================================================
      # STEP 32
      # FINAL ROOT DELETION WAIT
      # ======================================================

      - name: "Step 32 - Final Root Deletion Wait"

        if: |
          steps.root.outputs.exists == 'true' &&
          steps.root_wait.outputs.deleted == 'false'

        shell: bash

        run: |

          set +e

          echo "=================================================="
          echo "FINAL ROOT DELETION WAIT"
          echo "=================================================="

          for ATTEMPT in $(seq 1 80)
          do

            STATUS=$(
              aws cloudformation describe-stacks \
                --stack-name "$STACK_NAME" \
                --region "$AWS_REGION" \
                --query "Stacks[0].StackStatus" \
                --output text \
                --no-cli-pager \
                2>/dev/null || echo "NOT_FOUND"
            )

            echo "Attempt $ATTEMPT / 80"

            echo "Status: $STATUS"

            if [[ "$STATUS" == "NOT_FOUND" ]]
            then

              echo "ROOT STACK DELETED."

              exit 0

            fi

            if [[ "$STATUS" == "DELETE_COMPLETE" ]]
            then

              echo "ROOT STACK DELETED."

              exit 0

            fi

            if [[ "$STATUS" == "DELETE_FAILED" ]]
            then

              echo "Root stack still DELETE_FAILED."

              exit 0

            fi

            sleep 15

          done

          echo "Final root deletion wait completed."


      # ======================================================
      # STEP 33
      # VERIFY STANDALONE ECS STACK
      # ======================================================

      - name: "Step 33 - Verify Standalone ECS Stack"

        shell: bash

        run: |

          set +e

          echo "=================================================="
          echo "VERIFY STANDALONE ECS STACK"
          echo "=================================================="

          if aws cloudformation describe-stacks \
            --stack-name "$ECS_STACK_NAME" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            >/dev/null 2>&1
          then

            aws cloudformation describe-stacks \
              --stack-name "$ECS_STACK_NAME" \
              --region "$AWS_REGION" \
              --query "Stacks[0].[StackName,StackStatus]" \
              --output table \
              --no-cli-pager

            echo ""

            echo "WARNING: Standalone ECS/ECR stack still exists."

          else

            echo "Standalone ECS/ECR stack deleted."

          fi


      # ======================================================
      # STEP 34
      # VERIFY ECS
      # ======================================================

      - name: "Step 34 - Verify ECS"

        shell: bash

        run: |

          set +e

          echo "=================================================="
          echo "FINAL ECS VERIFICATION"
          echo "=================================================="

          aws ecs list-clusters \
            --region "$AWS_REGION" \
            --output table \
            --no-cli-pager

          echo ""

          echo "If the Charlie Cafe ECS cluster was deleted, it should"
          echo "no longer appear in the list above."


      # ======================================================
      # STEP 35
      # VERIFY ECR
      # ======================================================

      - name: "Step 35 - Verify ECR"

        shell: bash

        run: |

          set +e

          echo "=================================================="
          echo "FINAL ECR VERIFICATION"
          echo "=================================================="

          aws ecr describe-repositories \
            --region "$AWS_REGION" \
            --query "repositories[].[repositoryName,repositoryUri]" \
            --output table \
            --no-cli-pager

          echo ""

          echo "If charlie-cafe is absent, the ECR repository was deleted."


      # ======================================================
      # STEP 36
      # VERIFY TEMPLATE BUCKET STACK
      # ======================================================

      - name: "Step 36 - Verify Template Bucket Stack"

        shell: bash

        run: |

          set +e

          echo "=================================================="
          echo "FINAL S3 STACK VERIFICATION"
          echo "=================================================="

          if aws cloudformation describe-stacks \
            --stack-name "$TEMPLATE_BUCKET_STACK" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            >/dev/null 2>&1
          then

            echo "WARNING: Template Bucket stack still exists."

            aws cloudformation describe-stacks \
              --stack-name "$TEMPLATE_BUCKET_STACK" \
              --region "$AWS_REGION" \
              --query "Stacks[0].[StackName,StackStatus]" \
              --output table \
              --no-cli-pager

          else

            echo "Template Bucket stack deleted."

          fi


      # ======================================================
      # STEP 37
      # VERIFY ROOT STACK
      # ======================================================

      - name: "Step 37 - Verify Root Stack"

        shell: bash

        run: |

          set +e

          echo "=================================================="
          echo "FINAL ROOT STACK VERIFICATION"
          echo "=================================================="

          if aws cloudformation describe-stacks \
            --stack-name "$STACK_NAME" \
            --region "$AWS_REGION" \
            --no-cli-pager \
            >/dev/null 2>&1
          then

            STATUS=$(
              aws cloudformation describe-stacks \
                --stack-name "$STACK_NAME" \
                --region "$AWS_REGION" \
                --query "Stacks[0].StackStatus" \
                --output text \
                --no-cli-pager
            )

            echo "WARNING: Root stack still exists."

            echo "Status: $STATUS"

          else

            echo "Root stack deleted successfully."

          fi


      # ======================================================
      # STEP 38
      # FINAL CLOUDFORMATION VERIFICATION
      # ======================================================

      - name: "Step 38 - Final CloudFormation Verification"

        shell: bash

        run: |

          set +e

          echo "=================================================="
          echo "FINAL CLOUDFORMATION VERIFICATION"
          echo "=================================================="

          aws cloudformation list-stacks \
            --region "$AWS_REGION" \
            --stack-status-filter \
              CREATE_IN_PROGRESS \
              CREATE_FAILED \
              CREATE_COMPLETE \
              ROLLBACK_IN_PROGRESS \
              ROLLBACK_FAILED \
              ROLLBACK_COMPLETE \
              UPDATE_IN_PROGRESS \
              UPDATE_COMPLETE \
              UPDATE_ROLLBACK_IN_PROGRESS \
              UPDATE_ROLLBACK_FAILED \
              UPDATE_ROLLBACK_COMPLETE \
              DELETE_IN_PROGRESS \
              DELETE_FAILED \
            --query "StackSummaries[?contains(StackName, 'Lab01-CloudFormation') || contains(StackName, 'CharlieCafe-ECS-Stack')].[StackName,StackStatus]" \
            --output table \
            --no-cli-pager


      # ======================================================
      # STEP 39
      # FINAL CLEANUP SUMMARY
      # ======================================================

      - name: "Step 39 - Final Cleanup Summary"

        shell: bash

        run: |

          echo ""

          echo "=========================================================="

          echo "              AWS LAB CLEANUP SUMMARY"

          echo "=========================================================="

          echo ""

          echo "AWS Region:"
          echo "  $AWS_REGION"

          echo ""

          echo "Standalone ECS/ECR Stack:"
          echo "  $ECS_STACK_NAME"

          echo ""

          echo "Root Stack:"
          echo "  $STACK_NAME"

          echo ""

          echo "Template Bucket Stack:"
          echo "  $TEMPLATE_BUCKET_STACK"

          echo ""

          echo "=========================================================="

          echo "FINAL DELETION ORDER"

          echo "=========================================================="

          echo ""

          echo "  1. Discover Root Stack"

          echo "  2. Discover CharlieCafe-ECS-Stack"

          echo "  3. Stop ECS Service"

          echo "  4. Wait for ECS Tasks"

          echo "  5. Delete ECR Images"

          echo "  6. Delete CharlieCafe-ECS-Stack"

          echo "  7. Clean Docker Containers"

          echo "  8. Clean Docker Images"

          echo "  9. Clean Docker Volumes"

          echo " 10. Clean Docker Networks"

          echo " 11. Empty S3 Template Bucket"

          echo " 12. Delete Template Bucket Stack"

          echo " 13. Disable RDS Deletion Protection"

          echo " 14. Discover Nested ECS Stack"

          echo " 15. Delete ROOT Stack"

          echo " 16. CloudFormation Deletes Nested Stacks"

          echo " 17. Monitor Root Deletion"

          echo " 18. Inspect DELETE_FAILED Resources"

          echo " 19. Retry ECS Cleanup"

          echo " 20. Retry ALB Cleanup"

          echo " 21. Retry Target Group Cleanup"

          echo " 22. FORCE_DELETE_STACK if required"

          echo " 23. Verify ECS"

          echo " 24. Verify ECR"

          echo " 25. Verify S3"

          echo " 26. Verify CloudFormation"

          echo ""

          echo "=========================================================="

          echo "           CLEANUP WORKFLOW FINISHED"

          echo "=========================================================="
```

---