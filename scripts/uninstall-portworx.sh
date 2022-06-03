#!/usr/bin/env bash

if [[ -n "${BIN_DIR}" ]]; then
  export PATH="${BIN_DIR}:${PATH}"
fi

CLUSTER_ID="$1"

#kubectl label daemonset/portworx-api name=portworx-api -
#│ n kube-system
#
curl -fsL https://install.portworx.com/px-wipe | bash -s -- -f

#todo: delete azure role definition, service principle

kubectl delete storagecluster "${CLUSTER_ID}" -n kube-system

while kubectl get storagecluster "${CLUSTER_ID}" -n kube-system; do
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

