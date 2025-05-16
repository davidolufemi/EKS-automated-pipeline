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

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
  
}

variable "control_plane_subnet_id" {
  type = list(string)
  
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

