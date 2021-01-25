#!/bin/bash
set -e

cd ../../../docker

az login --service-principal --username "$ARM_CLIENT_ID" --password "$ARM_CLIENT_SECRET" --tenant "microsoft.onmicrosoft.com"

while true;
do
  echo "checking for acr..."
  sleep 1
  created=$(az acr check-name -n $acr_name --query [nameAvailable] --output tsv)
  [[ $created == 'false' ]] && break
done

az configure --defaults acr=$acr_name
az acr build -t "aci-devops-agent:0.2-linux" linux  >> acr.txt