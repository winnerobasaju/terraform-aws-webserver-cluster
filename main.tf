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

data "aws_vpc" "existing_vpc" {
  count = var.use_existing_vpc ? 1 : 0

  filter {
    name   = "tag:Name"
    values = ["existing-vpc"]
  }
}

data "aws_route53_zone" "primary" {
  name = var.domain_name
}

resource "aws_vpc" "new" {
  count = var.use_existing_vpc ? 1 :0
  cidr_block = "10.0.0.0/16"
}

locals {
  vpc_id = var.use_existing_vpc ? data.aws_vpc.existing_vpc[0].id : aws_vpc.new[0].id
}

resource "aws_security_group_rule" "ssh" {
  for_each  = var.enable_ssh ? toset(["0.0.0.0/0"]) : []
  type = "ingress"
  security_group_id = aws_security_group.web_sg.id
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = each.value
}

resource "aws_security_group_rule" "http" {
  for_each = toset(var.allowed_cidr_blocks)

  type = "ingress"
  security_group_id = aws_security_group.web_sg.id
  from_port = var.server_port
  to_port = var.server_port
  protocol = "tcp"
  cidr_blocks = [ each.value ]
  
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
    instance_type = local.instance_type
    key_name = var.key_name

    network_interfaces {
      associate_public_ip_address = true
      security_groups = [ aws_security_group.web_sg.id ]
    }


    user_data = base64encode(templatefile("$path.module/user_data.sh", {
      server_port = var.server_port
    }))
}

#Auto Scaling Group
resource "aws_autoscaling_group" "web_asg" {
    count = var.enable_autoscaling ? 1 : 0

    name = "${var.cluster_name}-asg"
    

    max_size = local.max_size
    min_size = local.min_size
    desired_capacity = local.min_size
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

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = local.enable_monitoring ? 1 : 0

  alarm_name = "${var.cluster_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 120
  statistic = "Average"
  threshold = 80
  alarm_description = "Alarm when CPU exceeds 80% for 4 minutes"
}

resource "aws_route53_record" "alb_dns" {
  count = var.create_dns_record ? 1 : 0

  zone_id = data.aws_route53_zones.primary.zone_id
  name = var.domain_name
  type = "A"

  alias {
    name = aws_lb.web_alb.dns_name
    zone_id = aws_lb.web_alb.zone_id
    evaluate_target_health = true
  }
}

