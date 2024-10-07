---
title: Accessing the IDE
weight: 12
---

### Access AWS Workshop IDE

You can find the elements to get a quick-start link to your Cloud IDE and its associated password either in the personal dashboard page, where you can scroll down to the Event Outputs section, or from the CloudFormation stack output. Open this in a new browser tab.

![Event Output](/static/images/event-output-ideurl.jpg)

Enter the password provided in the previous step:

![IDE Password](/static/images/10-IDE-Password.jpg)

Open the IDE Terminal by click the menu icon on the top left, then selecting **Terminal** -> **New Terminal** like the image below:

![IDE](/static/images/10-IDE.jpg)

The Terminal should be at the bottom, this will be the location to enter the terminal commands during the workshop:

![IDE Terminal](/static/images/10-IDE-Terminal.jpg)

::::expand{header="Click here to see the list of tools and utilities that are boostrapped to your IDE environment:"}

- kubectl = The Kubernetes command-line tool, kubectl, allows you to run commands against Kubernetes clusters. You can use kubectl to deploy applications, inspect and manage cluster resources, and view logs.
- helm = Helm helps you manage Kubernetes applications — Helm Charts help you define, install, and upgrade even the most complex Kubernetes application.
- kns = kns is a very small shellscript that utilizes fzf to switch between Kubernetes namespaces fast.
- kctx = kubectx is a tool to switch between contexts (clusters) on kubectl faster. A Kubernetes context is a group of access parameters that define which cluster you're interacting with, which user you're using, and which namespace you're working in. It's helpful if you need to access different clusters for different purposes or if you want to limit your access to certain parts of a cluster.
- AWS CLI version 2
- IAM role
- jq = JSON processor
- yq = YAML processor
- envsubst = The envsubst command is used to get a substitute of environment variables and that's what its name suggests.
- bash-completion = Bash completion is a bash function that allows you to auto complete commands or arguments by typing partially commands or arguments, then pressing the [Tab] key.
- c9 = Cloud9 CLI and tools (c9 open file.txt)
- [k9s](https://k9scli.io/) = K9s is a terminal based UI to interact with your Kubernetes clusters. The aim of this project is to make it easier to navigate, observe and manage your deployed applications in the wild. K9s continually watches Kubernetes for changes and offers subsequent commands to interact with your observed resources.
- [eks-node-viewer](https://github.com/awslabs/eks-node-viewer) = eks-node-viewer is a tool for visualizing dynamic node usage within a cluster. It was originally developed as an internal tool at AWS for demonstrating consolidation with Karpenter. It displays the scheduled pod resource requests vs the allocatable capacity on the node. It does not look at the actual pod resource usage.
- aliases (k, kgn, kgp, tfi, tfp, tfy) - type alias to see them

::::
