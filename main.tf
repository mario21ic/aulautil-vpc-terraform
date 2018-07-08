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

/* Ec2 bastion */
resource "aws_instance" "ec2_bastion" {
  ami = "ami-0ad99772"
  instance_type = "t2.micro"
  key_name = "demoaulutil"
  associate_public_ip_address = true

  vpc_security_group_ids = ["${aws_security_group.sg_bastion.id}"]
  subnet_id = "${aws_subnet.sn_public_1.id}"
}

resource "aws_security_group" "sg_bastion" {
  name        = "mysg_bastion"

  description = "Allow traffic"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}


/* Ec2 private */
resource "aws_instance" "ec2_private" {
  ami = "ami-0ad99772"
  instance_type = "t2.micro"
  key_name = "demoaulutil"
  associate_public_ip_address = false

  vpc_security_group_ids = ["${aws_security_group.sg_private.id}"]
  subnet_id = "${aws_subnet.sn_private_1.id}"
}

resource "aws_security_group" "sg_private" {
  name        = "mysg_private"

  description = "Allow traffic"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = ["${aws_security_group.sg_bastion.id}"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
