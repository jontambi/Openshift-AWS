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
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDWpKTQ+kEUhMT8dJzzRwBo51N7xQNe5Fh5UhOz2aikW9MQn+IcegjYegf4+ZLsi4c9wo/qvOniBFgQl7agNE07HQoDsB+2Mw1D8D8DeCqF+kkachlVdFw5WkNjdk1UhNTwUh0njxh6tT939cZl/9gOQ/l7u/YaTVNdtyhyb0i80tffmICOiXYTNVHXJ40ZFrXkqOWkuB60O6PqRrZE+evFoIhfpPwUW1jEEYZKlh+YoVCcRSQIzOdTi2Yla9q0SgxQDAKKODNDGvqJLlTdDxE5oE4vA+/8haJbvfGDurxtpx9IATUeuibyhGRIF0lNB7P6HTTN7GqoGI5rZtv0nJhdmaUYTa25m39a5axa7S4mC3/fa+tCkktIi+v6tQDPiIGHi0+LkgxNs4oR6MkYGQ4E+xJjolvCkQpmRteAz7JCF6zesowPIH0uUfr9aozz3MyPhYram89xAEe8rYj6CElM9pxcDVIfGVUW9Xhkr+y5dmyXHN+PMl2I6Kthn0XTAFM+BIxVDSlthDUv3Buf18SAvzhqLPW1yYZtI3dSGN1FEe/UjafAnA5JhXotRp29a1ytjOxqiuesbT/hkgXORnmGE9aPkCbdXnep3XRGDkHA729lszoBlfSFGIAd83uEJA04jKxcKLf822Ti4uRlTz/EGztpfcx25O4hPnb3pqCXvw== jontambi.business@gmail.com"
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
