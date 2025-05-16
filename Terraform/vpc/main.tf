terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}


# VPC

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.name
  cidr = var.cidr

  azs             = var.azs  
  private_subnets = var.private_subnets   
  public_subnets  = var.public_subnets

  enable_nat_gateway = true

  tags = {
    Environment = var.Environment
  }
}



