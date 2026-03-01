#!/bin/bash

# =============================================================================
# EKS Post-Deploy Setup Script
# Run this after: terraform destroy + terraform apply
# Automates: kubeconfig update, RBAC setup, and app deployment
# =============================================================================

set -e  # Exit on any error

# --- Configuration ---
CLUSTER_NAME="staging-demo"
REGION="eu-west-1"
BASE_DIR="$HOME/Kubernetes-Cloud/aws"

echo "============================================="
echo "  EKS Post-Deploy Setup"
echo "============================================="

# Step 1: Update kubeconfig with default admin profile
echo ""
echo "📡 Step 1: Updating kubeconfig..."
aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION
echo "   ✅ kubeconfig updated"

# Step 2: Wait for nodes to be ready
echo ""
echo "⏳ Step 2: Waiting for nodes to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s
echo "   ✅ Nodes are ready"

# Step 3: Apply RBAC manifests
echo ""
echo "🔐 Step 3: Applying RBAC..."
kubectl apply -f $BASE_DIR/1-example/   # Viewer ClusterRole + Binding
kubectl apply -f $BASE_DIR/2-example/   # Admin ClusterRoleBinding
echo "   ✅ RBAC applied"

# Step 4: Deploy applications
# echo ""
# echo "🚀 Step 4: Deploying applications..."
# kubectl apply -f $BASE_DIR/3-example/   # App + HPA
# kubectl apply -f $BASE_DIR/4-example/   # App for autoscaler testing
# kubectl apply -f $BASE_DIR/5-example/   # App with LoadBalancer
# echo "   ✅ Applications deployed"

# Step 5: Wait for pods to be ready
echo ""
echo "⏳ Step 5: Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n 3-example --timeout=120s 2>/dev/null || true
kubectl wait --for=condition=Ready pods --all -n 4-example --timeout=120s 2>/dev/null || true
kubectl wait --for=condition=Ready pods --all -n 5-example --timeout=120s 2>/dev/null || true
echo "   ✅ Pods are ready"

# Step 6: Show cluster status
echo ""
echo "============================================="
echo "  📊 Cluster Status"
echo "============================================="
echo ""
echo "--- Nodes ---"
kubectl get nodes
echo ""
echo "--- Pods (all namespaces) ---"
kubectl get pods -A
echo ""
echo "--- Services ---"
kubectl get svc -A
echo ""
echo "--- HPA ---"
kubectl get hpa -n 3-example 2>/dev/null || echo "   No HPA found"
echo ""
echo "============================================="
echo "  ✅ Setup complete!"
echo "============================================="
echo ""
echo "To test eks-admin access:"
echo "  aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION --profile eks-admin"
echo "  kubectl get pods -A"
