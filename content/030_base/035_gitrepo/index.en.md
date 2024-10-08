---
title: "Workshop Git Repositories"
weight: 35
---

In this workshop you are going to work with three git repositories using a [gitea](https://github.com/go-gitea/gitea) server already install in the IDE instance:

![CodeCommit Repository](/static/images/gitea_repos.jpg)

1. **eks-blueprints-workshop-gitops-apps** for platform engineers to store Kubernetes addons manifests

2. **eks-blueprints-workshop-gitops-platform** for platform engineers to store infrastructure artifacts like namespaces configurations

3. **eks-blueprints-workshop-gitops-addons** for developers to store Kubernetes manifests for webstore microservices workload

The separation of the workload and platform repositories between developers and platform engineers illustrates a separation of roles and responsibilities.

We are using Gitea for this workshop for convenience but you can uses any Git management system in replacement.
