---
title: 'Autoscaling with Karpenter'
weight: 40
---

In this module, you will learn how to maintain your Kubernetes clusters at any scale using [Karpenter](https://karpenter.sh).

Karpenter is an open-source autoscaling project built for Kubernetes. Karpenter is designed to provide the right compute resources to match your application’s needs in seconds instead of minutes by observing the aggregate resource requests of unschedulable pods and making decisions to launch and terminate nodes to minimize scheduling latencies.

![GitHub Create File](/static/images/karpenter-overview.png)

Karpenter is a node lifecycle management solution used to scale your Kubernetes cluster. It observes incoming pods and launches the right instances for the situation. Instance selection decisions are intent-based and driven by the specification of incoming pods, including resource requests and scheduling constraints.

For now, our EKS blueprint cluster is configured to run with an EKS [Managed Node Group](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html), which has deployed a minimum set of On-Demand instances that we will use to deploy Kubernetes controllers on it.

::alert[We could also have chosen to deploy Karpenter on [Fargate](https://docs.aws.amazon.com/fr_fr/eks/latest/userguide/fargate.html) instead like in this [example](https://github.com/aws-ia/terraform-aws-eks-blueprints/blob/main/examples/karpenter)]{header="Important"}




 After that, we will use Karpenter to deploy a mix of On-Demand and Spot instances to showcase a few of the benefits of running a group-less autoscaler. [EC2 Spot](https://aws.amazon.com/fr/ec2/spot/) Instances allow you to architect for optimizations on cost and scale.

