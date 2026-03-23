output "alb_dns_name" {
    value = aws_lb.web_alb.dns_name
    description = "The DNS name of the application load balancer"
}

output "asg_name" {
    value = aws_autoscaling_group.web_asg.name
    description = "The name of the autoscaling group"
}

output "security_group_id" {
    value = aws_security_group.web_sg.id
    description = "The ID of the security group for the web servers"
}