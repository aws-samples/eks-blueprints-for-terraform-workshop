---
title: 'Workload'
weight: 78
---

In this chapter, you will deploy the webstore workload across the namespaces we previously provisioned. The webstore workload comprises multiple microservices, including ui, orders, checkout, carts, catalog, assets, and rabbitmq, each serving a specific function within the application architecture.

![Webstore](/static/images/webstore.png)

Developer webstore workload code is in your git repo in `~/environment/wgit/assets/developer/webstore/` directory, you can check the files in this that we will deploy with Argo CD.

![Webstore](/static/images/developer-webstore.png)