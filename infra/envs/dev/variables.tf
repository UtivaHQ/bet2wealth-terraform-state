variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "backend_container_port" {
  description = "Port backend listens on"
  type        = number
  default     = 4000
}

variable "backend_image" {
  description = "Docker image for backend (will be updated by CI later)"
  type        = string
}

variable "container_environment" {
  description = "Plaintext environment variables to inject into the ECS backend container (non-sensitive values only)."
  type        = map(string)
  default     = {}
}

variable "container_secrets" {
  description = "Secret environment variables to inject into the ECS backend container. Values must be SSM parameter ARNs or Secrets Manager secret ARNs."
  type        = map(string)
  default     = {}
}

variable "create_github_oidc_provider" {
  description = "Whether to create the GitHub Actions OIDC provider in IAM (token.actions.githubusercontent.com). Set to true once per AWS account."
  type        = bool
  default     = false
}

variable "create_github_actions_deploy_role" {
  description = "Whether to create an IAM role that GitHub Actions can assume (OIDC) to deploy to ECS/ECR for this environment."
  type        = bool
  default     = false
}

variable "github_repo" {
  description = "GitHub repo in the form 'OWNER/REPO' (e.g. 'bet2wealth/bet2wealth-backend'). Required if create_github_actions_deploy_role is true."
  type        = string
  default     = ""
}

variable "github_branches" {
  description = "Branches allowed to assume the GitHub deploy role (e.g. ['main'] or ['develop'])."
  type        = list(string)
  default     = []
}
