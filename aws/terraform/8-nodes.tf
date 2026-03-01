# =============================================================================
# EKS WORKER NODES
# Creates the EC2 instances (nodes) that run your pods.
# Managed by an EKS Node Group — AWS handles OS updates and lifecycle.
#
# Instance type: t3.large (2 vCPU, 8 GB memory)
# Scaling: 0-5 nodes, autoscaler adjusts based on pod demand
# =============================================================================

# --- IAM Role for Worker Nodes ---
# Nodes need permissions to: pull container images (ECR), manage networking (CNI),
# and register themselves with the EKS cluster.
resource "aws_iam_role" "eks_nodes" {
  name = "${local.env}-${local.eks_name}-eks-nodes"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com" # Only EC2 instances can assume this role
      }
    }]
    Version = "2012-10-17"
  })
}

# Required policies for worker nodes
resource "aws_iam_role_policy_attachment" "eks_worker_nodes" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy" # Register with EKS
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_CNI" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy" # Manage pod networking
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_ECR" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" # Pull container images
  role       = aws_iam_role.eks_nodes.name
}

# --- Node Group ---
# Defines the actual EC2 instances that run workloads
resource "aws_eks_node_group" "general" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "general"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  version         = local.eks_version

  subnet_ids = [
    aws_subnet.private_zone1.id, # Nodes run in PRIVATE subnets (no public IPs)
    aws_subnet.private_zone2.id,
  ]

  capacity_type  = "ON_DEMAND"  # Reliable instances (vs SPOT which is cheaper but can be interrupted)
  instance_types = ["t3.large"] # 2 vCPU, 8 GB memory per node

  scaling_config {
    desired_size = 1 # Start with 1 node
    max_size     = 5 # Cluster Autoscaler can add up to 5
    min_size     = 0 # Can scale down to 0 when idle
  }

  update_config {
    max_unavailable = 1 # During updates, only 1 node goes down at a time
  }

  labels = {
    role = "general" # Label for node selection (nodeSelector)
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_nodes,
    aws_iam_role_policy_attachment.eks_CNI,
    aws_iam_role_policy_attachment.eks_ECR,
  ]

  # Let the Cluster Autoscaler manage desired_size — don't fight over it
  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size
    ]
  }
}
