variable "env" {
  description = "Environment name (dev or production)"
  type        = string
}

variable "repository_name" {
  description = "Base name of the ECR repository"
  type        = string
  default     = "bet2wealth-backend"
}
