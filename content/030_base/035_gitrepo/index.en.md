---
title: 'Setup Git Repository'
weight: 35
---

In this workshop you are going to create two git repositories using a [gitea](https://github.com/go-gitea/gitea) server already install in the IDE:

TODO: update image
![CodeCommit Repository](/static/images/codecommit_repos.png)

1. "gitops-workload" for developers to store Kubernetes manifests for webstore microservices workload

2. "gitops-platform" for platform engineers to store infrastructure artifacts like addons, application deployment, etc.

The separation of the workload and platform repositories between developers and platform engineers illustrates a separation of roles and responsibilities. Using CodeCommit provides a managed git service on AWS. Creating the IAM user allows controlled access to the repositories.

