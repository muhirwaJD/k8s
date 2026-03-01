#!/bin/bash

# =============================================================================
# EKS Cost-Saving Destroy Script
# Destroys the most expensive AWS resources without tearing down everything.
# Run this at the end of each session to save money overnight.
#
# What it destroys (~$0.15/hr saved):
#   - EC2 Node Group    ($0.08/hr) ← biggest cost
#   - NAT Gateway       ($0.045/hr)
#   - All Helm releases ($0.02+/hr) ← removes NLBs
#
# What it KEEPS (cheap/free):
#   - VPC, Subnets, IGW, Route Tables (free)
#   - EKS Control Plane ($0.10/hr ← only thing still billed)
#   - IAM Roles (free)
#
# To rebuild everything: run terraform apply
# =============================================================================

set -e

TERRAFORM_DIR="$HOME/Kubernetes-Cloud/aws/terraform"

echo "============================================="
echo "  💰 EKS Cost-Saving Destroy"
echo "============================================="
echo ""
echo "This will destroy:"
echo "  - EC2 Node Group        (~\$0.08/hr)"
echo "  - NAT Gateway           (~\$0.045/hr)"
echo "  - All Helm releases     (~\$0.02+/hr = NLBs)"
echo ""
echo "This will KEEP:"
echo "  - EKS Control Plane     (~\$0.10/hr — unavoidable)"
echo "  - VPC, Subnets, IAM     (free)"
echo ""
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Cancelled."
  exit 0
fi

cd "$TERRAFORM_DIR"

echo ""
echo "🗑️  Step 1: Destroying Helm releases (removes NLBs/ALBs)..."
terraform destroy -auto-approve \
  -target=helm_release.cert_manager \
  -target=helm_release.external_nginx \
  -target=helm_release.cluster_autoscaler \
  -target=helm_release.metrics_server \
  -target=helm_release.aws_load_balancer_controller
echo "   ✅ Helm releases destroyed"

echo ""
echo "🗑️  Step 2: Destroying EC2 Node Group (most expensive)..."
terraform destroy -auto-approve \
  -target=aws_eks_node_group.general
echo "   ✅ Node group destroyed"

echo ""
echo "🗑️  Step 3: Destroying NAT Gateway..."
terraform destroy -auto-approve \
  -target=aws_nat_gateway.nat \
  -target=aws_eip.nat
echo "   ✅ NAT Gateway destroyed"

echo ""
echo "============================================="
echo "  ✅ Done! Resources destroyed."
echo "============================================="
echo ""
echo "💰 Estimated savings: ~\$0.15/hr = ~\$3.50/day"
echo "   Still running: EKS Control Plane (~\$0.10/hr)"
echo ""
echo "To rebuild everything:"
echo "  cd $TERRAFORM_DIR && terraform apply"
echo ""
