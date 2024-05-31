# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

#!/bin/bash

set -e
####################
##  Tools Install ##
####################

# reset yum history
sudo yum history new

# Install jq (json query)
sudo yum -y -q install jq

# Install yq (yaml query)
echo 'yq() {
  docker run --rm -i -v "${PWD}":/workdir mikefarah/yq "$@"
}' | tee -a ~/.bashrc && source ~/.bashrc

# Install other utils:
#   gettext: a framework to help other GNU packages product multi-language support. Part of GNU Translation Project.
#   bash-completion: supports command name auto-completion for supported commands
#   moreutils: a growing collection of the unix tools that nobody thought to write long ago when unix was young
sudo yum -y install gettext bash-completion moreutils

# Update awscli v1, just in case it's required
pip install --user --upgrade awscli

# Install awscli v2
curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'
unzip awscliv2.zip -d /tmp
sudo /tmp/aws/install --update
rm -rf aws awscliv2.zip

# Install kubectl
sudo curl --silent --location -o /usr/local/bin/kubectl \
   https://amazon-eks.s3.us-west-2.amazonaws.com/1.24.7/2022-10-31/bin/linux/amd64/kubectl
sudo chmod +x /usr/local/bin/kubectl


# populate kubectl bash-completion
echo "source <(kubectl completion bash)" >> ~/.bash_completion
#make completio works with k alias
echo "complete -F __start_kubectl k" >> ~/.bashrc

echo ". /etc/profile.d/bash_completion.sh" >> ~/.bashrc
echo ". ~/.bash_completion" >> ~/.bashrc

# Install eksctl and move to path
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Install helm
curl -sSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Install Argo Rollout
sudo curl -Lo /usr/local/bin/kubectl-argo-rollouts https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
sudo chmod +x /usr/local/bin/kubectl-argo-rollouts

# Install Terraform
#sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
#sudo yum -y install terraform

#####################
##  Set Variables  ##
#####################

# Set AWS region in env and awscli config
AWS_REGION=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bash_profile

cat << EOF > ~/.aws/config
[default]
region = ${AWS_REGION}
output = json
EOF

# Set accountID
ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bash_profile

# install c9
npm i -g c9

# install k9s
curl -sS https://webinstall.dev/k9s | bash

#Install eks-node-viewer
sudo curl -L https://github.com/awslabs/eks-node-viewer/releases/download/v0.2.1/eks-node-viewer_Linux_x86_64 -o /usr/local/bin/eks-node-viewer  && sudo chmod +x $_

echo "export TERM=xterm-color" >> ~/.bashrc
echo "PATH=$PATH:~/go/bin/" >> ~/.bashrc

# enable some aliases
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all
sudo curl https://raw.githubusercontent.com/blendle/kns/master/bin/kns -o /usr/local/bin/kns && sudo chmod +x $_
sudo curl https://raw.githubusercontent.com/blendle/kns/master/bin/ktx -o /usr/local/bin/ktx && sudo chmod +x $_
echo "alias kgn='kubectl get nodes -L beta.kubernetes.io/arch -L eks.amazonaws.com/capacityType -L beta.kubernetes.io/instance-type -L eks.amazonaws.com/nodegroup -L topology.kubernetes.io/zone -L karpenter.sh/provisioner-name -L karpenter.sh/capacity-type'" | tee -a ~/.bashrc
echo "alias k=kubectl" | tee -a ~/.bashrc
echo "alias kgp='kubectl get pods'" | tee -a ~/.bashrc
echo "alias tfi='terraform init'" | tee -a ~/.bashrc
echo "alias tfp='terraform plan'" | tee -a ~/.bashrc
echo "alias tfy='terraform apply --auto-approve'" | tee -a ~/.bashrc
source ~/.bashrc


aws cloud9 update-environment  --environment-id $C9_PID --managed-credentials-action DISABLE
rm -vf ${HOME}/.aws/credentials