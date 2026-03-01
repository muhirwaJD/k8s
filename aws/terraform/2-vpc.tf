# =============================================================================
# VPC (Virtual Private Cloud)
# The isolated network where all our AWS resources live.
# CIDR 10.0.0.0/16 = 65,536 IP addresses available for subnets.
# =============================================================================

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16" # IP range: 10.0.0.0 — 10.0.255.255

  enable_dns_support   = true # Enable DNS resolution inside the VPC
  enable_dns_hostnames = true # Enable DNS hostnames for EC2 instances

  tags = {
    Name = "${local.env}-main" # e.g. "staging-main"
  }
}
