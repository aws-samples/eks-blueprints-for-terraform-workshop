---
title : "Deploy Workload"
weight : 40
---
Now that the cluster is ready and the Platform Team has onboarded the Application Team Riker, they are ready to deploy their workloads.  

In the following exercise, you are going to work from your clone of [eks-blueprints-workloads](https://github.com/aws-samples/eks-blueprints-workloads.git) repository, as a member of Team Riker, and you will deploy your workloads only by interacting with the git repository.

We will be deploying the Team Riker static site using ALB in this exercise.

## Team Riker Objectives

The team has a static website that they need to publish. Changes should be tracked by source control using GitOps. This means that if a feature branch is merged into the main branch, a “sync” is triggered, and the app is updated seamlessly.

All of this work will be done within the Riker Team’s environment in EKS/Kubernetes.

The following is a list of key features of this workload:

* A simple static website featuring great ski photography.
* In a real environment, we could add a custom FQDN and associated TLS Certificate. But in this lab, we can't have a custom domain, so we will stay at http on default domains.

As we mentioned earlier in our workshop, we use Helm to package apps and deploy workloads. The Workloads repository is the one recognized by ArgoCD (already set up by the Platform Team).