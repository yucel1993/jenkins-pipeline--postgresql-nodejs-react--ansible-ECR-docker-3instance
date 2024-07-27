terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "jenkins-project-backend-burhan"
    key = "backend/tf-backend-jenkins.tfstate"
    region = "us-east-1"
  }
}
provider "aws" {
  region = "us-east-1"
}
variable "tags" {
  default = ["postgresql", "nodejs", "react"]
}
resource "aws_instance" "managed_nodes" {
  ami = "ami-0fe630eb857a6ec83"
  count = 3
  instance_type = "t2.micro"
  key_name = "your_pem_key_name"
  vpc_security_group_ids = [aws_security_group.tf-sec-gr.id]
  iam_instance_profile = aws_iam_instance_profile.ec2-profile.name
  tags = {
    Name = "ansible_${element(var.tags, count.index )}"
    stack = "ansible_project"
    environment = "development"
  }
  user_data = <<-EOF
              #!/bin/bash
              dnf upgrade -y
              EOF
}
resource "aws_iam_role" "aws_access" {
  name = "awsrole-project"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"]
}
resource "aws_iam_instance_profile" "ec2-profile" {
  name = "jenkins-project-profile-2"
  role = aws_iam_role.aws_access.name
}
resource "aws_security_group" "tf-sec-gr" {
  name = "project208-sec-gr"
  tags = {
    Name = "project208-sec-gr"
  }
  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5000
    protocol    = "tcp"
    to_port     = 5000
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3000
    protocol    = "tcp"
    to_port     = 3000
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5432
    protocol    = "tcp"
    to_port     = 5432
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
output "react_ip" {
  value = "http://${aws_instance.managed_nodes[2].public_ip}:3000"
}
output "node_public_ip" {
  value = aws_instance.managed_nodes[1].public_ip
}
output "postgre_private_ip" {
  value = aws_instance.managed_nodes[0].private_ip
}