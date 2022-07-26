# provider
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.23.0"
    }
  }
}

provider "aws" {
  # COE supplies credentials
}


# eks module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.26.6"
  
  # cluster specs
  cluster_name    = "2206-devops-cluster"
  cluster_version = "1.0"
  
  # vpc info from COE
  vpc_id     = # COE supplied
  subnet_ids = [""] # COE supplied

  #cluster nodes x 2
  
  #ssh into nodes

}

