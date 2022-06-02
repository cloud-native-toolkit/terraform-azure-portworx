
module "portworx" {
  source = "./module"

  azure_client_id       = var.azure_client_id
  azure_client_secret   = var.azure_client_secret
  azure_subscription_id = var.azure_subscription_id
  azure_tenant_id       = var.azure_tenant_id
  cluster_config_file   = module.dev_cluster.platform.kubeconfig
  portworx_spec         = var.portworx_spec
  cluster_type          = var.cluster_type
}
