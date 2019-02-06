#!groovy

pipeline {
    agent {
        docker {
            image 'civdocker.azurecr.io/civdocker/civdocker:latest'
            args '-u root:root'
            registryUrl 'https://civdocker.azurecr.io'
            registryCredentialsId 'civdocker-credential'
        }
    }
    environment {
        CLOUDINIT_GIT_URL = 'https://git.launchpad.net/~johnsonshi/cloud-init/'
        CLOUDINIT_GIT_BRANCH = 'master'
        CLOUDINIT_VALIDATION_PACKER_TEMPLATES_GIT_URL = 'https://github.com/johnsonshi/cloudinit-validation-pipeline.git'
        CLOUDINIT_VALIDATION_PACKER_TEMPLATES_GIT_BRANCH = 'master'
    }
    triggers {
        pollSCM 'H/2 * * * *'
    }
    stages {
        stage('Setup & Checkout') {
            steps {
                // unit tests have issues if the locale isn't set properly
                sh 'export LC_ALL="en_US.UTF-8"'
                sh 'export LC_CTYPE="en_US.UTF-8"'
                sh 'export LANG="en_US.UTF-8"'
                sh 'export LANGUAGE="en_US.UTF-8"'
                sh 'export LC_CTYPE="en_US.UTF-8"'
                sh 'export LC_NUMERIC="en_US.UTF-8"'
                sh 'export LC_TIME="en_US.UTF-8"'
                sh 'export LC_COLLATE="en_US.UTF-8"'
                sh 'export LC_MONETARY="en_US.UTF-8"'
                sh 'export LC_MESSAGES="en_US.UTF-8"'
                sh 'export LC_PAPER="en_US.UTF-8"'
                sh 'export LC_NAME="en_US.UTF-8"'
                sh 'export LC_ADDRESS="en_US.UTF-8"'
                sh 'export LC_TELEPHONE="en_US.UTF-8"'
                sh 'export LC_MEASUREMENT="en_US.UTF-8"'
                sh 'export LC_IDENTIFICATION="en_US.UTF-8"'
                dir('unittests') {
                    git url: "${CLOUDINIT_GIT_URL}", branch: "${CLOUDINIT_GIT_BRANCH}"
                    // Why do we set the git hash here, then pass the hash on
                    // to the packer script later? This is because developers
                    // may have updated the branch remotely in the meantime,
                    // imagine packing Ubuntu 16.04 (and instructing the Ubuntu VM
                    // to clone cloud-init), then testing scenarios, then packing
                    // Ubuntu 18.04. By the time the Ubuntu 18.04 VM clones
                    // cloud-init (and if this git hash at this moment is not checked out)
                    // then Ubuntu 18.04 might clone newer commits down.
                    // This hash is intended so that all cloud-inits cloned within
                    // packed VMs are consistent.
                    sh 'export CLOUDINIT_GIT_HASH=$(git rev-parse --verify HEAD)'
                }
                dir('pipeline-code') {
                    git url: "${CLOUDINIT_VALIDATION_PACKER_TEMPLATES_GIT_URL}", branch: "${CLOUDINIT_VALIDATION_PACKER_TEMPLATES_GIT_BRANCH}"
                }
            }
        }
        stage('Unit & Style Tests') {
            steps {
                dir('unittests') {
                    sh 'rm -rf ./.tox || true'
                    // make test cache (which sometimes does not exist,
                    // hence the "|| true" part of the command).
                    // available to the jenkins user.
                    sh 'chmod -R 777 ./.tox || true'
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
                    // sh 'su jenkins -c "tox --notest"'
                }
            }
        }
        stage('Pack OpenLogic CentOS 6.8 on Azure') {
            steps {
                dir('pipeline-code') {
                    withCredentials([azureServicePrincipal('azure-service-principal-azblitz')]) {
                        sh 'packer validate -var "cloudinit_git_url=$CLOUDINIT_GIT_URL" -var "cloudinit_git_hash=$CLOUDINIT_GIT_HASH" -var "client_id=$AZURE_CLIENT_ID" -var "client_secret=$AZURE_CLIENT_SECRET" -var "tenant_id=$AZURE_TENANT_ID" -var "subscription_id=$AZURE_SUBSCRIPTION_ID" ./packer-templates/openlogic-centos-6.8.json'
                        sh 'packer build -var "cloudinit_git_url=$CLOUDINIT_GIT_URL" -var "cloudinit_git_hash=$CLOUDINIT_GIT_HASH" -var "client_id=$AZURE_CLIENT_ID" -var "client_secret=$AZURE_CLIENT_SECRET" -var "tenant_id=$AZURE_TENANT_ID" -var "subscription_id=$AZURE_SUBSCRIPTION_ID" ./packer-templates/openlogic-centos-6.8.json'
                    }
                }
            }
        }
    }
}
