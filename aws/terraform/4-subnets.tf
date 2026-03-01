# =============================================================================
# SUBNETS
# Split the VPC into 4 subnets across 2 availability zones for high availability.
#
# Private subnets: EKS worker nodes live here (no direct internet access)
#   - Tagged with "kubernetes.io/role/internal-elb" for internal load balancers
#
# Public subnets: NAT Gateway and external load balancers live here
#   - Tagged with "kubernetes.io/role/elb" for internet-facing load balancers
#   - map_public_ip_on_launch = true (resources get public IPs)
#
# Network layout:
#   10.0.0.0/19   = private zone 1 (8,192 IPs)
#   10.0.32.0/19  = private zone 2 (8,192 IPs)
#   10.0.64.0/19  = public zone 1  (8,192 IPs)
#   10.0.96.0/19  = public zone 2  (8,192 IPs)
# =============================================================================

# --- Private Subnets (for EKS worker nodes) ---
resource "aws_subnet" "private_zone1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/19"
  availability_zone = local.zone1

  tags = {
    "Name"                                                 = "${local.env}-private-${local.zone1}"
    "kubernetes.io/role/internal-elb"                      = "1" # EKS uses this to place internal LBs
    "kubernetes.io/cluster/${local.env}-${local.eks_name}" = "owned"
  }
}

resource "aws_subnet" "private_zone2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.32.0/19"
  availability_zone = local.zone2

  tags = {
    "Name"                                                 = "${local.env}-private-${local.zone2}"
    "kubernetes.io/role/internal-elb"                      = "1"
    "kubernetes.io/cluster/${local.env}-${local.eks_name}" = "owned"
  }
}

# --- Public Subnets (for NAT gateway and external load balancers) ---
resource "aws_subnet" "public_zone1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.64.0/19"
  availability_zone       = local.zone1
  map_public_ip_on_launch = true # Resources here get public IPs

  tags = {
    "Name"                                                 = "${local.env}-public-${local.zone1}"
    "kubernetes.io/role/elb"                               = "1" # EKS uses this to place internet-facing LBs
    "kubernetes.io/cluster/${local.env}-${local.eks_name}" = "owned"
  }
}

resource "aws_subnet" "public_zone2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.96.0/19"
  availability_zone       = local.zone2
  map_public_ip_on_launch = true

  tags = {
    "Name"                                                 = "${local.env}-public-${local.zone2}"
    "kubernetes.io/role/elb"                               = "1"
    "kubernetes.io/cluster/${local.env}-${local.eks_name}" = "owned"
  }
}
