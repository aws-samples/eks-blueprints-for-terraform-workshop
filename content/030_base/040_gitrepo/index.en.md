---
title: "Git Repository Overview"
weight: 40
---

In this chapter, we will work with three Git repositories using a [gitea](https://github.com/go-gitea/gitea) server that has been pre-installed in our IDE instance:

![Developer](/static/images/developer-task.png) Developer Repository

- **eks-blueprints-workshop-gitops-apps** - Contains Kubernetes manifests for the webstore microservices workload.

![Platform](/static/images/platform-task.png) Platform Repository

- **eks-blueprints-workshop-gitops-platform** - Contains infrastructure code to automate namespace creation and workload deployment.

- **eks-blueprints-workshop-gitops-addons** -Contains Kubernetes add-on manifests and configuration values

The separation between workload and platform repositories illustrates the distinct roles and responsibilities of Developers and Platform engineers.

We are using Gitea in this workshop for convenience, but any Git management system( GitHub, GitLab, Bitbucket) can serve as a replacement.
