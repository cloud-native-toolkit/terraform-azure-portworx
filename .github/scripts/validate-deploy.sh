#!/usr/bin/env bash

set -e

export KUBECONFIG=$(cat .kubeconfig)
echo "sleeping for 2 mins to prevent synchronization errors"
sleep 2m

echo "checking for portworx services"


oc rollout status deployment/portworx-operator -n kube-system
STORAGECLUSTER=$(kubectl get storagecluster -n kube-system -o=jsonpath='{.items[].metadata.name}' )
oc rollout status storagecluster/$STORAGECLUSTER -n kube-system

exit 0
