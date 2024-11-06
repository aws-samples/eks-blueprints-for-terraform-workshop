# EKS Blueprints for Terraform - Workshop

This is the repository for the [EKS Blueprints for Terraform Workshop](https://catalog.workshops.aws/eks-blueprints-terraform), which contains the workshop and associated assets.

This workshop helps you build a shared platform (Kubernetes multi-tenant) where multiple developer groups at an organization can consume and deploy workloads freely without the platform team being the bottleneck. We walk through the baseline setup of an EKS cluster, and gradually add add-ons to easily enhance its capabilities such as enabling Argo CD, Rollouts, GitOps and other common open-source add-ons. We then deploy a static website with proper SSL and domain via GitOps using Argo CD

It rely on [GitOps Bridge](https://github.com/gitops-bridge-dev/gitops-bridge) to provide a link between Terraform and Argo CD to bootstrap and configure your EKS clusters.

![](/static/images/gitops-bridge.png)

We will also walk through different architecture patterns like standalone 

![](/static/images/argocd-standalone.png)


or hub and spoke

![](/static/images/argocd-hub-spoke.jpg)


## CDK Bootstrap for environments

### What's Included

The CDK code will bootstrap the workshop on each custom AWS accounts provided by Workshop Studio. The CDK will deploy:

- This has VsCode + Gitea (see below on how to use) using CDK. To use VsCode check the Stack Output for public url (through Cloudfront) and password. For Gitea, see section below
- A codebuild that runs the terraform (currently using the RIV24 branch of the github repo)

### How to use in your account: Pre-requisites

- Follow the instructions : [Workshop Quick Start Template Getting Started](), you need to configure `.npmrc` with a gitlab token

- Taskfile (brew install go-task/tap/go-task)
- use node version v18
  ```bash
  nvm install lts/hydrogen
  nvm use lts/hydrogen
  ```
- Install direnv
  ```bash
  brew install direnv
  ```
  - You need to enable the hook by adding `eval "$(direnv hook bash)"` to your .bashrc or equivalent
  - See below for `.envrc` file content and allow command
- Install CDK
  ```bash
  task install
  ```
- Bootstrap CDK environment if first time
  ```bash
  task bootstrap
  ```
- Activate SecurityHub in your account
  ```bash
  aws securityhub enable-security-hub
  ```
- Install pre-commit 
  - `brew install pre-commit`
  - configure it
    ```bash
    git config --system --unset-all core.hookspath
    pre-commit install
    # If you use git defender make sure to re-enable it
    git defender --install
    ```

Create an `.envrc` file:
The `PARTICIPANT_ROLE_ARN` should have same permissions as specified in `contentspec.yaml` You can use your `Admin` role for testing

Example of `.envrc` file:

```bash
export PARTICIPANT_ROLE_ARN=arn:aws:iam::123456789123:role/demo3

export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

if [ -f $HOME/.nvm/nvm.sh ]; then
  type nvm >/dev/null 2>&1 || . $HOME/.nvm/nvm.sh
  nvm use lts/hydrogen
fi

# see below for advanced options configuration
#export FORCE_DELETE_VPC=true

#export WORKSHOP_GIT_URL=https://github.com/<githubusername>/fleet-management-on-amazon-eks-workshop
#export WORKSHOP_GIT_BRANCH=<your_pr_branch>
```

Be sure you activated `direnv` in your shell and that variables are existing:

Activate direnv in your shell

```bash
eval "$(direnv hook bash)"
#or
eval "$(direnv hook zsh)"
```

check it is working:

```bash
echo $PARTICIPANT_ROLE_ARN
```

Additional env variables you can set for debugging:
You can use your own fork and branch to deploy

```bash
export WORKSHOP_GIT_URL=https://github.com/<githubusername>/fleet-management-on-amazon-eks-workshop
export WORKSHOP_GIT_BRANCH=<your_pr_branch>
```

If you need the [special logic](https://github.com/aws-samples/fleet-management-on-amazon-eks-workshop/blob/riv24/terraform/common.sh#L79) to destroy vpc set the following environment variables:

```bash
export FORCE_DELETE_VPC=true
```

#### CDK Interactions

To Install

```bash
task deploy
```

To Destroy

```bash
task delete
```

### How to use for Workshop Studio Git Repo :

```bash
task assets
```

This will generate cloudformation in the path referenced by your contentspec.yaml. and push in the s3 buckets the version for on-your-own path

Then, you need to commit your files and you can push this directly to workshop studio git (see [Workshop Quick Start Template Getting Started]())).