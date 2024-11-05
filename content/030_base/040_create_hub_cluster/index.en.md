---
title: "EKS cluster"
weight: 40
---

Kubernetes is a powerful and extensible container orchestration technology that enables deploying and managing containerized applications at scale. While its extensible nature allows the use of many popular open-source tools in Kubernetes clusters, configuring an EKS cluster to meet specific organizational needs can be time-consuming due to the wide array of tooling and design choices available.

In the following chapters, we will cover how to deploy and integrate with Argo CD for managing Kubernetes configurations, and how to use the gitops-bridge and eks-blueprints-addons modules to manage additional add-ons that may require AWS resources like IAM roles and permissions to function.

For now, in this chapter, we use the Terraform EKS module to build the EKS cluster, including managed node groups and some EKS-managed add-ons. Using this module offers several advantages:

- Pre-built configurations: The module provides pre-configured settings for EKS clusters, including the number of worker nodes, node sizes, and storage options.

- Automated provisioning: It automates the provisioning of EKS clusters and associated resources, such as creating the EKS cluster, setting up required IAM roles and policies, and configuring network and security settings.

- Integration with other AWS services: The module integrates with other AWS services like Amazon Elastic Load Balancing (ELB), Amazon RDS, and Amazon CloudWatch, providing a complete infrastructure solution for EKS applications.

- Community support: The module is actively maintained by the community, with a large user base and numerous resources available for support and troubleshooting.

In advanced modules, we will explore the hub-and-spoke pattern for EKS, where a centralized management cluster named "hub" is used to control and govern multiple application clusters called "spokes." This architectural design pattern enables centralized management, consistent policies, scalability, isolation, and disaster recovery across the Kubernetes infrastructure. The Terraform stack we will create is named "hub" as it represents the central control plane for managing the spoke clusters.
