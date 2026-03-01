# =============================================================================
# EKS CLUSTER
# Creates the managed Kubernetes control plane on AWS.
# The control plane (API server, etcd, scheduler) is managed by AWS.
# Worker nodes are defined separately in 8-nodes.tf.
#
# Access mode: API only (no aws-auth ConfigMap, uses EKS access entries instead)
# =============================================================================

resource "aws_eks_cluster" "eks" {
  name = "${local.env}-${local.eks_name}" # e.g. "staging-demo"

  access_config {
    authentication_mode                         = "API" # Use EKS access entries (modern approach)
    bootstrap_cluster_creator_admin_permissions = true  # Whoever runs terraform gets admin
  }

  role_arn = aws_iam_role.eks.arn # IAM role the cluster uses to call AWS APIs
  version  = local.eks_version    # Kubernetes version (from 0-locals.tf)

  vpc_config {
    endpoint_private_access = false # API server NOT accessible from within VPC only
    endpoint_public_access  = true  # API server accessible from the internet (for kubectl)

    subnet_ids = [
      aws_subnet.private_zone1.id, # Worker nodes will run in private subnets
      aws_subnet.private_zone2.id,
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks, # Role must have permissions before cluster creation
  ]
}

# --- IAM Role for the EKS Cluster ---
# The cluster itself needs an IAM role to manage AWS resources (networking, logging, etc.)
resource "aws_iam_role" "eks" {
  name = "${local.env}-${local.eks_name}-eks-cluster"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com" # Only EKS service can assume this role
        }
      },
    ]
  })
}

# Attach the AWS-managed EKS policy to the cluster role
resource "aws_iam_role_policy_attachment" "eks" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}
