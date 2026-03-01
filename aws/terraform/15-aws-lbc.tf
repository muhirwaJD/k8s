# =============================================================================
# AWS LOAD BALANCER CONTROLLER (LBC)
# Watches for Service (type: LoadBalancer) and Ingress resources, then
# automatically creates AWS NLBs (for Services) or ALBs (for Ingress).
#
# Same pattern as Cluster Autoscaler:
#   Trust Policy → IAM Role → IAM Policy → Pod Identity → Helm Install
#
# The IAM policy is loaded from ./iam/AWSLoadBalancerController.json
# which grants permissions to create/manage load balancers, target groups, etc.
# =============================================================================

# --- Trust Policy: Allow EKS pods to assume this role ---
data "aws_iam_policy_document" "aws_lbc" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"] # EKS Pod Identity
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

# --- IAM Role for the LBC pod ---
resource "aws_iam_role" "aws_lbc" {
  name               = "${aws_eks_cluster.eks.name}-aws-lbc"
  assume_role_policy = data.aws_iam_policy_document.aws_lbc.json
}

# --- IAM Policy: Permissions to manage load balancers ---
# Loaded from a separate JSON file (too large to inline)
resource "aws_iam_policy" "aws_lbc" {
  policy = file("./iam/AWSLoadBalancerController.json")
  name   = "AWSLoadBalancerController"
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "aws_lbc" {
  policy_arn = aws_iam_policy.aws_lbc.arn
  role       = aws_iam_role.aws_lbc.name
}

# --- Pod Identity Association ---
# Maps K8s service account → IAM role (so the pod can call AWS APIs)
resource "aws_eks_pod_identity_association" "aws_lbc" {
  cluster_name    = aws_eks_cluster.eks.name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller" # Must match Helm chart SA
  role_arn        = aws_iam_role.aws_lbc.arn
}

# --- Helm Release: Install the AWS LBC ---
resource "helm_release" "aws_lbc" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  # Tell the controller which cluster it manages
  set {
    name  = "clusterName"
    value = aws_eks_cluster.eks.name
  }

  # Service account name (must match pod identity association above)
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  # VPC ID so the controller knows where to create load balancers
  set {
    name  = "vpcId"
    value = aws_vpc.main.id
  }

  depends_on = [helm_release.cluster_autoscaler]
}
