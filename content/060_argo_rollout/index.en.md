---
title: 'Blue/Green Deployments with Argo Rollouts'
weight: 40
hidden: false
---

In this module, we use Argo **Rollouts** to implement an advanced deployment strategy called blue-green. There are many benefits to using this strategy, including zero-downtime deployments.

The Kubernetes Deployment already uses rolling updates but does not give you enough control. Here is a comparison.

| Features                                    | Kubernetes Deployment | Argo Rollouts |
| ------------------------------------------- | --------------------- | ------------- |
| Blue/Green                                  | No                    | Yes           |
| Control over Rollout Speed                  | No                    | Yes           |
| Easy traffic Management                     | No                    | Yes           |
| Verify using External Metrics               | No                    | Yes           |
| Automate Rollout/rollback based on analysis | No                    | Yes           |
|                                             |                       |               |

::alert[This workshop is focused on how to enable and try Argo Rollouts in the context of using **EKS Blueprints for Terraform**. We do not provide a deep-dive into **Argo Rollouts**. To learn more about Argo Rollouts, view the [docs](https://argoproj.github.io/argo-rollouts/concepts/#rollout)]{header="Important"}

# How Argo Rollouts Blue/Green Deployments Work

The Rollout will configure the preview service _(Green)_ to send traffic to the new version while the active service _(Blue)_ continues to receive production traffic. Once we are satisfied, we promote the preview service as the new active service.

![Argo Rollouts Architecture](https://argoproj.github.io/argo-rollouts/concepts-assets/blue-green-deployments.png)

**FIGURE 1 - Argo Rollouts Blue/Green Deployment Strategy**
> source: [Argo Rollouts Docs](https://argoproj.github.io/argo-rollouts)

# Scenario

Marketing would like to run functional testing on a new version of the **Skiapp** before it starts to serve production traffic.

Marketing decided there were too many global navigation items:

The current version we are using is `sharepointoscar/skiapp:v1` which is pulled from Docker Hub. The new and improved version is appropriately tagged `sharepointoscar/skiapp:v2` and includes fewer global navigation items.
