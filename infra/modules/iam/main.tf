# Trust policy for ECS Execution Role
resource "aws_iam_role" "ecs_execution_role" {
  name = "bet2wealth-backend-ecs-execution-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the ECS Execution Policy to the ECS Execution Role
resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role for the backend
resource "aws_iam_role" "ecs_task_role" {
  name = "bet2wealth-backend-ecs-task-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Inline Policy for ECS Task Role
resource "aws_iam_role_policy" "ecs_task_basic" {
  name = "ecs-task-basic-${var.env}"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Allow reading secrets from AWS Secrets Manager
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      },

      # Allow reading parameters from SSM Parameter Store
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "*"
      }
    ]
  })
}

# --------------------------------------------------------------------
# Optional: GitHub Actions OIDC + deploy role (ECR push + ECS deploy)
# --------------------------------------------------------------------

data "aws_caller_identity" "current" {}

locals {
  github_subjects = [
    for b in var.github_branches :
    "repo:${var.github_repo}:ref:refs/heads/${b}"
  ]

  ecr_repository_arn = "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/bet2wealth-backend-${var.env}"

  terraform_state_prefix = "${var.terraform_state_key_prefix}/${var.env}/"
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.github_oidc_thumbprints
}

resource "aws_iam_role" "github_actions_deploy" {
  count = var.create_github_actions_deploy_role ? 1 : 0

  name = "bet2wealth-github-actions-deploy-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = local.github_subjects
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  count = var.create_github_actions_deploy_role ? 1 : 0

  name = "bet2wealth-github-actions-deploy-${var.env}"
  role = aws_iam_role.github_actions_deploy[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Terraform remote state access (S3 backend)
      {
        Sid    = "TerraformStateListBucket"
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${var.terraform_state_bucket}"
        Condition = {
          StringLike = {
            "s3:prefix" = [
              local.terraform_state_prefix,
              "${local.terraform_state_prefix}*"
            ]
          }
        }
      },
      {
        Sid    = "TerraformStateReadWriteObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.terraform_state_bucket}/${local.terraform_state_prefix}*"
      },

      # ECR login
      {
        Sid    = "ECRAuth"
        Effect = "Allow"
        Action = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },

      # Push/pull to the environment repository
      {
        Sid    = "ECRPushPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ]
        Resource = local.ecr_repository_arn
      },

      # ECS deployment primitives
      {
        Sid    = "ECSDeploy"
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService"
        ]
        Resource = "*"
      },

      # Needed because registering a task definition that references roles requires PassRole
      {
        Sid    = "AllowPassEcsRoles"
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = [
          aws_iam_role.ecs_execution_role.arn,
          aws_iam_role.ecs_task_role.arn
        ]
      }
    ]
  })
}