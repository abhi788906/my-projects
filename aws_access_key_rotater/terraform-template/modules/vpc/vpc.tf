resource "aws_vpc" "vpc" {

  # VPC configuration
  cidr_block = var.cidr
  tags = {
    Name = "schduler_vpc"
  }
}

resource "aws_eip" "nat" {
  # Elastic IP configuration for NAT gateway
  vpc = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "InternetGateway"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "scheduler_public_table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "scheduler_private_table"
  }
}

resource "aws_subnet" "public_subnet" {
  # Subnet configuration
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidr
#   availability_zone       = element(["us-east-1a", "us-east-1b"], count.index % 2)
  map_public_ip_on_launch = true

  tags = {
    Name = "Scheduler_Public_Subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  # Subnet configuration
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_subnet_cidr
#   availability_zone       = element(["us-east-1a", "us-east-1b"], count.index % 2)
  map_public_ip_on_launch = false

  tags = {
    Name = "Scheduler_Private_Subnet"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  depends_on = [aws_internet_gateway.igw]

  # NAT gateway configuration
  subnet_id = aws_subnet.public_subnet.id
  allocation_id = aws_eip.nat.id

  tags = {
    Name = "SchedulerGateway"
  }
}

resource "aws_route_table_association" "public_route" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_route" {
    subnet_id = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.private_route_table.id
}


