#!/usr/bin/env bash

set -e

BIN_DIR=$(cat .bin_dir)
export PATH="${BIN_DIR}:${PATH}"

export KUBECONFIG=$(cat .kubeconfig)
echo "sleeping to prevent synchronization errors"
sleep 3m

echo "checking for portworx services"


oc rollout status deployment/portworx-operator -n kube-system

#STORAGECLUSTER=$(kubectl get storagecluster -n kube-system -o=jsonpath='{.items[].metadata.name}' )
#oc rollout status storagecluster.core.libopenstorage.org/$STORAGECLUSTER -n kube-system

PX_POD=$(kubectl get pods -l name=portworx -n kube-system -o json | jq -r '.items[] | .metadata.name' | head -1)

if [[ -z "${PX_POD}" ]]; then
  echo "Portworx pod name not found" >&2
  exit 1
else
  echo "Portworx pod name: ${PX_POD}"
fi

kubectl exec "${PX_POD}" -n kube-system -- /opt/pwx/bin/pxctl status

exit 0
