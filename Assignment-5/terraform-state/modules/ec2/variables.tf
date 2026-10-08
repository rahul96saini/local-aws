variable "instances" {
  type = map(object({
    subnet_id = string
    name      = string
  }))
}

variable "security_group_id" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type = string
}