# =============================================================================
# Route53 Module Outputs
# =============================================================================

output "fqdn" {
  description = "Fully qualified domain name of the record"
  value       = aws_route53_record.main.fqdn
}

output "record_name" {
  description = "Name of the DNS record"
  value       = aws_route53_record.main.name
}

output "zone_id" {
  description = "Zone ID where the record was created"
  value       = aws_route53_record.main.zone_id
}