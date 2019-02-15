#!/bin/bash


MANAGED_IMAGE_NAME=$1
MANAGED_IMAGE_RESOURCE_GROUP_NAME=$2
LOCATION=$3

AZURE_CLIENT_ID=$4
AZURE_CLIENT_SECRET=$5
AZURE_TENANT_ID=$6
AZURE_SUBSCRIPTION_ID=$7

TESTVM_NAME="civtest-$(cat /proc/sys/kernel/random/uuid)"
TESTVM_USER='dummy'

az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID --subscription $AZURE_SUBSCRIPTION_ID

az vm create \
    --generate-ssh-keys \
    --admin-username $TESTVM_USER \
    --name $TESTVM_NAME \
    --image $MANAGED_IMAGE_NAME \
    --resource-group $MANAGED_IMAGE_RESOURCE_GROUP_NAME \
    --location $LOCATION
