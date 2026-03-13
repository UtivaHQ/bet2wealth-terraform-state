terraform {
  backend "s3" {
    bucket = "bet2wealth-terraform-state"
    key    = "backend/prod/terraform.tfstate"
    region = "eu-central-1"
  }
}
