# 🚀 Full-Stack AWS Deployment with Monitoring & Security

## 📌 Project Overview

This project implements a **secure, scalable, production-ready full-stack application architecture on AWS**.

It includes:

- Custom domain with SSL
- CDN + WAF protection
- Auto Scaling (Frontend & Backend)
- Private RDS database
- Centralized logging
- CloudWatch-based alerting
- Slack notifications
- Cost optimization using lifecycle hooks & scheduling

---

# 🏗 Architecture Overview

## 🌐 Traffic Flow

    User
      ↓
    GoDaddy (DNS)
      ↓
    AWS Certificate Manager (SSL)
      ↓
    CloudFront (CDN)
      ↓
    AWS WAF
      ↓
    Application Load Balancer (ALB)
      ↓
    Frontend Auto Scaling Group (EC2)
      ↓
    Network Load Balancer (NLB)
      ↓
    Backend Auto Scaling Group (EC2)
      ↓
    Amazon RDS (MySQL - Private Subnet)

---

## 📊 Logging & Alerting Flow

    EC2 Logs
      ↓
    CloudWatch Log Group
      ↓
    Metric Filter
      ↓
    CloudWatch Alarm
      ↓
    SNS Topic
      ↓
    Lambda Function
      ↓
    Slack Channel

---

# 🧰 AWS Services Used

## 🌐 Networking & Security

- Amazon CloudFront  
- AWS WAF  
- AWS Certificate Manager (ACM)  
- Security Groups  
- Application Load Balancer (ALB)  
- Network Load Balancer (NLB)

## 🖥 Compute

- EC2 (Frontend ASG)  
- EC2 (Backend ASG)  
- Lifecycle Hooks  
- Scheduling (Cost optimization)

## 🗄 Storage

- Amazon S3 (Frontend artifacts)  
- Amazon S3 (Backend artifacts)

## 🛢 Database

- Amazon RDS (MySQL)  
- Private Subnet Group

## 📊 Monitoring

- CloudWatch Logs  
- Metric Filters  
- CloudWatch Alarms  
- SNS  
- Lambda  
- Slack Webhook  

---

# ⚠️ Issues Faced & Resolutions

---

## 1️⃣ Metric Filter Button Disabled in CloudWatch

### Issue
Unable to create metric filter.

### Error Observed
"Create metric filter" button disabled.

### Root Cause
Metric filters can only be created at **Log Group level**, not inside a Log Stream.

### Fix
Navigate correctly:

    CloudWatch → Log Groups → /application-log-group

---

## 2️⃣ Lambda Error – KeyError: 'Records'

### Error Observed
KeyError: 'Records'

### Root Cause
Lambda expected SNS event structure:

    event['Records'][0]['Sns']['Message']

Manual test event did not follow SNS format.

### Fix
Created proper SNS test payload.

---

## 3️⃣ Lambda Not Triggered by SNS

### Root Cause
SNS policy referenced wrong Topic ARN.

### Fix
Updated SNS policy with correct ARN.

---

## 4️⃣ Only One Slack Notification for Multiple Errors

### Root Cause
CloudWatch alarms are **state-based**, not event-based.

    OK → ALARM → Notification  
    ALARM → ALARM → No notification  

### Fix
Understood behavior.

For per-log alerts → use Subscription Filter → Lambda.

---

## 5️⃣ Missing JAR File on EC2

### Error Observed
cannot access 'datastore-0.0.7.jar'  
No such file or directory

### Root Cause
JAR file not present on EC2 instance.

### Fix
Downloaded artifact from S3.

---

## 6️⃣ S3 Access Denied (403)

### Error Observed
An error occurred (403) when calling HeadObject: Forbidden

### Root Cause
EC2 instance had no IAM role.

### Fix
Attached IAM role with:

    AmazonS3ReadOnlyAccess

---

## 7️⃣ CloudFront 403 Error

### Root Cause
- Domain not mapped correctly  
- WAF rule blocking requests  

### Fix
- Added correct CNAME  
- Attached ACM certificate  
- Refined WAF rules  

---

## 8️⃣ ACM Certificate Stuck in Pending Validation

### Root Cause
CAA record did not allow Amazon certificate authority.

### Fix

    0 issue "amazon.com"
    0 issue "amazontrust.com"

Certificate status changed to **Issued**.

---

## 9️⃣ WAF Blocking All Traffic

### Root Cause
Broad blocking rule matched all traffic.

### Fix
- Refined match conditions  
- Adjusted rule priority  
- Tested in Count mode first  

---

## 🔟 WAF Custom Response Not Appearing

### Root Cause
Rule order misconfiguration.

### Fix
Adjusted rule priority and match conditions.

---

## 1️⃣1️⃣ Country-Based Blocking Issue

### Root Cause
Geo restriction rule allowed only specific country.

### Fix
- Switched rule to Count for testing  
- Expanded allowed countries  

---

## 1️⃣2️⃣ MySQL Workbench SSH Tunnel Error

### Architecture

    Laptop → SSH → EC2 → RDS

### Error Observed
Lost connection to MySQL server at  
'reading initial communication packet'

### Root Cause
RDS Security Group did not allow EC2 Security Group.

### Fix

RDS SG → Inbound:

- Type: MySQL/Aurora  
- Port: 3306  
- Source: EC2 Security Group  

Connection successful.

---

## 1️⃣3️⃣ Security Group Misconfiguration (Internal Communication Failure)

### Root Cause
Security Groups allow traffic only from explicitly defined sources.

### Fix
Explicitly allowed:

- ALB SG → Frontend SG  
- NLB → Backend SG  
- EC2 SG → RDS SG  

Implemented **least privilege design**.

---

## 1️⃣4️⃣ Cron Expression Error (Auto Scaling Scheduled Action)

### Error Observed
Given recurrence string:  
0 0 6 * * 1 - 5 is invalid

### Root Cause
System expected **5-field cron format**, not 6-field.

Used incorrectly:

    0 0 6 * * 1-5

### Fix
Used correct 5-field format:

    0 6 * * 1-5

Scheduled action created successfully.

### Lesson Learned

- Always confirm 5-field vs 6-field cron format  
- Never add spaces in ranges (1-5, not 1 - 5)  
- AWS services may use different cron interpretations  

---

## 1️⃣5️⃣ Backend Not Reachable After Creating NLB

### Problem
Frontend was using:

    API_URL = "http://localhost:8081"

After deploying NLB, requests failed.

### Root Causes Identified
- localhost works only within same machine  
- Backend possibly bound to 127.0.0.1  
- Incorrect endpoint reference  
- Security group blocking backend port  

### Fix

Updated API URL:

    API_URL = "http://dev-nlb-97d4fdee62657c1c.elb.us-east-1.amazonaws.com"

Ensured backend runs with:

    host="0.0.0.0"

Verified:
- Target group status → Healthy  
- Port open in Security Group  
- Listener correctly configured  

Backend became reachable via NLB.

---

# 🔐 Security Design Highlights

- RDS deployed in private subnet  
- No public database exposure  
- WAF geo-restriction rule  
- IP allow rule  
- Custom response body (401)  
- SSL via ACM  
- Security Groups referencing each other (least privilege)  
- IAM roles instead of static credentials  

---

# 💰 Cost Optimization

- Auto Scaling Groups (Frontend & Backend)  
- Lifecycle Hooks  
- Instance scheduling  
- Separate frontend and backend scaling  
- NLB used for backend service routing  

---

# ✅ Final Outcome

- End-to-end secure full-stack architecture  
- Scalable frontend and backend tiers  
- Centralized logging & alerting  
- Slack-based monitoring notifications  
- Hardened WAF and SSL configuration  
- Secure RDS connectivity  
- IAM-based secure S3 access  
- Production-ready infrastructure  

---
