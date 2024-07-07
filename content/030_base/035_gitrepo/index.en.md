---
title: 'Setup Git Repository'
weight: 35
---

In this workshop we create two codecommit repositories:

![CodeCommit Repository](/static/images/codecommit_repos.png)

1. "gitops-workload" for developers to store Kubernetes manifests for webstore microservices workload

2. "gitops-platform" for platform engineers to store infrastructure artifacts like addons, application deployment, etc.

The separation of the workload and platform repositories between developers and platform engineers illustrates a separation of roles and responsibilities. Using CodeCommit provides a managed git service on AWS. Creating the IAM user allows controlled access to the repositories.

This workshop creates "terraform-workshop-gitops" IAM user  to [access](https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-ssh-unixes.html#setting-up-ssh-unixes-keys) both repositories.

* Creates policy to access two repositories
* Configures SSH access to the repositories with public and private key
