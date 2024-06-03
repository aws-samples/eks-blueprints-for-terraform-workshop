---
title: 'Create shared environment'
weight: 31
---



We separate the environment creation from the EKS cluster creation in case we want to be able to adopt a seamless blue/green or canary migration later.

So first, we will create a Terraform stack for our environment that will contain shared resources such as VPC.

![Environment architecture diagram](/static/images/environment.png)