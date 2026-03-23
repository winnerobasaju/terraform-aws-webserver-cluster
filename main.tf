#Security Group for the Web Server Cluster
resource "aws_security_group" "web_sg" {
    name = "${var.cluster_name}-sg"
    description = "Security group for ${var.cluster_name} web servers"
    vpc_id = var.vpc_id

    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = var.allowed_cidr_blocks
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}

#Application Load Balancer
resource "aws_lb" "web_alb" {
    name = "${var.cluster_name}-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [ aws_security_group.web_sg.id ]
    subnets = var.subnet_ids
}

#Target Group for the ALB
resource "aws_lb_target_group" "tg" {
    name = "${var.cluster_name}-tg"
    port = var.server_port
    protocol = "HTTP"
    vpc_id = var.vpc_id
    health_check {
      path = "/"
      interval = 30
      timeout = 5
      healthy_threshold = 3
      unhealthy_threshold = 3
    }
}

#Listener for the ALB
resource "aws_lb_listener" "listener" {
    load_balancer_arn = aws_lb.web_alb.arn
    port = var.server_port
    protocol = "HTTP"

    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.tg.arn
    }
}

#Launch Template for the ASG
resource "aws_launch_template" "web_template" {
    name_prefix = "${var.cluster_name}-lt"
    image_id = var.ami_id
    instance_type = var.instance_type
    key_name = var.key_name

    network_interfaces {
      associate_public_ip_address = true
      security_groups = [ aws_security_group.web_sg.id ]
    }


    user_data = base64encode(<<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y httpd
    sudo systemctl start httpd
    sudo systemctl enable httpd
    echo "Hello from ${var.cluster_name}" > /var/www/html/index.html
    EOF
    )
}

#Auto Scaling Group
resource "aws_autoscaling_group" "web_asg" {
    name = "${var.cluster_name}-asg"
    max_size = var.max_size
    min_size = var.min_size
    desired_capacity = var.desired_capacity
    vpc_zone_identifier = var.subnet_ids

    launch_template {
      id = aws_launch_template.web_template.id
      version = "$Latest"
    }

    target_group_arns = [ aws_lb_target_group.tg.arn ]

    tag {
      key = "Name"
      value = var.cluster_name
      propagate_at_launch = true
    }

    lifecycle {
      create_before_destroy = true
    }
}