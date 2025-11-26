# =============================================================================
# Route53 Module Variables
# =============================================================================

variable "zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

variable "record_name" {
  description = "DNS record name (FQDN)"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB"
  type        = string
}

variable "alb_zone_id" {
  description = "Zone ID of the ALB"
  type        = string
}