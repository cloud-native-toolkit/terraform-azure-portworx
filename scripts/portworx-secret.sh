
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
TENANT=$(echo $CREDENTIALS | jq '.tenant')
APP_ID=$(echo $CREDENTIALS | jq '.appId')
PASS=$(echo $CREDENTIALS | jq '.password')

echo "creating kube secret"
kubectl create secret generic -n kube-system px-azure --from-literal=AZURE_TENANT_ID=$TENANT \
                                                      --from-literal=AZURE_CLIENT_ID=$CLIENT_ID \
                                                      --from-literal=AZURE_CLIENT_SECRET=$CLIENT_SECRET
