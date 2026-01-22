output "ecs_execution_role_arn" {
  description = "IAM role ARN used by ECS to pull images and write logs"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "IAM role ARN available inside containers"
  value       = aws_iam_role.ecs_task_role.arn
}

output "github_actions_deploy_role_arn" {
  description = "IAM role ARN that GitHub Actions can assume via OIDC to deploy this environment (if enabled)."
  value       = try(aws_iam_role.github_actions_deploy[0].arn, null)
}
