variable "vpc_id" {}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}
variable "region" {
  description = "AWS region"
  type        = string
}

variable "mongo_uri" {
  description = "MongoDB Atlas connection string"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "MongoDB database name"
  type        = string
}

variable "jwt_secret_key" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
}

variable "redis_addr" {
  description = "Redis endpoint address"
  type        = string
}
