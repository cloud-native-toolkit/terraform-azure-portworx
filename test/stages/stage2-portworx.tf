
locals {
  portworx_config = {
    cluster_id = var.px_cluster_id
    user_id = var.px_user_id
    osb_endpoint = var.px_osb_endpoint
    type = var.portworx_type
    enable_encryption = false
  }
}

module "portworx" {
  source = "./module"

  region                = var.region
  azure_client_id       = var.azure_client_id
  azure_client_secret   = var.azure_client_secret
  azure_subscription_id = var.azure_subscription_id
  azure_tenant_id       = var.azure_tenant_id
  cluster_name          = var.cluster_name
  cluster_config_file   = module.dev_cluster.platform.kubeconfig
  portworx_config       = local.portworx_config
  resource_group_name   = var.resource_group_name
  cluster_type          = var.cluster_type
}
