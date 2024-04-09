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
data "aws_vpc" "default" {
  default = true
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
  vpc_id = data.aws_vpc.default.id
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
  ami = data.aws_ami.ami_id.id
  instance_type = "t3.medium"
  key_name = aws_key_pair.terraform-key-pair.key_name
  associate_public_ip_address = true
  security_groups = [aws_security_group.terraform-allow-ssh.name]

  tags = {
    "Name" = "Terraform-Instance"
  }
}