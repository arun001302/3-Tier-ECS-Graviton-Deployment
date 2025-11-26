# =============================================================================
# Route53 Module
# =============================================================================
# Creates DNS A record alias pointing to the ALB
# =============================================================================

# -----------------------------------------------------------------------------
# A Record (Alias to ALB)
# -----------------------------------------------------------------------------

resource "aws_route53_record" "main" {
  zone_id = var.zone_id
  name    = var.record_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# =============================================================================
# NOTES:
# =============================================================================
#
# Alias Record:
#   - Points directly to ALB without additional DNS lookup
#   - No charge for alias queries to AWS resources
#   - Automatically updates if ALB IP changes
#
# evaluate_target_health:
#   - Route53 checks ALB health before routing traffic
#   - If ALB is unhealthy, Route53 stops routing to it
#   - Useful for multi-region failover scenarios
#
# Record Name:
#   - Will be: wp.architecture-demo.com
#   - Full FQDN constructed from subdomain + domain
#
# TTL:
#   - Alias records don't support TTL setting
#   - TTL is inherited from the target resource
#
# Alternative Record Types:
#   - CNAME: Cannot be used at zone apex (naked domain)
#   - A Record with IP: Requires static IP, not recommended for ALB
#   - Alias: Best choice for AWS resources
#
# =============================================================================