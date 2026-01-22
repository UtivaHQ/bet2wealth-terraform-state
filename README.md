# bet2wealth-terraform-state

Terraform codebase for provisioning the **Bet2wealth backend infrastructure on AWS**.

This repo is organized as:

- `infra/envs/dev`: dev environment root module (composition of shared modules)
- `infra/envs/production`: production environment root module (composition of shared modules)
- `infra/modules/*`: reusable Terraform modules (VPC, ALB, ECS, ECR, IAM, Redis)

---

## What this creates (high level)

For each environment (`dev`, `production`) Terraform provisions:

- **Networking**: a VPC with public + private subnets (plus NAT for private egress)
- **Load balancing**: a public **Application Load Balancer** that forwards to ECS tasks
- **Compute**: an **ECS Fargate** cluster + service running the backend container in **private subnets**
- **Container registry**: an **ECR** repository to store backend images
- **IAM**: execution + task roles for ECS tasks
- **Cache**: an **ElastiCache Redis replication group** (Multi-AZ) in private subnets, only reachable from ECS
- **Logging**: CloudWatch Log Group for ECS container logs

Outputs:

- ALB DNS name (public endpoint)
- Redis primary endpoint address

---

## Environments

Each environment is a standalone Terraform root under `infra/envs/<env>` with its own:

- `backend.tf`: remote state configuration (S3)
- `main.tf`: provider + module composition
- `variables.tf`: inputs required by that environment
- `terraform.tfvars`: concrete values (image URL, env vars, secret ARNs, etc.)
- `versions.tf`: Terraform + provider versions

### Remote state (S3 backend)

Both environments store state in the same S3 bucket but with different keys:

- dev: `backend/dev/terraform.tfstate`
- production: `backend/production/terraform.tfstate`

**Important**: This repo assumes the S3 bucket already exists:

- Bucket name: `bet2wealth-terraform-state`
- Region: `eu-central-1`

If you are bootstrapping a new AWS account, you must create the S3 bucket (and ideally a DynamoDB lock table) before running `terraform init`.

---

## Modules (what each one does)

### `infra/modules/vpc`

Uses `terraform-aws-modules/vpc/aws` to create:

- VPC CIDR: `10.0.0.0/16`
- 2 AZs (currently hard-coded): `eu-central-1a`, `eu-central-1b`
- Public subnets: `10.0.1.0/24`, `10.0.2.0/24`
- Private subnets: `10.0.11.0/24`, `10.0.12.0/24`
- NAT gateway enabled (currently **single NAT gateway**)

Outputs:

- `vpc_id`
- `public_subnets`
- `private_subnets`

### `infra/modules/alb`

Creates:

- ALB security group allowing inbound **HTTP :80** from `0.0.0.0/0`
- Public ALB across the VPC public subnets
- Listener on **:80** forwarding to a target group
- Target group is configured for **HTTP** and uses `/health` for health checks

Outputs:

- `alb_dns_name`
- `target_group_arn`
- `alb_security_group_id`

### `infra/modules/ecr`

Creates:

- ECR repository named: `bet2wealth-backend-<env>`
- Image scanning on push enabled
- Lifecycle policy to keep the **last 5 images**

Outputs:

- `repository_url`
- `repository_name`

### `infra/modules/iam`

Creates:

- ECS execution role with `AmazonECSTaskExecutionRolePolicy` attached
- ECS task role with an inline policy that allows reading from:
  - AWS Secrets Manager (`GetSecretValue`, `DescribeSecret`)
  - SSM Parameter Store (`GetParameter`, `GetParameters`, `GetParametersByPath`)

Outputs:

- `ecs_execution_role_arn`
- `ecs_task_role_arn`

### `infra/modules/ecs`

Creates:

- ECS cluster
- ECS service (Fargate) with `desired_count = 2`
- CloudWatch Log Group: `/ecs/backend-logs-<env>`
- Task definition with:
  - container image `image_url`
  - port mappings from `container_port`
  - **plaintext** env vars via `container_environment` (map)
  - **secret** env vars via `container_secrets` (map of `KEY => ARN`)
- ECS security group that only allows inbound traffic from the **ALB security group** to the container port
- Network config:
  - tasks run in **private subnets**
  - `assign_public_ip = false`

Outputs:

- `ecs_cluster_name`
- `ecs_service_name`
- `ecs_security_group_id`

### `infra/modules/redis`

Creates:

- ElastiCache subnet group (private subnets)
- Redis security group: allows inbound **:6379** only from the ECS service security group
- Redis replication group (Multi-AZ, automatic failover enabled)
  - Engine: Redis `7.0`
  - Nodes: 2 cache clusters
  - Encryption: in transit + at rest enabled

Outputs:

- `redis_primary_endpoint`
- `redis_port`

---

## Services used (AWS)

- **VPC / Subnets / Routes / NAT Gateway**
- **Security Groups**
- **Elastic Load Balancing (ALB)**
- **ECS (Fargate)**
- **ECR**
- **IAM**
- **CloudWatch Logs**
- **ElastiCache for Redis**
- **S3 (Terraform remote state)**

---

## Secrets and configuration (end-to-end)

### Non-secret runtime config

Each environment passes non-sensitive configuration to the backend container via:

- `container_environment` (a `map(string)` in `terraform.tfvars`)

These become ECS container environment variables (plaintext).

### Secret runtime config

Each environment can pass sensitive configuration via:

- `container_secrets` (a `map(string)` in `terraform.tfvars`)

Each value must be an **ARN** pointing to either:

- an SSM Parameter (recommended in this repo’s current pattern), or
- a Secrets Manager secret

Example (dev):

- `arn:aws:ssm:eu-central-1:<account-id>:parameter/bet2wealth/dev/JWT_SECRET`

### Where to store secrets

This repo’s current convention (as seen in `infra/envs/dev/terraform.tfvars`) is:

- SSM Parameter Store path prefix: `/bet2wealth/<env>/...`

You are responsible for creating those parameters (and rotating them) outside of this repo.

### ⚠️ Important note about ECS secret injection

ECS retrieves SSM/Secrets Manager values on task start. In AWS, that typically requires permissions on the **task execution role** (not just the task role).

In this codebase:

- `infra/modules/iam` grants SSM/Secrets permissions to the **task role**
- `infra/modules/iam` does **not** grant SSM/Secrets permissions to the **execution role**

If you see tasks failing to start with errors like “access denied retrieving secrets”, update IAM so the execution role can read the referenced ARNs (and scope it down to only the parameters/secrets you use).

---

## How to deploy / operate

### Prerequisites

- Terraform `>= 1.14`
- AWS credentials configured locally (or in CI)
- Access to the AWS account hosting:
  - the remote state bucket (`bet2wealth-terraform-state`)
  - the infrastructure resources (VPC/ECS/etc.)

---

## GitHub Actions CI/CD (OIDC) - managed by Terraform

If you want GitHub Actions (in your backend repo) to deploy to this infrastructure **without long-lived AWS keys**, this repo can create:

- a GitHub Actions **OIDC provider** in AWS IAM (optional; typically **once per AWS account**), and
- a per-environment **deploy role** that GitHub can assume via OIDC to:
  - push images to **ECR** for that environment, and
  - update the **ECS service** to roll out the new task definition

### Enable for dev

In `infra/envs/dev/terraform.tfvars` add:

```hcl
# GitHub Actions OIDC + deploy role (dev)
create_github_oidc_provider      = true  # set true once, then you can turn it off in other envs
create_github_actions_deploy_role = true
github_repo                      = "OWNER/REPO"
github_branches                  = ["develop"]
```

### Enable for production

In `infra/envs/production/terraform.tfvars` add:

```hcl
# GitHub Actions OIDC + deploy role (production)
create_github_oidc_provider      = false # usually already created by dev
create_github_actions_deploy_role = true
github_repo                      = "OWNER/REPO"
github_branches                  = ["main"]
```

### Important: `github_repo` format

`github_repo` must be **exactly** `OWNER/REPO` (example: `UtivaHQ/bet2wealth_backend`) — **not** a full URL.

After `terraform apply`, take the output `github_actions_deploy_role_arn` and set it in your backend GitHub repo as:

- GitHub repo → Settings → Secrets and variables → Actions → **New secret**
- Name: `AWS_ROLE_ARN_DEV` | `AWS_ROLE_ARN_PROD`
- Value: the role ARN output from Terraform

### Note on OIDC thumbprint

The GitHub OIDC provider requires a TLS thumbprint. This repo sets a sensible default, but if AWS/GitHub rotates certificates you may need to update `github_oidc_thumbprints`.

### Option A (recommended): CI runs `terraform apply` to deploy a new image (no drift)

If your backend pipeline builds a new image tag like `:${GITHUB_SHA}`, the cleanest way to avoid Terraform drift is:

1. CI builds + pushes image to ECR (immutable tag)
2. CI checks out this infra repo
3. CI runs `terraform apply -var="backend_image=<new-image-uri>"` in the right env folder (`infra/envs/dev` or `infra/envs/production`)

To make this work, the GitHub deploy role created by this repo includes:

- ECR push permissions for `bet2wealth-backend-<env>`
- ECS deployment permissions
- `iam:PassRole` for the ECS task roles
- **S3 remote state access** scoped to `backend/<env>/...` in the state bucket (defaults to `bet2wealth-terraform-state`)

If your remote state bucket or key prefix differs, set:

- `terraform_state_bucket` (default: `bet2wealth-terraform-state`)
- `terraform_state_key_prefix` (default: `backend`)

### Checking out this infra repo from the backend pipeline

If your backend GitHub Actions workflow checks out this infra repo (cross-repo checkout):

- If the infra repo is **public**, `actions/checkout` works without extra setup.
- If the infra repo is **private**, you must provide a token with read access to this repo (PAT or GitHub App token) and pass it to `actions/checkout` as `token: ${{ secrets.INFRA_REPO_TOKEN }}`.

### AWS authentication

The provider blocks in both environments currently hard-code:

- `profile = "abayomi-admin"`

If you want this to work in CI (or across multiple developers), prefer one of:

- remove the hard-coded profile and rely on standard AWS env vars
- use `assume_role` (recommended) and pass role ARN per environment

### Deploying dev

From `infra/envs/dev`:

```bash
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

### Deploying production

From `infra/envs/production`:

```bash
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

### Updating the backend image

Each environment provides `backend_image` in `terraform.tfvars`, e.g.:

- `.../bet2wealth-backend-dev:latest`
- `.../bet2wealth-backend-production:latest`

Common workflow:

1. CI builds and pushes a new image tag to ECR
2. CI updates `backend_image` (or passes it as a `-var backend_image=...`)
3. CI runs `terraform apply` to update the ECS task definition and roll the service

---

## Known gaps / recommended improvements (production hardening)

These are not “wrong”, but they’re the most important things you’d typically add before calling this production-grade:

- **HTTPS**: ALB is HTTP-only; add ACM cert + HTTPS listener and redirect HTTP→HTTPS.
- **Remote state locking**: add DynamoDB state lock table; enable bucket encryption/versioning and consider access logging.
- **IAM least privilege**: current SSM/Secrets permissions are `Resource="*"`; scope down to the exact parameter/secret ARNs used.
- **Configurability**: VPC CIDR/subnets/AZs and ALB target group port are hard-coded; make them variables.
- **Reliability**: VPC uses a **single NAT gateway** (SPOF); consider one NAT per AZ for production.
- **Autoscaling**: ECS desired count is fixed at 2; add Application Auto Scaling policies and CloudWatch alarms.
- **Observability**: add ALB access logs, dashboards/alarms, and (optionally) VPC flow logs.

---

## Quick file map

- `infra/envs/dev/main.tf`: wires modules together for dev
- `infra/envs/dev/terraform.tfvars`: dev image + runtime config + secret ARNs
- `infra/envs/production/main.tf`: wires modules together for production
- `infra/modules/*`: the reusable building blocks
