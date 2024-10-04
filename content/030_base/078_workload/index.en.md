---
title: 'Workload'
weight: 78
---

In this chapter, you will deploy the webstore workload across the namespaces we previously provisioned. The webstore workload comprises multiple microservices, including ui, orders, checkout, carts, catalog, assets, and rabbitmq, each serving a specific function within the application architecture.

![Webstore](/static/images/webstore.png)

Webstore workload code is in your git repo in `~/environment/gitops-repo/workload/webstore/` directory, you can check the files that will be deployed with Argo CD.

![Webstore](/static/images/developer-webstore.jpg)

The webstore workload supports multiple environments like hub, staging and prod. Environment-specific configurations are applied using kustomization.
