# Provider Configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Create a new VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Project Main VPC"
  }
}
# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}
# Generate a new private key locally
resource "tls_private_key" "project_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair with the public key
resource "aws_key_pair" "key_pair" {
  key_name   = "my-key"
  public_key = tls_private_key.project_private_key.public_key_openssh
}

# Save the private key locally (optional)
resource "local_file" "private_key_pem" {
  content         = tls_private_key.project_private_key.private_key_pem
  filename        = "${path.module}/my-key.pem"
  file_permission = "0600"
}

# Create a new Internet Gateway for the new VPC
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Project Main IGW"
  }
}
# Public Subnet for Slaves

# Create a new Public Subnet in the new VPC
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet"
    Type = "Public"
  }
}

# Route Table for Public Subnet

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}
# Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group

resource "aws_security_group" "sg" {
  name_prefix = "slaves-sg"
  description = "Security group for slave servers with HTTP access"
  vpc_id      = aws_vpc.main.id

  # HTTP access from internet
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access from anywhere (for demo purposes; restrict in production)
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Opened all traffic
  ingress {

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Security Group"
  }
}
# EC2 Instance: Provisioner-Server

resource "aws_instance" "Provisioner-Server" {
  ami                         = "ami-0360c520857e3138f"
  instance_type               = "t2.medium"
  key_name                    = aws_key_pair.key_pair.key_name
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  associate_public_ip_address = true

  # User data for basic setup
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get upgrade -y
              hostnamectl set-hostname Provisioner-Server
              echo "Updating package index..."
              sudo apt update -y

              echo "Installing required dependencies..."
              sudo apt install -y software-properties-common

              echo "Adding Ansible PPA repository..."
              sudo add-apt-repository --yes --update ppa:ansible/ansible

              echo "Installing Ansible..."
              sudo apt install -y ansible
              EOF

  tags = {
    Name = "Provisioner-Server"
    Role = "Controller"
  }
}

# EC2 Instance: Master Controller

resource "aws_instance" "KMaster-JenSlave" {
  ami                         = "ami-0360c520857e3138f"
  instance_type               = "t2.medium"
  key_name                    = aws_key_pair.key_pair.key_name
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  associate_public_ip_address = true

  # User data for basic setup
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get upgrade -y
              hostnamectl set-hostname KMaster-JenSlave
              EOF

  tags = {
    Name = "KMaster-JenSlave"
    Role = "Controller"
  }
}

# EC2 Instance: Slave01

resource "aws_instance" "Slave01" {
  ami                         = "ami-0360c520857e3138f"
  instance_type               = "t2.medium"
  key_name                    = aws_key_pair.key_pair.key_name
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  associate_public_ip_address = true

  # User data for basic setup
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get upgrade -y
              hostnamectl set-hostname Slave01
              EOF
  tags = {
    Name = "Slave01"
    Role = "Worker"
  }
}

# EC2 Instance: Slave02

resource "aws_instance" "Slave02" {
  ami                         = "ami-0360c520857e3138f"
  instance_type               = "t2.medium"
  key_name                    = aws_key_pair.key_pair.key_name
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  associate_public_ip_address = true

  # User data for basic setup
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get upgrade -y
              hostnamectl set-hostname Slave02
              EOF
  tags = {
    Name = "Slave02"
    Role = "Worker"
  }
}

# Outputs of Public Ips and Private IPs with the name of the instances

output "Provisioner-Server_Public_IP" {
  value = aws_instance.Provisioner-Server.public_ip
}
output "Provisioner-Server_Private_IP" {
  value = aws_instance.Provisioner-Server.private_ip
}
output "KMaster-JenSlave_Public_IP" {
  value = aws_instance.KMaster-JenSlave.public_ip
}
output "KMaster-JenSlave_Private_IP" {
  value = aws_instance.KMaster-JenSlave.private_ip
}
output "Slave01_Public_IP" {
  value = aws_instance.Slave01.public_ip
}
output "Slave01_Private_IP" {
  value = aws_instance.Slave01.private_ip
}
output "Slave02_Public_IP" {
  value = aws_instance.Slave02.public_ip
}
output "Slave02_Private_IP" {
  value = aws_instance.Slave02.private_ip
}
output "Private_Key_Location" {
  value = local_file.private_key_pem.filename
}
# End of main.tf

