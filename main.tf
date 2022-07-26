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
  vpc_id     = ""
  subnet_ids = [""] 

  # cluster t3.large x 2
  eks_managed_node_groups = {
    # ssh into nodes
    min_size     = 1
    max_size     = 10
    desired_size = 1

    instance_types = ["t3.large", "t3.large"]
    capacity_type  = "SPOT"
  }

  # aws-auth configmap
  manage_aws_auth_configmap = true
  # COE provided
  aws_auth_roles = [
    {
      rolearn  = ""
      username = ""
      groups   = [""]
    },
  ]


  tags = {
    Name = "2206-devops-cluster"
    Terraform   = "true"
  }

}

