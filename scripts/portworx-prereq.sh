#!/bin/bash

set -e

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

if [ "$CLUSTER_TYPE" = "ARO" ]; then
  echo "Preparing Portworx for ARO cluster"

  RESOURCE_GROUP_ID=$(az aro show --name $CLUSTER_NAME -g $RESOURCE_GROUP_NAME | jq -r '.clusterProfile.resourceGroupId')
  RESOURCE_GROUP_ID=$(echo $RESOURCE_GROUP_ID | awk -F / '{print $NF}')
  APP_ID=$(az ad sp list --display-name $RESOURCE_GROUP_ID | jq -r '.[].appId')
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

echo $CREDENTIALS