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
    triggers {
        pollSCM 'H 0 * * *'
    }
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
        stage('Unit & Style Tests') {
            steps {
                dir('cloud-init') {
                    // unit tests have issues if the locale isn't set properly
                    sh 'export LC_ALL="en_US.UTF-8"'
                    sh 'export LC_CTYPE="en_US.UTF-8"'
                    sh 'export LANG="en_US.UTF-8"'
                    sh 'export LANGUAGE="en_US.UTF-8"'
                    sh 'export LC_CTYPE="en_US.UTF-8"'
                    // make test cache available to the jenkins user,
                    // which sometimes does not exist,
                    // hence the "|| true" part of the command
                    sh 'chmod -R 777 ./.tox || true'
                    sh 'chmod -R 777 . || true'
                    // Running docker slave as root, then running unit
                    // and style tests as user jenkins is needed because:
                    //      1. If Docker slave workload is run without
                    //          specifying the user (user that workload is run as),
                    //          Docker slave with a default Unix system account,
                    //          which means a Unix account with no homedir.
                    //          Line of code within tox that will cause problems:
                    //              "pwd.getpwuid(os.getuid()).pw_dir"
                    //          because Unix system account created has no homedir,
                    //          the created user has no homedir in the /etc/passwd.
                    //          Look up the docs of each of the above python commands.
                    //      2. Running Docker slave workload with root user specified
                    //          (args -u root:root) causes unit tests to fail because
                    //          of an error "No such file or directory: 'ud'".
                    //          This has been reproduced in several vanilla cloud-init
                    //          repos and vanilla systems. Running unit tests as root
                    //          causes tests to fail as tests aren't OK with root-env.
                    //      3. Running Docker slave workload with a specified
                    //          pre-created jenkins user causes permission denied issues
                    //          when writing to the Jenkins log file within the
                    //          slave container.
                    //      4. Solution: Run Docker slave workload as root,
                    //          but run the unit tests with the pre-created jenkins
                    //          user using the command "su".
                    sh 'su jenkins -c "tox"'
                }
            }
        }
        stage('Pack RedHat 7.6 Image') {
            steps {
                withCredentials([azureServicePrincipal("$JENKINS_AZURE_SERVICE_PRINCIPAL_ID")]) {
                    script {
                        test = 'azlinux-dansol-rh76-release-test'
                        // MANAGED_IMAGE_NAME = 'rh76_release_' + UUID.randomUUID().toString()
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
