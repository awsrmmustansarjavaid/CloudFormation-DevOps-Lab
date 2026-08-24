# Complete AWS CloudFormation Lab Verification Guide

## How to Fully Test a Beginner AWS CloudFormation DevOps Lab

Building AWS infrastructure with CloudFormation is only half of the learning process.

The other half is **verification**.

A stack showing:

```text
CREATE_COMPLETE
```

does not automatically mean that the complete application architecture is working correctly.

For a proper CloudFormation lab, we should verify:

* CloudFormation templates
* Main stack
* Nested stacks
* VPC
* Internet Gateway
* Public subnets
* Private subnets
* Route tables
* Security Groups
* EC2
* UserData
* S3
* RDS MySQL
* Secrets Manager
* ECR
* ECS Fargate
* VPC Endpoints
* Application Load Balancer
* CloudWatch Logs
* IAM roles
* End-to-end application connectivity
* Stack deletion and cleanup

This article provides a complete verification checklist and practical commands.

---

# 1. Understand the Architecture Before Testing

Your lab contains two major CloudFormation architectures.

## Architecture 1 — Main CloudFormation Stack

The main stack creates:

```text
CloudFormation Main Stack
        |
        +-- VPC
        |
        +-- Internet Gateway
        |
        +-- Public Subnet 1
        |
        +-- Public Subnet 2
        |
        +-- Private Subnet 1
        |
        +-- Private Subnet 2
        |
        +-- Public Route Table
        |
        +-- Private Route Table
        |
        +-- Web Security Group
        |
        +-- EC2 Nested Stack
        |      |
        |      +-- EC2 Instance
        |
        +-- S3 Nested Stack
        |      |
        |      +-- S3 Bucket
        |
        +-- RDS Nested Stack
               |
               +-- RDS MySQL
               +-- RDS Security Group
               +-- RDS Subnet Group
               +-- Secrets Manager Secret
```

## Architecture 2 — Independent ECS Stack

Your ECS stack is separate from the main stack.

```text
Existing VPC
     |
     +-----------------------------+
     |                             |
 Public Subnets              Private Subnets
     |                             |
     v                             v
    ALB                      ECS Fargate Tasks
     |                             |
     |                             +---- ECR
     |                             |
     |                             +---- S3 Endpoint
     |                             |
     |                             +---- CloudWatch Logs
     |
     v
Internet
```

This distinction is important.

Your ECS stack **consumes networking created by the main stack**.

---

# 2. Test #1 — Validate All CloudFormation Templates

Before creating anything, validate every template.

For example:

```bash
aws cloudformation validate-template \
  --template-body file://templates/main.yaml
```

Validate the ECS template:

```bash
aws cloudformation validate-template \
  --template-body file://templates/aws-ecs-ecr.yaml
```

Validate RDS:

```bash
aws cloudformation validate-template \
  --template-body file://templates/aws-rds.yaml
```

Validate EC2:

```bash
aws cloudformation validate-template \
  --template-body file://templates/ec2-webserver.yaml
```

Validate S3:

```bash
aws cloudformation validate-template \
  --template-body file://templates/s3.yaml
```

Validate the template-bucket template:

```bash
aws cloudformation validate-template \
  --template-body file://templates/template-bucket.yaml
```

Expected result:

```text
Parameters:
...
Description:
...
```

The important thing is that CloudFormation does not return a validation error.

---

# 3. Test #2 — Check the Main Stack

First retrieve the stack status.

```bash
aws cloudformation describe-stacks \
  --stack-name CloudFormation-DevOps-Lab
```

Look for:

```text
StackStatus: CREATE_COMPLETE
```

You can also use:

```bash
aws cloudformation describe-stack-events \
  --stack-name CloudFormation-DevOps-Lab
```

Check for:

```text
CREATE_COMPLETE
```

and make sure there are no resources stuck in:

```text
CREATE_FAILED
ROLLBACK_FAILED
UPDATE_FAILED
```

---

# 4. Test #3 — Check Nested Stacks

Your main stack creates three nested stacks:

```text
EC2WebServerStack
S3NestedStack
RDSNestedStack
```

Run:

```bash
aws cloudformation list-stack-resources \
  --stack-name CloudFormation-DevOps-Lab
```

Verify that the nested stack resources exist.

Then check each nested stack.

For example:

```bash
aws cloudformation describe-stack-resources \
  --stack-name CloudFormation-DevOps-Lab
```

You should find:

```text
EC2WebServerStack
S3NestedStack
RDSNestedStack
```

The nested stacks should ultimately reach:

```text
CREATE_COMPLETE
```

---

# 5. Test #4 — Verify VPC

Retrieve the VPC:

```bash
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=Lab-VPC"
```

Verify:

```text
CIDR = 10.0.0.0/16
DNS Support = enabled
DNS Hostnames = enabled
```

You can also check:

```bash
aws ec2 describe-vpc-attribute \
  --vpc-id VPC_ID \
  --attribute enableDnsSupport
```

And:

```bash
aws ec2 describe-vpc-attribute \
  --vpc-id VPC_ID \
  --attribute enableDnsHostnames
```

Both should be enabled.

---

# 6. Test #5 — Verify Internet Gateway

Run:

```bash
aws ec2 describe-internet-gateways \
  --filters "Name=tag:Name,Values=Lab-InternetGateway"
```

Verify that the Internet Gateway is attached to your VPC.

Expected relationship:

```text
Internet Gateway
       |
       v
    Lab-VPC
```

---

# 7. Test #6 — Verify Public Subnets

Your public subnet CIDRs are:

```text
10.0.1.0/24
10.0.4.0/24
```

Run:

```bash
aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=Public-Subnet-1"
```

and:

```bash
aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=Public-Subnet-2"
```

Verify:

```text
MapPublicIpOnLaunch = true
```

Also verify they are in different Availability Zones.

For example:

```text
Public-Subnet-1 -> AZ-1
Public-Subnet-2 -> AZ-2
```

---

# 8. Test #7 — Verify Private Subnets

Your private subnets are:

```text
10.0.2.0/24
10.0.3.0/24
```

Run:

```bash
aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=Private-Subnet-1"
```

and:

```bash
aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=Private-Subnet-2"
```

Verify:

```text
MapPublicIpOnLaunch = false
```

This is important because ECS tasks and RDS are designed to stay private.

---

# 9. Test #8 — Verify Public Route Table

Run:

```bash
aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=Public-RouteTable"
```

You should see:

```text
0.0.0.0/0
      |
      v
Internet Gateway
```

The public subnets should be associated with this route table.

---

# 10. Test #9 — Verify Private Route Table

Run:

```bash
aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=Private-RouteTable"
```

The important learning point is that your private route table does **not** contain:

```text
0.0.0.0/0 -> Internet Gateway
```

Your architecture intentionally does not use a NAT Gateway.

Therefore:

```text
Private Subnet
      |
      X
 Internet Gateway
```

is expected.

Later, your ECS stack adds VPC endpoints for private AWS service connectivity.

---

# 11. Test #10 — Verify Web Security Group

Run:

```bash
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=Lab-Web-SG"
```

Verify inbound rules:

```text
TCP 22  -> SSH
TCP 80  -> HTTP
TCP 443 -> HTTPS
```

For a temporary lab, SSH from:

```text
0.0.0.0/0
```

works, but in a real environment it should be restricted to your IP.

---

# 12. EC2 Complete Verification Test

Now we reach one of the most important parts of the lab.

Your EC2 instance is created through the nested stack.

The test should cover:

```text
EC2 exists
    |
    +-- Correct AMI
    |
    +-- Correct subnet
    |
    +-- Public IP
    |
    +-- Security Group
    |
    +-- SSH
    |
    +-- Internet connectivity
    |
    +-- UserData
    |
    +-- Apache
    |
    +-- PHP
    |
    +-- Docker
    |
    +-- Docker Compose
    |
    +-- Git
    |
    +-- AWS CLI
    |
    +-- Bootstrap logs
```

---

# 13. Test EC2 Instance Status

Get the instance ID from CloudFormation:

```bash
aws cloudformation describe-stacks \
  --stack-name CloudFormation-DevOps-Lab \
  --query "Stacks[0].Outputs"
```

Then:

```bash
aws ec2 describe-instances \
  --instance-ids INSTANCE_ID
```

Verify:

```text
InstanceState = running
```

Also verify:

```text
SubnetId = Public Subnet
```

and:

```text
PublicIpAddress = available
```

---

# 14. Test EC2 System Status Checks

Run:

```bash
aws ec2 describe-instance-status \
  --instance-ids INSTANCE_ID
```

Verify:

```text
SystemStatus = ok
InstanceStatus = ok
```

This confirms that AWS has passed both major EC2 health checks.

---

# 15. Test EC2 SSH Connectivity

From your local machine:

```bash
ssh -i your-key.pem ec2-user@PUBLIC_IP
```

If the connection succeeds:

```text
EC2 SSH TEST = PASS
```

---

# 16. Test EC2 Operating System

Once connected:

```bash
cat /etc/os-release
```

Expected:

```text
Amazon Linux
```

Check kernel:

```bash
uname -a
```

Check hostname:

```bash
hostname
```

Check CPU:

```bash
lscpu
```

Check memory:

```bash
free -h
```

Check disk:

```bash
df -h
```

---

# 17. Test EC2 Internet Connectivity

Run:

```bash
ping -c 4 8.8.8.8
```

Then:

```bash
curl -I https://www.google.com
```

Then:

```bash
curl -I https://raw.githubusercontent.com
```

The last test is particularly important because your UserData downloads:

```text
ec2-userdata.sh
```

from GitHub.

---

# 18. Test EC2 DNS

Run:

```bash
getent hosts github.com
```

You should receive an IP address.

Also:

```bash
getent hosts amazonaws.com
```

If DNS resolution works, your VPC DNS configuration is functioning.

---

# 19. Test EC2 UserData

This is one of the most important tests.

Check:

```bash
sudo cat /var/log/bootstrap.log
```

Look for:

```text
Starting EC2 UserData Bootstrap
```

and:

```text
EC2 bootstrap script downloaded successfully.
```

and finally:

```text
EC2 UserData Bootstrap Completed Successfully
```

---

# 20. Test Bootstrap Status

Run:

```bash
sudo cat /var/log/bootstrap-status.log
```

Expected:

```text
Bootstrap completed successfully.
```

If this file does not exist, investigate:

```bash
sudo cat /var/log/cloud-init-output.log
```

Also:

```bash
sudo cat /var/log/cloud-init.log
```

These are extremely useful when EC2 UserData fails.

---

# 21. Test the Downloaded Bootstrap Script

Run:

```bash
ls -lh /tmp/ec2-userdata.sh
```

Then:

```bash
sudo head -n 30 /tmp/ec2-userdata.sh
```

Verify that the script is actually the expected GitHub script.

You can also calculate its checksum:

```bash
sha256sum /tmp/ec2-userdata.sh
```

---

# 22. Test Apache

Run:

```bash
sudo systemctl status httpd
```

You want:

```text
Active: active (running)
```

Check whether port 80 is listening:

```bash
sudo ss -tulpn | grep :80
```

Test locally:

```bash
curl http://localhost
```

Then from your own computer:

```text
http://EC2_PUBLIC_IP
```

If the web page loads:

```text
HTTP TEST = PASS
```

---

# 23. Test PHP

Run:

```bash
php --version
```

You should see the installed PHP version.

You can also test Apache/PHP integration.

Create a temporary file:

```bash
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php
```

Then open:

```text
http://EC2_PUBLIC_IP/info.php
```

After testing, remove it:

```bash
sudo rm -f /var/www/html/info.php
```

Do not leave `phpinfo()` publicly accessible on a real server.

---

# 24. Test Docker

Run:

```bash
docker --version
```

Then:

```bash
sudo systemctl status docker
```

Expected:

```text
Active: active (running)
```

Run:

```bash
sudo docker info
```

If Docker responds correctly:

```text
Docker TEST = PASS
```

---

# 25. Test Docker Service at Boot

Run:

```bash
sudo systemctl is-enabled docker
```

Expected:

```text
enabled
```

This means Docker should automatically start after reboot.

---

# 26. Test Docker Container

Run:

```bash
sudo docker ps
```

Then:

```bash
sudo docker ps -a
```

This shows running and stopped containers.

---

# 27. Test Docker Image

Run:

```bash
sudo docker images
```

Verify that the expected images exist.

For deeper testing:

```bash
sudo docker image ls
```

---

# 28. Test Docker Compose

Run:

```bash
docker compose version
```

If your installation uses the older standalone command, also check:

```bash
docker-compose --version
```

---

# 29. Test Git

Run:

```bash
git --version
```

Then:

```bash
git config --list
```

Test GitHub connectivity:

```bash
git ls-remote https://github.com/awsrmmustansarjavaid/CloudFormation-DevOps-Lab.git
```

If the repository references are returned, Git connectivity works.

---

# 30. Test AWS CLI From EC2

Run:

```bash
aws --version
```

Then:

```bash
aws sts get-caller-identity
```

This test is extremely important.

If it succeeds, the EC2 instance has AWS API access.

If it fails, check whether your EC2 instance has an IAM role attached.

---

# 31. Test EC2 IAM Role

Run:

```bash
aws iam list-attached-role-policies \
  --role-name YOUR_EC2_ROLE
```

If your lab does not create an EC2 IAM role, remember:

**Installing AWS CLI does not automatically give EC2 permission to use AWS APIs.**

The AWS CLI must have credentials through an IAM role, environment credentials, or another credential mechanism.

For production environments, an EC2 IAM role is preferred over storing long-lived access keys on the server.

---

# 32. Test S3 Nested Stack

Retrieve the output:

```bash
aws cloudformation describe-stacks \
  --stack-name CloudFormation-DevOps-Lab \
  --query "Stacks[0].Outputs"
```

Find:

```text
S3BucketName
```

Then:

```bash
aws s3 ls s3://YOUR_BUCKET_NAME
```

Because the bucket is initially empty, this may return nothing.

That is not a failure.

Test bucket existence:

```bash
aws s3api head-bucket \
  --bucket YOUR_BUCKET_NAME
```

If there is no error:

```text
S3 TEST = PASS
```

---

# 33. Test S3 Versioning

Run:

```bash
aws s3api get-bucket-versioning \
  --bucket YOUR_BUCKET_NAME
```

Expected:

```json
{
    "Status": "Enabled"
}
```

This confirms that your nested S3 template worked correctly.

---

# 34. Test RDS

First retrieve the database identifier:

```bash
aws cloudformation describe-stacks \
  --stack-name CloudFormation-DevOps-Lab \
  --query "Stacks[0].Outputs"
```

Then:

```bash
aws rds describe-db-instances \
  --db-instance-identifier YOUR_RDS_ID
```

Verify:

```text
DBInstanceStatus = available
```

Also verify:

```text
Engine = mysql
PubliclyAccessible = false
```

---

# 35. Test RDS Private Connectivity

Your RDS architecture should be:

```text
Internet
   X
   |
   X
RDS
 |
Private Subnet
 |
EC2
```

The database should **not** be directly accessible from the public Internet.

---

# 36. Test RDS Security Group

Run:

```bash
aws ec2 describe-security-groups \
  --group-ids RDS_SECURITY_GROUP_ID
```

Verify that port:

```text
3306
```

allows traffic from:

```text
WebSecurityGroup
```

rather than:

```text
0.0.0.0/0
```

This is a very important security test.

---

# 37. Test RDS Endpoint From EC2

From EC2:

```bash
getent hosts YOUR_RDS_ENDPOINT
```

Then test port 3306:

```bash
nc -zv YOUR_RDS_ENDPOINT 3306
```

Expected:

```text
Connection succeeded
```

If `nc` is unavailable, install the appropriate package for your Amazon Linux environment or use another TCP connectivity test.

This test verifies:

```text
EC2
 |
 VPC
 |
Private subnet
 |
RDS
```

---

# 38. Test RDS Credentials Through Secrets Manager

Your RDS template uses:

```yaml
ManageMasterUserPassword: true
```

Therefore AWS manages the master password through Secrets Manager.

First get the secret ARN from the nested stack output.

Then:

```bash
aws secretsmanager describe-secret \
  --secret-id YOUR_SECRET_ARN
```

Verify that the secret exists.

Do not expose the actual password in terminal screenshots, GitHub Actions logs, LinkedIn posts, or documentation.

---

# 39. Important RDS Test — EC2 Security Group Dependency

Your RDS rule is:

```text
RDS
 |
TCP 3306
 |
WebSecurityGroup
 |
EC2
```

Therefore test this relationship carefully.

If the EC2 instance can reach port 3306:

```text
RDS Network Security = PASS
```

---

# 40. ECS Stack Verification

Now test the independent ECS stack.

First:

```bash
aws cloudformation describe-stacks \
  --stack-name CharlieCafe-ECS-Stack
```

Expected:

```text
CREATE_COMPLETE
```

Then:

```bash
aws cloudformation describe-stack-events \
  --stack-name CharlieCafe-ECS-Stack
```

Check for failed resources.

---

# 41. Test ECR Repository

Run:

```bash
aws ecr describe-repositories \
  --repository-names charlie-cafe
```

The repository should exist.

Check images:

```bash
aws ecr list-images \
  --repository-name charlie-cafe
```

If the repository is empty before GitHub Actions pushes the image, that is expected.

After deployment, you should see:

```text
latest
```

or your versioned image tag.

---

# 42. Test Docker Image in ECR

Run:

```bash
aws ecr describe-images \
  --repository-name charlie-cafe
```

Look for:

```text
imageTags
```

For your current design:

```text
latest
```

should eventually exist.

---

# 43. Test ECS Cluster

Run:

```bash
aws ecs describe-clusters \
  --clusters CharlieCafe-Cluster
```

Expected:

```text
status = ACTIVE
```

---

# 44. Test ECS Service

Run:

```bash
aws ecs describe-services \
  --cluster CharlieCafe-Cluster \
  --services CharlieCafe-Service
```

Verify:

```text
status = ACTIVE
```

Initially your CloudFormation template uses:

```yaml
DesiredCount: 0
```

So:

```text
runningCount = 0
```

can be completely normal immediately after infrastructure creation.

Your deployment workflow later changes the desired count to:

```text
1
```

---

# 45. Test ECS Task Definition

Run:

```bash
aws ecs describe-task-definition \
  --task-definition CharlieCafe
```

Verify:

```text
FARGATE
awsvpc
CPU = 256
Memory = 512
Container Port = 80
```

Also verify the image:

```text
charlie-cafe:<tag>
```

---

# 46. Test ECS Task IAM Roles

Verify the execution role:

```text
CharlieCafe-ECSTaskExecutionRole
```

The execution role should provide the permissions needed for:

```text
ECR image pulling
CloudWatch Logs
```

The task role:

```text
CharlieCafe-ECSTaskRole
```

is intended for permissions required by the application itself.

This distinction is important:

```text
Execution Role
     |
     +-- ECS/Fargate infrastructure actions


Task Role
     |
     +-- Application AWS API actions
```

---

# 47. Test VPC Endpoints

Your ECS architecture depends heavily on VPC endpoints because there is no NAT Gateway.

Check:

```bash
aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=YOUR_VPC_ID"
```

You should find endpoints for:

```text
ECR API
ECR DKR
S3
CloudWatch Logs
```

---

# 48. Test ECR API Endpoint

Verify:

```text
com.amazonaws.REGION.ecr.api
```

Expected:

```text
State = available
```

---

# 49. Test ECR DKR Endpoint

Verify:

```text
com.amazonaws.REGION.ecr.dkr
```

Expected:

```text
State = available
```

---

# 50. Test S3 Gateway Endpoint

Verify:

```text
com.amazonaws.REGION.s3
```

Expected:

```text
VpcEndpointType = Gateway
```

Also verify that your private route table is associated with the endpoint.

This is especially important because ECR image layers rely on S3.

---

# 51. Test CloudWatch Logs Endpoint

Verify:

```text
com.amazonaws.REGION.logs
```

Expected:

```text
State = available
```

This allows ECS tasks in private subnets to send container logs to CloudWatch without requiring a NAT Gateway.

---

# 52. Test VPC Endpoint Security Group

Your endpoint security group allows:

```text
Private Subnet 1 -> HTTPS 443
Private Subnet 2 -> HTTPS 443
```

Verify:

```bash
aws ec2 describe-security-groups \
  --group-ids VPC_ENDPOINT_SECURITY_GROUP_ID
```

Confirm port:

```text
443
```

is allowed from the private subnet CIDRs.

---

# 53. Test ALB

Run:

```bash
aws elbv2 describe-load-balancers \
  --names CharlieCafe-ALB
```

Verify:

```text
Scheme = internet-facing
Type = application
```

The ALB should be deployed into:

```text
Public Subnet 1
Public Subnet 2
```

---

# 54. Test ALB Security Group

Verify that the ALB security group allows:

```text
TCP 80
Source = 0.0.0.0/0
```

The ECS task security group should **not** allow Internet traffic directly.

Instead:

```text
Internet
   |
   v
ALB Security Group
   |
   v
ECS Task Security Group
```

---

# 55. Test ECS Task Security Group

Verify:

```text
ContainerPort
Source = ALB Security Group
```

For your current configuration:

```text
TCP 80
Source = CharlieCafe-ALB-SG
```

This is much safer than:

```text
TCP 80
0.0.0.0/0
```

---

# 56. Test ALB Target Group

Run:

```bash
aws elbv2 describe-target-groups \
  --names CharlieCafe-TG
```

Verify:

```text
TargetType = ip
Protocol = HTTP
Port = 80
HealthCheckPath = /
```

---

# 57. Test ALB Target Health

Run:

```bash
aws elbv2 describe-target-health \
  --target-group-arn TARGET_GROUP_ARN
```

You want:

```text
TargetHealth.State = healthy
```

This is one of the most important ECS tests.

---

# 58. Test ECS Running Task

Run:

```bash
aws ecs list-tasks \
  --cluster CharlieCafe-Cluster \
  --service-name CharlieCafe-Service
```

Then:

```bash
aws ecs describe-tasks \
  --cluster CharlieCafe-Cluster \
  --tasks TASK_ARN
```

Verify:

```text
lastStatus = RUNNING
```

and:

```text
healthStatus = HEALTHY
```

if container health checks are configured.

---

# 59. Test ECS Service Stability

Run:

```bash
aws ecs wait services-stable \
  --cluster CharlieCafe-Cluster \
  --services CharlieCafe-Service
```

If the command completes successfully:

```text
ECS SERVICE STABILITY = PASS
```

This is an excellent command to include in your GitHub Actions deployment workflow.

---

# 60. Test CloudWatch Logs

Run:

```bash
aws logs describe-log-groups \
  --log-group-name-prefix /ecs/charlie-cafe
```

Then:

```bash
aws logs describe-log-streams \
  --log-group-name /ecs/charlie-cafe
```

You should see ECS log streams.

You can retrieve recent logs:

```bash
aws logs tail /ecs/charlie-cafe --since 10m
```

Look for application startup messages.

---

# 61. Test Application Through ALB

Retrieve the ALB DNS name:

```bash
aws cloudformation describe-stacks \
  --stack-name CharlieCafe-ECS-Stack \
  --query "Stacks[0].Outputs"
```

Find:

```text
ApplicationURL
```

Then:

```bash
curl -I http://ALB_DNS_NAME
```

Expected:

```text
HTTP/1.1 200 OK
```

Depending on your application, other successful HTTP responses may also be valid.

---

# 62. Test Application From Browser

Open:

```text
http://ALB_DNS_NAME
```

Verify:

```text
Internet
   |
   v
Application Load Balancer
   |
   v
Target Group
   |
   v
ECS Fargate Task
   |
   v
Docker Container
```

If the application page loads:

```text
END-TO-END APPLICATION TEST = PASS
```

---

# 63. Test ECS Without NAT Gateway

This is an important architectural test.

Your private ECS tasks have:

```text
No public IP
```

and:

```text
No NAT Gateway
```

Yet they can pull images and send logs because of:

```text
ECR API Endpoint
ECR DKR Endpoint
S3 Gateway Endpoint
CloudWatch Logs Endpoint
```

This demonstrates an important AWS networking concept:

> Private workloads do not always need a NAT Gateway to communicate with AWS services.

---

# 64. Test the Complete Traffic Flow

Your application traffic should work like this:

```text
Internet
   |
   | HTTP :80
   v
Public ALB
   |
   | TCP :80
   v
Private ECS Task
   |
   | Docker Container
   v
Charlie Cafe Application
```

ECS image retrieval:

```text
ECS Task
   |
   +----> ECR API Endpoint
   |
   +----> ECR DKR Endpoint
   |
   +----> S3 Gateway Endpoint
```

Logging:

```text
ECS Task
   |
   v
CloudWatch Logs Endpoint
   |
   v
CloudWatch Logs
```

Database:

```text
Application / EC2
       |
       | TCP 3306
       v
Private RDS MySQL
```

---

# 65. Complete EC2 Verification Checklist

Use this checklist whenever you launch the EC2 server.

* [ ] EC2 instance exists
* [ ] EC2 state is `running`
* [ ] System status check is `ok`
* [ ] Instance status check is `ok`
* [ ] Correct AMI is used
* [ ] Correct instance type is used
* [ ] Correct key pair is attached
* [ ] EC2 is inside Public Subnet 1
* [ ] Public IP exists
* [ ] Correct security group is attached
* [ ] SSH port 22 is reachable
* [ ] HTTP port 80 is reachable
* [ ] HTTPS port 443 is configured if required
* [ ] Internet connectivity works
* [ ] DNS resolution works
* [ ] GitHub is reachable
* [ ] `bootstrap.log` exists
* [ ] `bootstrap-status.log` exists
* [ ] `ec2-userdata.sh` downloaded successfully
* [ ] Apache is running
* [ ] PHP is installed
* [ ] Docker is installed
* [ ] Docker service is running
* [ ] Docker starts on boot
* [ ] Docker Compose is installed
* [ ] Git is installed
* [ ] AWS CLI is installed
* [ ] AWS CLI can authenticate
* [ ] EC2 can resolve the RDS endpoint
* [ ] EC2 can reach RDS port 3306
* [ ] EC2 can access required AWS services

---

# 66. Complete VPC Verification Checklist

* [ ] VPC exists
* [ ] CIDR is `10.0.0.0/16`
* [ ] DNS support enabled
* [ ] DNS hostnames enabled
* [ ] Internet Gateway exists
* [ ] Internet Gateway attached
* [ ] Public Subnet 1 exists
* [ ] Public Subnet 2 exists
* [ ] Private Subnet 1 exists
* [ ] Private Subnet 2 exists
* [ ] Public subnets use different AZs
* [ ] Private subnets use different AZs
* [ ] Public route table exists
* [ ] Public route points to Internet Gateway
* [ ] Public subnets associated with public route table
* [ ] Private route table exists
* [ ] Private subnets associated with private route table
* [ ] No accidental public route exists on private subnets

---

# 67. Complete RDS Verification Checklist

* [ ] RDS instance exists
* [ ] RDS status is `available`
* [ ] Engine is MySQL
* [ ] Database is in private subnets
* [ ] RDS is not publicly accessible
* [ ] RDS subnet group contains two subnets
* [ ] RDS security group exists
* [ ] Port 3306 is allowed
* [ ] Port 3306 source is EC2 security group
* [ ] No `0.0.0.0/0` database access
* [ ] RDS endpoint resolves from EC2
* [ ] Port 3306 is reachable from EC2
* [ ] Secrets Manager secret exists
* [ ] Master password is managed by RDS/Secrets Manager

---

# 68. Complete S3 Verification Checklist

* [ ] S3 nested stack exists
* [ ] S3 bucket exists
* [ ] Bucket versioning enabled
* [ ] Bucket has expected tags
* [ ] Bucket can be accessed according to intended permissions
* [ ] Bucket ARN exists
* [ ] Bucket can store objects
* [ ] Objects can be listed
* [ ] Objects can be uploaded
* [ ] Objects can be downloaded
* [ ] Versioning creates object versions

---

# 69. Complete ECS Verification Checklist

* [ ] ECS CloudFormation stack exists
* [ ] ECS stack is `CREATE_COMPLETE`
* [ ] ECR repository exists
* [ ] ECR image exists
* [ ] ECS cluster is `ACTIVE`
* [ ] ECS service is `ACTIVE`
* [ ] Task definition exists
* [ ] Fargate launch type is configured
* [ ] `awsvpc` networking is configured
* [ ] ECS tasks use private subnets
* [ ] ECS tasks have no public IP
* [ ] ECS task security group exists
* [ ] ALB security group exists
* [ ] ALB exists
* [ ] ALB is internet-facing
* [ ] Target group exists
* [ ] Target type is `ip`
* [ ] Listener exists on port 80
* [ ] ECS task starts
* [ ] ECS service becomes stable
* [ ] Target becomes healthy
* [ ] CloudWatch logs appear
* [ ] ALB URL responds
* [ ] Application loads successfully

---

# 70. Complete VPC Endpoint Verification Checklist

* [ ] ECR API endpoint exists
* [ ] ECR DKR endpoint exists
* [ ] S3 Gateway endpoint exists
* [ ] CloudWatch Logs endpoint exists
* [ ] Interface endpoints are `available`
* [ ] Private subnets are associated with interface endpoints
* [ ] Private route table is associated with S3 endpoint
* [ ] Endpoint security group allows HTTPS 443
* [ ] ECS tasks can pull the ECR image
* [ ] ECS tasks can send logs to CloudWatch

---

# 71. Final End-to-End Test

The most important test is the complete application path.

Start from the user's browser:

```text
Browser
   |
   | HTTP :80
   v
Application Load Balancer
   |
   | Target Group
   v
ECS Fargate Task
   |
   | Docker
   v
Charlie Cafe Application
```

The ECS task obtains its image through:

```text
ECR
 |
 +-- ECR API Endpoint
 |
 +-- ECR DKR Endpoint
 |
 +-- S3 Gateway Endpoint
```

The application logs go through:

```text
ECS
 |
 v
CloudWatch Logs Endpoint
 |
 v
CloudWatch Logs
```

The database architecture is:

```text
Private Application
       |
       | TCP 3306
       v
RDS MySQL
       |
       v
Secrets Manager
```

If every section works, your lab has passed a genuine end-to-end verification.

---

# 72. Recommended Final Test Order

Do not test everything randomly.

Use this order:

## Phase 1 — CloudFormation

```text
1. Validate templates
2. Create main stack
3. Check CREATE_COMPLETE
4. Check nested stacks
```

## Phase 2 — Network

```text
5. VPC
6. Internet Gateway
7. Public subnets
8. Private subnets
9. Route tables
10. Security groups
```

## Phase 3 — EC2

```text
11. EC2 running
12. SSH
13. Internet
14. DNS
15. UserData
16. Apache
17. PHP
18. Docker
19. Git
20. AWS CLI
```

## Phase 4 — Storage and Database

```text
21. S3
22. S3 versioning
23. RDS
24. RDS security group
25. RDS connectivity
26. Secrets Manager
```

## Phase 5 — ECS

```text
27. ECS stack
28. ECR
29. Docker image
30. ECS cluster
31. Task definition
32. ECS service
33. VPC endpoints
34. ALB
35. Target group
36. ECS task
37. CloudWatch Logs
38. Target health
```

## Phase 6 — Application

```text
39. ALB HTTP test
40. Browser test
41. Application functionality
```

## Phase 7 — Cleanup

```text
42. Stop ECS service
43. Delete ECS stack
44. Verify ECR cleanup
45. Verify ALB cleanup
46. Verify VPC endpoints cleanup
47. Delete main stack
48. Verify nested stacks deleted
49. Verify EC2 deleted
50. Verify RDS deleted
51. Verify S3 bucket
52. Verify no unexpected resources remain
```

---

# 73. The Most Important Lesson

Do not consider a CloudFormation lab successful simply because:

```text
CREATE_COMPLETE
```

A better definition is:

```text
Infrastructure Created
        +
Infrastructure Configured
        +
Network Connectivity Verified
        +
Security Verified
        +
Application Verified
        +
Logs Verified
        +
Failure Conditions Tested
        +
Cleanup Verified
        =
Successful CloudFormation Lab
```

That is the difference between **deploying AWS infrastructure** and actually **understanding and operating AWS infrastructure**.

---

# 74. Final Lab Verification Scorecard

At the end of your testing, you should be able to answer:

* [ ] Can CloudFormation validate every template?
* [ ] Does the main stack create successfully?
* [ ] Do all nested stacks complete successfully?
* [ ] Is the VPC configured correctly?
* [ ] Are public and private subnets correctly separated?
* [ ] Does the public route table reach the Internet Gateway?
* [ ] Does EC2 receive a public IP?
* [ ] Can I SSH into EC2?
* [ ] Does EC2 UserData complete successfully?
* [ ] Is Apache running?
* [ ] Is PHP working?
* [ ] Is Docker working?
* [ ] Is Git working?
* [ ] Is AWS CLI working?
* [ ] Does EC2 reach RDS?
* [ ] Is RDS private?
* [ ] Does Secrets Manager contain the RDS credentials?
* [ ] Does S3 exist?
* [ ] Is S3 versioning enabled?
* [ ] Does ECR exist?
* [ ] Is the Docker image in ECR?
* [ ] Is ECS active?
* [ ] Is the ECS task running?
* [ ] Is the ECS task private?
* [ ] Are VPC endpoints available?
* [ ] Is the ALB available?
* [ ] Is the target healthy?
* [ ] Are CloudWatch logs appearing?
* [ ] Does the ALB URL load the application?
* [ ] Can the entire application path be demonstrated?
* [ ] Can the entire infrastructure be deleted cleanly?

## Final Result

If all of these tests pass, you have demonstrated a complete AWS CloudFormation lab covering:

**CloudFormation + Nested Stacks + VPC + Networking + EC2 + UserData + S3 + RDS + Secrets Manager + ECR + ECS Fargate + VPC Endpoints + ALB + IAM + CloudWatch Logs + Docker + GitHub-based automation.**

That is a strong hands-on DevOps/AWS portfolio lab because you are not only creating resources—you are proving that the resources communicate correctly, are secured appropriately, and can be operated and cleaned up correctly.
