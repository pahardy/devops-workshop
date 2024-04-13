#get the AMI ID through filters
data "aws_ami" "ami_id" {
  most_recent = true
  owners = ["099720109477"]

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "architecture"
    values = ["x86_64"]
  }

  filter {
    name = "state"
    values = ["available"]
  }
}

#Get the default VPC ID
#data "aws_vpc" "default" {
#  default = true
#}

#Create a new VPC
resource "aws_vpc" "terraform-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "terraform-vpc"
  }
}

#Create the subnets for the new VPC
resource "aws_subnet" "public_subnets" {
  count = length(var.public_cidrs)
  cidr_block = var.public_cidrs[count.index]
  vpc_id = aws_vpc.terraform-vpc.id

  tags = {
    Name = "PublicSubnet-${count.index}"
  }
}

resource "aws_subnet" "private_subnets" {
  count = length(var.private_cidrs)
  cidr_block = var.private_cidrs[count.index]
  vpc_id = aws_vpc.terraform-vpc.id

  tags = {
    Name = "PrivateSubnet-${count.index}"
  }
}

#Create IGW for the public subnets
resource "aws_internet_gateway" "terraform-igw" {
  vpc_id = aws_vpc.terraform-vpc.id

  tags = {
    Name = "terraform-IGW"
  }
}

#Create the route table for public routes
resource "aws_route_table" "terraform-public-rt" {
  vpc_id = aws_vpc.terraform-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform-igw.id
  }

  tags = {
    Name = "terraform-public-route-table"
  }
}

#Associate public route table with public subnet
resource "aws_route_table_association" "public-rt-assoc" {
  count = length(var.public_cidrs)
  subnet_id = "${element(aws_subnet.public_subnets.*.id, count.index)}"
  route_table_id = aws_route_table.terraform-public-rt.id
}

#create the key pair
resource "aws_key_pair" "terraform-key-pair" {
  key_name = "terraform-key-pair"
  public_key = file("~/.ssh/id_rsa.pub")
}

#create the SG for SSH access
resource "aws_security_group" "terraform-allow-ssh" {
  name = "terraform-allow-ssh"
  description = "Allow SSH traffic for EC2 instances created in Terraform"
  vpc_id = aws_vpc.terraform-vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "sg-ingress-rule" {
  security_group_id = aws_security_group.terraform-allow-ssh.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 22
  ip_protocol = "tcp"
  to_port = 22
}

resource "aws_vpc_security_group_egress_rule" "sg-egress-rule" {
  security_group_id = aws_security_group.terraform-allow-ssh.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}

#create the EC2 instance
resource "aws_instance" "terraform-instance" {
  for_each = toset(["jenkins-master", "jenkins-slave", "ansible"])
  ami = data.aws_ami.ami_id.id
  instance_type = "t3.medium"
  key_name = aws_key_pair.terraform-key-pair.key_name
  associate_public_ip_address = true
  #security_groups = [aws_security_group.terraform-allow-ssh.id]
  subnet_id = aws_subnet.public_subnets[0].id
  vpc_security_group_ids = [aws_security_group.terraform-allow-ssh.id]

  tags = {
    "Name" = each.value
  }
}