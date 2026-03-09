#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -x

echo "Executing User_Data In dev"

# Update and install Java
yum update -y

# Installing Python
sudo dnf install -y python3-pip

# Creating Virtual Environment
cd /root
python3 -m venv /root/venv
source /root/venv/bin/activate
pip install --upgrade pip
pip install streamlit requests

aws s3 cp s3://cheetah-dev-fe-app-bucket/app.py /root/

cat << EOF > /etc/systemd/system/frontend.service
[Unit]
Description=Streamlit Frontend App
After=network.target

[Service]
User=root
WorkingDirectory=/root
ExecStart=/root/venv/bin/streamlit run app.py --server.port=8501 --server.address=0.0.0.0
Environment=API_URL=http://cheetah-dev-backend-lb-cf954d3679c06e98.elb.us-east-1.amazonaws.com
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable frontend
systemctl start frontend
