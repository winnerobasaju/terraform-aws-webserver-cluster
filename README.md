# Webserver Cluster Module

## Overview
This Terraform module deploys a highly available web server cluster on AWS. It provisions an Auto Scaling Group (ASG) of EC2 instances behind an Application Load Balancer (ALB). All resources are configurable via input variables, allowing you to specify instance types, cluster size, AMI, VPC/subnet placement, and optional SSH access. This module is intended to be reusable across multiple environments, supporting versioned deployment patterns.

---

## Input Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `cluster_name` | string | n/a | The name prefix to use for all resources in the cluster |
| `instance_type` | string | `"t2.micro"` | EC2 instance type for the cluster |
| `ami_id` | string | n/a | The AMI ID to launch instances with |
| `min_size` | number | n/a | Minimum number of instances in the ASG |
| `max_size` | number | n/a | Maximum number of instances in the ASG |
| `vpc_id` | string | n/a | VPC where instances will be deployed |
| `subnet_ids` | list(string) | n/a | List of subnet IDs for the ASG |
| `server_port` | number | `8080` | Port on which the web server will listen |
| `key_name` | string | `null` | Optional EC2 key pair for SSH access |
| `enable_ssh` | bool | `false` | Optional flag to create SSH ingress rule for the security group |
| `desired_capacity` | number | `null` | Optional desired number of instances in the ASG; defaults to `min_size` if not provided |

---

## Outputs

| Name | Description |
|------|-------------|
| `alb_dns_name` | The DNS name of the Application Load Balancer |
| `asg_name` | The name of the Auto Scaling Group |
| `security_group_id` | The ID of the security group associated with the cluster instances |

---

## Usage Example

```hcl
module "webserver_cluster" {
  source = "github.com/winnerobasaju/terraform-aws-webserver-cluster?ref=v0.0.2"

  cluster_name  = "webservers-dev"
  ami_id        = "ami-0abcdef1234567890"
  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 4
  server_port   = 80

  vpc_id     = "vpc-0123456789abcdef"
  subnet_ids = ["subnet-1234abcd", "subnet-5678efgh"]

  enable_ssh = true
  key_name   = "my-keypair"
}