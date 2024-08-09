provider "aws" {
  region = "us-west-2"
}

# -------------------------------------
# VPC and Networking Components
# -------------------------------------

# Create a VPC
resource "aws_vpc" "example_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "example-vpc"
  }
}

# Create a public subnet
resource "aws_subnet" "example_subnet" {
  vpc_id            = aws_vpc.example_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name = "example-subnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "example_igw" {
  vpc_id = aws_vpc.example_vpc.id
  tags = {
    Name = "example-igw"
  }
}

# Create a route table
resource "aws_route_table" "example_route_table" {
  vpc_id = aws_vpc.example_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example_igw.id
  }

  tags = {
    Name = "example-route-table"
  }
}

# Associate the route table with the subnet
resource "aws_route_table_association" "example_route_table_assoc" {
  subnet_id      = aws_subnet.example_subnet.id
  route_table_id = aws_route_table.example_route_table.id
}

# -------------------------------------
# EC2 Instance
# -------------------------------------

# Create a security group for the EC2 instance
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.example_vpc.id
  name   = "ec2-sg"

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "ec2-sg"
  }
}

# Create an EC2 instance
resource "aws_instance" "example_ec2" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.example_subnet.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name = "example-ec2-instance"
  }
}

# -------------------------------------
# Elastic Beanstalk
# -------------------------------------

# Create an Elastic Beanstalk application
resource "aws_elastic_beanstalk_application" "example_app" {
  name = "example-app"
}

# Create an Elastic Beanstalk environment
resource "aws_elastic_beanstalk_environment" "example_env" {
  name                = "example-env"
  application         = aws_elastic_beanstalk_application.example_app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.2.7 running Node.js 14"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.micro"
  }

  tags = {
    Name = "example-beanstalk-env"
  }
}

# -------------------------------------
# AWS Lambda
# -------------------------------------

# Create a simple Lambda function
resource "aws_lambda_function" "example_lambda" {
  function_name = "example_lambda_function"
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  
  filename = "lambda_function.zip"  # You need to create and upload this zip file containing your Lambda function code

  source_code_hash = filebase64sha256("lambda_function.zip")

  tags = {
    Name = "example-lambda-function"
  }
}

# -------------------------------------
# Elastic Container Service (ECS)
# -------------------------------------

# Create an ECS cluster
resource "aws_ecs_cluster" "example_ecs_cluster" {
  name = "example-ecs-cluster"
}

# Create a Fargate task definition
resource "aws_ecs_task_definition" "example_task" {
  family                   = "example-task"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name  = "example-container"
      image = "nginx"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

output "vpc_id" {
  value = aws_vpc.example_vpc.id
}

output "subnet_id" {
  value = aws_subnet.example_subnet.id
}

output "ec2_instance_public_ip" {
  value = aws_instance.example_ec2.public_ip
}

output "beanstalk_environment_url" {
  value = aws_elastic_beanstalk_environment.example_env.endpoint_url
}

output "lambda_function_name" {
  value = aws_lambda_function.example_lambda.function_name
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.example_ecs_cluster.name
}
