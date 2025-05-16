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




