########################
# Security Groups
########################

resource "aws_security_group" "alb_sg" {
  name   = "starttech-alb-sg"
  vpc_id = var.vpc_id

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
}

resource "aws_security_group" "ec2_sg" {
  name   = "starttech-ec2-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################
# Application Load Balancer
########################

resource "aws_lb" "alb" {
  name               = "starttech-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids
}

########################
# Target Group
########################

resource "aws_lb_target_group" "tg" {
  name     = "starttech-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

########################
# Listener
########################

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

########################
# IAM Role
########################

resource "aws_iam_role" "ec2_role" {
  name = "starttech-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cw" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "starttech-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

########################
# CloudWatch Log Group
########################

resource "aws_cloudwatch_log_group" "backend_logs" {
  name              = "/starttech/backend"
  retention_in_days = 7
}

########################
# AMI
########################

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

########################
# Launch Template
########################

resource "aws_launch_template" "lt" {
  name_prefix   = "starttech-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              EOF
  )
}

########################
# Auto Scaling Group
########################

resource "aws_autoscaling_group" "asg" {
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.tg.arn]
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
}
########################
# ECR Repository
########################

resource "aws_ecr_repository" "backend" {
  name = "starttech-backend"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true
}
