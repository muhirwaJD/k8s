# =============================================================================
# TERRAFORM PROVIDERS
# Declares which providers (AWS, Helm) Terraform needs and their versions.
# Providers are plugins that let Terraform manage specific cloud resources.
# =============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws" # AWS provider — manages EC2, EKS, IAM, VPC, etc.
      version = "~> 6.0"        # Use version 6.x (~ allows minor upgrades)
    }
    helm = {
      source  = "hashicorp/helm" # Helm provider — installs Helm charts into K8s
      version = "~> 2.0"         # Use version 2.x
    }
    kubernetes = {
      source  = "hashicorp/kubernetes" # Kubernetes provider — manages K8s resources like StorageClass
      version = "~> 2.0"               # Use version 2.x
    }
    null = {
      source  = "hashicorp/null" # Null provider — runs local commands (kubectl apply)
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider with our region
provider "aws" {
  region = local.region # From 0-locals.tf (eu-west-1)
}

# Configure the Kubernetes Provider to connect to the EKS cluster
# Used by resources like kubernetes_storage_class_v1 (EFS StorageClass in 19-efs-csi-driver.tf)
provider "kubernetes" {
  host                   = aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks.name]
  }
}

# Configure the Helm Provider to connect to the EKS cluster
# Used by helm_release resources (metrics-server, ingress-nginx, etc.)
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks.name]
    }
  }
}
