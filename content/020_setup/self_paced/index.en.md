---
title: 'In your AWS account'
chapter: false
weight: 11
---

::alert[If you ARE NOT at an AWS event : You will deploy an [AWS CloudFormation](https://aws.amazon.com/cloudformation/) stack to create the VPC environment (including subnets and routing tables), a **Workstation** EC2 instance which supports the Cloud-9 IDE, IAM roles, security groups and other prerequisites.]{type="info"}

**Note**: This workshop is designed for compatibility in the following regions: **us-east-1 (N.Virginia)**, **us-east-2 (Ohio)**, **us-west-2 (Oregon)**, **eu-west-1 (Ireland)**, **eu-west-3 (Paris)**, **ap-northeast-1 (Tokyo)**, **ap-northeast-2(Seoul)** and **ap-south-1 (Mumbai)**. Please ensure that your region is set appropriately in your account prior to beginning the workshop. The CloudFormation stack deploys in **us-east-1** by default unless otherwise specified

You can download the the CloudFormation script to launch the stack for the workshop:

:button[Download Template]{href="https://raw.githubusercontent.com/aws-samples/eks-blueprints-for-terraform-workshop/mainline/static/cfn.yml" download}

Then go to CloudFormation and create a stack for the Workshop

![](/static/images/cfn-create-stack.png)

![](/static/images/cfn-create-stack2.png)

Validate the next steps keeping default options to create the stack, and wait to the CloudFormation stack to be `CREATE_COMPLETE`.
