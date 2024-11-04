---
title: Accessing the IDE
weight: 12
---

### Accessing the AWS Workshop IDE

The elements needed to access our Cloud IDE can be found in either the personal dashboard page (scroll down to the Event Outputs section) or in the CloudFormation stack output. Let's open this in a new browser tab.

![Event Output](/static/images/event-output-ideurl.jpg)

Enter the password provided in the previous step:

![IDE Password](/static/images/10-IDE-Password.jpg)

To open the IDE Terminal, follow these steps:

1. Click the menu icon on the top left
2. Select **Terminal** -> **New Terminal** as shown below:

![IDE](/static/images/10-IDE.jpg)

The Terminal will appear at the bottom of the screen. We will use this terminal to enter commands throughout the workshop:

![IDE Terminal](/static/images/10-IDE-Terminal.jpg)

::::expand{header="Click here to see the list of tools and utilities that are bootstrapped to our IDE environment:"}

- **kubectl**: The Kubernetes command-line tool that allows us to run commands against Kubernetes clusters. We can use kubectl to deploy applications, inspect and manage cluster resources, and view logs.
- **helm**: Helm helps us manage Kubernetes applications — Helm Charts help us define, install, and upgrade even the most complex Kubernetes application.
- **kns**: A small shell script that utilizes fzf to switch between Kubernetes namespaces quickly.
- **kctx**: A tool to switch between contexts (clusters) on kubectl faster. A Kubernetes context is a group of access parameters that define which cluster we're interacting with, which user we're using, and which namespace we're working in.
- **AWS CLI version 2**
- **IAM role**
- **jq**: JSON processor
- **yq**: YAML processor
- **envsubst**: Used to substitute environment variables in text.
- **bash-completion**: A bash function that allows us to auto-complete commands or arguments by typing partial commands or arguments, then pressing the [Tab] key.
- **c9**: Cloud9 CLI and tools (e.g., c9 open file.txt)
- **[k9s](https://k9scli.io/)**: A terminal-based UI to interact with Kubernetes clusters. It continually watches Kubernetes for changes and offers subsequent commands to interact with observed resources.
- **[eks-node-viewer](https://github.com/awslabs/eks-node-viewer)**: A tool for visualizing dynamic node usage within a cluster. It displays the scheduled pod resource requests vs the allocatable capacity on the node.
- **aliases** (k, kgn, kgp, tfi, tfp, tfy): Type 'alias' to see them

::::
