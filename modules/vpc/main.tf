resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "tp-${var.poste_nn}-vpc"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "tp-${var.poste_nn}-public-a"
  }
}

resource "aws_subnet" "prive_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "tp-${var.poste_nn}-prive-a"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "tp-${var.poste_nn}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "tp-${var.poste_nn}-rt-public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "tp-${var.poste_nn}-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  allocation_id     = aws_eip.nat.id
  subnet_id         = aws_subnet.public_a.id
  connectivity_type = "public"

  tags = {
    Name = "tp-${var.poste_nn}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "prive" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.test_panne_route ? [] : [1]
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main.id
    }
  }

  tags = {
    Name = "tp-${var.poste_nn}-rt-prive"
  }
}

resource "aws_route_table_association" "prive" {
  subnet_id      = aws_subnet.prive_a.id
  route_table_id = aws_route_table.prive.id
}
