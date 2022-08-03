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

data "aws_eks_cluster" "default" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "default" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.default.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
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
    Name = "*public*"
  }
}

# eks module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.26.6"

  # cluster specs
  cluster_name    = "2206-devops-cluster-v1"
  cluster_version = "1.22"

  # vpc info from COE
  vpc_id     = data.aws_vpc.p3_vpc.id
  subnet_ids = data.aws_subnet_ids.public.ids

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
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  # cluster t3.large x 2
  eks_managed_node_groups = {

    default_node_group = {
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      min_size               = 1
      max_size               = 2
      desired_size           = 2
      create_launch_template = false
      launch_template_name   = ""
      ami_id                 = "ami-052efd3df9dad4825"
      disk_size              = 50
      instance_types         = ["t3.large"]
      # capacity_type          = "SPOT"
      # Remote access cannot be specified with a launch templatecd 

      remote_access = {
        ec2_ssh_key = aws_key_pair.ssh_access_key.key_name
      }
    }
  }
  # aws-auth configmap
  manage_aws_auth_configmap = true
  # COE provided
  aws_auth_users = [
    {
      userarn  = aws_iam_user.eks-user.arn
      username = aws_iam_user.eks-user.name
      groups   = ["system:masters"]
    },
  ]

  tags = {
    Name      = "2206-devops-cluster"
    Terraform = "true"
  }
} # end module eks

resource "aws_iam_user" "eks-user" {
  name = "2206-devops-user"

  tags = {
    tag-key = "2206-devops-user"
  }
}

resource "aws_iam_user_policy" "eks-iam-user_policy" {
  name = "devopsPolicy"
  user = aws_iam_user.eks-user.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "2206DevopsUser",
        Effect = "Allow",
        Action = [
          "eks:AccessKubernetesApi",
          "eks:DescribeCluster",
          "eks:CreateNodegroup",
          "eks:DeleteNodegroup",
          "eks:DescribeNodegroup",
          "eks:DescribeUpdate",
          "eks:ListNodegroups",
          "eks:ListTagsForResource",
          "eks:UpdateClusterConfig",
          "eks:UpdateNodegroupConfig"
        ],
        Resource = "${module.eks.cluster_arn}"
      }
    ]
  })
}


resource "aws_key_pair" "ssh_access_key" {
  key_name   = "2206-devops-key"
  public_key = file(".ssh/id_rsa.pub")
}

# needed for output aws credential keys
resource "aws_iam_access_key" "eks-access-key" {
  user = aws_iam_user.eks-user.name
}
output "aws-keys" {
  value = {
    access_key = aws_iam_access_key.eks-access-key.id
    secret_key = aws_iam_access_key.eks-access-key.secret
  }
  sensitive = true
}
