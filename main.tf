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
  vpc_id     = data.aws_vpc.selected.id
  subnet_ids = [""] 

  # node security group rules
  node_security_group_additional_rules = {
    https_ingress = {
      description      = "HTTPS"
      from_port        = 443
      to_port          = 443
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["0.0.0.0/0"]
    }
    http_ingress = {
      description      = "HTTP"
      from_port        = 80
      to_port          = 80
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["0.0.0.0/0"]
    }
    ssh_ingress = {
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["0.0.0.0/0"]
    }

    egress = {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  # cluster t3.large x 2
  eks_managed_node_groups = {
    # ssh into nodes
    min_size     = 1
    max_size     = 2
    desired_size = 2

    instance_types = ["t3.large"]
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

resource "aws_key_pair" "id_rsa" {
  key_name   = "2206-devops-key"
  public_key = file(".ssh/id_rsa.pub")
}
