---
title: '...On Your Own'
chapter: false
weight: 11
---

::alert[If you ARE NOT at an AWS event : You will deploy an [AWS CloudFormation](https://aws.amazon.com/cloudformation/) stack to create the VPC environment (including subnets and routing tables), a **Workstation** EC2 instance which supports the Cloud-9 IDE, IAM roles, security groups and other prerequisites.]{type="info"}

**Note**: This workshop is designed for compatibility in the following regions: **us-east-1 (N.Virginia)**, **us-east-2 (Ohio)**, **us-west-2 (Oregon)**, **eu-west-1 (Ireland)**, **eu-west-3 (Paris)**, **ap-northeast-1 (Tokyo)**, **ap-northeast-2(Seoul)** and **ap-south-1 (Mumbai)**. Please ensure that your region is set appropriately in your account prior to beginning the workshop. The CloudFormation stack deploys in **us-east-1** by default unless otherwise specified

You can download the the CloudFormation script to launch the stack for the workshop:

:button[Download Template]{href=":assetUrl{path="/cfn.yml" source=repo}"}

1. Go to the CloudFormation console and click on **Create Stack** and upload the template and click **Next**

![CloudFormation_StackDeploy](/static/images/cloudformation1.png)

1. Enter **eks-blueprint** as the  **Stack name**, leave the default values for other fields but enter the IAM role in **OwnerArn** with the role which can be assumed to access the AWS Cloud9 IDE, like `arn:aws:sts::012345678910:assumed-role/Admin/Isengard`

![CloudFormation_StackDeploy](/static/images/cloudformation2.png)

1. Skip **Configure stack options** and click **Next**.

2. Review and create - check **I acknowledge that AWS CloudFormation might create IAM resources** and click **Submit**

![CloudFormation_03](/static/images/cloud_formation3.png)

1. Wait till the stack status turned to **CREATE_COMPLETE**. This may take up to 5 minutes.

![CloudFormation_04](/static/images/cloud_formation4.png)
