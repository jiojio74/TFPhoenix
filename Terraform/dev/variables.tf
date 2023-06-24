variable "region" {
  description = "AWS Region"
  default     = "eu-central-1"
  type        = string
}

variable "namespace" {
  description = "Project namespace [dev,staging,production]"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "ssh_key" {
  description = "Public key for EC2 ssh login"
  type        = string
}

variable "app_source_url" {
  description = "URL of the Node.js application source"
  type        = string
}