# =============================================================================
# LOCAL VARIABLES
# Central configuration — change values here to affect the entire project.
# Referenced throughout all other .tf files as local.<name>
# =============================================================================

locals {
  env         = "staging"    # Environment name (used in resource naming)
  region      = "eu-west-1"  # AWS region (Ireland)
  zone1       = "eu-west-1a" # Availability Zone 1
  zone2       = "eu-west-1b" # Availability Zone 2
  eks_name    = "demo"       # EKS cluster name suffix (full name: staging-demo)
  eks_version = "1.35"       # Kubernetes version for EKS
}
