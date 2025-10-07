variable "env" {}
variable "vpc_cidr" {
  type = list(string)
  default = ["10.0.0.0/16", "10.1.0.0/16"]
}
variable "public_subnet_cidrs" {
  type = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.1.1.0/24", "10.1.2.0/24"]
}
variable "private_subnet_cidrs" {
  type = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24", "10.1.3.0/24", "10.1.4.0/24"]
}
variable "availability_zones" {
  type = list(string)
  default = ["us-east-1a", "us-east-1b"]
}
