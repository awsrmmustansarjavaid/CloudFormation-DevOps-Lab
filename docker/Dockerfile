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
# 9. Expose Container Port
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
# 10. Container Startup Command
# ==========================================================
#
# The container needs both:
#
# 1. PHP-FPM
# 2. Nginx
#
# PHP-FPM handles PHP execution.
#
# Nginx handles HTTP requests.
#
# Nginx runs in the foreground so that Docker can monitor
# the main container process.
# ==========================================================

CMD ["bash", "-c", "php-fpm8.3 -D && nginx -g 'daemon off;'"]