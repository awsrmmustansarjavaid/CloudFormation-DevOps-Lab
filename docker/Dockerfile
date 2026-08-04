# ==========================================================
# AWS DevOps CloudFormation Lab Docker Image
# ==========================================================
#
# Purpose:
# - Lightweight Linux development environment
# - Install AWS CLI
# - Install Git
# - Install Bash
# - Install Python 3
# - Practice AWS CLI and CloudFormation
# - Use as a reusable DevOps lab container
#
# Base OS:
# Alpine Linux (Small, fast, secure)
#
# ==========================================================

# ----------------------------------------------------------
# Base Image
# ----------------------------------------------------------
# Use the latest Alpine Linux image.
# Alpine is very small compared to Ubuntu,
# making Docker images faster to download and build.
# ----------------------------------------------------------
FROM alpine:latest

# ----------------------------------------------------------
# Image Metadata (Optional but Recommended)
# ----------------------------------------------------------
LABEL maintainer="IT Charlie"
LABEL project="AWS DevOps CloudFormation Lab"
LABEL description="Docker development environment for AWS CloudFormation practice"

# ----------------------------------------------------------
# Update Package Index and Install Required Packages
# ----------------------------------------------------------
# Install:
#
# bash      -> Linux shell
# git       -> Version control
# curl      -> Download files
# unzip     -> Extract archives
# python3   -> Required for AWS CLI
# py3-pip   -> Python package manager
#
# --no-cache keeps the image smaller by avoiding
# cached package indexes.
# ----------------------------------------------------------
RUN apk update && \
    apk add --no-cache \
        bash \
        git \
        curl \
        unzip \
        python3 \
        py3-pip

# ----------------------------------------------------------
# Install AWS CLI
# ----------------------------------------------------------
# Install the latest AWS CLI using pip.
#
# --no-cache-dir prevents pip from storing
# unnecessary cache files, reducing image size.
# ----------------------------------------------------------
RUN pip3 install --no-cache-dir awscli

# ----------------------------------------------------------
# Verify Installed Tools
# ----------------------------------------------------------
# Display installed versions during the image build.
# This helps detect installation issues immediately.
# ----------------------------------------------------------
RUN aws --version && \
    git --version && \
    python3 --version && \
    bash --version

# ----------------------------------------------------------
# Create Working Directory
# ----------------------------------------------------------
# All project files will be accessed from /workspace.
# Docker Compose will mount the project folder here.
# ----------------------------------------------------------
WORKDIR /workspace

# ----------------------------------------------------------
# Copy Project Files
# ----------------------------------------------------------
# Copies the project into the image.
#
# Note:
# During development, Docker Compose mounts the project
# directory as a volume, so this copy is mainly useful
# when the image is run without a mounted volume.
# ----------------------------------------------------------
COPY . .

# ----------------------------------------------------------
# Default Command
# ----------------------------------------------------------
# Start an interactive Bash shell when the container starts.
# ----------------------------------------------------------
CMD ["/bin/bash"]