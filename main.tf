#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#REQUIRE A SPECIFIC TERRAFORM VERSION
#This module has been update with Terraform 0.12 syntax.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
    required_version = ">= 0.12"
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#AWS PROVIDER
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

provider "aws" {
    region = var.aws_region
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY VPC
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

resource "aws_vpc" "minishift_vpc" {
    cidr_block = "172.16.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
        Name = "Minishift VPC"
    }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY INTERNET GATEWAY
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
resource "aws_internet_gateway" "minishift_gateway" {
    vpc_id = aws_vpc.minishift_vpc.id
    tags = {
        Name = "minishift_gateway"
    }

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY SUBNET
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
resource "aws_subnet" "minishift_subnet" {
  cidr_block = "172.16.10.0/24"
  vpc_id = aws_vpc.minishift_vpc.id
  availability_zone = var.available_zone

  tags = {
    Name = "minishift_public_subnet"
  }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DEPLOY ROUTE TABLE
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
resource "aws_route_table" "default_route" {
  vpc_id = aws_vpc.minishift_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.minishift_gateway.id
  }
  tags = {
    Name = "Minishift Gateway"
  }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DEPLOY ROUTE TABLE ASSOCIATION
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
resource "aws_route_table_association" "minishift_public" {
  route_table_id = aws_route_table.default_route.id
  subnet_id = aws_subnet.minishift_subnet.id
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DEPLOY SECURITY GROUP
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
resource "aws_security_group" "allow_tls_ssh" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.minishift_vpc.id
  
  # Inbound SSH from anywhere
  ingress {
    from_port = var.ssh_port
    protocol = "tcp"
    to_port = var.ssh_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound HTTPS from anywhere
  ingress {
    from_port = var.https_port
    protocol = "tcp"
    to_port = var.https_port
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls_ssh"
  }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create AWS Key Pair
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
resource "aws_key_pair" "ssh_default" {
    key_name = "ssh_minishift"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4en3e08Qqt5W83DH9Ln2v9VKG5QLK/w8/4nAbUCNGmBXfQxjq2xrVijTWIuLHh850Nc6KhLHnOqDpTe96a0HqffkKGXpmlm+X94cM1IOikbjalwP+u9MA55hyeIz5EnRfx0zoLJuYTFLIP23JZtQ+NPI557XqMKsSmfur7UTtwHKQPaetn5du7SK+Ztxd/O0/2IEU139B2C2VMCdTBNNUGTpig5D1vR1QKvZng4kNEB34Ey23WCPpxKqO9HMqybRlJ6iLkeL65s31Gh6w5UCySNKbUX1jJpO/zmHHwxpl+Xb08e8wjesaMndsPM1QpWNhAS/1BzRJ7pYsGOYYWPB3 john@amaterasu"
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Select Most recent ami GitLab
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
resource "aws_instance" "minishiftserver" {
  ami           = var.ami_server
  instance_type = var.ec2_type
  key_name = aws_key_pair.ssh_default.key_name
  vpc_security_group_ids = [aws_security_group.allow_tls_ssh.id]

  tags = {
    Name = "minishiftserver"
  }
  availability_zone = var.available_zone
  subnet_id = aws_subnet.minishift_subnet.id
  user_data = file("install_minishift.sh")
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DEPLOY ASSOCIATION EIP - INTANCE
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
resource "aws_eip_association" "associationip_minishift" {
  instance_id = aws_instance.minishiftserver.id
  allocation_id = aws_eip.elasticip_minishift.id
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DEPLOY ELASTIC IP
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
resource "aws_eip" "elasticip_minishift" {
  vpc = true
}
