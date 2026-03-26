user_data = base64encode(<<-EOF
#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
echo "Hello from ${var.cluster_name}" > /var/www/html/index.html
EOF
)