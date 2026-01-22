# ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = "bet2wealth-backend-cluster-${var.env}"

  tags = {
    Name = "bet2wealth-backend-cluster-${var.env}"
    Terraform = "true"
    Environment = var.env
  }
}

# Security Group for ECS to allow traffic to the ECS service
resource "aws_security_group" "ecs_sg" {
  name        = "bet2wealth-backend-ecs-sg-${var.env}"
  description = "Allow traffic from ALB to the ECS service"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bet2wealth-backend-ecs-sg-${var.env}"
    Terraform = "true"
    Environment = var.env
  }
}

# IAM Role for ECS Task Execution Role
# resource "aws_iam_role" "ecs_execution_role" {
#  name = "bet2wealth-backend-ecs-execution-role-${var.env}"

#  assume_role_policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [{
#      Effect = "Allow"
#      Principal = { Service = "ecs-tasks.amazonaws.com" }
#      Action = "sts:AssumeRole"
#    }]
#  })
#}

# IAM Policy for ECS Task Execution
# resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
#  role = aws_iam_role.ecs_execution_role.name
#  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
#}

# CloudWatch Logs for ECS Task
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "/ecs/backend-logs-${var.env}"
  retention_in_days = 14
}

# Task definition for ECS Service
resource "aws_ecs_task_definition" "backend" {
  family                   = "bet2wealth-backend-task-${var.env}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name  = "backend"
      image = var.image_url

      environment = [
        for k, v in var.container_environment : {
          name  = k
          value = v
        }
      ]

      secrets = [
        for k, v in var.container_secrets : {
          name      = k
          valueFrom = v
        }
      ]

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_log_group.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# ECS Service (Run Container)
resource "aws_ecs_service" "backend" {
  name            = "bet2wealth-backend-service-${var.env}"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnets
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "backend"
    container_port   = var.container_port
  }

  depends_on = [aws_ecs_task_definition.backend]
}
