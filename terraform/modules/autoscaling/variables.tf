
variable "name" {
  description = "Name to be used on all the resources as identifier"
  default     = ""
}

variable "ecs_service_name" {
  description = "Name of ecs service"
  default     = ""
}


variable "resource_id" {
  description = "Resource Identifier"
}


variable "cluster_name" {
  description = "Cluster Name"
}

variable "action" {
  description = "Lambda Function Arn"
}
