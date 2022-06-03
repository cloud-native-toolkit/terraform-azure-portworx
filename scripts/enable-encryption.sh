#!/usr/bin/env bash

ENTERPRISE="$1"

if [[ -n "${BIN_DIR}" ]]; then
  export PATH="${BIN_DIR}:${PATH}"
fi

if [[ "${ENTERPRISE}" != "true" ]]; then
  echo "Encryption not available for Portworx Essentials"
  exit 0
fi

echo "Enabling encryption"
PX_POD=$(oc get pods -l name=portworx -n kube-system -o jsonpath='{.items[0].metadata.name}')
oc exec $PX_POD -n kube-system -- /opt/pwx/bin/pxctl secrets aws login
