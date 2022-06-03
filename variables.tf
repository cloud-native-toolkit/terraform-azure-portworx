variable "provision" {
  default     = true
  description = "If set to true installs Portworx on the given cluster"
}

variable "azure_subscription_id" {
  type    = string
  description = "The subscription id of the Azure account where the OpenShift cluster has been provisioned"
}

variable "azure_tenant_id" {
  type    = string
  description = "The tenant id of the Azure account where the OpenShift cluster has been provisioned"
}

variable "azure_client_id" {
  type    = string
  description = "The client id used to access the Azure account"
}

variable "azure_client_secret" {
  type    = string
  description = "The client secret used to access the Azure account"
}

variable "cluster_type" {
  type        = string
  description = "Type of OCP cluster on Azure (ARO | IPI)"
  default     = "ARO"
  #enum: ARO, IPI
  validation {
    condition     = contains(["ARO","IPI"], var.cluster_type)
    error_message = "Allowed values for cluster_type are \"ARO\" or \"IPI\"."
  }
}


variable "disk_size" {
  description = "Disk size for each Portworx volume"
  default     = 1000
}

variable "kvdb_disk_size" {
  default = 150
}

variable "px_enable_monitoring" {
  type        = bool
  default     = true
  description = "Enable monitoring on PX"
}

variable "px_enable_csi" {
  type        = bool
  default     = true
  description = "Enable CSI on PX"
}

variable "cluster_config_file" {
  type        = string
  description = "Cluster config file for Kubernetes cluster."
}

variable "portworx_spec_file" {
  type = string
  description = "The path to the file that contains the yaml spec for the Portworx config. Either the `portworx_spec_file` or `portworx_spec` must be provided. The instructions for creating this configuration can be found at https://github.com/cloud-native-toolkit/terraform-azure-portworx/blob/main/PORTWORX_CONFIG.md"
  default = ""
}

variable "portworx_spec" {
  type = string
  description = "The yaml spec for the Portworx config. Either the `portworx_spec_file` or `portworx_spec` must be provided. The instructions for creating this configuration can be found at https://github.com/cloud-native-toolkit/terraform-azure-portworx/blob/main/PORTWORX_CONFIG.md"
  default = ""
}

variable "enable_encryption" {
  type = bool
  description = "Flag indicating portworx volumes should be encrypted"
  default = false
}
