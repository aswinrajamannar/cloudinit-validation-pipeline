# This is a test scenario.
# Before this script is run by Jenkins, several env variables are set.
# After this script terminates, the env variables (which may contain
# sensitive information) are unset by Jenkins's withEnv method and
# Jenkin's Azure Credentials Plugin.

# subscription id env variable:
# $AZURE_TENANT_ID
# service principal-related env variables:
# $AZURE_CLIENT_ID, $AZURE_CLIENT_SECRET, $AZURE_TENANT_ID

# The az cli is already authenticated because this script
# should be invoked from within a block of withCredentials([azureServicePrincipal('credentials_id')]).
# When this script is invoked from within the withCredentials block,
# the CLI is already authenticated, and the env variables for the
# subscription and service principal are already set.
# see https://wiki.jenkins.io/display/JENKINS/Azure+Credentials+plugin

# Jenkins can also set other env variables to be used by these scripts,
# such as an env var for the created managed_image_name, the
# resource group of the created managed_image, the location, etc.

# This script can then test a deployment of the packed managed_image.
# After a VM is created, there are multiple creative ways to test the VM,
# such as:

# testing echo within VM
ssh $created_vm "echo 'hello from within VM'; echo 'hello from within VM'"

# testing writing and reading of files within VM
ssh $created_vm "echo 'hello' > file; cat file"

# the script should then clean up the VM.
