terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.68.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "xxxxxxxxxxxxxxxxxxxx"
  secret_key = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  # Configuration options
}

variable "vnet-address" {
    description = "Vnet address space"
    type = string
}

variable "echannel" {
    description = "All variable used for echannel"
    type = any
    default = "application"
}

variable "smasm" {
    description = "All variable used for SMASM"
    type = any
}

variable "route" {
    description = "Routing"
    type = string
  
}
resource "aws_vpc" "Azure_Vnet" {
    cidr_block = var.vnet-address
    tags = {
      Name = "Azure_Vnet"
    }
  
}

resource "aws_subnet" "eChannel-prd" {
    vpc_id = aws_vpc.Azure_Vnet.id
    cidr_block = var.echannel[0].subnet
    availability_zone = var.echannel[0].availability_zone

    tags = {
        Name = var.echannel[0].name
    }
  
}
resource "aws_subnet" "eChannel-dev" {
    vpc_id = aws_vpc.Azure_Vnet.id
    cidr_block = var.echannel[1].subnet
    availability_zone = var.echannel[1].availability_zone

    tags = {
        Name = var.echannel[1].name
    }
  
}
resource "aws_subnet" "smasm-prd" {
    vpc_id = aws_vpc.Azure_Vnet.id
    cidr_block = var.smasm[0].subnet
    availability_zone = var.smasm[0].availability_zone

    tags = {
        Name = var.smasm[0].name
    }
  
}
resource "aws_subnet" "smasm-dev" {
    vpc_id = aws_vpc.Azure_Vnet.id
    cidr_block = var.smasm[1].subnet
    availability_zone = var.smasm[1].availability_zone

    tags = {
        Name = var.smasm[1].name
    }
  
}
resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.Azure_Vnet.id

  tags = {
    Name = "echannel-igw"
  }
}
resource "aws_route_table" "echannel" {
  vpc_id = aws_vpc.Azure_Vnet.id

  route {
    cidr_block = var.route
    gateway_id = aws_internet_gateway.internet_gw.id
  }

  tags = {
    Name = "echannel"
  }
}
resource "aws_route_table" "smasm" {
  vpc_id = aws_vpc.Azure_Vnet.id

  route {
    cidr_block = var.route
    gateway_id = aws_internet_gateway.internet_gw.id
  }

  tags = {
    Name = "smasm"
  }
}
resource "aws_route_table_association" "echannel-prd" {
  subnet_id      = aws_subnet.eChannel-prd.id
  route_table_id = aws_route_table.echannel.id
}
resource "aws_route_table_association" "echannel-dev" {
  subnet_id      = aws_subnet.eChannel-dev.id
  route_table_id = aws_route_table.echannel.id
}
resource "aws_route_table_association" "smasm-prd" {
  subnet_id      = aws_subnet.smasm-prd.id
  route_table_id = aws_route_table.smasm.id
}
resource "aws_route_table_association" "smasm-dev" {
  subnet_id      = aws_subnet.smasm-dev.id
  route_table_id = aws_route_table.smasm.id
}

resource "aws_security_group" "common-sg" {
  name        = "common-sg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.Azure_Vnet.id

  ingress {
    description      = "HTTP from Internet"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
      }
  ingress {
    description      = "SSH from Internet"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
      }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "common-sg"
  }
}
resource "aws_network_interface" "echannel-prd-nic" {
  subnet_id       = aws_subnet.eChannel-prd.id
  private_ips     = ["10.151.1.6"]
  security_groups = [aws_security_group.common-sg.id]

  tags = {
    name = "echannel-prd-nic"
  }

}
resource "aws_instance" "terraform" {
  instance_type = "t2.micro"
  ami           = "ami-0ed9277fb7eb570c9"

  network_interface {
    network_interface_id = aws_network_interface.echannel-prd-nic.id
    device_index         = 0
  }
  key_name = "Terraform-KP"

  tags = {
    Name = "echannel-1"
  }
  
}
resource "aws_eip" "echannel-pip" {
  vpc                       = true
  network_interface         = aws_network_interface.echannel-prd-nic.id
  associate_with_private_ip = "10.151.1.6"

}
