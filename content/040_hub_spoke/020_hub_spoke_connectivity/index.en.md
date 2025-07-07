---
title: "Hub to Spoke Connectivity"
weight: 20
---

The following diagram explains how the hub ArgoCD manages a remote cluster (`spoke-staging`):

![Hub Spoke Connectivity](/static/images/hub-spoke-connectivity.png)

To enable ArgoCD in the hub cluster to manage workloads on a spoke cluster, we need the following:

1. **IAM Role in Hub**: Associate ArgoCD service accounts with an IAM role (`hub-role`) that has permission to assume the `spoke-role`.

2. **IAM Role in Spoke**: Create a spoke IAM role (`spoke-role`) with admin permissions on the spoke cluster. This role must trust the ArgoCD IAM role (`hub-role`).

3. **Cluster Object in Hub**: Create a `Cluster` object (`spoke-staging`) in the hub with the following:
   - API endpoint of the spoke cluster
   - Cluster certificate
   - `roleArn`: `spoke-role`

When an ArgoCD Application deploys to the `spoke-staging` cluster, ArgoCD assumes the `spoke-role`. This role grants access to the spoke cluster’s Kubernetes API server, allowing ArgoCD to deploy applications, manage addons, and orchestrate workloads remotely.
