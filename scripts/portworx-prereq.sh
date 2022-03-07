#!/bin/bash

set -e

az login --service-principal -u $CLIENT_ID -p $CLIENT_SECRET --tenant $TENANT

az account set -–subscription $SUBSCRIPTION_ID

ROLE=$(az role definition create --role-definition '{
        "Name": "portworx-'$CLUSTER_NAME'",
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


SP=$(az ad sp create-for-rbac --role=portworx-$CLUSTER_NAME --scopes="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME")

TENANT=$(echo $SP | jq '.tenant')
APP_ID=$(echo $SP | jq '.appId')
PASS=$(echo $SP | jq '.password')

kubectl create secret generic -n kube-system px-azure --from-literal=AZURE_TENANT_ID=$TENANT \
                                                      --from-literal=AZURE_CLIENT_ID=$APP_ID \
                                                      --from-literal=AZURE_CLIENT_SECRET=$PASS