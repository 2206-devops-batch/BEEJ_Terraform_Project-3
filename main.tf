# provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.23.0"
    }
  }
}

provider "aws" {
  # COE supplies credentials
  profile = "revature-terraform"
}


provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = module.eks.cluster_certificate_authority_data
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_id]
      command     = "aws"
    }
  }
}

data "aws_vpc" "p3_vpc" {
  filter {
    name   = "tag:Name"
    values = ["project-3-vpc"]
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.p3_vpc.id

  tags = {
    Name = "public"
  }
}
# eks module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.26.6"

  # cluster specs
  cluster_name    = "2206-devops-cluster"
  cluster_version = "1.0"

  # vpc info from COE
  vpc_id     = data.aws_vpc.p3_vpc.id
  subnet_ids = data.aws_subnet_ids.public.id

  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }
  # node security group rules
  node_security_group_additional_rules = {
    https_ingress = {
      description      = "HTTPS"
      from_port        = 443
      to_port          = 443
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["0.0.0.0/0"]
      type             = "ingress"
    }
    http_ingress = {
      description      = "HTTP"
      from_port        = 80
      to_port          = 80
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["0.0.0.0/0"]
      type             = "ingress"
    }
    ssh_ingress = {
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["0.0.0.0/0"]
      type             = "ingress"
    }

    egress = {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      type             = "egress"
    }
  }

  # cluster t3.large x 2
  eks_managed_node_groups = {
    # ssh into nodes
    min_size     = 1
    max_size     = 2
    desired_size = 2



    default_node_group = {
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      create_launch_template = false
      launch_template_name   = ""
      ami_id                 = "ami-052efd3df9dad4825"
      disk_size              = 50
      instance_types         = ["t3.large"]
      # capacity_type          = "SPOT"
      # Remote access cannot be specified with a launch templatecd 

      remote_access = {
        ec2_ssh_key               = aws_key_pair.ssh_access_key.key_name
      }
    }

    # aws-auth configmap
    manage_aws_auth_configmap = true
    # COE provided
    aws_auth_users = [
      {
        userarn  = aws_iam_user.eks-iam-user
        username = aws_iam_user.eks-iam-user.name
        groups   = ["system:masters"]
      },
    ]


    tags = {
      Name      = "2206-devops-cluster"
      Terraform = "true"
    }

  }
} # end module eks

resource "aws_iam_user" "eks-iam-user" {
  name = "2206-devops-eks-iam-role"

  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "eks:AccessKubernetesApi",
                "eks:DescribeCluster"
            ],
            "Resource": "module.eks.cluster.id"
        }
    ]
}
EOF

}


resource "aws_key_pair" "ssh_access_key" {
  key_name   = "2206-devops-key"
  public_key = file(".ssh/id_rsa.pub")
}

output "aws-keys" {
  value = {
    access_key = aws_iam_user.eks-iam-user.access_key
    secret_key = aws_iam_user.eks-iam-user.secret_key
  }
}
