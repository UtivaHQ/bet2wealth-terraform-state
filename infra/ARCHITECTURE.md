# Infrastructure Architecture (Bet2wealth Backend)

This document provides a **high-level architecture diagram** for the Terraform setup under `infra/` (applies to both `dev` and `production` environments).

## Diagram

```mermaid
flowchart TB
  %% ================
  %% Entry + DNS/TLS
  %% ================
  U[Users / Clients] -->|HTTPS 443| D[api.<env>.bet2wealth.co]
  D -->|CNAME / Alias| ALB[(Public Application Load Balancer)]

  %% ================
  %% VPC Layout
  %% ================
  subgraph VPC[VPC: bet2wealth-backend-<env> (10.0.0.0/16)]
    direction TB

    subgraph PUB[Public Subnets (eu-central-1a/1b)]
      ALB
      IGW[Internet Gateway]
      NAT[NAT Gateway (single)]
    end

    subgraph PRIV[Private Subnets (eu-central-1a/1b)]
      ECS[ECS Cluster (Fargate)]
      SVC[ECS Service (desired=2)]
      TASKS[Backend Tasks/Containers (port 4000)]
      REDIS[(ElastiCache Redis\nMulti-AZ, encrypted)]
    end

    IGW <-->|Internet| ALB
    TASKS -->|egress| NAT
  end

  %% ================
  %% Load balancing
  %% ================
  ALB -->|HTTP 80 redirect| ALB
  ALB -->|Forward| TG[Target Group (type=ip)]
  TG -->|port 4000| TASKS

  %% Health checks
  ALB -. health check .->|/api/v1/health-check| TASKS

  %% ================
  %% Container image + logs
  %% ================
  ECR[(ECR Repo: bet2wealth-backend-<env>)] -->|pull image| TASKS
  CW[(CloudWatch Logs\n/ecs/backend-logs-<env>)] <-->|logs| TASKS

  %% ================
  %% Secrets/config
  %% ================
  SSM[(SSM Parameter Store\n/bet2wealth/<env>/*)] -->|ECS secrets injection| TASKS
  SM[(Secrets Manager\n(optional))] -->|ECS secrets injection| TASKS

  %% IAM
  IAMEX[IAM: ECS Execution Role] -->|pull image + fetch secrets| TASKS
  IAMTASK[IAM: ECS Task Role] -->|app AWS access (if needed)| TASKS

  %% Redis access control
  TASKS -->|TCP 6379 (SG restricted)| REDIS
```

## Notes

- **Networking**:
  - ALB is in **public subnets** and receives internet traffic.
  - ECS tasks run in **private subnets** with **no public IPs**.
  - Outbound internet access from private subnets is via a **NAT gateway**.
- **Traffic flow**:
  - HTTPS traffic terminates at the **ALB** and is forwarded to ECS tasks via an **IP target group**.
  - ALB health checks must match the backend health endpoint (currently `/api/v1/health-check`).
- **Secrets**:
  - Non-sensitive config is passed via `container_environment`.
  - Sensitive config is injected via `container_secrets` (SSM Parameter ARNs and/or Secrets Manager ARNs).
  - ECS secret injection requires the **execution role** to be able to read those secret sources.
- **CI/CD**:
  - GitHub Actions builds/pushes images to ECR and deploys by updating the ECS task definition (via Terraform apply with `backend_image`).

