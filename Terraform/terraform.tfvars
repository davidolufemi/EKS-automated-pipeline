#VPC
name = "microservice-vpc"
cidr = "10.0.0.0/16"
azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets =  ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
Environment = "prod"


#EKS
cluster_name = "app-cluster-1"
cluster_version = "1.31"
bootstrap_self_managed_addons = true
cluster_endpoint_public_access = true
enable_cluster_creator_admin_permissions = true
eks_managed_node_groups = {
  "name" = {
    ami_type       = "AL2023_x86_64_STANDARD"
    min_size       = 5
    max_size       = 10
    desired_size   = 7
    instance_types = ["t3.micro"]
  }
}

tags = {
  "name"       = "app-cluster"
  "Environment" = "prod"
  "Terraform"   = "true"
}
