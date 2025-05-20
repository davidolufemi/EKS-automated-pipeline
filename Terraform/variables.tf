#VPC

variable "name" {
    type = string
    description = "name of the VPC"
}

variable "cidr" {
    type = string
    description = "CIDR range"
  
}

variable "azs" {
  type = list(string)
  description = "AZ's"
}

variable "private_subnets" {
  type = list(string)
  description = "private subnets"
}

variable "public_subnets" {
  type = list(string)
  description = "public subnets"
}


variable "Environment" {
  type = string
}

# EKS
variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "bootstrap_self_managed_addons" {
  type = bool
}

variable "cluster_endpoint_public_access" {
  type = bool
}

variable "enable_cluster_creator_admin_permissions" {
  type = bool
}


variable "eks_managed_node_groups" {
  type = map(object({
    ami_type       = string
    instance_types = list(string)
    min_size = number
    max_size = number
    desired_size = number
  }))
}

variable "tags" {
  type        = map(string)
  default     = {
    Environment = "prod"
  }
}






