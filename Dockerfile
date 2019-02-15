# This is a sample Dockerfile with a couple of problems.
# Paste your Dockerfile here.

FROM ubuntu:16.04
RUN apt update && \
    apt install -y tox wget curl unzip git python python3 python-pip python3-pip locales jq && \
    # reconfigure locales
    locale-gen en_US && \
    locale-gen en_US.UTF-8 && \
    # add the jenkins group and user
    groupadd -r jenkins && \
    useradd -m -g jenkins jenkins && \
    cd /tmp && \
    # install packer
    # change the link to newer packer versions if you wish
    wget https://releases.hashicorp.com/packer/1.3.4/packer_1.3.4_linux_amd64.zip && \
    unzip packer*.zip && \
    mv packer /usr/bin/ && \
    rm -rf packer*.zip && \
    # install the azure cli https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest
    # Note: within the docker image, there is no sudo, so run the commands without sudo (since you are root anyways)
    apt install -y apt-transport-https lsb-release software-properties-common dirmngr && \
    AZ_REPO=$(lsb_release -cs) && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list && \
    # Note: the keys may have been updated by Microsoft since then
    apt-key --keyring /etc/apt/trusted.gpg.d/Microsoft.gpg adv --keyserver packages.microsoft.com --recv-keys BC528686B50D79E339D3721CEB3E94ADBE1229CF && \
    apt update && \
    apt install azure-cli
