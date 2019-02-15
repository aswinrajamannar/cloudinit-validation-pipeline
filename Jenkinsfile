#!groovy

// Written by Johnson Shi

JENKINS_AZURE_SERVICE_PRINCIPAL_ID = 'azure-service-principal-azblitz'

// These variables can be set before passing them to the packer template for packing.
// These variables *must* be passed to the scenario test scripts so
// that the scenario test scripts can test the packed image.
MANAGED_IMAGE_NAME = 'Unknown' // dummy var. this variable *must* be uniquely set for each pack because packer requires
                               // the image name to not exist in the resource group.
MANAGED_IMAGE_RESOURCE_GROUP_NAME = 'cloudinit-validation-packed-images-eastus2euap'
LOCATION = 'eastus2euap'

CLOUDINIT_GIT_URL = 'https://git.launchpad.net/~johnsonshi/cloud-init/'
CLOUDINIT_GIT_BRANCH = 'master'
// Why do we set a variable to the git hash of the
// checked out cloud-init repo, then pass the hash on
// to the packer script later? This is because developers
// may have updated the branch remotely in the meantime.
// Imagine packing Ubuntu 16.04 (and instructing the Ubuntu VM
// to clone cloud-init), then testing scenarios, then packing
// Ubuntu 18.04. By the time the Ubuntu 18.04 VM clones
// cloud-init (and if this git hash at this moment is not checked out)
// then Ubuntu 18.04 might clone newer commits down.
// This hash is intended so that all cloud-inits cloned within
// packed VMs are consistent.
CLOUDINIT_GIT_HASH = 'Unknown'
CLOUDINIT_VALIDATION_PACKER_TEMPLATES_GIT_URL = 'https://github.com/johnsonshi/cloudinit-validation-pipeline.git'
CLOUDINIT_VALIDATION_PACKER_TEMPLATES_GIT_BRANCH = 'master'

pipeline {
    agent {
        docker {
            image 'civdocker.azurecr.io/civdocker/civdocker:latest'
            args '-u root:root'
            registryUrl 'https://civdocker.azurecr.io'
            registryCredentialsId 'civdocker-credential'
        }
    }
    triggers { pollSCM 'H 0 * * *' }
    stages {
        stage('Checkout') {
            steps {
                dir('cloud-init') {
                    git url: "$CLOUDINIT_GIT_URL", branch: "$CLOUDINIT_GIT_BRANCH"
                    script {
                        cloudinit_git_hash = sh(
                            script: 'git rev-parse --verify HEAD',
                            returnStdout: true
                        ).trim()
                        if ("$cloudinit_git_hash" == 'Unknown') {
                            error('[!] Checkout: git hash of cloud-init repo not properly set')
                        }
                    }
                }
                dir('pipeline-code') {
                    git url: "${CLOUDINIT_VALIDATION_PACKER_TEMPLATES_GIT_URL}", branch: "${CLOUDINIT_VALIDATION_PACKER_TEMPLATES_GIT_BRANCH}"
                }
            }
        }
        stage('Pack RedHat 7.6 Image') {
            steps {
                withCredentials([azureServicePrincipal("$JENKINS_AZURE_SERVICE_PRINCIPAL_ID")]) {
                    script {
                        test = 'azlinux-dansol-rh76-release-test'
                        MANAGED_IMAGE_NAME = 'rh76_release_' + UUID.randomUUID().toString()
                        packer_template = "rh76_release_packer.json"
                    }
                    dir("pipeline-code/$test") {
                        sh """
                            packer validate \
                                -var 'managed_image_name=$MANAGED_IMAGE_NAME' \
                                -var 'managed_image_resource_group_name=$MANAGED_IMAGE_RESOURCE_GROUP_NAME' \
                                -var 'location=$LOCATION' \
                                -var 'cloudinit_git_url=$CLOUDINIT_GIT_URL' \
                                -var 'cloudinit_git_hash=$CLOUDINIT_GIT_HASH' \
                                -var 'client_id=$AZURE_CLIENT_ID' \
                                -var 'client_secret=$AZURE_CLIENT_SECRET' \
                                -var 'tenant_id=$AZURE_TENANT_ID' \
                                -var 'subscription_id=$AZURE_SUBSCRIPTION_ID' \
                                ${packer_template}
                        """
                        sh """
                            packer build \
                                -var 'managed_image_name=$MANAGED_IMAGE_NAME' \
                                -var 'managed_image_resource_group_name=$MANAGED_IMAGE_RESOURCE_GROUP_NAME' \
                                -var 'location=$LOCATION' \
                                -var 'cloudinit_git_url=$CLOUDINIT_GIT_URL' \
                                -var 'cloudinit_git_hash=$CLOUDINIT_GIT_HASH' \
                                -var 'client_id=$AZURE_CLIENT_ID' \
                                -var 'client_secret=$AZURE_CLIENT_SECRET' \
                                -var 'tenant_id=$AZURE_TENANT_ID' \
                                -var 'subscription_id=$AZURE_SUBSCRIPTION_ID' \
                                ${packer_template}
                        """
                    }
                }
            }
        }
        stage('Test Packed RedHat 7.6 Image') {
            steps {
                withCredentials([azureServicePrincipal("$JENKINS_AZURE_SERVICE_PRINCIPAL_ID")]) {
                    script {
                        test = 'azlinux-dansol-rh76-release-test'
                    }
                    dir("pipeline-code/$test") {
                        sh """
                            chmod +x test1.sh && \
                                ./test1.sh \
                                $MANAGED_IMAGE_NAME \
                                $MANAGED_IMAGE_RESOURCE_GROUP_NAME \
                                $LOCATION \
                                $AZURE_CLIENT_ID \
                                $AZURE_CLIENT_SECRET \
                                $AZURE_TENANT_ID \
                                $AZURE_SUBSCRIPTION_ID
                        """
                    }
                }
            }
        }
    }
}
