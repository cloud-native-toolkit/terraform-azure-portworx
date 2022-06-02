
# Resource Group Variables

variable "region" {
  type        = string
  description = "Region where AWS cluster is deployed"
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

variable cluster_username {
  type        = string
  description = "The username for ARO cluster access"
}

variable "cluster_password" {
  type        = string
  description = "The password for ARO cluster access"
}


variable "cluster_token" {
  type        = string
  description = "The token for ARO cluster access"
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

variable "cluster_type" {
  type        = string
  description = "Type of OCP cluster on Azure (ARO | IPI)"
  default     = "ARO"
  validation {
    condition     = contains(["ARO","IPI"], var.cluster_type)
    error_message = "Allowed values for cluster_type are \"ARO\" or \"IPI\"."
  }
}

variable "portworx_spec" {
  type = string
}

variable "ca_cert" {
  type = string
}
