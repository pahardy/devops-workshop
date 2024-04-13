output "instance_public_ips" {
  description = "Public IP address of the EC2 instances"
  value = [for instance in aws_instance.terraform-instance : instance.public_ip]
}