#!/bin/bash

# ==========================================================
# verify-docker.sh
# ==========================================================
#
# Purpose:
# Verify that the Docker container is running and that
# the required development tools are installed correctly.
#
# This script checks:
# - AWS CLI
# - Git
# - Python 3
# - Bash
# - Current working directory
# - Project files
#
# ==========================================================

echo "==========================================="
echo " AWS DevOps CloudFormation Lab Verification"
echo "==========================================="
echo

# Verify container is running
echo "Checking Docker container..."
docker ps --filter "name=aws-cloudformation-lab"

echo
echo "==========================================="
echo "Verifying installed tools..."
echo "==========================================="
echo

docker exec aws-cloudformation-lab aws --version
echo

docker exec aws-cloudformation-lab git --version
echo

docker exec aws-cloudformation-lab python3 --version
echo

docker exec aws-cloudformation-lab bash --version | head -n 1
echo

echo "==========================================="
echo "Current Working Directory"
echo "==========================================="
docker exec aws-cloudformation-lab pwd
echo

echo "==========================================="
echo "Project Files"
echo "==========================================="
docker exec aws-cloudformation-lab ls -la /workspace
echo

echo "==========================================="
echo "Verification Complete"
echo "==========================================="