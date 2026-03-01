# # =============================================================================
# # EFS CSI DRIVER
# # Allows pods to use AWS EFS (Elastic File System) for SHARED persistent storage.
# # Unlike EBS (one pod at a time), EFS allows MANY pods to read/write simultaneously.
# #
# # Real-world use: shared config files, user uploads served by multiple pods,
# #                 shared logs, ML model files read by many inference pods.
# #
# # Architecture:
# #   EFS File System → Mount Targets (one per subnet) → EFS CSI Driver → Pods
# #
# # Same IAM pattern as EBS CSI Driver (18-ebs-csi-driver.tf):
# #   Trust Policy → IAM Role → IAM Policy → Pod Identity → EKS Addon
# #
# # KEY DIFFERENCE from EBS:
# #   EBS: ReadWriteOnce (one pod)  → storageClassName: gp2
# #   EFS: ReadWriteMany (all pods) → storageClassName: efs
# # =============================================================================

# # --- Trust Policy: Allow EKS pods to assume this IAM role ---
# data "aws_iam_policy_document" "efs_csi_driver" {
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

# # --- IAM Role for the EFS CSI Driver pod ---
# resource "aws_iam_role" "efs_csi_driver" {
#   name               = "${aws_eks_cluster.eks.name}-efs-csi-driver"
#   assume_role_policy = data.aws_iam_policy_document.efs_csi_driver.json
# }

# # --- Attach AWS managed policy for EFS CSI Driver ---
# # Grants permissions to create/describe/delete EFS access points and mount targets
# resource "aws_iam_role_policy_attachment" "efs_csi_driver" {
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
#   role       = aws_iam_role.efs_csi_driver.name
# }

# # --- Pod Identity Association ---
# # Maps the EFS CSI controller service account → IAM role
# # Same pattern as EBS (18-ebs-csi-driver.tf) — only service account name differs
# resource "aws_eks_pod_identity_association" "efs_csi_driver" {
#   cluster_name    = aws_eks_cluster.eks.name
#   namespace       = "kube-system"
#   service_account = "efs-csi-controller-sa" # Different from EBS ("ebs-csi-controller-sa")
#   role_arn        = aws_iam_role.efs_csi_driver.arn
# }

# # --- EKS Addon: Install the EFS CSI Driver ---
# resource "aws_eks_addon" "efs_csi_driver" {
#   cluster_name             = aws_eks_cluster.eks.name
#   addon_name               = "aws-efs-csi-driver"
#   service_account_role_arn = aws_iam_role.efs_csi_driver.arn

#   depends_on = [aws_eks_node_group.general] # Nodes must exist first
# }

# # =============================================================================
# # EFS FILE SYSTEM
# # The actual shared file system in AWS.
# # Like a network drive that multiple pods can mount simultaneously.
# # =============================================================================

# # --- Create the EFS File System ---
# resource "aws_efs_file_system" "main" {
#   encrypted = true # Encrypt data at rest

#   tags = {
#     Name = "${local.env}-efs"
#   }
# }

# # --- Security Group for EFS ---
# # Controls which resources can connect to EFS on port 2049 (NFS)
# resource "aws_security_group" "efs" {
#   name   = "${local.env}-efs-sg"
#   vpc_id = aws_vpc.main.id

#   ingress {
#     from_port   = 2049 # NFS port (EFS uses NFS protocol)
#     to_port     = 2049
#     protocol    = "tcp"
#     cidr_blocks = [aws_vpc.main.cidr_block] # Allow access from within the VPC only
#   }

#   tags = {
#     Name = "${local.env}-efs-sg"
#   }
# }

# # --- Mount Targets: One per subnet so pods in each AZ can reach EFS ---
# # Without mount targets, pods can't connect to EFS
# resource "aws_efs_mount_target" "zone1" {
#   file_system_id  = aws_efs_file_system.main.id
#   subnet_id       = aws_subnet.private_zone1.id # Zone 1 (eu-west-1a)
#   security_groups = [aws_security_group.efs.id]
# }

# resource "aws_efs_mount_target" "zone2" {
#   file_system_id  = aws_efs_file_system.main.id
#   subnet_id       = aws_subnet.private_zone2.id # Zone 2 (eu-west-1b)
#   security_groups = [aws_security_group.efs.id]
# }

# # --- StorageClass: Tells K8s how to provision EFS volumes ---
# # Unlike EBS (gp2 StorageClass exists by default), EFS needs a custom StorageClass
# resource "kubernetes_storage_class_v1" "efs" {
#   metadata {
#     name = "efs" # Referenced in PVC: storageClassName: efs
#   }

#   storage_provisioner = "efs.csi.aws.com" # EFS CSI Driver
#   reclaim_policy      = "Retain"          # Keep EFS data even after PVC is deleted

#   parameters = {
#     provisioningMode = "efs-ap" # Use EFS Access Points (recommended)
#     fileSystemId     = aws_efs_file_system.main.id
#     directoryPerms   = "700" # Directory permissions for each PVC
#   }

#   depends_on = [aws_eks_addon.efs_csi_driver] # Driver must be installed first
# }
