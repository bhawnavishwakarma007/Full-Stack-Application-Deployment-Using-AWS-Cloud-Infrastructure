# 🚀 FULL STACK AWS PROJECT – MANUAL DEPLOYMENT (STEP-BY-STEP)

This project was created manually using the AWS Console following a structured order — from networking to application deployment, monitoring, scaling, CDN, and security hardening.

---
# Architecture Diagram

![Architecture](images/architecture.png)
---

# 🔷 PHASE 1 — NETWORK SETUP

## 1️⃣ Create VPC

Service Used: Amazon VPC

Name: dev-vpc  
CIDR Block: 10.0.0.0/16  

This creates the isolated virtual network for the entire infrastructure.

---

## 2️⃣ Create Subnets (Multi-AZ)

### Public Subnets

dev-pub-sub-1 → us-east-1a → 10.0.0.0/24  
dev-pub-sub-2 → us-east-1b → 10.0.1.0/24  
dev-pub-sub-3 → us-east-1c → 10.0.2.0/24  

### Private Subnets

dev-pvt-sub-1 → us-east-1a → 10.0.3.0/24  
dev-pvt-sub-2 → us-east-1b → 10.0.4.0/24  
dev-pvt-sub-3 → us-east-1c → 10.0.5.0/24  

Ensures high availability across three Availability Zones.

---

## 3️⃣ Create Internet Gateway

Service Used: Internet Gateway

- Created Internet Gateway  
- Attached it to dev-vpc  

Purpose:  
Allows public subnets to communicate with the internet.

---

## 4️⃣ Create NAT Gateway

Service Used: NAT Gateway

- Created manually  
- Placed inside Public Subnet (1a)  
- Attached Elastic IP  

Purpose:  
Allows private instances to access the internet securely without public exposure.

---

## 5️⃣ Configure Route Tables

### Public Route Table

Route:  
0.0.0.0/0 → Internet Gateway  

Attached to:  
dev-pub-sub-1  
dev-pub-sub-2  
dev-pub-sub-3  

### Private Route Table

Route:  
0.0.0.0/0 → NAT Gateway  

Attached to:  
dev-pvt-sub-1  
dev-pvt-sub-2  
dev-pvt-sub-3  

---

## 6️⃣ Enable VPC Flow Logs

Enabled VPC Flow Logs to:

- Monitor traffic  
- Understand networking behavior  
- Debug connectivity issues  

---

# 🔷 PHASE 2 — SECURITY GROUP DESIGN (LAYERED SECURITY)

Security was designed in strict layered architecture.

## 7️⃣ Create Security Groups

### ALB Security Group

HTTP (80) → 0.0.0.0/0  

### Frontend Security Group

TCP 8501 → From ALB Security Group  

### NLB Security Group

TCP 80 → From Frontend Security Group  

### Backend Security Group

TCP 8084 → From NLB Security Group  

### RDS Security Group

MySQL / Aurora → Port 3306  
Source → Backend Security Group  

This ensures:

- No direct database exposure  
- No public backend access  
- Strict service-to-service communication  

---

# 🔷 PHASE 3 — DATABASE CONFIGURATION

## 8️⃣ Create DB Subnet Group

Included:

- Private Subnet 1a  
- Private Subnet 1b  
- Private Subnet 1c  

Ensures Multi-AZ database placement.

---

## 9️⃣ Create RDS Instance

Engine: MySQL / Aurora  
Public Access: Disabled  
Subnet Group: Private Subnets  
Security Group: RDS SG  
Logging: Enabled  
Encryption: Enabled using KMS  

### 🔐 Encryption Configuration

Encryption at Rest → Data encrypted before storage  
Encryption in Transit → Data encrypted while moving between services  

---

# 🔷 PHASE 4 — ACCESS MANAGEMENT & SECRETS

## 🔟 Configure Systems Manager Access

Configured SSM so that:

- EC2 instances in private subnet can be accessed  
- No Bastion Host required  
- No public IP required  

Secure login into private instances using Session Manager.

---

## 1️⃣1️⃣ Create Parameters in Parameter Store

### Database Host

Name: /cheetah/dev/mysql/host  
Type: String  
Value: RDS Endpoint  

### Database Username

Name: /cheetah/dev/mysql/username  
Type: String  
Value: admin  

### Database Password

Name: /cheetah/dev/mysql/password  
Type: SecureString  
Encryption: KMS  
Value: RDS Password  

Ensures:

- No hardcoded credentials  
- Secure encrypted storage  

---

# 🔷 PHASE 5 — APPLICATION ARTIFACT STORAGE

## 1️⃣2️⃣ Create S3 Bucket

Uploaded:

- Backend JAR file  

Bucket accessed by EC2 during deployment.

---

# 🔷 PHASE 6 — IAM ROLE FOR EC2

## 1️⃣3️⃣ Create IAM Role (For EC2)

Attached Managed Policies:

- AmazonSSMManagedInstanceCore  
- S3 Full Access  
- CloudWatchAgentServerPolicy  

Created Custom Policy:

Permissions:

- ssm:GetParameter  
- kms:Decrypt  

Purpose:

- Fetch secure DB credentials  
- Access S3 bucket  
- Allow SSM login  
- Allow log publishing  

---

# 🔷 PHASE 7 — BACKEND DEPLOYMENT TEST

## 1️⃣4️⃣ Launch EC2 Instance (Testing)

Instance Type: t2.medium  
Subnet: Private Subnet 2  
IAM Role: Attached  
Security Group: Backend SG  

Used for manual verification before automation.

---

# 🔷 PHASE 8 — CREATE LAUNCH TEMPLATE (BACKEND)

## 1️⃣5️⃣ Create Launch Template

Configured:

- Instance Type: t2.medium  
- Key Pair  
- Backend Security Group  
- IAM Role  
- User Data script  

User Data performs:

- Install Java  
- Download JAR from S3  
- Fetch DB credentials from SSM  
- Start Spring Boot application  

---

# 🔷 PHASE 9 — CREATE TARGET GROUP (BACKEND)

## 1️⃣6️⃣ Create Target Group

Protocol: TCP  
Port: 8084  

Health Check:

Protocol: HTTP  
Port Override: 8084  
Success Code: 200–499  

---

# 🔷 PHASE 10 — BACKEND LOAD BALANCING & AUTO SCALING

## 1️⃣7️⃣ Create Internal NLB

Type: Internal  
Subnets: Private Subnet 1 & 2  
Listener: TCP 80  
Forward to: Backend Target Group  

Purpose:

Expose backend only inside VPC.

---

## 1️⃣8️⃣ Create Backend ASG

Launch Template: Backend LT  
Subnets: Private Subnet 1 & 2  
Attach to Target Group  
Health Check Type: ELB  
Desired Capacity: 1  

---

# 🔷 COMPLETE MONITORING PIPELINE

Backend Application Logs  
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
Slack Channel  

---

# 🔷 AUTO SCALING LIFECYCLE STATES

Normal EC2:

Pending → Running → Terminating → Terminated  

ASG Lifecycle:

Launch  
   ↓  
Pending  
   ↓  
Pending:Wait  
   ↓  
Pending:Proceed  
   ↓  
InService  
   ↓  
Terminating  
   ↓  
Terminating:Wait  
   ↓  
Terminating:Proceed  
   ↓  
Terminated  

Lifecycle Hooks used during:

- Launch  
- Termination  

Heartbeat Timeout: 3600 seconds  

---

# 🔷 SCHEDULED SCALING

Scale Up (Weekdays 6 AM):

0 6 * * 1-5  

Scale Down (Weekdays 7:30 PM):

30 19 * * 1-5  

Cost optimization strategy implemented.

---

# 🔷 CLOUD ARCHITECTURE (FINAL)

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

---

# 🔷 SECURITY HARDENING

- WAF IP Allow/Block Rules  
- Geo Blocking  
- Custom 403 Response  
- HTTPS via ACM  
- KMS Encryption  
- Least Privilege IAM  
- Bastion Host for DB access  
- Parameter Store SecureString  

---

# 🔷 FINAL VALIDATION

✔ High Availability (Multi-AZ)  
✔ Auto Scaling Enabled  
✔ Monitoring & Alerting Working  
✔ Slack Real-Time Alerts  
✔ CDN Integrated  
✔ HTTPS Enforced  
✔ WAF Protection Active  
✔ Database Private  
✔ Secure Access via Bastion & SSM  
✔ Production-grade systemd services  

---

# 🎯 RESULT

A complete production-style AWS full stack architecture built manually via AWS Console with:

Networking  
Security  
Database  
Auto Scaling  
Monitoring  
Alerting  
CDN  
WAF  
DNS  
SSL  
Cost Optimization  
Lifecycle Management  
Encryption  

End-to-end cloud infrastructure implementation from scratch.
