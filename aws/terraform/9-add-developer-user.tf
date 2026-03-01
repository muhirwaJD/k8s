# # =============================================================================
# # DEVELOPER USER SETUP — Read-only EKS access
# # Creates an IAM user "developer" with limited EKS permissions.
# # Mapped to K8s group "my-viewer" → gets read-only access via ClusterRole (1-example/)
# #
# # Flow: developer user → authenticates to EKS → placed in "my-viewer" group
# #       → ClusterRoleBinding maps to "viewer" ClusterRole → get/list/watch only
# # =============================================================================

# # Create the IAM user
# resource "aws_iam_user" "developer" {
#   name = "developer"
# }

# # --- IAM Policy: Limited EKS access ---
# # Can only Describe and List EKS resources (read-only in AWS console)
# resource "aws_iam_policy" "developer_eks" {
#   name        = "developer_eks_policy"
#   path        = "/"
#   description = "Developer EKS policy"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "eks:Describe*", # Describe cluster, nodegroups, etc.
#           "eks:List*",     # List clusters, nodegroups, etc.
#         ]
#         Effect   = "Allow"
#         Resource = "*"
#       },
#     ]
#   })
# }

# # Attach the policy to the developer user
# resource "aws_iam_policy_attachment" "developer_eks_attachment" {
#   name       = "developer_eks_attachment"
#   users      = [aws_iam_user.developer.name]
#   policy_arn = aws_iam_policy.developer_eks.arn
# }

# # --- EKS Access Entry: Bridge between AWS IAM and Kubernetes RBAC ---
# # Maps the developer IAM user to the "my-viewer" K8s group.
# # The ClusterRoleBinding (1-example/) then maps "my-viewer" → viewer ClusterRole.
# resource "aws_eks_access_entry" "developer" {
#   cluster_name      = aws_eks_cluster.eks.name
#   principal_arn     = aws_iam_user.developer.arn
#   kubernetes_groups = ["my-viewer"] # Read-only group from 1-example/
# }
