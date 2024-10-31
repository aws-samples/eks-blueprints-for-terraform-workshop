---
title: "Create Spoke Staging"
weight: 10
---

In this chapter, we will create another EKS cluster called spoke-staging

![spoke-staging](/static/images/spoke-staging.jpg)

::::expand{header="What is Terraform workspaces?"}

Terraform [workspace](https://developer.hashicorp.com/terraform/language/state/workspaces) is a feature that enables managing multiple distinct infrastructures or environments from the same Terraform configuration.

In this chapter, we will create the spoke-staging cluster. The spoke-prod cluster will be created in upcoming chapters. These clusters are identical except for a few variable changes. We will use Terraform workspaces to create the clusters and maintain two different states with the same Terraform files.
::::
