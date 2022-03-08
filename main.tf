#resource "aws_kms_key" "px_key" {
#  count       = var.cloud_provider == "aws" ? 1:0
#  description = "Key used to encrypt Portworx PVCs"
#}

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
    region              = var.region
    kubeconfig          = var.cluster_config_file
    px_cluster_id       = local.px_cluster_id
    SUBSCRIPTION_ID = base64encode(var.azure_subscription_id)
    CLUSTER_NAME = var.cluster_name
    RESOURCE_GROUP_NAME = var.resource_group_name
    CLIENT_ID = var.azure_client_id
    CLIENT_SECRET = base64encode(var.azure_client_secret)
    TENANT = var.azure_tenant_id
  }
  provisioner "local-exec" {
    working_dir = "${path.module}/scripts/"
    when        = create
    environment = {
      SUBSCRIPTION_ID = base64decode(self.triggers.SUBSCRIPTION_ID)
      CLUSTER_NAME = self.triggers.CLUSTER_NAME
      RESOURCE_GROUP_NAME = self.triggers.RESOURCE_GROUP_NAME
      CLIENT_ID = self.triggers.CLIENT_ID
      CLIENT_SECRET = base64decode(self.triggers.CLIENT_SECRET)
      TENANT = self.triggers.TENANT
    }
    command     = <<EOF

echo '${var.cluster_config_file}' > .kubeconfig
export KUBECONFIG=${var.cluster_config_file}:$KUBECONFIG

pwd
chmod +x portworx-prereq.sh
bash portworx-prereq.sh ${self.triggers.region} || { echo 'portworx-prereq.sh failed' ; exit 1; }

cat ${self.triggers.installer_workspace}/portworx_operator.yaml
oc apply -f ${self.triggers.installer_workspace}/portworx_operator.yaml
echo "Sleeping for 5mins"
sleep 300
echo "Deploying StorageCluster"
oc apply -f ${self.triggers.installer_workspace}/portworx_storagecluster.yaml
sleep 300
echo "Create storage classes"
oc apply -f ${self.triggers.installer_workspace}/storage_classes.yaml
EOF
  }

  provisioner "local-exec" {
    when = destroy

    interpreter = ["/bin/bash", "-c"]
    environment = {
      SUBSCRIPTION_ID = base64decode(self.triggers.SUBSCRIPTION_ID)
      CLUSTER_NAME = self.triggers.CLUSTER_NAME
      RESOURCE_GROUP_NAME = self.triggers.RESOURCE_GROUP_NAME
      CLIENT_ID = self.triggers.CLIENT_ID
      CLIENT_SECRET = base64decode(self.triggers.CLIENT_SECRET)
      TENANT = self.triggers.TENANT
    }
    command     = <<EOF
echo '${self.triggers.kubeconfig}' > .kubeconfig

#kubectl label daemonset/portworx-api name=portworx-api -
#│ n kube-system
#
curl -fsL https://install.portworx.com/px-wipe | bash -s -- -f

#todo: delete azure role definition, service principle

kubectl delete storagecluster ${self.triggers.px_cluster_id} -n kube-system

while kubectl get storagecluster ${self.triggers.px_cluster_id} -n kube-system; do
  echo "waiting for storagecluster to destroy"
  sleep 15s
done
echo "storagecluster destroyed"


kubectl delete secret px-essential -n kube-system

kubectl delete deployment portworx-operator -n kube-system
kubectl delete ClusterRoleBinding portworx-operator -n kube-system
kubectl delete ClusterRole portworx-operator -n kube-system
kubectl delete PodSecurityPolicy portworx-operator -n kube-system
kubectl delete ServiceAccount portworx-operator -n kube-system
kubectl delete Secret px-azure -n kube-system

kubectl get sc | grep portworx | awk '{print $1}' | while read -r SC; do
  kubectl delete storageclass $SC
done

EOF
  }
}


resource "null_resource" "enable_portworx_encryption" {
  count = var.provision && local.px_enterprise && var.portworx_config.enable_encryption ? 1 : 0
  triggers = {
    installer_workspace = local.installer_workspace
    region              = var.region
  }
  #todo: fix for both azure/aws
  provisioner "local-exec" {
    when    = create
    command = <<EOF
echo "Enabling encryption"
PX_POD=$(oc get pods -l name=portworx -n kube-system -o jsonpath='{.items[0].metadata.name}')
oc exec $PX_POD -n kube-system -- /opt/pwx/bin/pxctl secrets aws login
EOF
  }
  depends_on = [
    null_resource.install_portworx,
  ]
}

locals {
  px_enterprise       = var.portworx_config.type == "enterprise"
  rootpath            = abspath(path.root)
  installer_workspace = "${local.rootpath}/installer-files"
  px_cluster_id       = var.portworx_config.cluster_id
  priv_image_registry = "image-registry.openshift-image-registry.svc:5000/kube-system"

  #todo: fix for azure + aws
  #secret_provider     = var.provision && local.px_enterprise && var.portworx_config.enable_encryption ? "aws-kms" : "k8s"
  secret_provider     = "k8s"
  px_workspace        = "${local.installer_workspace}/ibm-px"
}
