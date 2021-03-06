# Variables

variable "ec2_type" {
  default = "t2.large"
}

variable "aws_region" {
  default = "us-east-1"
  description = "OKD311 Cluster"
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

variable "kiali_port" {
  default = 32284
}

variable "jaeger_port" {
  default = 4443
}

variable "prometheus_port" {
  default = 9099
}

variable "tracing_port" {
  default = 30593
}

variable "ingressgateway_port" {
  default = 32280
}

variable "available_zone" {
  default = "us-east-1a"
}

variable "ami_server" {
  default = "ami-0affd4508a5d2481b"
}

#ami-0affd4508a5d2481b CENTOS
#ami-0c322300a1dd5dc79 REDHAT8