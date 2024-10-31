---
title: Accessing the IDE
weight: 12
---

### Access AWS Workshop IDE

We can find the elements needed to access our Cloud IDE in either the personal dashboard page (scroll down to the Event Outputs section) or in the CloudFormation stack output. Let's open this in a new browser tab.

![Event Output](/static/images/event-output-ideurl.jpg)

Enter the password provided in the previous step:

![IDE Password](/static/images/10-IDE-Password.jpg)

To open the IDE Terminal, we click the menu icon on the top left, then select **Terminal** -> **New Terminal** as shown below:

![IDE](/static/images/10-IDE.jpg)

The Terminal will appear at the bottom of the screen. We will use this terminal to enter commands throughout the workshop:

![IDE Terminal](/static/images/10-IDE-Terminal.jpg)

::::expand{header="Click here to see the list of tools and utilities that are bootstrapped to our IDE environment:"}

- kubectl = The Kubernetes command-line tool, kubectl, allows us to run commands against Kubernetes clusters. We can use kubectl to deploy applications, inspect and manage cluster resources, and view logs.
- helm = Helm helps us manage Kubernetes applications — Helm Charts help us define, install, and upgrade even the most complex Kubernetes application.
- kns = kns is a very small shellscript that utilizes fzf to switch between Kubernetes namespaces fast.
- kctx = kubectx is a tool to switch between contexts (clusters) on kubectl faster. A Kubernetes context is a group of access parameters that define which cluster we're interacting with, which user we're using, and which namespace we're working in. It's helpful if we need to access different clusters for different purposes or if we want to limit our access to certain parts of a cluster.
- AWS CLI version 2
- IAM role
- jq = JSON processor
- yq = YAML processor
- envsubst = The envsubst command is used to substitute environment variables in text.
- bash-completion = Bash completion is a bash function that allows us to auto complete commands or arguments by typing partial commands or arguments, then pressing the [Tab] key.
- c9 = Cloud9 CLI and tools (c9 open file.txt)
- [k9s](https://k9scli.io/) = K9s is a terminal based UI to interact with Kubernetes clusters. The aim of this project is to make it easier to navigate, observe and manage deployed applications. K9s continually watches Kubernetes for changes and offers subsequent commands to interact with observed resources.
- [eks-node-viewer](https://github.com/awslabs/eks-node-viewer) = eks-node-viewer is a tool for visualizing dynamic node usage within a cluster. It was originally developed as an internal tool at AWS for demonstrating consolidation with Karpenter. It displays the scheduled pod resource requests vs the allocatable capacity on the node. It does not look at the actual pod resource usage.
- aliases (k, kgn, kgp, tfi, tfp, tfy) - type alias to see them

::::
