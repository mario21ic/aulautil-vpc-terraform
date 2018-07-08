provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags {
    Name = "myvpc"
    Description = "VPC demo to delete"
  }
}

/* Public */
resource "aws_internet_gateway" "my_igw" {
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_default_security_group" "def_sg" {
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_default_network_acl" "def_nacl" {
  default_network_acl_id = "${aws_vpc.vpc.default_network_acl_id}"

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_route_table" "rt_public" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.my_igw.id}"
  }
}

resource "aws_route_table_association" "rt_association_public_1" {
  subnet_id = "${aws_subnet.sn_public_1.id}"
  route_table_id = "${aws_route_table.rt_public.id}"
}

resource "aws_route_table_association" "rt_association_public_2" {
  subnet_id = "${aws_subnet.sn_public_2.id}"
  route_table_id = "${aws_route_table.rt_public.id}"
}


/* Private */
resource "aws_eip" "eip_nat_gw" {
  vpc = true
}

resource "aws_nat_gateway" "my_nat_gw" {
  allocation_id = "${aws_eip.eip_nat_gw.id}"
  subnet_id     = "${aws_subnet.sn_public_1.id}"
}

resource "aws_route_table" "rt_private" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.my_nat_gw.id}"
  }
}

resource "aws_route_table_association" "rt_association_private_1" {
  subnet_id = "${aws_subnet.sn_private_1.id}"
  route_table_id = "${aws_route_table.rt_private.id}"
}

resource "aws_route_table_association" "rt_association_private_2" {
  subnet_id = "${aws_subnet.sn_private_2.id}"
  route_table_id = "${aws_route_table.rt_private.id}"
}



/* Subnets */
resource "aws_subnet" "sn_public_1" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-west-2a"
}
resource "aws_subnet" "sn_public_2" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2b"
}

resource "aws_subnet" "sn_private_1" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}
resource "aws_subnet" "sn_private_2" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-west-2b"
}


