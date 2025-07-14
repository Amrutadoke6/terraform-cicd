# -----------------------------------------------------
# 🔧 PROVIDERS & BACKEND CONFIG (FROM providers.tf & backend.tf)
# -----------------------------------------------------
provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket         = "amruta-tfstate-bucket2"
    key            = "terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-lock2"
    encrypt        = true
  }
}

# -----------------------------------------------------
# 🌐 VPC + SUBNETS + ROUTES (FROM modules/vpc)
# -----------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project}-igw"
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  map_public_ip_on_launch = true
  availability_zone       = element(var.azs, count.index)
  tags = {
    Name = "${var.project}-public-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = element(var.azs, count.index)
  tags = {
    Name = "${var.project}-private-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.project}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# -----------------------------------------------------
# 🛡️ SECURITY GROUPS (partial from modules/security)
# -----------------------------------------------------
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project}-ec2-sg"
  description = "Allow HTTP"
  vpc_id      = aws_vpc.main.id
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

resource "aws_security_group" "rds_sg" {
  name        = "${var.project}-rds-sg"
  description = "Allow RDS"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port       = 1433
    to_port         = 1433
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------------------------------
# 🧠 IAM Role for EC2 to access SSM & Secrets (from ssm_secrets.tf)
# -----------------------------------------------------
resource "aws_iam_role" "ec2_ssm_role" {
  name = "${var.project}-ec2-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project}-ec2-instance-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "secrets" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

# -----------------------------------------------------
# 💻 COMPUTE: Launch Template + ASG + ALB (with SSM Agent for Fleet Manager)
# -----------------------------------------------------
data "aws_ami" "windows" {
  most_recent = true
  owners      = ["801119661308"]
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "web" {
  name_prefix            = "${var.project}-tpl"
  image_id               = data.aws_ami.windows.id
  instance_type          = "t3.medium"
  user_data              = base64encode(file("./scripts/bootstrap.ps1"))
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project}-web"
    }
  }
}

resource "aws_autoscaling_group" "web_asg" {
  desired_capacity    = 2
  max_size            = 2
  min_size            = 2
  vpc_zone_identifier = aws_subnet.private[*].id
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "${var.project}-web"
    propagate_at_launch = true
  }
}

resource "aws_lb" "internal_alb" {
  name               = "${var.project}-alb"
  internal           = true
  load_balancer_type = "application"
  subnets            = aws_subnet.private[*].id
  security_groups    = [aws_security_group.ec2_sg.id]
  access_logs {
    bucket  = "amruta-log-bucket2"
    enabled = true
    prefix  = "alb-logs"
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "${var.project}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path     = "/"
    protocol = "HTTP"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.internal_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_autoscaling_attachment" "asg_attach" {
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  lb_target_group_arn    = aws_lb_target_group.tg.arn
}

# -----------------------------------------------------
# 💾 RDS + Secrets
# -----------------------------------------------------
resource "aws_secretsmanager_secret" "rds" {
  name = "${var.project}-rds-credentials"
}

resource "aws_secretsmanager_secret_version" "rds_secret" {
  secret_id = aws_secretsmanager_secret.rds.id
  secret_string = jsonencode({
    username = var.db_user,
    password = var.db_pass
  })
}


resource "aws_db_subnet_group" "db" {
  name       = "${var.project}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_instance" "sql" {
  identifier             = "${var.project}-rds-sql"
  engine                 = "sqlserver-ex"
  license_model          = "license-included"            
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_encrypted      = true
  multi_az               = false
  publicly_accessible    = false
 #db_name                = "mydb"
  username               = var.db_user
  password               = var.db_pass
  db_subnet_group_name = aws_db_subnet_group.db.name          
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}

# -----------------------------------------------------
# 🔍 CloudWatch Monitoring
# -----------------------------------------------------
resource "aws_cloudwatch_log_group" "web_logs" {
  name              = "/${var.project}/app"
  retention_in_days = 7
}

resource "aws_cloudwatch_metric_alarm" "asg_cpu" {
  alarm_name          = "${var.project}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
  alarm_description  = "High CPU alarm for ASG"
  treat_missing_data = "missing"
}

