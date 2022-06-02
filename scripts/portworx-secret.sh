#!/usr/bin/env bash

if [[ -n "${BIN_DIR}" ]]; then
  export PATH="${BIN_DIR}:${PATH}"
fi

if [[ -z "$CLIENT_ID" ]]; then
      echo "\$CLIENT_ID is required"
      exit 1
fi
if [[ -z "$CLIENT_SECRET" ]]; then
      echo "\$CLIENT_SECRET is required"
      exit 1
fi
if [[ -z "$TENANT" ]]; then
      echo "\$TENANT is required"
      exit 1
fi


echo "creating kube secret"
kubectl delete secret generic -n kube-system px-azure --ignore-not-found=true
kubectl create secret generic -n kube-system px-azure --from-literal=AZURE_TENANT_ID=$TENANT \
                                                      --from-literal=AZURE_CLIENT_ID=$CLIENT_ID \
                                                      --from-literal=AZURE_CLIENT_SECRET=$CLIENT_SECRET
