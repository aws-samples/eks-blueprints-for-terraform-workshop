---
title: "Hub to Spoke Connectivity"
weight: 30
---

In this chapter, we will configure the Argo CD installation in the Hub Cluster to assume an IAM role in the spoke cluster. This enables the Hub Cluster's Argo CD to manage (install, uninstall, update) addons, namespaces, and workloads on the spoke cluster.

![Hub Role](/static/images/hub-manage-spoke-addons.jpg)
