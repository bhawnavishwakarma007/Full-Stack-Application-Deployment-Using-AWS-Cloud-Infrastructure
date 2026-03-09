#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -x

echo "Executing User Data - DEV Environment"

REGION="us-east-1"

# --------------------------------------------------
# System Update & Install Dependencies
# --------------------------------------------------
yum update -y
yum install -y java-11-amazon-corretto amazon-cloudwatch-agent

# --------------------------------------------------
# Create Log Directory
# --------------------------------------------------
mkdir -p /var/log/app/
chown ec2-user:ec2-user /var/log/app/

cd /home/ec2-user

# --------------------------------------------------
# Fetch Secure Parameters from SSM Parameter Store
# (Using AWS managed key aws/ssm)
# --------------------------------------------------
echo "Fetching parameters from SSM..."

MYSQL_HOST=$(aws ssm get-parameter \
  --name "/cheetah/dev/mysql/host" \
  --region $REGION \
  --with-decryption \
  --query "Parameter.Value" \
  --output text)

MYSQL_USERNAME=$(aws ssm get-parameter \
  --name "/cheetah/dev/mysql/username" \
  --region $REGION \
  --with-decryption \
  --query "Parameter.Value" \
  --output text)


MYSQL_PASSWORD=$(aws ssm get-parameter \
  --name "/cheetah/dev/mysql/password" \
  --region $REGION \
  --with-decryption \
  --query "Parameter.Value" \
  --output text)

echo "Parameters fetched successfully"

# --------------------------------------------------
# Download Spring Boot Application
# --------------------------------------------------
aws s3 cp s3://cheetah-dev-be-app-bucket-new/datastore-0.0.7.jar .

chmod 755 datastore-0.0.7.jar
chown ec2-user:ec2-user datastore-0.0.7.jar

# --------------------------------------------------
# Start Spring Boot Application
# --------------------------------------------------
echo "Starting Spring Boot application..."
MYSQL_HOST=jdbc:mysql://$MYSQL_HOST:3306/datastore?createDatabaseIfNotExist=true MYSQL_USERNAME=$MYSQL_USERNAME MYSQL_PASSWORD=$MYSQL_PASSWORD LOG_FILE_PATH=/var/log/app/datastore.log nohup java -jar /home/ec2-user/datastore-0.0.7.jar > /var/log/app/nohup.out 2>&1 &

# --------------------------------------------------
# Configure CloudWatch Agent
# --------------------------------------------------
cat << EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/app/datastore.log",
            "log_group_name": "/datastore/app",
            "log_stream_name": "{instance_id}",
            "timestamp_format": "%Y-%m-%d %H:%M:%S"
          }
        ]
      }
    }
  }
}
EOF

# --------------------------------------------------
# Start CloudWatch Agent
# --------------------------------------------------
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

echo "User data execution completed successfully"
