provider "aws" {
  region = "us-east-1"
}

locals {
  selected_vpc_cidr = var.vpc_cidr[0] 
  selected_public_cidr =[var.public_subnet_cidrs[0], var.public_subnet_cidrs[1]]
  selected_private_cidr = [var.private_subnet_cidrs[0], var.private_subnet_cidrs[1]]
}


resource "aws_vpc" "app_vpc" {
  cidr_block = local.selected_vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "PROD-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  count = length(local.selected_public_cidr)
  vpc_id = aws_vpc.app_vpc.id
  cidr_block = local.selected_public_cidr[count.index]
  map_public_ip_on_launch = true
  availability_zone = element(var.availability_zones, count.index)
  tags = {
    Name = "${var.env}-public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private_subnet" {
  count = length(local.selected_private_cidr)
  vpc_id = aws_vpc.app_vpc.id
  cidr_block = local.selected_private_cidr[count.index]
  availability_zone = element(var.availability_zones, count.index)
  tags = {
    Name = "${var.env}-private-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name = "${var.env}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name = "${var.env}-public-rt"
  }
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count          = length(local.selected_public_cidr)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat1" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat1" {
  allocation_id = aws_eip.nat1.id
  subnet_id     = aws_subnet.public_subnet[0].id
  tags = {
    Name = "${var.env}-nat1"
  }
}

resource "aws_route_table" "private1" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name = "${var.env}-private-rt1"
  }
}

resource "aws_route" "private_internet_access1" {
  route_table_id         = aws_route_table.private1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat1.id
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private_subnet[0].id
  route_table_id = aws_route_table.private1.id
}

resource "aws_eip" "nat2" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat2" {
  allocation_id = aws_eip.nat2.id
  subnet_id     = aws_subnet.public_subnet[1].id
  tags = {
    Name = "${var.env}-nat2"
  }
}

resource "aws_route_table" "private2" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name = "${var.env}-private-rt2"
  }
}

resource "aws_route" "private_internet_access2" {
  route_table_id         = aws_route_table.private2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat2.id
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private_subnet[1].id
  route_table_id = aws_route_table.private2.id
}

resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.app_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

    resource "aws_instance" "first_instance" {
  ami           = ami-0360c520857e3138f
  instance_type = t3.micro
  subnet_id = aws_subnet.public_subnet[0]
  associate_public_ip_address = true
  user_data = base64encode(
    <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y apt-transport-https ca-certificates curl software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt update -y
              apt-cache policy docker-ce
              apt install -y docker-ce
              systemctl status docker

              docker run -p 80:80

              EOF
  )

}
