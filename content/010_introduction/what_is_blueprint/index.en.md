---
title: 'What is EKS Blueprints?'
weight: 10
---

The EKS Blueprints is an open-source development framework that abstracts the complexities of cloud infrastructure from developers and allows them to deploy workloads with ease. Containerized environments on AWS are composed of multiple AWS or open source products and services, including services for running containers, CI/CD pipelines, capturing logs/metrics, and security enforcements. The EKS Blueprints framework packages these tools into a cohesive whole and makes them available to development teams as a service. From an operational perspective, the framework allows companies to consolidate tools and best practices for securing, scaling, monitoring, and operating containerized infrastructure into a central platform that can then be used by developers across an enterprise.

# How is the EKS Blueprints built?

The EKS Blueprints is built on top of Amazon EKS and all the various components that we need to efficiently address Day 2 operations. A blueprint is defined via Infrastructre-as-Code best practices through [AWS CDK](https://aws.amazon.com/cdk/) or Hashicorp Terraform, through two open-source projects:

- The [EKS Blueprints for Terraform](https://github.com/aws-ia/terraform-aws-eks-blueprints)
- The [EKS Blueprints for CDK](https://github.com/aws-quickstart/cdk-eks-blueprints)

::alert[We also have a [dedicated workshop](https://catalog.workshops.aws/eks-blueprints-for-cdk) for CDK version.]

# What can I do with a Blueprint?

Customers can leverage the EKS Blueprints to:

- Deploy EKS clusters across any number of accounts and regions, following best practices.
- Manage cluster configuration, including add-ons that run in each cluster, from a single Git repository.
- Define teams, namespaces, and their associated access permissions for your clusters.
- Leverage GitOps-based workflows for onboarding and managing workloads for your teams.

There is also a EKS Blueprints Patterns examples [directory](https://github.com/aws-ia/terraform-aws-eks-blueprints/tree/main/examples) that provides a library of different deployment options defined as constructs, which include the following:

- analytics clusters with Spark or EMR on EKS
- fully private eks clusters
- IPV6 eks clusters
- EKS clusters scaling with Karpenter
- Clusters with observability tools
- and much more...

In the next section, we will talk about the benefits of following the EKS Blueprints model.
