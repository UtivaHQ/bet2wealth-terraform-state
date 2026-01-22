# Security Group for ALB to allow HTTP traffic
resource "aws_security_group" "alb_sg" {
  name        = "bet2wealth-backend-alb-sg-${var.env}"
  description = "Allow HTTP traffic to ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bet2wealth-backend-alb-sg-${var.env}"
    Terraform = "true"
    Environment = var.env
  }
}

# Create the Load Balancer
resource "aws_lb" "this" {
  name               = "bet2wealth-backend-alb-${var.env}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnets

  tags = {
    Name = "bet2wealth-backend-alb-${var.env}"
    Terraform = "true"
    Environment = var.env
  }
}

# Create the Target Group for the ALB
resource "aws_lb_target_group" "backend" {
  name        = "bet2wealth-backend-tg-${var.env}"
  port        = 4000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "bet2wealth-backend-tg-${var.env}"
    Terraform = "true"
    Environment = var.env
  }
}

# Create the Listener for the ALB
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  tags = {
    Name = "bet2wealth-backend-listener-http-${var.env}"
    Terraform = "true"
    Environment = var.env
  }
}