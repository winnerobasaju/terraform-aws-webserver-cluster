variable "cluster_name" {
  description = "The name to use for all cluster resources"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the cluster"
  type        = string
  default     = "t2.micro"
}

variable "min_size" {
  description = "Minimum number of EC2 instances in the ASG"
  type        = number
}

variable "max_size" {
  description = "Maximum number of EC2 instances in the ASG"
  type        = number
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances in the ASG"
  type        = number
}

variable "server_port" {
  description = "Port the server uses for HTTP"
  type        = number
  default     = 8080
}

variable "vpc_id" {
  description = "The VPC ID where resources will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ALB and ASG"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ami_id" {
  description = "The AMI ID to use for the EC2 instances"
  type        = string
}

variable "key_name" {
  description = "The optional name of the SSH key pair to use for the EC2 instances"
  type        = string
    default     = null
}

variable "enable_ssh" {
  description = "Enable SSH access to the instance"
  type = bool
  default = false
  
}

variable "enable_autoscaling" {
  description = "Enable autoscaling for the cluster"
  type = bool
  default = true
}

variable "environment" {
  description = "The environment to deploy the cluster in (e.g. dev, staging, production)"
  type = string
  
  validation {
    condition = contains(["dev", "staging", "production"], var.environment)
    error_message = "Invalid environment. Please choose from: dev, staging, production."
  }
}


locals {
  is_production = var.environment == "production"


  instance_type = local.is_production ? "t3.medium" : "t2.micro"
  min_size = local.is_production ? 3 : 1
  max_size = local.is_production ? 10 : 3
  enable_monitoring = local.is_production
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed cloudwatch monitoring for the cluster"
  type = bool
  default = false 
}

variable "create_dns_record" {
  description = "Whether to create route53 dns record"
  type = bool
  default = false
}

variable "domain_name" {
  description = "The domain name to use for the route53 record"
  type = string
  default = null
}

variable "use_existing_vpc" {
  description = "Whether to use an existing VPC"
  type = bool
  default = false
}