#!/bin/bash

###############################################################################
# Script Name : git-workflow.sh
# Description : Standard Git workflow for updating a local repository
# Author      : Raja Muhammad Mustansar Javaid
###############################################################################

###############################################################################
# STEP 1 - Check Repository Status
###############################################################################

# Display the current status of the Git repository.
# This shows:
#   - Modified files
#   - New (untracked) files
#   - Deleted files
#   - Files already staged for commit
echo "==============================="
echo "Step 1 - Checking Git Status"
echo "==============================="

git status

###############################################################################
# STEP 2 - Stage Changes
###############################################################################

# Option 1
# Stage a single file.
# Uncomment this line if you only want to commit one file.

# git add README.md

# Option 2
# Stage every modified, new, and deleted file.

echo ""
echo "==============================="
echo "Step 2 - Staging Files"
echo "==============================="

git add .

###############################################################################
# STEP 3 - Verify Staged Changes
###############################################################################

# Verify which files are staged and ready to be committed.

echo ""
echo "==============================="
echo "Step 3 - Verify Staged Files"
echo "==============================="

git status

###############################################################################
# STEP 4 - Commit Changes
###############################################################################

# Save the staged files to the local Git history.
# Replace the commit message with a meaningful description.

echo ""
echo "==============================="
echo "Step 4 - Creating Commit"
echo "==============================="

git commit -m "Describe your changes"

###############################################################################
# Examples of Good Commit Messages
###############################################################################

# git commit -m "Add VPC CloudFormation template"
# git commit -m "Update Docker configuration"
# git commit -m "Fix EC2 deployment script"
# git commit -m "Add GitHub Actions workflow"
# git commit -m "Improve project documentation"

###############################################################################
# STEP 5 - Push Changes to GitHub
###############################################################################

# Upload the latest commit to the remote GitHub repository.
# Since the local 'main' branch already tracks 'origin/main',
# you only need the following command.

echo ""
echo "==============================="
echo "Step 5 - Pushing to GitHub"
echo "==============================="

git push

###############################################################################
# Git Workflow Complete
###############################################################################

echo ""
echo "=============================================="
echo " Git workflow completed successfully!"
echo "=============================================="