# AWS Region
variable "aws_region" {
  description = "The AWS region to launch resources in"
  default     = "us-east-1"  
}

# VPC CIDR block
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

# Subnet CIDR block
variable "subnet_cidr_block" {
  description = "CIDR block for the subnet"
  default     = "10.0.1.0/24"
}

# Availability Zone
variable "availability_zone" {
  description = "The availability zone to deploy resources in"
  default     = "us-east-1a" 
}

# AMI ID
variable "ami_id" {
  description = "The AMI ID for Ubuntu"
  default     = "ami-0e86e20dae9224db8"  # Ubuntu 20.04 in us-east-1
}

# Instance Type
variable "instance_type" {
  description = "Instance type for EC2"
  default     = "t3.xlarge"
}

# Root Volume Size
variable "root_volume_size" {
  description = "Root volume size in GB"
  default     = 30
}

# Additional EBS Volume Size
variable "additional_volume_size" {
  description = "Size of the additional EBS volume in GB"
  default     = 100
}

