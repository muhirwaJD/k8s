# =============================================================================
# EKS POD IDENTITY ADDON
# Enables pods to securely assume IAM roles using EKS Pod Identity.
# This is the modern replacement for IRSA (IAM Roles for Service Accounts).
# Required by: Cluster Autoscaler (14-cluster-autoscaler.tf)
# =============================================================================

resource "aws_eks_addon" "pod_identity" {
  cluster_name  = aws_eks_cluster.eks.name
  addon_name    = "eks-pod-identity-agent"
  addon_version = "v1.3.10-eksbuild.2"
}
