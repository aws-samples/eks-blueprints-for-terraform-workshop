---
title: "Workload"
weight: 78
---

In this chapter, we will deploy the webstore workload across the namespaces we previously provisioned. The webstore workload consists of multiple microservices that work together to provide the complete application functionality:

- UI service
- Orders service
- Checkout service
- Carts service
- Catalog service
- Assets service
- RabbitMQ messaging service

![Webstore](/static/images/webstore.png)

The webstore workload code is located in our git repository in the `~/environment/gitops-repo/workload/webstore/` directory. We can examine these files that will be deployed using Argo CD.

![Webstore](/static/images/developer-webstore.jpg)

The webstore workload supports multiple environments including hub, staging and production. Environment-specific configurations are managed through kustomization files.
