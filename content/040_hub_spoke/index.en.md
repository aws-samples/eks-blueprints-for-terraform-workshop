---
title: "Hub-Spoke ArgoCD Deployment"
weight: 40
---

In the **Hub-Spoke** approach, a single, centralized Argo CD instance (running in the **hub cluster**) is responsible for managing applications and addons across multiple **spoke EKS clusters**.

In this chapter, we will configure Argo CD in the **hub cluster** to manage applications and addons deployed on the **spoke-staging cluster**.

![Platform Task](/static/images/standalone-argocd.png)