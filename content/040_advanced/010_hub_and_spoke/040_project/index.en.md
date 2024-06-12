---
title: 'Project'
weight: 40
---

Argo CD [Projects](https://argo-cd.readthedocs.io/en/stable/user-guide/projects/) is a logical grouping of Argo CD Applications. Projects provide the following features:

- Restrict what may be deployed:
    - Specify trusted Git source repositories. In this workshop we uses an ApplicationSet named `argoprojects` to dynamically create ArgoProjects pointing to the platform git repository.

- Restrict where apps may be deployed:
    - Specify destination clusters and namespaces. We will restrict webstore microservices (UI, catalog, etc.) to the spoke-staging namespace. This will prevent the webstore from accidentally being deployed to the hub cluster.

- Restrict what kinds of objects may or may not be deployed: 
    - We have already set limit ranges, resource quotas etc on the namespaces. We should prevent application teams from overwriting these restrictions. But they can create pods, deployments, etc. in their namespace.

- Define project roles:
    - This workshop does not define any project roles. You can explore this on your own.


