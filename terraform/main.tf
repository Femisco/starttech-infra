terraform {
  backend "s3" {
    bucket         = "starttech-terraform-state-ahmed-2026"   # use your exact bucket name
    key            = "global/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
provider "aws" {
  region = "us-east-1"
}

module "networking" {
  source = "./modules/networking"
}

module "compute" {
  source             = "./modules/compute"
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
}
module "storage" {
  source             = "./modules/storage"
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
}
