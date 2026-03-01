# =============================================================================
# MANAGER ROLE SETUP - Admin access to EKS via IAM role assumption
# Flow: manager user → assumes eks_admin role → gets temporary credentials
#       → mapped to K8s group "my-admin" → full cluster-admin access
# =============================================================================

# Get the current AWS account ID (used in the trust policy)
data "aws_caller_identity" "current" {}

# --- IAM Role: eks_admin ---
# The role that grants EKS admin access. Must be assumed (not used directly).
# Trust policy: any IAM identity in this account can assume it
# (as long as they also have sts:AssumeRole permission on their side).
resource "aws_iam_role" "eks_admin" {
  name = "${local.env}-${local.eks_name}-eks-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Principal = {
          # "root" = any IAM user/role in this account (not just the root user)
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })
}

# --- IAM Policy: What the eks_admin role can do ---
# Full EKS access + ability to pass IAM roles to EKS service
resource "aws_iam_policy" "eks_admin" {
  name = "AmazonEKSAdminPolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        # Full control over all EKS operations
        Effect = "Allow",
        Action = [
          "eks:*"
        ],
        Resource = "*"
      },
      {
        # Allow passing IAM roles to EKS (needed for node groups, etc.)
        Effect   = "Allow",
        Action   = "iam:PassRole",
        Resource = "*",
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "eks.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Attach the EKS admin policy to the role
resource "aws_iam_role_policy_attachment" "eks_admin" {
  role       = aws_iam_role.eks_admin.name
  policy_arn = aws_iam_policy.eks_admin.arn
}

# --- Manager IAM User ---
# The human user who will assume the eks_admin role.
# This user has NO direct EKS permissions — must assume the role first.
resource "aws_iam_user" "manager" {
  name = "manager"
}

# --- Assume Role Policy for the Manager ---
# The ONLY permission the manager user gets: assume the eks_admin role.
# This ensures they must use temporary credentials (best practice).
resource "aws_iam_policy" "eks_assume_admin" {
  name = "AmazonEKSAssumeAdminPolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sts:AssumeRole",
        Resource = "${aws_iam_role.eks_admin.arn}"
      }
    ]
  })
}

# Attach the assume-role policy to the manager user
resource "aws_iam_user_policy_attachment" "manager" {
  user       = aws_iam_user.manager.name
  policy_arn = aws_iam_policy.eks_assume_admin.arn
}

# --- EKS Access Entry: Bridge between AWS IAM and Kubernetes RBAC ---
# Maps the eks_admin IAM role to the "my-admin" Kubernetes group.
# The ClusterRoleBinding (2-example/) then maps "my-admin" → cluster-admin.
# Best practice: use IAM roles due to temporary credentials
resource "aws_eks_access_entry" "manager" {
  cluster_name      = aws_eks_cluster.eks.name
  principal_arn     = aws_iam_role.eks_admin.arn
  kubernetes_groups = ["my-admin"]
}
