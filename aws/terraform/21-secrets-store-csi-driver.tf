# # =============================================================================
# # SECRETS STORE CSI DRIVER
# # Allows Kubernetes to fetch secrets from external secret managers (like AWS 
# # Secrets Manager or Parameter Store) and mount them as volumes in pods.
# #
# # Components:
# #   1. Secrets Store CSI Driver (Helm — generic driver)
# #   2. AWS Provider (kubectl apply — AWS-specific logic)
# #      NOTE: We use kubectl instead of a 2nd Helm chart because both charts
# #      create resources with the same names (ServiceAccount, ClusterRoles),
# #      causing Helm ownership conflicts.
# #   3. IAM Role + Pod Identity (Permissions to read secrets)
# # =============================================================================

# # --- Helm: Secrets Store CSI Driver (Core) ---
# resource "helm_release" "secrets_store_csi_driver" {
#   name       = "secrets-store-csi-driver"
#   repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
#   chart      = "secrets-store-csi-driver"
#   namespace  = "kube-system"

#   set {
#     name  = "syncSecret.enabled"
#     value = "true" # Allows sync to K8s Secret objects if needed
#   }

#   depends_on = [aws_eks_node_group.general]
# }

# # --- AWS Provider: Installed via kubectl (avoids Helm ownership conflicts) ---
# # This DaemonSet runs on every node and handles the actual AWS API calls
# # to fetch secrets from AWS Secrets Manager.
# resource "null_resource" "secrets_store_aws_provider" {
#   depends_on = [helm_release.secrets_store_csi_driver]

#   provisioner "local-exec" {
#     command = "kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml"
#   }

#   # Clean up on destroy
#   provisioner "local-exec" {
#     when    = destroy
#     command = "kubectl delete -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml --ignore-not-found"
#   }
# }

# # --- IAM Role for Pods to Access AWS Secrets Manager ---
# data "aws_iam_policy_document" "secrets_csi" {
#   statement {
#     actions = ["sts:AssumeRole", "sts:TagSession"]
#     effect  = "Allow"
#     principals {
#       type        = "Service"
#       identifiers = ["pods.eks.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "secrets_csi" {
#   name               = "${aws_eks_cluster.eks.name}-secrets-csi"
#   assume_role_policy = data.aws_iam_policy_document.secrets_csi.json
# }

# # Policy to allow reading secrets from Secrets Manager
# resource "aws_iam_policy" "secrets_csi" {
#   name = "${aws_eks_cluster.eks.name}-secrets-csi-policy"
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "secretsmanager:GetSecretValue",
#           "secretsmanager:DescribeSecret"
#         ],
#         Resource = "*" # In production, restrict to specific secret ARNs
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "secrets_csi" {
#   policy_arn = aws_iam_policy.secrets_csi.arn
#   role       = aws_iam_role.secrets_csi.name
# }

# # --- Pod Identity Association ---
# # This connects the IAM role to the service account used by your application pods
# # in the 12-example namespace.
# resource "aws_eks_pod_identity_association" "secrets_csi" {
#   cluster_name    = aws_eks_cluster.eks.name
#   namespace       = "12-example"
#   service_account = "myapp-sa"
#   role_arn        = aws_iam_role.secrets_csi.arn
# }
