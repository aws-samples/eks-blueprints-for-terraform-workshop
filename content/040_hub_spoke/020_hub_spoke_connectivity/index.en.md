---
title: "Hub to Spoke Connectivity"
weight: 20
---

The following diagram explains how the hub Argo CD manages a remote cluster (`spoke-staging`):

![Hub Spoke Connectivity](/static/images/hub-spoke-connectivity.png)

To enable Argo CD in the hub cluster to manage workloads on a spoke cluster, we need the following:

1. **IAM Role in Hub**: Associate Argo CD service accounts with an IAM role (`hub-role`) that has permission to assume the `spoke-role`.

2. **IAM Role in Spoke**: Create a spoke IAM role (`spoke-role`) with admin permissions on the spoke cluster. This role must trust the Argo CD IAM role (`hub-role`).

3. **Cluster Object in Hub**: Create a `Cluster` object (`spoke-staging`) in the hub with the following:
   - API endpoint of the spoke cluster
   - Cluster certificate
   - `roleArn`: `spoke-role`

When an Argo CD Application deploys to the `spoke-staging` cluster, Argo CD assumes the `spoke-role`. This role grants access to the spoke cluster’s Kubernetes API server, allowing Argo CD to deploy applications, manage addons, and orchestrate workloads remotely.
