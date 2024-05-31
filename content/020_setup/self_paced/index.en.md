---
title: '...On Your Own'
chapter: false
weight: 11
---

::alert[If you ARE NOT at an AWS event : You will deploy an [AWS CloudFormation](https://aws.amazon.com/cloudformation/) stack to create the VPC environment (including subnets and routing tables), a **Workstation** EC2 instance which supports the Cloud-9 IDE, IAM roles, security groups and other prerequisites.]{type="info"}

**Note**: This workshop is designed for compatibility in the following regions: **us-east-1 (N.Virginia)**, **us-east-2 (Ohio)**, **us-west-2 (Oregon)**, **eu-west-1 (Ireland)**, **eu-west-3 (Paris)**, **ap-northeast-1 (Tokyo)**, **ap-northeast-2(Seoul)** and **ap-south-1 (Mumbai)**. Please ensure that your region is set appropriately in your account prior to beginning the workshop. The CloudFormation stack deploys in **us-east-1** by default unless otherwise specified

You can download the the CloudFormation script to launch the stack for the workshop:

:button[Download Template]{href="https://raw.githubusercontent.com/seb-tmp/eks-blueprints-for-terraform-workshop/main/static/cfn.yml?token=GHSAT0AAAAAACGSEW6IZ733BPPS3G5NIB66ZSZTZDQ"}

Todo: Add steps to create the stack