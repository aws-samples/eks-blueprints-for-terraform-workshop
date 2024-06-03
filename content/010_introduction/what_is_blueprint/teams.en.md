---
title: 'How does it affect different individuals?'
chapter: false
weight: 12
---

## What can each individual on your team expect from EKS Blueprints?

Now that we have an understanding of why we are using the EKS Blueprints, let's take some time to understand how this will benefit the various roles on each team that we will be working with.

Team topologies vary by environment; however, one topology that is prevalent across many organizations is having a _Platform Team_ provision and manage infrastructure. And also having multiple _Application Teams_ that need to focus on deploying features in an agile manner.

Many companies face a big challenge in enabling multiple developer teams to freely consume a platform with proper guardrails. The objective of our workshop is to show you how you can provision a platform based on EKS to remove these barriers.

The workshop focuses on two key enterprise teams: a **Platform Team** and a **Application Team**.

The Platform Team will provision the EKS cluster and onboard the Developer Team. The Application Team will deploy a workload to the cluster.

## Platform Team

Acting as the Platform Team, we will use the [EKS Blueprints for Terraform](https://github.com/aws-ia/terraform-aws-eks-blueprints) which is a solution entirely written in Terraform HCL language. It helps you build a shared platform where multiple teams can consume and deploy their workloads. The EKS underlying technology is Kubernetes of course, so having some experience with Terraform and Kubernetes is helpful. You will be guided by our AWS experts (on-site) as you follow along in this workshop.

## Application Team

Once the EKS cluster has been provisioned, a Application Team (Riker Team) will deploy a workload. The workload is a basic static web app. The static site will be deployed using GitOps continuous delivery.
