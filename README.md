# Webserver Cluster Module

This module creates a fully managed web server cluster using:

- Auto Scaling Group
- Application Load Balancer (ALB)
- EC2 instances

## Inputs

- `cluster_name` — name for all resources
- `instance_type` — EC2 instance type
- `min_size` — minimum ASG size
- `max_size` — maximum ASG size
- `desired_capacity` — desired ASG size
- `server_port` — port for HTTP
- `vpc_id` — VPC where resources will be deployed
- `subnet_ids` — list of subnets for ALB and ASG
- `allowed_cidr_blocks` — IPs allowed to access the ALB

## Outputs

- `alb_dns_name` — ALB DNS name
- `asg_name` — Auto Scaling Group name