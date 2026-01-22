output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "Target group ARN for ECS service"
  value       = aws_lb_target_group.backend.arn
}

output "alb_security_group_id" {
  description = "Security group of ALB"
  value       = aws_security_group.alb_sg.id
}

output "cert_validation_records" {
  description = "Validation records for the ACM certificate"
  value       = aws_acm_certificate.api_cert.domain_validation_options
}
