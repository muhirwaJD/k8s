terraform {
  backend "s3" {
    key            = "global/infra/terraform.tfstate"
    use_lockfile = true
  }
}