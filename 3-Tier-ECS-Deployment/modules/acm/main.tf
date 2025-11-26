# =============================================================================
# ACM Module
# =============================================================================
# Creates SSL/TLS certificate with automatic DNS validation
# =============================================================================

# -----------------------------------------------------------------------------
# ACM Certificate
# -----------------------------------------------------------------------------

resource "aws_acm_certificate" "main" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = var.domain_name
  })
}

# -----------------------------------------------------------------------------
# Route53 DNS Validation Records
# -----------------------------------------------------------------------------
# Automatically creates the CNAME records required for DNS validation
# -----------------------------------------------------------------------------

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}

# -----------------------------------------------------------------------------
# Certificate Validation
# -----------------------------------------------------------------------------
# Waits for the certificate to be validated before completing
# -----------------------------------------------------------------------------

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

# =============================================================================
# NOTES:
# =============================================================================
#
# DNS Validation:
#   - Automatically creates CNAME record in Route53
#   - Certificate validates within 5-30 minutes
#   - No manual steps required
#
# Certificate Lifecycle:
#   - create_before_destroy: Prevents downtime during renewal
#   - ACM automatically renews certificates before expiry
#   - Renewal is free and automatic
#
# Validation Wait:
#   - aws_acm_certificate_validation waits until cert is ISSUED
#   - ALB module depends on this, ensuring cert is ready
#   - Terraform apply may take 5-10 minutes on first run
#
# Alternative: Email Validation
#   - Requires manual email confirmation
#   - Not recommended for automation
#
# Multi-Domain Certificates:
#   - Add subject_alternative_names for additional domains
#   - Example:
#     subject_alternative_names = [
#       "*.${var.domain_name}",
#       "www.${var.domain_name}"
#     ]
#
# =============================================================================