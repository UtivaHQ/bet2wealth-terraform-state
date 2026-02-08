variable "env" {
  description = "Environment name (dev or prod)"
  type        = string
}

variable "health_check_path" {
  description = "Health check path for the ALB"
  type        = string
  default     = "/api/v1/health-check"
}

variable "vpc_id" {
  description = "VPC where ALB will live"
  type        = string
}

variable "public_subnets" {
  description = "Public subnets for ALB"
  type        = list(string)
}

variable "domain_name" {
  description = "Domain name for API (e.g. api.dev.bet2wealth.co)"
  type        = string
}
