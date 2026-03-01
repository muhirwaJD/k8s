# =============================================================================
# CLUSTER AUTOSCALER - Automatically scales EC2 nodes based on pod demand
# When pods can't be scheduled (nodes full), it adds more EC2 instances.
# When nodes are underutilized, it removes them to save costs.
# =============================================================================

# --- IAM Role for the Cluster Autoscaler pod ---
# This role allows the autoscaler pod to call AWS APIs (add/remove EC2 instances).
# Uses EKS Pod Identity (pods.eks.amazonaws.com) instead of access keys for security.
resource "aws_iam_role" "cluster_autoscaler" {
  name = "${aws_eks_cluster.eks.name}-cluster-autoscaler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
      }
    ]
  })
}

# --- IAM Policy: What the autoscaler is allowed to do in AWS ---
# Read permissions: discover auto scaling groups, instances, and node info
# Write permissions: change desired capacity (add nodes) and terminate instances (remove nodes)
resource "aws_iam_policy" "cluster_autoscaler" {
  name = "${aws_eks_cluster.eks.name}-cluster-autoscaler"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Read-only: discover existing infrastructure
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      },
      {
        # Write: actually scale nodes up/down
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Resource = "*"
      },
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
  role       = aws_iam_role.cluster_autoscaler.name
}

# --- Pod Identity Association ---
# Maps the Kubernetes service account "cluster-autoscaler" in "kube-system"
# to the IAM role above. This lets the autoscaler pod assume the role
# automatically without needing AWS access keys.
resource "aws_eks_pod_identity_association" "cluster_autoscaler" {
  cluster_name    = aws_eks_cluster.eks.name
  namespace       = "kube-system"
  service_account = "cluster-autoscaler"
  role_arn        = aws_iam_role.cluster_autoscaler.arn
}

# --- Helm Release: Install Cluster Autoscaler ---
# Deploys the autoscaler into kube-system namespace via Helm chart.
# It auto-discovers node groups using the cluster name.
resource "helm_release" "cluster_autoscaler" {
  name = "autoscaler"

  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"

  # Name of the K8s service account (must match pod identity association above)
  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }

  # Auto-discover node groups belonging to this cluster
  set {
    name  = "autoDiscovery.clusterName"
    value = aws_eks_cluster.eks.name
  }

  # MUST match your cluster's AWS region
  set {
    name  = "awsRegion"
    value = "eu-west-1"
  }

  set {
  name  = "extraArgs.scale-down-unneeded-time"
  value = "5m"
}

set {
  name  = "extraArgs.scale-down-delay-after-add"
  value = "5m"
}

set {
  name  = "extraArgs.scale-down-utilization-threshold"
  value = "0.3"   # more aggressive — removes nodes below 30% usage
}

  depends_on = [helm_release.metrics_server]
}
