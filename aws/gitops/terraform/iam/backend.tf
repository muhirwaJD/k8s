terraform {
  backend "s3" {
    region       = var.region
    bucket       = var.bucket
    key          = "global/iam/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}