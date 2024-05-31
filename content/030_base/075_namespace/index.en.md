---
title: 'Namespace'
weight: 75
---

In a multi-tenant environment, you want to isolate applications from other applications running on shared infrastructure. You can use namespaces to isolate applications. All of an application's objects, such as secrets, configmaps, volumes, etc. are created in the application's namespace. You can use quotas and limit ranges to control the amount of cluster resources each application uses. You can also set network policies and RBAC to further isolate applications.

![Namespace](/static/images/namespace.png)

In upcoming chapters, you will deploy the webstore workload. It is made up of the ui, carts, catalog, orders, checkout, rabbitmq and assets microservices. In this chapter, you will create namespaces to isolate these microservices.

![Webstore](/static/images/webstore.png)