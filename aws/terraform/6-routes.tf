# =============================================================================
# ROUTE TABLES
# Define where network traffic goes for each subnet type.
#
# Private route table: All outbound traffic → NAT Gateway → Internet
#   (nodes can pull images, but can't be reached from outside)
#
# Public route table: All outbound traffic → Internet Gateway → Internet
#   (load balancers are directly accessible from the internet)
#
# Associations: Connect each subnet to its route table
# =============================================================================

# --- Private Route Table ---
# All traffic (0.0.0.0/0) goes through NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"            # All traffic
    nat_gateway_id = aws_nat_gateway.nat.id # → via NAT Gateway
  }

  tags = {
    Name = "${local.env}-private"
  }
}

# --- Public Route Table ---
# All traffic (0.0.0.0/0) goes directly through Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"                 # All traffic
    gateway_id = aws_internet_gateway.igw.id # → directly to internet
  }

  tags = {
    Name = "${local.env}-public"
  }
}

# --- Associate private subnets with private route table ---
resource "aws_route_table_association" "private_zone1" {
  subnet_id      = aws_subnet.private_zone1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_zone2" {
  subnet_id      = aws_subnet.private_zone2.id
  route_table_id = aws_route_table.private.id
}

# --- Associate public subnets with public route table ---
resource "aws_route_table_association" "public_zone1" {
  subnet_id      = aws_subnet.public_zone1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_zone2" {
  subnet_id      = aws_subnet.public_zone2.id
  route_table_id = aws_route_table.public.id
}
