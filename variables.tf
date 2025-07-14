variable "region" {}
variable "backend_bucket" {}
variable "backend_region" {}
variable "dynamodb_table" {}
variable "project" {}
variable "vpc_cidr" {}
variable "public_subnets" {
  type = list(string)
}
variable "private_subnets" {
  type = list(string)
}
variable "azs" {
  type = list(string)
}
variable "db_user" {}
variable "db_pass" {}
variable "log_bucket" {}

