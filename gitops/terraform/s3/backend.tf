terraform {
  backend "s3" {
    # Values come from state.config via: terraform init -backend-config=../state.config
    key          = "global/s3/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}
