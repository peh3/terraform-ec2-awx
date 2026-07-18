# 1. VPC INITIALIZATION
resource "aws_vpc" "tk_tf_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "tk-tf-vpc"
  }
}

resource "aws_internet_gateway" "tk_tf_igw" {
  vpc_id = aws_vpc.tk_tf_vpc.id

  tags = {
    Name = "tk-tf-igw"
  }
}

# 2. SUBNET CONFIGURATIONS
resource "aws_subnet" "public_1a" {
  vpc_id            = aws_vpc.tk_tf_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = { Name = "tk-tf-public-subnet-1a" }
}

resource "aws_subnet" "public_1b" {
  vpc_id            = aws_vpc.tk_tf_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = { Name = "tk-tf-public-subnet-1b" }
}

# --- Private App Tier ---
resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.tk_tf_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = { Name = "tk-tf-private-subnet-1a" }
}

resource "aws_subnet" "private_1b" {
  vpc_id            = aws_vpc.tk_tf_vpc.id
  cidr_block        = "10.0.4.0/24" 
  availability_zone = "us-east-1b"

  tags = { Name = "tk-tf-private-subnet-1b" }
}

# 3. NAT GATEWAY IN A PUBLIC SUBNET
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "tk_tf_nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1b.id

  tags = {
    Name = "tk-tf-nat-gw"
  }
  depends_on = [aws_internet_gateway.tk_tf_igw]
}

# 4. ROUTE TABLES & EXPLICIT BOUNDARIES
# --- Public Route Table & Routes ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.tk_tf_vpc.id
  tags   = { Name = "tk-tf-public-route-table" }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.tk_tf_igw.id
}

# --- Private Route Table & Routes ---
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.tk_tf_vpc.id
  tags   = { Name = "tk-tf-private-route-table" } 
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.tk_tf_nat_gw.id 
}

# 5. ROUTE TABLE ASSOCIATIONS
# Public Subnet Associations
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_1b" {
  subnet_id      = aws_subnet.public_1b.id
  route_table_id = aws_route_table.public.id
}

# Private Subnet Associations
resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private_1b" {
  subnet_id      = aws_subnet.private_1b.id
  route_table_id = aws_route_table.private.id
}