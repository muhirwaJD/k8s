# =============================================================================
# METRICS SERVER - Collects CPU/memory usage from all pods and nodes
# Enables: kubectl top pods, kubectl top nodes
# Required by: HPA (Horizontal Pod Autoscaler) to make scaling decisions
# =============================================================================

resource "helm_release" "metrics_server" {
  name = "metrics-server"

  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  # Custom configuration values (see values/metrics-server.yaml)
  values = [file("${path.module}/values/metrics-server.yaml")]

  # Wait for nodes to be ready before installing
  depends_on = [aws_eks_node_group.general]
}
