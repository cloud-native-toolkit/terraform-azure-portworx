#!/usr/bin/env bash

INPUT=$(tee)

BIN_DIR=$(echo "${INPUT}" | grep "bin_dir" | sed -E 's/.*"bin_dir": ?"([^"]+)".*/\1/g')

export PATH="${BIN_DIR}:${PATH}"

if ! command -v jq 1> /dev/null 2> /dev/null; then
  echo "jq cli not found" >&2
  exit 1
fi

if ! command -v yq4 1> /dev/null 2> /dev/null; then
  echo "yq4 cli not found" >&2
  exit 1
fi

PORTWORX_CONFIG=$(echo "${INPUT}" | jq -r '.portworx_spec | @base64d')

if [[ -z "${PORTWORX_CONFIG}" ]]; then
  echo "portworx_spec has not been set" >&2
  exit 1
fi

CLUSTER_ID=$(echo "${PORTWORX_CONFIG}" | yq4 'select(documentIndex == 0) | .metadata.name')
SECRET_NAME=$(echo "${PORTWORX_CONFIG}" | yq4 'select(documentIndex == 1) | .metadata.name')
USER_ID=$(echo "${PORTWORX_CONFIG}" | yq4 'select(documentIndex == 1) | .data.px-essen-user-id')
OSB_ENDPOINT=$(echo "${PORTWORX_CONFIG}" | yq4 'select(documentIndex == 1) | .data.px-osb-endpoint')

if [[ "${SECRET_NAME}" =~ "essential" ]]; then
  TYPE="essentials"
else
  TYPE="enterprise"
fi

if [[ -z "${CLUSTER_ID}" ]]; then
  echo "CLUSTER_ID not found" >&2
  echo "Portworx config: ${PORTWORX_CONFIG}" >&2
  exit 1
fi

jq -n \
  --arg TYPE "${TYPE}" \
  --arg CLUSTER_ID "${CLUSTER_ID}" \
  --arg USER_ID "${USER_ID}" \
  --arg OSB_ENDPOINT "${OSB_ENDPOINT}" \
  '{"type": $TYPE, "cluster_id": $CLUSTER_ID, "user_id": $USER_ID, "osb_endpoint": $OSB_ENDPOINT}'
