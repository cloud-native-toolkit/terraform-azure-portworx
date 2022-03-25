
# Resource Group Variables

variable "region" {
  type        = string
  description = "Region where AWS cluster is deployed"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where AWS cluster is deployed"
}

variable "azure_subscription_id" {
  type    = string
  default = ""
}

variable "azure_client_id" {
  type    = string
  default = ""
}

variable "azure_client_secret" {
  type    = string
  default = ""
}

variable "azure_tenant_id" {
  type    = string
  default = ""
}

variable cluster_name {
  type        = string
  description = "The name of the ARO cluster"
}

variable cluster_username {
  type        = string
  description = "The username for ARO cluster access"
}

variable "cluster_password" {
  type        = string
  description = "The password for ARO cluster access"
}

variable "server_url" {
  type        = string
}

variable "px_cluster_id" {
  type        = string
}

variable "px_user_id" {
  type        = string
}

variable "px_osb_endpoint" {
  type        = string
}

variable "portworx_type" {
  type        = string
  default     = "essentials"
}
