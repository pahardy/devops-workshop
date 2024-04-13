variable "public_cidrs" {
  type = list(string)
  description = "List of public CIDRs for the created VPC"
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_cidrs" {
  type = list(string)
  description = "List of public CIDRs for the created VPC"
  default = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}