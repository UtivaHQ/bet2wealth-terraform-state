variable "env" {
  description = "Environment name (dev or production)"
  type        = string
}

variable "vpc_id" {
  description = "VPC where ALB will live"
  type        = string
}

variable "public_subnets" {
  description = "Public subnets for ALB"
  type        = list(string)
}
