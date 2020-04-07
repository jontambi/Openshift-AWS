# Variables

variable "ec2_type" {
  default = "t2.large"
}

variable "aws_region" {
  default = "us-east-1"
  description = "Minishift Cluster"
}

variable "balancer_port" {
  default = 8443
}

variable "ssh_port" {
  default = 22
}

variable "https_port" {
  default = 8443
}

variable "available_zone" {
  default = "us-east-1a"
}