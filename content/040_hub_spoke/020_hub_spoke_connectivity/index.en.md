---
title: "Hub to Spoke Connectivity"
weight: 20
---

In this chapter, we will configure the Argo CD installation in the Hub Cluster to assume an IAM role in the spoke cluster. This setup enables the Hub Cluster's Argo CD to manage (install, uninstall, update) addons, namespaces, and workloads on the spoke cluster.

The following diagram illustrates the connectivity between the Hub and Spoke clusters:

![Hub Role](/static/images/hub-manage-spoke-addons.jpg)

By establishing this connection, we create a centralized management structure that allows for efficient control and deployment across multiple clusters from a single Hub. This approach simplifies cluster management, ensures consistency, and streamlines operations across our Kubernetes infrastructure.
