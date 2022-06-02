#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

if [[ -n "${BIN_DIR}" ]]; then
  export PATH="${BIN_DIR}:${PATH}"
fi

if [[ -z "${INSTALLER_WORKSPACE}" ]]; then
  echo "INSTALLER_WORKSPACE must be provided as an environment variable" >&2
  exit 1
fi

"${SCRIPT_DIR}/portworx-secret.sh"

cat "${INSTALLER_WORKSPACE}/portworx_operator.yaml"
oc apply -f "${INSTALLER_WORKSPACE}/portworx_operator.yaml"

oc rollout status deployment.apps/portworx-operator -n kube-system

echo "Deploying StorageCluster"
oc apply -f "${INSTALLER_WORKSPACE}/portworx_storagecluster.yaml"
sleep 300
echo "Create storage classes"
oc apply -f "${INSTALLER_WORKSPACE}/storage_classes.yaml"
