# =============================================================================
# ECR Module Variables
# =============================================================================

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}