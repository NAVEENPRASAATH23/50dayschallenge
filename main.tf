provider "aws" {
  region = "us-west-2"
}

# Create an S3 bucket
resource "aws_s3_bucket" "example_bucket" {
  bucket = "my-unique-s3-bucket-name-terraform"
  acl    = "private"
}

# Create an EBS volume
resource "aws_ebs_volume" "example_ebs" {
  availability_zone = "us-west-2a"
  size              = 10
}

# Create a security group for the EC2 instance
resource "aws_security_group" "example_sg" {
  name_prefix = "example-sg-"
  
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
}

# Create an EC2 instance
resource "aws_instance" "example_ec2" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  key_name      = "my-key-pair"

  vpc_security_group_ids = [aws_security_group.example_sg.id]

  root_block_device {
    volume_size = 8
  }

  tags = {
    Name = "example-ec2-instance"
  }
}

# Attach the EBS volume to the EC2 instance
resource "aws_volume_attachment" "ebs_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.example_ebs.id
  instance_id = aws_instance.example_ec2.id
}

# Create an IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach a policy to the IAM role to allow Lambda to write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create a Lambda function
resource "aws_lambda_function" "example_lambda" {
  function_name = "example_lambda_function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  
  filename = "lambda_function.zip"  # You need to create and upload this zip file containing your Lambda function code

  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      BUCKET = aws_s3_bucket.example_bucket.bucket
    }
  }
}

output "s3_bucket_name" {
  value = aws_s3_bucket.example_bucket.bucket
}

output "ec2_instance_public_ip" {
  value = aws_instance.example_ec2.public_ip
}

output "lambda_function_name" {
  value = aws_lambda_function.example_lambda.function_name
}
