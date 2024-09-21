# Provider Configuration
provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "azure_devops_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "azure-devops-vpc"
  }
}

# Subnet
resource "aws_subnet" "azure_devops_subnet" {
  vpc_id            = aws_vpc.azure_devops_vpc.id
  cidr_block        = var.subnet_cidr_block
  map_public_ip_on_launch = true
  availability_zone = var.availability_zone
  tags = {
    Name = "azure-devops-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "azure_devops_igw" {
  vpc_id = aws_vpc.azure_devops_vpc.id
  tags = {
    Name = "azure-devops-igw"
  }
}

# Route Table
resource "aws_route_table" "azure_devops_route_table" {
  vpc_id = aws_vpc.azure_devops_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.azure_devops_igw.id
  }

  tags = {
    Name = "azure-devops-route-table"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "azure_devops_route_table_association" {
  subnet_id      = aws_subnet.azure_devops_subnet.id
  route_table_id = aws_route_table.azure_devops_route_table.id
}

# Security Group to allow SSH
resource "aws_security_group" "azure_devops_sg" {
  vpc_id = aws_vpc.azure_devops_vpc.id

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
    Name = "azure-devops-sg"
  }
}

# EC2 Instance
resource "aws_instance" "azure_devops_instance" {
  ami           = "ami-0e86e20dae9224db8"
  instance_type = var.instance_type
  subnet_id     = aws_subnet.azure_devops_subnet.id
   key_name               = "azuredevops"
  vpc_security_group_ids = [aws_security_group.azure_devops_sg.id]

  root_block_device {
    volume_size = var.root_volume_size
  }

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = var.additional_volume_size
  }

  associate_public_ip_address = true

  tags = {
    Name = "azure-devops-instance"
  }
}

# Outputs
output "instance_public_ip" {
  value = aws_instance.azure_devops_instance.public_ip
}

