
variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_params" {
  type = list(object({
    cidr_block              = string
    availability_zone       = string
    map_public_ip_on_launch = bool
    tags = object({
      Name = string
    })
  }))
}
