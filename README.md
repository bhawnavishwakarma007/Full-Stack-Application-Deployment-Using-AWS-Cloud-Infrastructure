# Project 1: Full-Stack Application Deployment Using AWS Cloud Infrastructure

## Overview

This project demonstrates how to deploy a **production-style full-stack application infrastructure on AWS** with **monitoring and automated alerting**.

The architecture focuses on:
- Secure networking using VPC
- Backend deployment on EC2
- Database layer with Amazon RDS
- Secret management using Parameter Store
- Application logging using CloudWatch
- Real-time alerting using SNS + Lambda + Slack

Whenever an **ERROR log appears in the backend application**, the system automatically sends a **notification to Slack**.

---

# Architecture

## High Level Flow

User  
↓  
CloudFront  
↓  
AWS WAF  
↓  
Application Load Balancer  
↓  
Frontend Auto Scaling Group  
↓  
Network Load Balancer  
↓  
Backend Auto Scaling Group  
↓  
Amazon RDS (MySQL)

Monitoring Pipeline:

Backend EC2 Logs  
↓  
CloudWatch Log Group  
↓  
Metric Filter (ERROR)  
↓  
CloudWatch Alarm  
↓  
SNS Topic  
↓  
Lambda Function  
↓  
Slack Notification

---

# Step 1: Create VPC

Create a custom VPC.

```
VPC Name: dev-vpc
CIDR Block: 10.0.0.0/16
```

---

# Step 2: Create Subnets

### Public Subnets

| Subnet | AZ | CIDR |
|------|------|------|
| pub-sub-1 | us-east-1a | 10.0.0.0/24 |
| pub-sub-2 | us-east-1b | 10.0.1.0/24 |
| pub-sub-3 | us-east-1c | 10.0.2.0/24 |

### Private Subnets

| Subnet | AZ | CIDR |
|------|------|------|
| pvt-sub-1 | us-east-1a | 10.0.3.0/24 |
| pvt-sub-2 | us-east-1b | 10.0.4.0/24 |
| pvt-sub-3 | us-east-1c | 10.0.5.0/24 |

---

# Step 3: Internet Gateway

Create an Internet Gateway and attach it to the VPC.

```
Internet Gateway → attach to dev-vpc
```

---

# Step 4: NAT Gateway

Create a NAT Gateway in a public subnet.

```
NAT Gateway
Elastic IP attached
```

Purpose:
Allow **private subnet instances to access internet**.

---

# Step 5: Route Tables

### Public Route Table

```
Destination: 0.0.0.0/0
Target: Internet Gateway
```

Attach to:
```
pub-sub-1
pub-sub-2
pub-sub-3
```

### Private Route Table

```
Destination: 0.0.0.0/0
Target: NAT Gateway
```

Attach to:
```
pvt-sub-1
pvt-sub-2
pvt-sub-3
```

---

# Step 6: Security Groups

### ALB Security Group

```
HTTP 80
Source: 0.0.0.0/0
```

### Frontend EC2 Security Group

```
Port: 8501
Source: ALB Security Group
```

### NLB Security Group

```
TCP 80
Source: Frontend Security Group
```

### Backend EC2 Security Group

```
TCP 8084
Source: NLB Security Group
```

### RDS Security Group

```
MySQL 3306
Source: Backend Security Group
```

---

# Step 7: Parameter Store (Secrets Management)

Store database credentials securely.

Path structure:

```
/cheetah/dev/mysql/host
/cheetah/dev/mysql/username
/cheetah/dev/mysql/password
```

Example:

```
host = RDS endpoint
username = admin
password = stored as SecureString with KMS
```

---

# Step 8: S3 Bucket

Create an S3 bucket and upload backend application JAR file.

```
S3 → upload application.jar
```

Purpose:
EC2 instances download the application during startup.

---

# Step 9: IAM Role for EC2

Create IAM role with following permissions:

```
AmazonSSMManagedInstanceCore
CloudWatchAgentServerPolicy
AmazonS3ReadOnlyAccess
SSM Parameter Store Read Access
```

Attach role to EC2 instances.

---

# Step 10: Launch Template

Create Launch Template for backend instances.

Configuration:

```
Instance Type: medium
Key pair
IAM role attached
User Data script
```

User data installs:

```
Java
CloudWatch agent
Download JAR from S3
Start application
```

---

# Step 11: Target Group

Create Target Group.

```
Protocol: TCP
Port: 8084
Health Check: HTTP
Path: /actuator
Success code: 200
```

---

# Step 12: Network Load Balancer

Create **Internal NLB**

Attach:

```
Private subnets
Target group
```

---

# Step 13: Auto Scaling Group

Create ASG using Launch Template.

```
Subnets: private subnets
Desired capacity: 1
Load balancer: NLB
Health check: ELB
```

---

# Step 14: Application Logs

Application logs stored at:

```
/var/log/app/datastore.log
```

CloudWatch Agent sends logs to:

```
CloudWatch Log Group
/datastore/app
```

---

# Step 15: CloudWatch Metric Filter

Create metric filter.

```
Pattern: ERROR
Namespace: be-cw-ns
Metric name: log-error
Metric value: 1
```

This converts log entries into metrics.

---

# Step 16: CloudWatch Alarm

Create alarm:

```
Condition:
log-error >= 1
Period: 1 minute
```

When triggered → send notification to SNS.

---

# Step 17: SNS Topic

Create SNS topic.

```
Topic type: Standard
```

Add access policy allowing **CloudWatch to publish**.

---

# Step 18: Lambda Function

Create Lambda:

```
Runtime: Python 3.12
```

Lambda receives message from SNS.

---

# Step 19: Slack Integration

Create Slack app.

Steps:

```
api.slack.com/apps
Create App
Enable Incoming Webhooks
Create Webhook URL
Select Slack Channel
```

---

# Step 20: Lambda Environment Variable

Add environment variable.

```
slackHookUrl = webhook url
```

---

# Step 21: Lambda Code

Lambda sends Slack message when alarm triggers.

Example logic:

```
Receive SNS event
Extract CloudWatch message
Send HTTP POST request to Slack webhook
```

---

# Final Workflow

Backend application error occurs  
↓  
CloudWatch logs detect ERROR  
↓  
Metric filter converts log to metric  
↓  
CloudWatch alarm triggered  
↓  
SNS topic receives alert  
↓  
Lambda function triggered  
↓  
Lambda sends Slack message  
↓  
Alert appears in Slack channel

---

# Result

The system now provides:

- Real-time application monitoring
- Automated alerting
- Faster incident detection
- Production-style observability

---

# AWS Services Used

- Amazon VPC
- Amazon EC2
- Auto Scaling Group
- Network Load Balancer
- Amazon RDS
- AWS Systems Manager Parameter Store
- Amazon S3
- Amazon CloudWatch
- Amazon SNS
- AWS Lambda

---

# Future Improvements

- Add CloudFront
- Add AWS WAF
- Implement CI/CD pipeline
- Add centralized logging
- Add distributed tracing
