# ⚠️ Issues Faced During Implementation & Fixes

During the implementation of the **CloudWatch Error Monitoring with Slack Notifications** pipeline, several issues were encountered. Below are the problems identified and the solutions used to resolve them.

---

## 1️⃣ Metric Filter Button Disabled in CloudWatch

### Issue
While creating a metric filter in CloudWatch, the **"Create metric filter"** button was disabled.

### Cause
Metric filters can only be created at the **Log Group level**, but the navigation was inside a **Log Stream**.

### Fix
Navigated to the correct location:

    CloudWatch → Log Groups → /datastore/app

Then created the metric filter successfully.

---

## 2️⃣ Lambda Test Error – KeyError: 'Records'

### Issue
Lambda execution failed during manual testing with the error:

    KeyError: 'Records'

### Cause
The Lambda function was written to process **SNS events**, but the manual test event did not follow the SNS event structure.

The function expected:

    event['Records'][0]['Sns']['Message']

### Fix
Created a proper SNS test event:

    {
      "Records": [
        {
          "Sns": {
            "Message": "{\"AlarmName\":\"HighCPUAlarm\",\"NewStateValue\":\"ALARM\",\"NewStateReason\":\"Threshold Crossed\"}"
          }
        }
      ]
    }

After using the correct event format, the Lambda test executed successfully.

---

## 3️⃣ Lambda Not Triggered by SNS

### Issue
Lambda worked when tested manually but was **not triggered when the CloudWatch alarm fired**.

### Investigation
Verified the following configurations:

- SNS subscription
- Lambda trigger configuration
- CloudWatch alarm action

All configurations appeared correct.

### Root Cause
The **SNS access policy referenced the wrong topic ARN**.

Incorrect topic:

    cheetah-dev-be-error-notify

Actual topic used:

    dev-sns-cw

### Fix
Updated the SNS policy with the correct ARN:

    "Resource": "arn:aws:sns:us-east-1:ACCOUNT-ID:dev-sns-cw"

After updating the policy, SNS successfully triggered the Lambda function.

---

## 4️⃣ Only One Slack Notification for Multiple Errors

### Issue
Multiple **ERROR logs** were generated, but only **one Slack notification** was received.

### Cause
CloudWatch alarms send notifications **only when the alarm state changes**.

State transition behavior:

    OK → ALARM → Notification Sent
    ALARM → ALARM → No Notification

Once the alarm enters the **ALARM state**, additional errors do not trigger new notifications.

### Alternative Approach
For real-time alerts for every log event, use the following architecture:

    CloudWatch Logs
          ↓
    Subscription Filter
          ↓
    Lambda
          ↓
    Slack Notification

---

## 5️⃣ Missing JAR File on EC2 Instance

### Issue
Application failed to start with the error:

    cannot access 'datastore-0.0.7.jar': No such file or directory

### Cause
The application **JAR file was not present** on the EC2 instance.

### Fix
Downloaded the artifact from S3:

    aws s3 cp s3://bucket-name/datastore-0.0.7.jar .

After downloading the file, the application started successfully.

---

## 6️⃣ S3 Access Denied Error

### Issue
Downloading the JAR file from S3 failed with:

    An error occurred (403) when calling the HeadObject operation: Forbidden

### Cause
The EC2 instance **did not have permission** to access the S3 bucket.

### Fix
Attached an IAM role to the EC2 instance with the following permission:

    AmazonS3ReadOnlyAccess

After attaching the role, the file was downloaded successfully.

---

# ✅ Final Monitoring Pipeline Architecture

The troubleshooting steps above helped in successfully implementing the monitoring pipeline:

    Application Logs
          ↓
    CloudWatch Logs
          ↓
    Metric Filter
          ↓
    CloudWatch Alarm
          ↓
    SNS Topic
          ↓
    Lambda Function
          ↓
    Slack Notification
