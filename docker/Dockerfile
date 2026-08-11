# ==========================================================
# AWS CloudFormation DevOps Lab
# Dockerfile
# ==========================================================
#
# Author : IT Charlie
#
# Purpose
# ----------------------------------------------------------
# Creates a complete Linux development environment for
# AWS CloudFormation practice.
#
# Installed Software
#
# • AWS CLI v2
# • Git
# • Bash
# • Python 3
# • Pip
# • curl
# • wget
# • unzip
# • zip
# • jq
# • tree
# • vim
# • nano
# • OpenSSH Client
# • less
# • groff
#
# ==========================================================

# ----------------------------------------------------------
# Base Image
# ----------------------------------------------------------

FROM ubuntu:24.04

# ----------------------------------------------------------
# Image Metadata
# ----------------------------------------------------------

LABEL maintainer="IT Charlie"

LABEL project="AWS CloudFormation DevOps Lab"

LABEL description="Docker development environment for AWS CloudFormation"

# ----------------------------------------------------------
# Prevent Interactive Installation
# ----------------------------------------------------------

ENV DEBIAN_FRONTEND=noninteractive

# ----------------------------------------------------------
# Update Ubuntu
# ----------------------------------------------------------

RUN apt-get update && \
    apt-get install -y \
    bash \
    git \
    curl \
    wget \
    unzip \
    zip \
    less \
    groff \
    jq \
    tree \
    nano \
    vim \
    make \
    python3 \
    python3-pip \
    openssh-client \
    ca-certificates \
    mariadb-server \
    mariadb-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------
# Install AWS CLI Version 2
# ----------------------------------------------------------

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# ----------------------------------------------------------
# Verify Installation
# ----------------------------------------------------------

RUN echo "=====================================" && \
    echo "Installed Versions" && \
    echo "=====================================" && \
    aws --version && \
    git --version && \
    python3 --version && \
    bash --version | head -n 1

# ----------------------------------------------------------
# Working Directory
# ----------------------------------------------------------

WORKDIR /workspace

# ----------------------------------------------------------
# MariaDB Port
# ----------------------------------------------------------

EXPOSE 3306

# ----------------------------------------------------------

# Default Shell / Container Startup Command

# ----------------------------------------------------------

# Original command:

# Keeps the Docker container running without starting MariaDB.

# This command is not used because MariaDB must start

# automatically when the container starts.

# CMD ["tail","-f","/dev/null"]

# Starts the MariaDB service and keeps the container running.

CMD ["bash", "-c", "service mariadb start && tail -f /dev/null"]
