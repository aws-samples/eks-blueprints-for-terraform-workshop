---
title: '...at an AWS event'
chapter: false
weight: 10
---

## Running the workshop at an AWS Event

::alert[If you are not currently participating in an AWS organized workshop event, this section does not apply to you. Please skip to setup [..on your own](../self_paced).]{header="Important" type="warning"}

To complete this workshop, you are provided with an AWS account via AWS Workshop Studio and a link to that will be shared by our event staff. AWS Workshop Studio allows AWS field teams to run Workshops, GameDays, Bootcamps, Immersion Days, and other events that require hands-on access to AWS accounts.

::alert[If you are currently logged in to an AWS Account, you can logout using this [link](https://console.aws.amazon.com/console/logout!doLogout).]{header="Important" type="warning"}

### Access AWS Workshop Studio

1 . [Click here](https://catalog.us-east-1.prod.workshops.aws/join/) to access AWS Workshop Studio

2 . Choose your preferred sign-in method as follows. For AWS Guided events, use **Email OTP** method.

![Workshop Studio Signin](/static/images/setup_ws_signin1.png)

3 . Enter the code provided by the event organizer, in the text box. You will usually find this code on a slide that is being shown, or a paper printout at your table.

![Workshop Studio Signin Event Code](/static/images/setup_ws_signin2.png)

4. Read and agree to the Terms and Conditions and click Join Event

![Workshop Studio Signin Terms](/static/images/setup_ws_signin3.png)

5. Join the event, and you will be taken to the workshop instructions. You can access the console of your personal AWS account for the event by clicking the link in the sidebar.

![Workshop Studio Signin Landing Page](/static/images/setup_ws_signin4.png)

::alert[Please stick to the region you see on the event page throughout your workshop.]{header="Important" type="info"}

6 . **Your account should be pre-configured with your Cloud9.** Follow this [link](https://console.aws.amazon.com/cloud9/home) to access your **eks-blueprints-for-terraform-workshop** Cloud9 environment, and Open the IDE.

![Cloud9 IDE](/static/images/c9-open-ide.png)

::alert[If you done see an environment, check if you are using the same region recommended on the event page.]

Verify your AWS identity:

```bash
aws sts get-caller-identity
```

You should have something similar to

```
{
    "UserId": "AROA6NAAL5J5H22JSBCPA:i-09e1d15b60696663c",
    "Account": "0123456789",
    "Arn": "arn:aws:sts::0123456789:assumed-role/eks-blueprints-for-terraform-workshop-admin/i-09e1d15b60696663c"
}
```

::alert[If you don't see **eks-blueprints-for-terraform-workshop-admin** in the output, just try type **bash** in the terminal to reload the environment]

Used this command to verify you are good to go:

```bash
aws sts get-caller-identity --query Arn | grep eks-blueprints-for-terraform-workshop-admin -q && echo "IAM role valid" || echo "IAM role NOT valid"
```

If the IAM role is not valid, <span style="color: red;">**DO NOT PROCEED**</span>. Go back and confirm the steps on this page.

or try : 

```bash
aws cloud9 update-environment  --environment-id $C9_PID --managed-credentials-action DISABLE
aws sts get-caller-identity --query Arn | grep eks-blueprints-for-terraform-workshop-admin -q && echo "IAM role valid" || echo "IAM role NOT valid"
```


::alert[When ready, go to EKS]{type="info"}

:button[Creating EKS Blueprint]{variant="primary" href="/030-provision-eks-cluster/"}

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
