terraform {
  backend "s3" {
    bucket = "bet2wealth-terraform-state"
    key    = "backend/dev/terraform.tfstate"
    region = "eu-central-1"
  }
}
