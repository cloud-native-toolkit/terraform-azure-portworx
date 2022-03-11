#!/bin/bash

set -e

if [ -z "$CLIENT_ID" ]; then
      echo "\$CLIENT_ID is required"
      exit 1
fi
if [ -z "$CLIENT_SECRET" ]; then
      echo "\$CLIENT_SECRET is required"
      exit 1
fi
if [ -z "$TENANT" ]; then
      echo "\$TENANT is required"
      exit 1
fi
if [ -z "$SUBSCRIPTION_ID" ]; then
      echo "\$SUBSCRIPTION_ID is required"
      exit 1
fi
if [ -z "$RESOURCE_GROUP_NAME" ]; then
      echo "\$RESOURCE_GROUP_NAME is required"
      exit 1
fi
if [ -z "$CLUSTER_NAME" ]; then
      echo "\$CLUSTER_NAME is required"
      exit 1
fi

echo "CLUSTER_NAME: $CLUSTER_NAME"
echo "RESOURCE_GROUP_NAME: $RESOURCE_GROUP_NAME"

CREDENTIALS=""

az login --service-principal -u $CLIENT_ID -p $CLIENT_SECRET --tenant $TENANT
az account set --subscription $SUBSCRIPTION_ID

if [ "$CLUSTER_TYPE" = "ARO" ]; then
  echo "Preparing Portworx for ARO cluster"

  RESOURCE_GROUP_ID=$(az aro show --name $CLUSTER_NAME -g $RESOURCE_GROUP_NAME | jq -r '.clusterProfile.resourceGroupId')
echo "RESOURCE_GROUP_ID: $RESOURCE_GROUP_ID"
  RESOURCE_GROUP_ID=$(echo $RESOURCE_GROUP_ID | awk -F / '{print $NF}')
  APP_ID=$(az ad sp list --display-name $RESOURCE_GROUP_ID | jq -r '.[].appId')


echo "CLUSTER_NAME: $CLUSTER_NAME"
echo "RESOURCE_GROUP_NAME: $RESOURCE_GROUP_NAME"
echo "RESOURCE_GROUP_ID: $RESOURCE_GROUP_ID"
echo "APP_ID: $APP_ID"
  CREDENTIALS=$(az ad app credential reset --id $APP_ID --append)

else
  echo "Preparing Portworx for IPI cluster"

  ROLE_EXISTS=$(az role definition list -g $RESOURCE_GROUP_NAME -n "portworx-$CLUSTER_NAME")
  if [[ ${#ROLE_EXISTS} -gt 2 ]] ; then
    echo "Role portworx-$CLUSTER_NAME already exists"
  else
    echo "creating role portworx-$CLUSTER_NAME"
    ROLE=$(az role definition create --role-definition '{
            "Name": "portworx-role-'$CLUSTER_NAME'",
            "Description": "",
            "AssignableScopes": [
                "/subscriptions/'$SUBSCRIPTION_ID'"
            ],
            "Permissions": [
                {
                    "Actions": [
                        "Microsoft.ContainerService/managedClusters/agentPools/read",
                        "Microsoft.Compute/disks/delete",
                        "Microsoft.Compute/disks/write",
                        "Microsoft.Compute/disks/read",
                        "Microsoft.Compute/virtualMachines/write",
                        "Microsoft.Compute/virtualMachines/read",
                        "Microsoft.Compute/virtualMachineScaleSets/virtualMachines/write",
                        "Microsoft.Compute/virtualMachineScaleSets/virtualMachines/read"
                    ],
                    "NotActions": [],
                    "DataActions": [],
                    "NotDataActions": []
                }
            ]
    }')

    echo "creating service principal portworx-$CLUSTER_NAME"
    CREDENTIALS=$(az ad sp create-for-rbac --role=portworx-$CLUSTER_NAME --scopes="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME")
  fi

fi

if [ -z "CREDENTIALS" ]; then
      echo "\$CREDENTIALS were empty"
      exit 1
fi

TENANT=$(echo $CREDENTIALS | jq '.tenant')
APP_ID=$(echo $CREDENTIALS | jq '.appId')
PASS=$(echo $CREDENTIALS | jq '.password')

echo "creating kube secret"
kubectl create secret generic -n kube-system px-azure --from-literal=AZURE_TENANT_ID=$TENANT \
                                                      --from-literal=AZURE_CLIENT_ID=$APP_ID \
                                                      --from-literal=AZURE_CLIENT_SECRET=$PASS
