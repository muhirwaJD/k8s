# =============================================================================
# NGINX INGRESS CONTROLLER
# Deploys NGINX as an Ingress Controller inside the cluster.
# Alternative to ALB Ingress — routes traffic inside the cluster via NGINX pod.
#
# Architecture: Internet → NLB → NGINX pod → routes to services
# Usage: Set ingressClassName: external-nginx in your Ingress resources
#
# Configuration values loaded from values/nginx-ingress.yaml
# =============================================================================

resource "helm_release" "external_nginx" {
  name = "external"

  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress" # Dedicated namespace for the controller
  create_namespace = true      # Create "ingress" namespace if it doesn't exist

  values = [file("${path.module}/values/nginx-ingress.yaml")]

  depends_on = [helm_release.aws_lbc] # Install after AWS LBC
}
