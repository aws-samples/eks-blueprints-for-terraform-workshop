---
title: "In your AWS account"
chapter: false
weight: 11
---

::alert[If you ARE NOT at an AWS event : You will deploy an [AWS CloudFormation](https://aws.amazon.com/cloudformation/) stack to create the VPC environment (including subnets and routing tables), a **Workstation** EC2 instance which supports the Cloud-9 IDE, IAM roles, security groups and other prerequisites.]{type="info"}

**Note**: This workshop is designed with compatibility for any AWS Region that Amazon EKS available on. The default region that will be used, will be the one that's configured on the machine/laptop you're running the following installation from.

This workshop is hosted in the following GitHub repository under the `aws-samples` organization: https://github.com/aws-samples/fleet-management-on-amazon-eks-workshop/

## Prerequisites

1. An access to an AWS account with permissions to provision the following resources: VPC, IAM, EKS, ECR.
2. Have CloudFormation Access to execute the installation

## Cost

Provisioning this workshop environment in your AWS account will create resources and there will be cost associated with them. The [cleanup](/090-cleanup) section provides a guide to remove them, preventing further charges.

## Bootstrapping the environment

Use the AWS CloudFormation quick-create links below to launch the desired template in the appropriate AWS region. The CloudFormation output will have the IDE url and password to use for the workshop.

| Region           | CloudFormation                                                                                                                                                                                                                                                                                                                                            |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `us-west-2`      | [Launch](https://us-west-2.console.aws.amazon.com/cloudformation/home#/stacks/quickcreate?templateUrl=https://ws-assets-prod-iad-r-pdx-f3b3f9f1a7d6a3d0.s3.us-west-2.amazonaws.com/d2b662ae-e9d7-4b31-b68b-64ade19d5dcc/eks-blueprints-workshop-team-stack-self.json&stackName=eks-blueprints-workshop&param_RepositoryRef=VAR::MANIFESTS_REF)            |
| `us-east-2`      | [Launch](https://us-east-2.console.aws.amazon.com/cloudformation/home#/stacks/quickcreate?templateUrl=https://ws-assets-prod-iad-r-cmh-8d6e9c21a4dec77d.s3.us-east-2.amazonaws.com/d2b662ae-e9d7-4b31-b68b-64ade19d5dcc/eks-blueprints-workshop-team-stack-self.json&stackName=eks-blueprints-workshop&param_RepositoryRef=VAR::MANIFESTS_REF)            |
| `eu-west-1`      | [Launch](https://eu-west-1.console.aws.amazon.com/cloudformation/home#/stacks/quickcreate?templateUrl=https://ws-assets-prod-iad-r-dub-85e3be25bd827406.s3.eu-west-1.amazonaws.com/d2b662ae-e9d7-4b31-b68b-64ade19d5dcc/eks-blueprints-workshop-team-stack-self.json&stackName=eks-blueprints-workshop&param_RepositoryRef=VAR::MANIFESTS_REF)            |
| `eu-west-3`      | [Launch](https://eu-west-3.console.aws.amazon.com/cloudformation/home#/stacks/quickcreate?templateUrl=https://ws-assets-prod-iad-r-cdg-9e76383c31ad6229.s3.eu-west-3.amazonaws.com/d2b662ae-e9d7-4b31-b68b-64ade19d5dcc/eks-blueprints-workshop-team-stack-self.json&stackName=eks-blueprints-workshop&param_RepositoryRef=VAR::MANIFESTS_REF)            |
| `ap-southeast-1` | [Launch](https://ap-southeast-1.console.aws.amazon.com/cloudformation/home#/stacks/quickcreate?templateUrl=https://ws-assets-prod-iad-r-sin-694a125e41645312.s3.ap-southeast-1.amazonaws.com/d2b662ae-e9d7-4b31-b68b-64ade19d5dcc/eks-blueprints-workshop-team-stack-self.json&stackName=eks-blueprints-workshop&param_RepositoryRef=VAR::MANIFESTS_REF") |

Enter a valid IAM role ARN, that will be used to access EKS clusters (this is generally the IAM role you assume to work in your account)

!["enter IAM role for EKS access"](/static/images/cfn_quickstart.jpg)

:::alert{header=Note type=success}
This might take some time (approximately 15 minutes).
:::

If you want to deploy in another region, you can download the Cloudformation template and run it in the region of your choice.

:button[CloudFormation Template]{variant="primary" href=":assetUrl{path="eks-blueprints-workshop-team-stack-self.json" source=s3}" download}

CloudFormation and create a stack for the Workshop

Validate the next steps keeping default options to create the stack, and wait to the CloudFormation stack to be `CREATE_COMPLETE`.
