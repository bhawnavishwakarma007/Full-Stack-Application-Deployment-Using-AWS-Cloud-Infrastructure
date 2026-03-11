
# 🚀 FULL STACK AWS PROJECT – MANUAL DEPLOYMENT (STEP-BY-STEP)

This project was created manually using the AWS Console following a structured, production-grade approach — from networking to security hardening, monitoring, CDN, WAF, DNS, lifecycle management, and cost optimization.

---
# Architecture Diagram

![Architecture](images/architecture.png)

---

# 🔷 PHASE 1 — NETWORK SETUP

## 1️⃣ Create VPC
- Name: dev-vpc  
- CIDR: 10.0.0.0/16  
Creates isolated network for entire infrastructure.

## 2️⃣ Create Subnets (Multi-AZ)

### Public Subnets
- dev-pub-sub-1 → us-east-1a → 10.0.0.0/24  
- dev-pub-sub-2 → us-east-1b → 10.0.1.0/24  
- dev-pub-sub-3 → us-east-1c → 10.0.2.0/24  

### Private Subnets
- dev-pvt-sub-1 → us-east-1a → 10.0.3.0/24  
- dev-pvt-sub-2 → us-east-1b → 10.0.4.0/24  
- dev-pvt-sub-3 → us-east-1c → 10.0.5.0/24  

Ensures high availability across 3 AZs.

## 3️⃣ Internet Gateway
Attached to VPC for public internet access.

## 4️⃣ NAT Gateway
- Placed in Public Subnet  
- Attached Elastic IP  
Allows private instances outbound internet securely.

## 5️⃣ Route Tables
Public:
    0.0.0.0/0 → IGW  

Private:
    0.0.0.0/0 → NAT  

## 6️⃣ Enable VPC Flow Logs
Used for traffic monitoring and debugging.

---

# 🔷 PHASE 2 — SECURITY GROUP DESIGN (LAYERED SECURITY)

## 7️⃣ Security Groups Created

ALB SG  
- HTTP 80 → 0.0.0.0/0  

Frontend SG  
- TCP 8501 → From ALB SG  

NLB SG  
- TCP 80 → From Frontend SG  

Backend SG  
- TCP 8084 → From NLB SG  

RDS SG  
- Port 3306 → From Backend SG  

Ensures strict service-to-service communication.

---

# 🔷 PHASE 3 — DATABASE CONFIGURATION

## 8️⃣ DB Subnet Group
Included all private subnets (Multi-AZ).

## 9️⃣ RDS Instance
- Engine: MySQL/Aurora  
- Public Access: Disabled  
- Encryption: Enabled (KMS)  
- Logging: Enabled  

### Encryption
- At Rest  
- In Transit  

---

# 🔷 PHASE 4 — ACCESS MANAGEMENT & SECRETS

## 🔟 Systems Manager (SSM)
Access EC2 in private subnet securely.  
No Bastion required.

## 1️⃣1️⃣ Parameter Store
Stored:
- /cheetah/dev/mysql/host  
- /cheetah/dev/mysql/username  
- /cheetah/dev/mysql/password (SecureString + KMS)

Prevents hardcoded credentials.

---

# 🔷 PHASE 5 — S3 ARTIFACT STORAGE

## 1️⃣2️⃣ S3 Bucket
Uploaded backend JAR file for EC2 deployment.

---

# 🔷 PHASE 6 — IAM ROLE FOR EC2

## 1️⃣3️⃣ IAM Role Attached
Policies:
- AmazonSSMManagedInstanceCore  
- CloudWatchAgentServerPolicy  
- S3 Access  
- Custom Policy:
    ssm:GetParameter  
    kms:Decrypt  

---

# 🔷 PHASE 7 — BACKEND DEPLOYMENT TEST

## 1️⃣4️⃣ Launch Test EC2
- t2.medium  
- Private Subnet  
- Backend SG  
- IAM Role attached  

Used for manual validation.

---

# 🔷 PHASE 8 — BACKEND LAUNCH TEMPLATE

## 1️⃣5️⃣ Launch Template
User Data Script:
- Install Java  
- Download JAR  
- Fetch DB credentials  
- Start Spring Boot app  

---

# 🔷 PHASE 9 — BACKEND TARGET GROUP

## 1️⃣6️⃣ Target Group
- TCP 8084  
Health Check:
- HTTP  
- Port Override: 8084  
- Success: 200–499  

---

# 🔷 PHASE 10 — BACKEND LOAD BALANCING & ASG

## 1️⃣7️⃣ Internal NLB
- Internal  
- Multi-AZ  
- Listener TCP 80  

## 1️⃣8️⃣ Backend ASG
- Launch Template attached  
- Private Subnets  
- Health Check: ELB  
- Desired Capacity: 1  

---

# 🔷 PHASE 11 — INSTANCE VERIFICATION

## 1️⃣9️⃣ Validate via SSM

Commands:

    ps -aux | grep java
    cd /var/log/app
    cat datastore.log
    kill <PID>

Confirmed:
- Health check working  
- ASG replaces unhealthy instances  

---

# 🔷 PHASE 12 — CLOUDWATCH MONITORING

## 2️⃣0️⃣ Log Group
Application logs shipped to CloudWatch.

## 2️⃣1️⃣ Metric Filter
Pattern:
    ERROR  

Metric:
- Namespace: be-cw-ns  
- Metric: log-error  

## 2️⃣2️⃣ CloudWatch Alarm
- Period: 1 minute  
- Threshold ≥ 1  
- Action → SNS  

Real-time backend error detection.

---

# 🔷 PHASE 13 — SNS & LAMBDA ALERTING

## 2️⃣3️⃣ SNS Topic
Standard topic for backend-error.

Restricted publish access to CloudWatch Alarm ARN.

## 2️⃣4️⃣ Lambda Function
- Python 3.12  
- Trigger: SNS  
- Sends Slack alert  

## 2️⃣5️⃣ SNS Subscription
Protocol: Lambda  

Flow:
CloudWatch → SNS → Lambda → Slack  

---

# 🔷 PHASE 14 — SLACK INTEGRATION

## 2️⃣6️⃣ Create Slack App
- Enabled Incoming Webhooks  
- Generated Webhook URL  

## 2️⃣7️⃣ Lambda Environment Variable
    slackHookUrl = <Webhook>

Instant Slack alerts on backend errors.

---

# 🔷 PHASE 15 — ASG LIFECYCLE UNDERSTANDING

## 2️⃣8️⃣ EC2 Lifecycle
Pending → Running → Terminating → Terminated  

## 2️⃣9️⃣ ASG Lifecycle
Launch → Pending → Pending:Wait → Pending:Proceed → InService → Terminating → Terminated  

---

# 🔷 PHASE 16 — LIFECYCLE HOOK IMPLEMENTATION

## 3️⃣0️⃣ Problem
Instance entering InService before app ready.

## 3️⃣1️⃣ Lifecycle Hook
- EC2_INSTANCE_LAUNCHING  
- Heartbeat: 3600s  
- Default: ABANDON  

Ensures user data completion before traffic routing.

---

# 🔷 PHASE 17 — SCHEDULED SCALING

## 3️⃣2️⃣ Concept
Scale up during day, down at night.

## 3️⃣3️⃣ Scale Up
    0 6 * * 1-5  

## 3️⃣4️⃣ Scale Down
    30 19 * * 1-5  

Cost optimization strategy.

---

# 🔷 PHASE 18 — STORAGE OPTIMIZATION

## 3️⃣5️⃣ EBS Optimization
Changed gp3 → gp2 for cost control.

---

# 🔷 PHASE 19 — CHALLENGES & SOLUTIONS

## 3️⃣6️⃣ Issues Faced
- User data not executing  
- IAM permission denied  
- Health check failures  
- Cron expression error  

Resolved using logs, proper IAM, lifecycle hooks, and correct cron format.

---

# 🔷 PHASE 20 — SYSTEMD SERVICE

## 3️⃣7️⃣ Created systemd service
- Auto start on reboot  
- Restart on failure  
- Background process  

Production-grade reliability.

---

# 🔷 PHASE 21 — CLOUDWATCH DASHBOARD

## 3️⃣8️⃣ Dashboard Widgets
- CPU Utilization  
- Network In/Out  
- Healthy Hosts  
- Alarm Status  

Centralized monitoring.

---

# 🔷 PHASE 22 — TESTING & VALIDATION

## 3️⃣9️⃣ Test EC2
Validated:

    aws s3 ls
    aws ssm get-parameter  

Confirmed IAM + S3 + SSM functionality.

---

# 🔷 PHASE 23 — FRONTEND DEPLOYMENT

## 4️⃣0️⃣ Frontend Launch Template
Runs app on port 8501.

## 4️⃣1️⃣ Frontend Target Group
Health Check override: 8501.

## 4️⃣2️⃣ Application Load Balancer
Public ALB forwards to frontend.

## 4️⃣3️⃣ Frontend ASG
Private subnets, ELB health checks.

---

# 🔷 PHASE 24 — CDN LAYER (CLOUDFRONT)

## 4️⃣6️⃣ CloudFront Distribution
Origin: ALB  
HTTP → HTTPS redirect  
Caching enabled  

Architecture:

User  
  ↓  
CloudFront  
  ↓  
ALB  
  ↓  
Frontend  
  ↓  
Backend  
  ↓  
RDS  

---

# 🔷 PHASE 25 — CLOUDFRONT BEHAVIOR CONFIGURATION

## 4️⃣7️⃣ Origin Policy
HTTP Only to ALB.

## 4️⃣8️⃣ Behavior Settings
- Redirect HTTP → HTTPS  
- Custom headers for WebSocket  
- TTL controlled by origin headers  

---

# 🔷 PHASE 26 — HTTPS WITH ACM

## 4️⃣9️⃣ SSL Certificate
Requested & DNS validated.

Attached to CloudFront.

Fully encrypted traffic.

---

# 🔷 PHASE 27 — CUSTOM DOMAIN

## 5️⃣0️⃣ Add CNAME
Mapped domain → CloudFront distribution.

---

# 🔷 PHASE 28 — AWS WAF

## 5️⃣1️⃣ IP Set  
## 5️⃣2️⃣ Web ACL (Global)

Attached to CloudFront.

---

# 🔷 PHASE 29 — ADVANCED WAF

## 5️⃣3️⃣ IP Allow Rule  
## 5️⃣4️⃣ IPv6 Support  
## 5️⃣5️⃣ Custom 403 Page  
## 5️⃣6️⃣ Geo Blocking  

Enhanced security filtering.

---

# 🔷 PHASE 30 — FINAL DNS RESOLUTION

## 5️⃣7️⃣ DNS Concept  
## 5️⃣8️⃣ CNAME Record (GoDaddy/Route53)

---

# 🔷 PHASE 31 — ALTERNATE DOMAIN (CLOUDFRONT)

## 5️⃣9️⃣ Added Alternate Domain Name
Attached validated ACM certificate.

---

# 🔷 PHASE 32 — SECURITY VERIFICATION

## 6️⃣0️⃣ Verified:
- WAF attached  
- HTTPS enforced  
- Access rules functioning  

---

# 🔷 PHASE 33 — BASTION HOST

## 6️⃣1️⃣ Bastion EC2
Public subnet, SSH from personal IP only.

## 6️⃣2️⃣ RDS SG Updated
Allowed connection only from Bastion SG.

---

# 🔷 PHASE 34 — CONNECT RDS

Used MySQL Workbench over SSH.

Validated:
- RDS not publicly accessible  
- Secure tunnel working  

---

# 🔷 PHASE 35 — FINAL SECURITY HARDENING

Improved:
✔ IAM least privilege  
✔ KMS encryption  
✔ Parameter security  
✔ Controlled database access  

---

# 🎯 FINAL ARCHITECTURE FLOW

User  
  ↓  
CloudFront  
  ↓  
WAF  
  ↓  
ALB  
  ↓  
Frontend ASG  
  ↓  
Internal NLB  
  ↓  
Backend ASG  
  ↓  
RDS  

Monitoring:

Logs → CloudWatch → Metric Filter → Alarm → SNS → Lambda → Slack  

---

# ✅ PROJECT OUTCOME

✔ Multi-AZ high availability  
✔ Auto Scaling with lifecycle hooks  
✔ Monitoring & real-time Slack alerts  
✔ CDN & HTTPS  
✔ WAF security hardening  
✔ Cost optimization (Scheduled Scaling + EBS tuning)  
✔ Secure secret management  
✔ Bastion-based DB access  
✔ Production-grade deployment  

Complete end-to-end AWS full stack deployment built manually with enterprise architecture standards.
