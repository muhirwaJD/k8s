# =============================================================================
# NAT GATEWAY
# Allows resources in PRIVATE subnets to reach the internet (for updates,
# pulling container images, etc.) WITHOUT being directly accessible from
# the internet. Traffic flows: Private subnet → NAT → Internet Gateway → Internet
#
# Components:
#   Elastic IP: A static public IP address assigned to the NAT Gateway
#   NAT Gateway: Placed in a PUBLIC subnet, translates private IPs to its public IP
# =============================================================================

# Static public IP for the NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${local.env}-nat"
  }
}

# NAT Gateway — placed in public subnet so it can reach the internet
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id             # Use the static IP above
  subnet_id     = aws_subnet.public_zone1.id # Must be in a PUBLIC subnet

  tags = {
    Name = "${local.env}-nat"
  }

  depends_on = [aws_internet_gateway.igw] # IGW must exist first
}
