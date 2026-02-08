variable "env" {
  description = "Environment name (dev or prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "subnets" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID (for security groups)"
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
}

variable "backend_image" {
  description = "Docker image in ECR"
  type        = string
}

variable "container_port" {
  description = "Port backend listens on"
  type        = number
  default     = 4000
}

variable "execution_role_arn" {
  description = "ARN of the ECS execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "container_environment" {
  description = "Plaintext environment variables to inject into the ECS container definition (non-sensitive values only)."
  type        = map(string)
  default     = {}
}

variable "container_secrets" {
  description = "Secret environment variables to inject into the ECS container definition. Values must be SSM parameter ARNs or Secrets Manager secret ARNs."
  type        = map(string)
  default     = {}
}
