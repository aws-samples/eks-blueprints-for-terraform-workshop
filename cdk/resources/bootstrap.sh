#!/bin/bash
set -x
sudo sh -c "echo LANG=en_US.utf-8 >> /etc/environment"
sudo sh -c "echo LC_ALL=en_US.UTF-8 >> /etc/environment"
# . /home/ec2-user/.bashrc
sudo yum -y install sqlite telnet jq strace tree gcc glibc-static python3 python3-pip gettext bash-completion npm zsh util-linux-user locate
echo '=== INSTALL and CONFIGURE default software components ==='

aws configure set cli_pager ""

export TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
export AWS_REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')
export ACCOUNTID=$(aws sts get-caller-identity | jq -r .Account)
export AWS_ACCOUNT_ID=$ACCOUNTID
export ACCOUNT_ID=$ACCOUNTID
export ASSETS_BUCKET_NAME=${AssetsBucketName} # Coming from Fn.Sub
export ASSETS_BUCKET_PREFIX=${AssetsBucketPrefix} # Coming from Fn.Sub
export BUCKET_NAME=${BUCKET_NAME} # Coming from Fn.Sub
export WORKSHOP_GIT_URL=${WORKSHOP_GIT_URL} # Coming from Fn.Sub
export WORKSHOP_GIT_BRANCH=${WORKSHOP_GIT_BRANCH} # Coming from Fn.Sub
export BASE_DIR=/home/ec2-user/eks-blueprints-for-terraform-workshop
export GITOPS_DIR=/home/ec2-user/environment/gitops-repos
export ENVIRONMENT_DIR=/home/ec2-user/environment
export GOROOT=/usr/local/go

# This is to go around problem with circular dependency
aws ssm put-parameter --type String --name EksBlueprintGiteaExternalUrl --value $GITEA_EXTERNAL_URL --overwrite

sudo bash -c "cat > /usr/local/bin/wait-for-lb" <<'EOT'
#!/bin/bash
set -e
export host=$1

if [ -z "$host" ]; then
  echo "the service is not found: $host"
  exit
fi

echo $host

set -Eeuo pipefail

echo "Waiting for $host..."

EXIT_CODE=0

timeout -s TERM 600 bash -c \
'while [[ "$(curl -s -o /dev/null -L -w ''%{http_code}'' http://$host/home)" != "200" ]];\
do sleep 5;\
done' || EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
echo "Load balancer did not become available or return HTTP 200 for 600 seconds"
exit 1
fi

echo "You can now access http://$host"
EOT
sudo chmod 755 /usr/local/bin/wait-for-lb
sudo bash -c "cat > /usr/local/bin/wait-for-lb-argocd" <<'EOT'
#!/bin/bash
set -e
export host=$1

if [ -z "$host" ]; then
echo "the service is not found: $host"
exit
fi

echo $host

set -Eeuo pipefail

echo "Waiting for $host..."

EXIT_CODE=0

timeout -s TERM 600 bash -c \
'while [[ "$(curl -s -k -o /dev/null -L -w ''%{http_code}'' http://$host/)" != "200" ]];\
do sleep 5;\
done' || EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
echo "Load balancer did not become available or return HTTP 200 for 600 seconds"
exit 1
fi

echo "You can now access http://$host"
EOT
sudo chmod 755 /usr/local/bin/wait-for-lb-argocd

sudo curl --silent --location -o /usr/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
sudo chmod +x /usr/bin/kubectl

sudo curl --silent --location -o /usr/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.12.2/argocd-linux-amd64
sudo chmod +x /usr/bin/argocd

sudo curl -Lo /usr/local/bin/kubectl-argo-rollouts https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
sudo chmod +x /usr/local/bin/kubectl-argo-rollouts

curl --silent --location "https://get.helm.sh/helm-v3.10.1-linux-amd64.tar.gz" | tar xz -C /tmp
sudo mv -f /tmp/linux-amd64/helm /usr/bin
sudo chmod +x /usr/bin/helm

sudo curl --silent --location -o /tmp/terraform.zip "https://releases.hashicorp.com/terraform/1.9.3/terraform_1.9.3_linux_amd64.zip"
cd /tmp && unzip -o /tmp/terraform.zip && cd -
chmod +x /tmp/terraform
sudo mv -f /tmp/terraform /usr/bin

sudo curl --silent --location "https://go.dev/dl/go1.23.1.linux-amd64.tar.gz" | sudo tar xz -C /usr/local

curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
chmod +x /tmp/eksctl
sudo mv /tmp/eksctl /usr/local/bin
curl -sSL "https://github.com/awslabs/eksdemo/releases/download/v0.12.0/eksdemo_Linux_x86_64.tar.gz" | tar xz -C /tmp
chmod +x /tmp/eksdemo
mv /tmp/eksdemo /usr/local/bin  



sudo su - ec2-user <<EOF
set -x
export | sort

aws configure set cli_pager ""

aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNTID.dkr.ecr.$AWS_REGION.amazonaws.com

# start of cloud9-init script
kubectl completion bash >>  ~/.bash_completion
echo "complete -F __start_kubectl k" >> ~/.bash_completion
argocd completion bash >>  ~/.bash_completion
helm completion bash >>  ~/.bash_completion
echo "alias k=kubectl" >> ~/.bashrc
echo "alias kgn='kubectl get nodes -L beta.kubernetes.io/arch -L eks.amazonaws.com/capacityType -L beta.kubernetes.io/instance-type -L eks.amazonaws.com/nodegroup -L topology.kubernetes.io/zone -L karpenter.sh/provisioner-name -L karpenter.sh/capacity-type'" | tee -a ~/.bashrc
echo "alias ll='ls -la'" >> ~/.bashrc

echo "alias ktx=kubectx" >> ~/.bashrc
echo "alias kctx=kubectx" >> ~/.bashrc
echo "alias kns=kubens" >> ~/.bashrc
echo "export TERM=xterm-color" >> ~/.bashrc

echo "alias code=/usr/lib/code-server/bin/code-server" >> ~/.bashrc
echo "complete -F __start_kubectl k" >> ~/.bashrc
curl -sS https://webinstall.dev/k9s | bash

helm repo add eks https://aws.github.io/eks-charts
helm repo update

#Install Krew and stern
(
  cd \$(mktemp -d) && pwd &&
  OS=\$(uname | tr '[:upper:]' '[:lower:]') &&
  ARCH=\$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/') &&
  KREW=krew-\${!OS}_\${!ARCH} && echo \$KREW
  curl -fsSLO https://github.com/kubernetes-sigs/krew/releases/latest/download/\${!KREW}.tar.gz &&
  tar zxvf \${!KREW}.tar.gz &&
  ./\${!KREW} install krew
)
echo "export PATH=${!KREW_ROOT:-/home/ec2-user/.krew}/bin:/home/ec2-user/.local/bin:/usr/local/go/bin:~/go/bin:$PATH" | tee -a ~/.bashrc
export PATH=${!KREW_ROOT:-/home/ec2-user/.krew}/bin:/home/ec2-user/.local/bin:/usr/local/go/bin:~/go/bin:$PATH
kubectl krew install stern
kubectl krew install np-viewer 

go install github.com/kyverno/chainsaw@latest
go install github.com/isovalent/aws-delete-vpc@latest

pip install pytest
pip install pytest_bdd boto3 kubernetes

curl -sfL https://direnv.net/install.sh | bash

#Try Install some VsCode plugins
/usr/lib/code-server/bin/code-server --install-extension hashicorp.terraform || true
/usr/lib/code-server/bin/code-server --install-extension moshfeu.compare-folders || true
/usr/lib/code-server/bin/code-server --install-extension amazonwebservices.amazon-q-vscode || true

#Install Amazon Q
curl --proto '=https' --tlsv1.2 -sSf "https://desktop-release.q.us-east-1.amazonaws.com/latest/q-x86_64-linux.zip" -o "/tmp/q.zip"
unzip /tmp/q.zip -d /tmp
/tmp/q/install.sh --no-confirm

#Install ag silver search
## Install build dependencies
sudo dnf install -y git gcc make pkg-config automake autoconf pcre-devel xz-devel zlib-devel
## Clone the repository, build and install from source
cd /tmp && git clone https://github.com/ggreer/the_silver_searcher.git && \
cd the_silver_searcher && \
./build.sh && \
sudo make install

#Install fuzzy search
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all  

#Install zsh
sudo -k chsh -s /bin/zsh ec2-user
jq '. + {"terminal.integrated.defaultProfile.linux": "zsh"}' /home/ec2-user/.local/share/code-server/User/settings.json > temp.json && mv temp.json /home/ec2-user/.local/share/code-server/User/settings.json
rm -rf ~/.oh-my-zsh

wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
CHSH=no RUNZSH=no sh install.sh

git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-history-substring-search ~/.oh-my-zsh/custom/plugins/zsh-history-substring-search


#Install workshop
mkdir -p $BASE_DIR
git clone $WORKSHOP_GIT_URL $BASE_DIR
cd $BASE_DIR
git checkout $WORKSHOP_GIT_BRANCH

cp hack/.zshrc hack/.p10k.zsh ~/

# Setup bashrc
ls -lt ~
mkdir -p ~/.bashrc.d
cp $BASE_DIR/hack/.bashrc.d/* ~/.bashrc.d/

# Common backend config
cat << EOT > $BASE_DIR/terraform/common/backend_override.tf
terraform {
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    key            = "common/terraform.tfstate"
    region         = "$AWS_REGION"
  }
}
EOT


# # Hub backend config
# cat << EOT > $BASE_DIR/terraform/hub/backend_override.tf
# terraform {
#   backend "s3" {
#     bucket         = "$BUCKET_NAME"
#     key            = "hub/terraform.tfstate"
#     region         = "$AWS_REGION"
#   }
# }
# EOT


# # Spokes backend config
# cat << EOT > $BASE_DIR/terraform/spokes/backend_override.tf
# terraform {
#   backend "s3" {
#     bucket         = "$BUCKET_NAME"
#     key            = "spokes/terraform.tfstate"
#     region         = "$AWS_REGION"
#     workspace_key_prefix = "spokes"
#   }
# }
# EOT


EOF

#install kubectx & kubens
sudo rm -rf /opt/kubectx
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -sf /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -sf /opt/kubectx/kubens /usr/local/bin/kubens


sudo curl -L https://github.com/awslabs/eks-node-viewer/releases/download/v0.7.0/eks-node-viewer_Linux_x86_64 -o /usr/local/bin/eks-node-viewer  && sudo chmod +x $_

source ~/.bashrc

# end of cloud9-init script

echo '=== Configure .bashrc.d ==='
if [[ ! -d "/home/ec2-user/.bashrc.d" ]]; then
    sudo -H -u ec2-user bash -c "mkdir -p ~/.bashrc.d"
fi
cat << EOT > /home/ec2-user/.bashrc.d/env.bash
export ACCOUNTID=$ACCOUNTID
export ACCOUNT_ID=$ACCOUNTID
export AWS_ACCOUNT_ID=$ACCOUNTID
export AWS_DEFAULT_REGION=$AWS_REGION
export GOROOT=/usr/local/go
export ASSETS_BUCKET_NAME=$ASSETS_BUCKET_NAME
export ASSETS_BUCKET_PREFIX=$ASSETS_BUCKET_PREFIX
export BUCKET_NAME=$BUCKET_NAME
export WORKSHOP_GIT_URL=$WORKSHOP_GIT_URL
export WORKSHOP_GIT_BRANCH=$WORKSHOP_GIT_BRANCH
export BASE_DIR=$BASE_DIR
export GITOPS_DIR=$GITOPS_DIR
EOT

sudo -H -u ec2-user bash -c "cat <<'EOF' >> ~/.bashrc 
for file in ~/.bashrc.d/*.bash; do
  source "\$file" || true
done
EOF
"

echo '=== CONFIGURE awscli and setting ENVIRONMENT VARS ==='
echo "complete -C '/usr/local/bin/aws_completer' aws" >> /home/ec2-user/.bashrc.d/aws.bash
echo '=== Run init script ==='
# aws s3 cp s3://${AssetsBucketName}/${AssetsBucketPrefix}cloud9-init.sh /tmp && bash /tmp/cloud9-init.sh
echo '=== CLEANING /home/ec2-user ==='
# for f in cloud9; do rm -rf /home/ec2-user/$f; done # cloud9 doesn't exists
chown -R ec2-user:ec2-user /home/ec2-user/
#Don't reboot in ssm document, that break the execution
echo "Bootstrap completed with return code $?"