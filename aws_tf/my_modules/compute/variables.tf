
variable "instance_type" {
  type = string
  default = "t2.micro"
}

variable "availability_zones" {
  type = list(string)
  default = ["ap-northeast-1a", "ap-northeast-1c"]
}

variable "db_username" {
  type = string
  sensitive = true
}

variable "db_password" {
  type = string
  sensitive = true
}

variable "db_port" {
  type = string
  default = "3306"
}

variable "db_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "db_address" {
  type = string
}

variable "subnet_ids" {
  type = map(string)
}

variable "key_name" {
  type    = string
  default = "yama-key-2025"
}