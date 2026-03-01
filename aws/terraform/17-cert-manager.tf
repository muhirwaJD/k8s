# # =============================================================================
# # CERT-MANAGER
# # Automatically provisions and renews TLS certificates for HTTPS.
# # Uses Let's Encrypt to get free certificates.
# #
# # How it works:
# #   1. You create an Ingress with a TLS section + cert-manager annotation
# #   2. Cert-manager sees it and requests a certificate from Let's Encrypt
# #   3. Let's Encrypt verifies you own the domain (via HTTP challenge)
# #   4. Certificate is stored as a Kubernetes Secret
# #   5. NGINX Ingress uses that Secret to serve HTTPS
# #   6. Cert-manager auto-renews before expiry (every 60 days)
# #
# # This installs cert-manager CRDs (Custom Resource Definitions) which add
# # new resource types: Certificate, ClusterIssuer, Issuer, etc.
# # =============================================================================

# resource "helm_release" "cert_manager" {
#   name = "cert-manager"

#   repository       = "https://charts.jetstack.io"
#   chart            = "cert-manager"
#   namespace        = "cert-manager"
#   create_namespace = true # Create "cert-manager" namespace

#   # CRDs (Custom Resource Definitions) must be installed for cert-manager to work
#   # This adds new K8s resource types: Certificate, ClusterIssuer, etc.
#   set {
#     name  = "crds.enabled"
#     value = "true"
#   }

#   depends_on = [helm_release.external_nginx] # Install after NGINX Ingress
# }
