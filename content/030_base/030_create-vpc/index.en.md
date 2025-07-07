---
title: "Amazon VPC Architecture"
weight: 30
---

In this chapter, as a Platform Engineer ![Platform](/static/images/platform-task.png) you will create a Terraform stack to provision an Amazon Virtual Private Cloud (VPC) with both public and private subnets. Public subnets are used for internet-facing resources, such as load balancers, while private subnets host internal resources, like Amazon EKS worker nodes, which should not be directly accessible from the internet.

![Environment architecture diagram](/static/images/environment.jpg)
