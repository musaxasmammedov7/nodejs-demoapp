terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    bucket         = "nodejs-demoapp-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
