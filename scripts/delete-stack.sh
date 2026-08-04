#!/bin/bash

# ==========================================
# AWS CloudFormation Stack Deletion Script
# Purpose:
#   Deletes an existing CloudFormation stack
#   and waits until the deletion is complete.
#
# Prerequisites:
#   - AWS CLI installed
#   - AWS CLI configured (aws configure)
#   - IAM user/role with CloudFormation permissions
# ==========================================

# Name of the CloudFormation stack to delete
STACK_NAME="Lab01-CloudFormation"

# AWS Region where the stack exists
REGION="us-east-1"

# Display a message to the user
echo "Deleting CloudFormation stack: $STACK_NAME"

# Delete the CloudFormation stack
aws cloudformation delete-stack \
  --stack-name "$STACK_NAME" \
  --region "$REGION"

# Inform the user that the script is waiting
echo "Waiting for stack deletion..."

# Wait until AWS confirms the stack has been deleted
aws cloudformation wait stack-delete-complete \
  --stack-name "$STACK_NAME" \
  --region "$REGION"

# Display a success message
echo "========================================="
echo "CloudFormation stack deleted successfully!"
echo "========================================="