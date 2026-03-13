# Commands Reference (Terraform + AWS)

Quick copy/paste reference for the common commands used with this repo.

## Local AWS authentication (recommended)

Use an AWS CLI profile you already have configured (replace with yours).

```bash
# replace with your own profile name
export AWS_PROFILE="abayomi-admin"
export AWS_REGION="eu-central-1"
export AWS_SDK_LOAD_CONFIG=1
```

If you use AWS SSO:

```bash
aws sso login --profile "$AWS_PROFILE"
```

Sanity check:

```bash
aws sts get-caller-identity --profile "$AWS_PROFILE"
```

## Terraform (by environment)

### Init (ensures correct backend key)

```bash
cd infra/envs/dev && terraform init -reconfigure
cd infra/envs/production && terraform init -reconfigure
```

### Plan/apply with an explicit image (recommended)

This repo treats `backend_image` as a CI-provided input. Pass an immutable tag (e.g. GitHub commit SHA).

```bash
# dev
cd infra/envs/dev
terraform plan  -var="backend_image=<account>.dkr.ecr.eu-central-1.amazonaws.com/bet2wealth-backend-dev:<tag>"
terraform apply -var="backend_image=<account>.dkr.ecr.eu-central-1.amazonaws.com/bet2wealth-backend-dev:<tag>"
```

```bash
# prod (note: repo name uses env=prod in this codebase)
cd infra/envs/production
terraform plan  -var="backend_image=<account>.dkr.ecr.eu-central-1.amazonaws.com/bet2wealth-backend-prod:<tag>"
terraform apply -var="backend_image=<account>.dkr.ecr.eu-central-1.amazonaws.com/bet2wealth-backend-prod:<tag>"
```

### Destroy an environment (danger)

```bash
cd infra/envs/dev
terraform destroy
```

## ECS / ALB health checks

### Check ECS service status

```bash
aws ecs describe-services \
  --cluster bet2wealth-backend-cluster-dev \
  --services bet2wealth-backend-service-dev \
  --query "services[0].{Desired:desiredCount,Running:runningCount,Pending:pendingCount,LastEvent:events[0].message}" \
  --output table
```

### Check target group health

```bash
aws elbv2 describe-target-health \
  --target-group-arn "$(aws elbv2 describe-target-groups --names bet2wealth-backend-tg-dev --query 'TargetGroups[0].TargetGroupArn' --output text)" \
  --query "TargetHealthDescriptions[].{Target:Target.Id,Port:Target.Port,State:TargetHealth.State,Reason:TargetHealth.Reason}" \
  --output table
```

## CloudWatch logs (ECS container logs)

Log groups:

- dev: `/ecs/backend-logs-dev`
- prod: `/ecs/backend-logs-prod`

### Find latest log streams

```bash
aws logs describe-log-streams \
  --log-group-name "/ecs/backend-logs-dev" \
  --order-by LastEventTime \
  --descending \
  --max-items 5
```

### Fetch log events (JSON)

```bash
aws logs get-log-events \
  --log-group-name "/ecs/backend-logs-dev" \
  --log-stream-name "<LOG_STREAM_NAME>" \
  --limit 200 \
  --output json
```

### Search for specific phrases (server-side filter)

```bash
aws logs filter-log-events \
  --log-group-name "/ecs/backend-logs-dev" \
  --filter-pattern '"Redirect URL resolved" "Incoming request" "OAuth code exchange failed"' \
  --output json
```

## SSM Parameter Store (SecureString secrets)

### Create/update a SecureString parameter

```bash
aws ssm put-parameter \
  --name "/bet2wealth/dev/MAILERSEND_API_KEY" \
  --type "SecureString" \
  --value "<SECRET_VALUE>" \
  --overwrite \
  --region eu-central-1
```

### Read a parameter (with decryption)

```bash
aws ssm get-parameter \
  --name "/bet2wealth/dev/MAILERSEND_API_KEY" \
  --with-decryption \
  --region eu-central-1
```

## “What is my backend public IP?” (egress IP)

For ECS tasks in private subnets, the “public IP” seen by third parties is typically the **NAT Gateway Elastic IP**.

```bash
aws ec2 describe-nat-gateways \
  --filter Name=state,Values=available \
  --query "NatGateways[].{NatId:NatGatewayId,VpcId:VpcId,PublicIp:NatGatewayAddresses[0].PublicIp}" \
  --output table
```
