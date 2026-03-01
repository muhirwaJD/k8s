# # =============================================================================
# # EBS CSI DRIVER
# # Allows pods to use AWS EBS (Elastic Block Store) volumes for persistent storage.
# # Without this, pod data is lost when a pod restarts or moves to another node.
# #
# # Use case: databases (PostgreSQL, MySQL), file uploads, any stateful app.
# # See: 10-example/ which uses a StatefulSet with EBS-backed storage.
# #
# # Same IAM pattern as Cluster Autoscaler and AWS LBC:
# #   Trust Policy → IAM Role → IAM Policy → Pod Identity → EKS Addon
# # =============================================================================

# # --- Trust Policy: Allow EKS pods to assume this IAM role ---
# data "aws_iam_policy_document" "ebs_csi_driver" {
#   statement {
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["pods.eks.amazonaws.com"] # EKS Pod Identity
#     }

#     actions = [
#       "sts:AssumeRole",
#       "sts:TagSession"
#     ]
#   }
# }

# # --- IAM Role for the EBS CSI Driver pod ---
# resource "aws_iam_role" "ebs_csi_driver" {
#   name               = "${aws_eks_cluster.eks.name}-ebs-csi-driver"
#   assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver.json
# }

# # --- Attach AWS managed policy for EBS CSI Driver ---
# # Grants permissions to create/attach/detach/delete EBS volumes
# resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
#   role       = aws_iam_role.ebs_csi_driver.name
# }

# # --- Optional: KMS encryption policy ---
# # Only needed if you want to encrypt EBS volumes with a custom KMS key.
# # If using the default AWS-managed key, this is not required.
# resource "aws_iam_policy" "ebs_csi_driver_encryption" {
#   name = "${aws_eks_cluster.eks.name}-ebs-csi-driver-encryption"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "kms:Decrypt",                         # Decrypt encrypted volumes
#           "kms:GenerateDataKeyWithoutPlaintext", # Generate data encryption keys
#           "kms:CreateGrant"                      # Allow granting KMS key access
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

# # --- Attach encryption policy to the role ---
# # Optional: only if you want to encrypt the EBS drives
# resource "aws_iam_role_policy_attachment" "ebs_csi_driver_encryption" {
#   policy_arn = aws_iam_policy.ebs_csi_driver_encryption.arn
#   role       = aws_iam_role.ebs_csi_driver.name
# }

# # --- Pod Identity Association ---
# # Maps the EBS CSI controller service account to the IAM role
# # so the driver pod can call AWS EBS APIs (create/attach/detach volumes)
# resource "aws_eks_pod_identity_association" "ebs_csi_driver" {
#   cluster_name    = aws_eks_cluster.eks.name
#   namespace       = "kube-system"
#   service_account = "ebs-csi-controller-sa" # Must match the driver's service account name
#   role_arn        = aws_iam_role.ebs_csi_driver.arn
# }

# # --- EKS Addon: Install the EBS CSI Driver ---
# # Installed as an EKS addon (not Helm) — AWS manages the lifecycle.
# # Once installed, you can use storageClassName: gp2 or gp3 in PVCs.
# resource "aws_eks_addon" "ebs_csi_driver" {
#   cluster_name             = aws_eks_cluster.eks.name
#   addon_name               = "aws-ebs-csi-driver"
#   service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

#   depends_on = [aws_eks_node_group.general] # Nodes must exist first
# }
