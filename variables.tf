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

variable "ami_server" {
  default = "ami-0c322300a1dd5dc79"
}

#ami-0affd4508a5d2481b CENTOS
#ami-0c322300a1dd5dc79 REDHAT8