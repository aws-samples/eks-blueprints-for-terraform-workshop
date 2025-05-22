---
title: "Namespace"
weight: 010
---

In a multi-tenant environment, we aim to isolate applications from one another on shared infrastructure. Namespaces provide this isolation. All of an application's objects, such as secrets, configmaps, and volumes, are created within the application's namespace. We can use quotas and limit ranges to control the amount of cluster resources each application uses. Additionally, we can set network policies and RBAC to further isolate applications.

![Namespace](/static/images/namespace.jpg)

In this scenario, we will use Argo CD to provision application namespaces in advance, separate from the actual workloads. It is considered a best practice to avoid using the "CreateNamespace: true" option in Argo CD when deploying workloads. This separation of concerns allows for a clear distinction between the responsibilities of the platform team and the application teams.

The platform team is responsible for establishing guardrails and defaults for each cluster and environment, ensuring consistent and secure deployment practices. They define RBAC rules, enforce resource quotas, set limits, configure network policies, and implement additional guardrail policies within each namespace. These guardrails act as a framework to ensure compliance and maintain control over the cluster's resources and security posture.

Application teams are granted permission to deploy workloads within the provisioned namespaces. However, they are not allowed to modify the guardrails enforced by the platform team. This separation of responsibilities ensures that the platform team maintains control over the cluster's overall security and resource management, while application teams can focus on deploying and managing their workloads within the defined boundaries.

By following this approach, we can achieve a balance between centralized governance and decentralized application deployment, promoting a secure and scalable Kubernetes environment.
