terraform {
  backend "s3" {
    bucket         = "pratyush-joshi-devops-lab"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}