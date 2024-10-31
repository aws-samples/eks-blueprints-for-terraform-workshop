---
title: "Workshop Git Repositories"
weight: 35
---

In this chapter we will work with three Git repositories using a [gitea](https://github.com/go-gitea/gitea) server that has already been installed in our IDE instance:

![CodeCommit Repository](/static/images/gitea_repos.jpg)

1. **eks-blueprints-workshop-gitops-apps** - Used by developers to store Kubernetes manifests for the webstore microservices workload

2. **eks-blueprints-workshop-gitops-platform** - Used by platform engineers to store infrastructure artifacts like namespace configurations

3. **eks-blueprints-workshop-gitops-addons** - Used by platform engineers to store Kubernetes add-on manifests

The separation between workload and platform repositories illustrates the distinct roles and responsibilities between developers and platform engineers.

We are using Gitea in this workshop for convenience, but any Git management system can be used as a replacement.
