#!/bin/bash


MANAGED_IMAGE_NAME=$1
MANAGED_IMAGE_RESOURCE_GROUP_NAME=$2
LOCATION=$3
TESTVM_NAME='test_vm_name'
TESTVM_USER='dummy'

echo $MANAGED_IMAGE_NAME

az vm create \
    --generate-ssh-keys \
    --admin-username $TESTVM_USER \
    --name $TESTVM_NAME \
    --image $MANAGED_IMAGE_NAME \
    --resource-group $MANAGED_IMAGE_RESOURCE_GROUP_NAME \
    --location $LOCATION
