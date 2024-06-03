---
title : "Working with GitOps"
weight : 33
---

## What is GitOps?

>Pioneered in 2017, GitOps is a way to do Kubernetes cluster management and application delivery. GitOps works by using Git as a single source of truth for declarative infrastructure and applications. With GitOps, the use of software agents can alert on any divergence between Git with what's running in a cluster, and if there's a difference, Kubernetes reconcilers automatically update or rollback the cluster depending on the case. With Git at the center of your delivery pipelines, developers use familiar tools to make pull requests to accelerate and simplify both application deployments and operations tasks to Kubernetes.
>
>— [WeaveWorks "Guide to GitOps"](https://www.weave.works/technologies/gitops/#what-is-gitops) .

GitOps can be summarized as these two things:

- An operating model for Kubernetes and other cloud-native technologies, providing a set of best practices that unify Git deployment, management, and monitoring for containerized clusters and applications.
- A path towards a developer experience for managing applications, where end-to-end CICD pipelines and Git workflows are applied to both operations and development.

Companies want to go fast; they need to deploy more often, more reliably, and preferably with less overhead. GitOps is a fast and secure method for developers to manage and update complex applications and infrastructure running in Kubernetes.

## GitOps vs IaC

Infrastructure as Code tools used for provisioning servers on demand have existed for quite some time. These tools originated from the concept of keeping infrastructure configurations versioned, backed up, and reproducible from source control.

With Kubernetes being almost completely declarative, combined with the immutable container, it is possible to extend some of these concepts to managing both applications and their resource dependencies as well.

The ability to manage and compare the current state of both your infrastructure and your applications so that you can test, deploy, rollback, and rollforward with a complete audit trail all from within Git is what encompasses the GitOps philosophy and its best practices. This is possible because Kubernetes is managed entirely through declarative, immutable configuration.

## What is ArgoCD?

[Argo CD](https://argoproj.github.io/cd/) is a declarative GitOps continuous delivery tool for Kubernetes. The Argo CD controller in the Kubernetes cluster continuously monitors the state of your cluster and compares it with the desired state defined in Git. If the cluster state does not match the desired state, Argo CD reports the deviation and provides visualizations to help developers manually or automatically sync the cluster state with the desired state.

Argo CD offers three ways to manage your application state:

- CLI - A powerful CLI that lets you create YAML resource definitions for your applications and sync them with your cluster.
- User Interface - A web-based UI that lets you do the same things that you can do with the CLI. It also lets you visualize the Kubernetes resources that belong to the Argo CD applications that you create.
- Kubernetes manifests and Helm charts are applied to the cluster.

![ArgoCD Architecture](/static/images/argo-cd-architecture.png)

There are alternatives to ArgoCD, like [Flux](https://fluxcd.io/flux/concepts/). In this workshop we will rely on ArgoCD mainly because of its nice UI.

