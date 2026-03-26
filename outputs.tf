output "alb_dns_name" {
    value = aws_lb.web_alb.dns_name
    description = "The DNS name of the application load balancer"
}

output "asg_name" {
    value = var.enable_autoscaling ? aws_autoscaling_group.web_asg[0].name : null
    description = "The name of the autoscaling group only if enabled"
}

output "security_group_id" {
    value = aws_security_group.web_sg.id
    description = "The ID of the security group for the web servers"
}

output "alarm_arn" {
    value = local.enable_monitoring ? aws_cloudwatch_metric_alarm.high_cpu[0].arn : null
    description = "The ARN of the cloudwatch metric alarm for high cpu utilization"
}

output "dns_record_name" {
    value = var.create_dns_record ? aws_route53_record.alb_dns[0].name : null
    description = "The name of the route 53 record if created"
}