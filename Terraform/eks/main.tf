# EKS Cluster

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  bootstrap_self_managed_addons = var.bootstrap_self_managed_addons  

  # Optional
  cluster_endpoint_public_access = var.cluster_endpoint_public_access 

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions 

  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids
  control_plane_subnet_ids = var.control_plane_subnet_id #["subnet-xyzde987", "subnet-slkjf456", "subnet-qeiru789"]

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t3.micro"]
  }

  eks_managed_node_groups = var.eks_managed_node_groups

  tags = var.tags
}