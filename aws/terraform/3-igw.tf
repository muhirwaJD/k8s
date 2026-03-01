# =============================================================================
# INTERNET GATEWAY
# Connects the VPC to the public internet.
# Without this, nothing in the VPC can reach the internet (or be reached).
# Used by: public subnets (4-subnets.tf) via the public route table (6-routes.tf)
# =============================================================================

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.env}-igw" # e.g. "staging-igw"
  }
}
