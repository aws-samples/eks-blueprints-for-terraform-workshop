---
title: AWS Cloud9 Setup
weight: 12
---


1. Open the Cloud9 service

**Your account is pre-configured with a Cloud9 instance.** Go to the [Cloud9 service](https://console.aws.amazon.com/cloud9control/home) select All account environments and click Open to access your **eks-terraform-blueprint-workshop** environment.

![](/static/images/cloud9-open.png)

::alert[If you do NOT see any environment, check if you have properly select **All account environments** and that you are using the same region recommended on the event page.]

During the initial setup, AWS Cloud9 creates an EC2 instance and connects the Cloud9 IDE to this newly created instance. 
Now we are going to work with the cloud9 Terminal which is already configured with necessary tools, But we need to confirm that we are using the correct IAM role:



1. Run the GetCallerIdentity command to confirm that Cloud9 IDE is using the **eks-blueprints-for-terraform-workshop-admin** we set as the IAM role for the Cloud9 instance

```bash
aws sts get-caller-identity --query Arn | grep eks-blueprints-for-terraform-workshop-admin -q && echo "IAM role valid" || echo "IAM role NOT valid"
```

If you are not in an AWS event, the previous command may return `IAM role NOT valid`. If this is the case try the following command:

  ```bash
  aws cloud9 update-environment  --environment-id $C9_PID --managed-credentials-action DISABLE
  sleep 10
  aws sts get-caller-identity --query Arn | grep eks-blueprints-for-terraform-workshop-admin -q && echo "IAM role valid" || echo "IAM role NOT valid"
  ```

This time you should have "IAM role valid", so we are OK to continue.



::::expand{header="Click here to see the list of tools and utilities that are boostrapped to your Cloud9 environment and the Event Engine AWS Accounts:"}

* kubectl =  The Kubernetes command-line tool, kubectl, allows you to run commands against Kubernetes clusters. You can use kubectl to deploy applications, inspect and manage cluster resources, and view logs. 
* helm =  Helm helps you manage Kubernetes applications — Helm Charts help you define, install, and upgrade even the most complex Kubernetes application. 
* kns = kns is a very small shellscript that utilizes fzf to switch between Kubernetes namespaces fast.
* kctx = kubectx is a tool to switch between contexts (clusters) on kubectl faster. A Kubernetes context is a group of access parameters that define which cluster you're interacting with, which user you're using, and which namespace you're working in. It's helpful if you need to access different clusters for different purposes or if you want to limit your access to certain parts of a cluster.
* AWS CLI version 2
* IAM role
* jq = JSON processor
* yq = YAML processor
* envsubst = The envsubst command is used to get a substitute of environment variables and that's what its name suggests.
* bash-completion = Bash completion is a bash function that allows you to auto complete commands or arguments by typing partially commands or arguments, then pressing the [Tab] key.
* c9 = Cloud9 CLI and tools (c9 open file.txt)
* [k9s](https://k9scli.io/) =  K9s is a terminal based UI to interact with your Kubernetes clusters. The aim of this project is to make it easier to navigate, observe and manage your deployed applications in the wild. K9s continually watches Kubernetes for changes and offers subsequent commands to interact with your observed resources. 
* [eks-node-viewer](https://github.com/awslabs/eks-node-viewer) = eks-node-viewer is a tool for visualizing dynamic node usage within a cluster. It was originally developed as an internal tool at AWS for demonstrating consolidation with Karpenter. It displays the scheduled pod resource requests vs the allocatable capacity on the node. It does not look at the actual pod resource usage.
* aliases (k, kgn, kgp, tfi, tfp, tfy) - type alias to see them


::::
