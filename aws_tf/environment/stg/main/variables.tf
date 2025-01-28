
variable "availability_zones" {
  type = list(string)
  default = ["ap-northeast-1a", "ap-northeast-1c"]
}

variable "instance_type" {
  type = string
  default = "t2.micro"
}


variable "key_name" {
  type    = string
  default = "yama-key-2025"
}

variable "db_identifier" {
  type    = string
  
}

variable "db_name" {
  type    = string
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_port" {
  type    = string
  default = "3306"
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "pgp_key" {
  type = string

}
