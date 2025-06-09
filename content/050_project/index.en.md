---
title: "Project"
weight: 50
hidden: true
---

Argo CD [Projects](https://argo-cd.readthedocs.io/en/stable/user-guide/projects/) provide logical groupings of Argo CD Applications. They offer several key capabilities:

- Control over what can be deployed:

  - Define trusted Git source repositories. In this workshop, we use an ApplicationSet named `argoprojects` to dynamically create ArgoProjects that point to the platform git repository.

- Control over deployment destinations:

  - Specify allowed destination clusters and namespaces. We will restrict webstore microservices (UI, catalog, etc.) to the spoke-staging namespace, preventing accidental deployment to the hub cluster.

- Control over allowed resource types:

  - We have already configured limit ranges and resource quotas on the namespaces. We need to prevent application teams from overriding these restrictions while allowing them to create pods, deployments, and other resources in their namespace.

- Project role definitions:
  - While this workshop does not cover project roles, we encourage exploring this functionality independently.

By leveraging these capabilities, Argo CD Projects enable fine-grained control over application deployments, enhancing security and maintaining consistency across your Kubernetes environments.
