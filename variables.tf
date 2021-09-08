variable "aws_region" {
  description = "Select regions"
  default     = "us-east-1"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "instance-count" {
  default = 1
}

variable "ami" {
  default = "ami-087c17d1fe0178315"
}

variable "private_subnet_1" {
  default = "172.31.96.0/20"
}