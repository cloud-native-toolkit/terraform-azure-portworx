#resource "aws_kms_key" "px_key" {
#  count       = var.cloud_provider == "aws" ? 1:0
#  description = "Key used to encrypt Portworx PVCs"
#}

locals {
  px_enterprise       = data.external.portworx_config.result.type == "enterprise"
  rootpath            = abspath(path.root)
  installer_workspace = "${local.rootpath}/installer-files"
  px_cluster_id       = data.external.portworx_config.result.cluster_id
  priv_image_registry = "image-registry.openshift-image-registry.svc:5000/kube-system"

  #todo: fix for azure + aws
  #secret_provider     = var.provision && local.px_enterprise && var.portworx_config.enable_encryption ? "aws-kms" : "k8s"
  secret_provider     = "k8s"
  px_workspace        = "${local.installer_workspace}/ibm-px"
  portworx_spec       = var.portworx_spec_file != null && var.portworx_spec_file != "" ? base64encode(file(var.portworx_spec_file)) : var.portworx_spec
}


module setup_clis {
  source = "cloud-native-toolkit/clis/util"
  version = "1.16.0"

  clis = ["kubectl", "oc", "yq4", "jq"]
}

data external portworx_config {
  program = ["bash", "${path.module}/scripts/parse-portworx-config.sh"]

  query = {
    bin_dir = module.setup_clis.bin_dir
    portworx_spec = local.portworx_spec
  }
}

resource "null_resource" "create_workspace" {
  provisioner "local-exec" {
    command = <<EOF
test -e ${local.installer_workspace} || mkdir -p ${local.installer_workspace}
EOF
  }
}

resource "local_file" "portworx_operator_yaml" {
  content  = data.template_file.portworx_operator.rendered
  filename = "${local.installer_workspace}/portworx_operator.yaml"
}

resource "local_file" "storage_classes_yaml" {
  content  = data.template_file.storage_classes.rendered
  filename = "${local.installer_workspace}/storage_classes.yaml"
}

resource "local_file" "portworx_storagecluster_yaml" {
  content  = data.template_file.portworx_storagecluster.rendered
  filename = "${local.installer_workspace}/portworx_storagecluster.yaml"
}


resource "null_resource" "install_portworx" {
  count = var.provision ? 1 : 0

  depends_on = [
    local_file.portworx_operator_yaml,
    local_file.storage_classes_yaml,
    local_file.portworx_storagecluster_yaml
  ]

  triggers = {
    installer_workspace = local.installer_workspace
    kubeconfig          = var.cluster_config_file
    px_cluster_id       = local.px_cluster_id
    SUBSCRIPTION_ID = base64encode(var.azure_subscription_id)
    CLIENT_ID = var.azure_client_id
    CLIENT_SECRET = base64encode(var.azure_client_secret)
    TENANT = var.azure_tenant_id
    CLUSTER_TYPE = var.cluster_type
    BIN_DIR = module.setup_clis.bin_dir
  }
  provisioner "local-exec" {
    when        = create
    environment = {
      SUBSCRIPTION_ID = base64decode(self.triggers.SUBSCRIPTION_ID)
      CLIENT_ID = self.triggers.CLIENT_ID
      CLIENT_SECRET = base64decode(self.triggers.CLIENT_SECRET)
      TENANT = self.triggers.TENANT
      CLUSTER_TYPE = self.triggers.CLUSTER_TYPE
      BIN_DIR = self.triggers.BIN_DIR
      KUBECONFIG = self.triggers.kubeconfig
      INSTALLER_WORKSPACE = self.triggers.installer_workspace
    }
    command     = "${path.module}/scripts/install-portworx.sh"
  }

  provisioner "local-exec" {
    when = destroy

    interpreter = ["/bin/bash", "-c"]
    environment = {
      SUBSCRIPTION_ID = base64decode(self.triggers.SUBSCRIPTION_ID)
      CLIENT_ID = self.triggers.CLIENT_ID
      CLIENT_SECRET = base64decode(self.triggers.CLIENT_SECRET)
      TENANT = self.triggers.TENANT
      BIN_DIR = self.triggers.BIN_DIR
      KUBECONFIG = self.triggers.kubeconfig
    }
    command     = "${path.module}/scripts/uninstall-portworx.sh ${self.triggers.px_cluster_id}"
  }
}


resource "null_resource" "enable_portworx_encryption" {
  count = var.provision && var.enable_encryption ? 1 : 0
  triggers = {
    installer_workspace = local.installer_workspace
    bin_dir = module.setup_clis.bin_dir
    kubeconfig          = var.cluster_config_file
  }
  #todo: fix for both azure/aws
  provisioner "local-exec" {
    when    = create
    command = "${path.module}/scripts/enable-encryption.sh '${local.px_enterprise}'"

    environment = {
      BIN_DIR = self.triggers.bin_dir
      KUBECONFIG = self.triggers.kubeconfig
    }
  }
  depends_on = [
    null_resource.install_portworx,
  ]
}
