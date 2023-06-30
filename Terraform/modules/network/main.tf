#This Terraform code sets up a VPC with public and private subnets, and provisions a load balancer.

# Define local variables for public and private subnet IP ranges.
locals {
  subnet_ips = {
    public_a  = "172.31.48.0/24"
    public_b  = "172.31.49.0/24"
    private_a = "172.31.50.0/24"
    private_b = "172.31.51.0/24"
  }
}

# Create the default VPC.
resource "aws_default_vpc" "default" {}

# Retrieve the current AWS region.
data "aws_region" "current" {
}

# Create the public subnet "public_a" in availability zone and default VPC
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_default_vpc.default.id
  cidr_block              = local.subnet_ips.public_a
  availability_zone       = "${data.aws_region.current.name}a"
  map_public_ip_on_launch = true
  tags                    = {
    Name = "public_a"
  }
}

# Associate the "public_a" subnet with the default route table.
resource "aws_route_table_association" "public_a_to_default" {
  route_table_id = aws_default_vpc.default.default_route_table_id
  subnet_id      = aws_subnet.public_a.id
}

# Create the public subnet "public_b" in availability zone and default VPC
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_default_vpc.default.id
  cidr_block              = local.subnet_ips.public_b
  availability_zone       = "${data.aws_region.current.name}b"
  map_public_ip_on_launch = true
  tags                    = {
    Name = "public_b"
  }
}

# Associate the "public_b" subnet with the default route table.
resource "aws_route_table_association" "public_b_to_default" {
  route_table_id = aws_default_vpc.default.default_route_table_id
  subnet_id      = aws_subnet.public_b.id
}

# Create the private route table in the VPC.
resource "aws_route_table" "private" {
  vpc_id = aws_default_vpc.default.id
}

# Create the private subnet "private_a" in availability zone and default VPC
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_default_vpc.default.id
  availability_zone       = "${data.aws_region.current.name}a"
  cidr_block              = local.subnet_ips.private_a
  map_public_ip_on_launch = false
  tags                    = {
    Name = "private_a"
  }
}

# Associate the "private_a" subnet with the private route table.
resource "aws_route_table_association" "private_to_private" {
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private_a.id
}

# Create the private subnet "private_b" in availability zone and default VPC
resource "aws_subnet" "private_b" {
  vpc_id                  = aws_default_vpc.default.id
  availability_zone       = "${data.aws_region.current.name}b"
  cidr_block              = local.subnet_ips.private_b
  map_public_ip_on_launch = false
  tags                    = {
    Name = "private_b"
  }
}

# Associate the "private_b" subnet with the private route table.
resource "aws_route_table_association" "private_b_to_private" {
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private_b.id
}

# Create an AWS security group for the load balancer
resource "aws_security_group" "load_balancer" {
  name        = "${var.namespace}-${var.project_name}-alb"
  description = "Allow traffic to loadbalancer"
  vpc_id      = aws_default_vpc.default.id

  # Allow incoming TCP traffic on port 80 from any source 
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    self        = false
  }

  # allow all outgoing traffic to any destination
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Create an AWS Application Load Balancer (ALB)
resource "aws_lb" "load_balancer" {
  name               = "${var.namespace}-${var.project_name}-alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
  security_groups = [aws_security_group.load_balancer.id]
}

