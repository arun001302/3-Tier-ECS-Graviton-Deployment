# =============================================================================
# ACM Module Outputs
# =============================================================================

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate.main.arn
}

output "certificate_domain_name" {
  description = "Domain name of the certificate"
  value       = aws_acm_certificate.main.domain_name
}

output "certificate_status" {
  description = "Status of the certificate"
  value       = aws_acm_certificate.main.status
}

output "validation_record_fqdns" {
  description = "FQDNs of the validation records"
  value       = [for record in aws_route53_record.validation : record.fqdn]
}

output "certificate_arn_validated" {
  description = "ARN of the validated certificate (use this for ALB)"
  value       = aws_acm_certificate_validation.main.certificate_arn
}