---
title: 'Namespace'
weight: 75
---

In a multi-tenant environment, you want to isolate applications from other applications running on shared infrastructure. You can use namespaces to isolate applications. All of an application's objects, such as secrets, configmaps, volumes, etc. are created in the application's namespace. You can use quotas and limit ranges to control the amount of cluster resources each application uses. You can also set network policies and RBAC to further isolate applications.

![Namespace](/static/images/namespace.png)

In this scenario, we will leverage Argo CD to provision application namespaces in advance, which are separate from the actual workloads themselves. It is considered a best practice to avoid using the "CreateNamespace: true" option in Argo CD when deploying workloads. This separation of concerns allows for a clear distinction between the responsibilities of the platform team and the application teams.

The platform team is responsible for establishing guardrails and defaults for each cluster and environment, ensuring consistent and secure deployment practices. They define RBAC rules, enforce resource quotas, set limits, configure network policies, and implement additional guardrail policies within each namespace. These guardrails act as a framework to ensure compliance and maintain control over the cluster's resources and security posture.

On the other hand, application teams are granted permission to deploy workloads within the provisioned namespaces. However, they are not allowed to modify the guardrails enforced by the platform team. This separation of responsibilities ensures that the platform team maintains control over the cluster's overall security and resource management, while application teams can focus on deploying and managing their workloads within the defined boundaries.

By following this approach, organizations can achieve a balance between centralized governance and decentralized application deployment, promoting a secure and scalable Kubernetes environment.

## Workloads

In upcoming chapters, you will deploy the webstore workload. It is made up of the ui, carts, catalog, orders, checkout, rabbitmq and assets microservices. In this chapter, you will create namespaces to isolate these microservices.

![Webstore](/static/images/webstore.png)