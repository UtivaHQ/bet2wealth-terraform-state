variable "env" {
  description = "Environment name (dev or production)"
  type        = string
}

variable "vpc_id" {
  description = "VPC where Redis will be deployed"
  type        = string
}

variable "private_subnets" {
  description = "Private subnets for Redis"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID of ECS (allowed to access Redis)"
  type        = string
}
