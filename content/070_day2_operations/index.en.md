---
title: 'Day 2 Operations'
weight: 70
---

## Introduction

One crucial aspect for individuals who opt for Kubernetes as their container management platform is to carefully plan for cluster upgrades. The Kubernetes project continually evolves with fresh features, design enhancements, and bug fixes, and minor versions are typically released approximately every three months, offering support for around twelve months after their release.

Amazon EKS typically lags a few weeks behind the latest Kubernetes version due to rigorous testing performed to ensure stability and compatibility with other AWS services and tools prior to making a new version available on EKS.

### Keep your cluster updated

Maintaining pace with Kubernetes releases is a pivotal aspect of the shared responsibility model when adopting EKS and Kubernetes.

After a certain period, typically one year, the Kubernetes community ceases to release bug and CVE patches for specific versions. Moreover, the Kubernetes project discourages CVE submissions for deprecated versions. Consequently, vulnerabilities specific to older Kubernetes versions may go unreported, leaving you exposed without any prior notice or options for remediation in case of a vulnerability.

We consider this security posture unacceptable for both EKS and our customers, which has led to the implementation of our current policy of automatic upgrades to newer versions. We urge you to review the EKS version support policy for further details.

If your cluster isn't upgraded before the end of the support date, it will be automatically upgraded to the next supported version. It's important to note that without proper testing and preparation, this upgrade may disrupt workloads and controllers. We highly recommend staying up-to-date with Kubernetes releases in EKS to ensure a secure and smooth operation.

### Kubernetes cluster upgrade strategy

A well-defined cluster upgrade strategy is essential for achieving success, allowing you to perform either in-place or blue-green upgrades based on the specific situation you encounter. For each scenario, it is crucial to develop a comprehensive and well-documented process for managing cluster upgrades. This includes creating detailed runbooks and implementing suitable tooling to facilitate the upgrade process.

To stay in sync with EKS Kubernetes releases, it is recommended to proactively plan and schedule regular cluster upgrades. It is advisable to upgrade clusters at least once per year to ensure compatibility with the latest features, bug fixes, and security patches provided by EKS. By adhering to a consistent upgrade schedule, you can effectively leverage the advancements and improvements offered by EKS and Kubernetes.


When upgrading Kubernetes, it is highly recommended to test each upgrade in staging and pre-production environments. This allows us to differentiate between "non-breaking changes" and "breaking changes". Non-breaking changes refer to upgrades where the planning phase does not reveal any changes that can cause downtime. On the other hand, breaking changes occur when upgrades to Kubernetes, Terraform, or add-ons have the potential to cause downtime. Based on this distinction, we employ different deployment strategies, as follows:

For non-breaking changes, we perform a standard upgrade **in-place**. This involves upgrading the existing EKS control plane first, followed by launching a rolling update on Kubernetes nodes, and finally upgrading the add-ons.

For breaking changes, we opt for a **blue-green** deployment approach. This entails creating a second cluster with the latest version of Amazon EKS and Add-ons. We deploy our applications and thoroughly test them before switching the traffic to the new cluster. Finally, we complete the upgrade process by shutting down the old cluster.
