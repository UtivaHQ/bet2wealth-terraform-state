variable "env" {
  description = "Environment name (dev or prod)"
  type        = string
}

variable "region" {
  description = "AWS region (used for building ARNs in IAM policies)"
  type        = string
}

# -----------------------------
# Optional: GitHub Actions OIDC
# -----------------------------

variable "create_github_oidc_provider" {
  description = "Whether to create the GitHub Actions OIDC provider in IAM (token.actions.githubusercontent.com). Set to true once per AWS account."
  type        = bool
  default     = false
}

variable "github_oidc_thumbprints" {
  description = "Thumbprints for the GitHub OIDC provider. Keep default unless AWS/GitHub rotates their cert chain."
  type        = list(string)
  default     = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
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

variable "terraform_state_bucket" {
  description = "S3 bucket name used for Terraform remote state (backend)."
  type        = string
  default     = "bet2wealth-terraform-state"
}

variable "terraform_state_key_prefix" {
  description = "Prefix used for Terraform remote state keys inside the bucket (e.g. 'backend' -> backend/<env>/terraform.tfstate)."
  type        = string
  default     = "backend"
}

variable "github_actions_deploy_attach_admin_policy" {
  description = "Attach AWS managed AdministratorAccess to the GitHub Actions deploy role so it can run terraform plan/apply across the whole stack."
  type        = bool
  default     = false
}
