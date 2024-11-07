terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.73.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-central-1"
}

# Create a VPC
resource "aws_vpc" "k8s" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "k8s"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "public_k8s" {
  vpc_id = aws_vpc.k8s.id

  tags = {
    Name = "igw-k8s"
  }
}

resource "aws_subnet" "public_k8s" {
  vpc_id                  = aws_vpc.k8s.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a" # Choose your desired AZ
  map_public_ip_on_launch = true

  tags = {
    Name = "public-k8s"
  }
}

# Create a Route Table for the Public Subnet
resource "aws_route_table" "public_k8s" {
  vpc_id = aws_vpc.k8s.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public_k8s.id
  }
  tags = {
    Name = "public-k8s"
  }
}

# Associate the Route Table with the Public Subnet
resource "aws_route_table_association" "public_k8s" {
  subnet_id      = aws_subnet.public_k8s.id
  route_table_id = aws_route_table.public_k8s.id
}

resource "aws_security_group" "allow_ssh_k8s" {
  vpc_id = aws_vpc.k8s.id
  name   = "allow_ssh_k8s"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_ssh_k8s.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_ssh_k8s.id
  cidr_ipv4         = aws_vpc.k8s.cidr_block
  ip_protocol       = "-1" # If ip_protocol is set to "-1", it translates at AWS's side to protocol=All, 
  # Port range = All thus no from_port/to_port is required.
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_ssh_k8s.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.allow_ssh_k8s.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

data "aws_ami" "linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20240801"] # Replace with the appropriate Ubuntu version
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  vm_names = {
    "vm0" = "jupyterhub"
    "vm1" = "master"
    "vm2" = "worker-01"
    "vm3" = "worker-02"
    "vm4" = "worker-03"
    "vm5" = "database"
  }
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = "aws"
  public_key = file("/Users/Name/.ssh/aws_pem.pub")
}

resource "aws_instance" "main" {
  for_each                    = local.vm_names
  ami                         = data.aws_ami.linux.id
  instance_type               = "t3.xlarge"
  subnet_id                   = aws_subnet.public_k8s.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.allow_ssh_k8s.id]
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 100
  }

  tags = {
    Name = "${each.value}"
  }

  key_name = aws_key_pair.my_key_pair.key_name
}
