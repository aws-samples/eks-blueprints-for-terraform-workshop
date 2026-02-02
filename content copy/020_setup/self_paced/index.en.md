---
title: "In your AWS account"
chapter: false
weight: 11
---

::alert[If we are NOT at an AWS event: We will deploy an [AWS CloudFormation](https://aws.amazon.com/cloudformation/) stack to create the VPC environment (including subnets and routing tables), a **Workstation** EC2 instance which supports the Cloud-9 IDE, IAM roles, security groups and other prerequisites.]{type="info"}

**Note**: This workshop is compatible with any AWS Region where Amazon EKS is available. The default region will be the one configured on the machine/laptop from which we are running the installation.

This workshop is hosted in the following GitHub repository under the `aws-samples` organization: https://github.com/aws-samples/fleet-management-on-amazon-eks-workshop/

## Prerequisites

1. Access to an AWS account with permissions to provision the following resources: VPC, IAM, EKS, ECR.
2. CloudFormation access to execute the installation.

## Cost

Provisioning this workshop environment in our AWS account will create resources that incur costs. The [cleanup](/090-cleanup/) section provides instructions to remove these resources, preventing further charges.

## Bootstrapping the environment

We can use the AWS CloudFormation quick-create links below to launch the template in our preferred AWS region. The CloudFormation output will provide the IDE URL and password needed for the workshop.

| Region           | CloudFormation                                                                                                                                                                                                                                                                                                                                            |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `us-west-2`      | [Launch](https://us-west-2.console.aws.amazon.com/cloudformation/home#/stacks/quickcreate?templateUrl=https://ws-assets-prod-iad-r-pdx-f3b3f9f1a7d6a3d0.s3.us-west-2.amazonaws.com/d2b662ae-e9d7-4b31-b68b-64ade19d5dcc/eks-blueprints-workshop-team-stack-self.json&stackName=eks-blueprints-workshop&param_RepositoryRef=VAR::MANIFESTS_REF)            |
| `us-east-2`      | [Launch](https://us-east-2.console.aws.amazon.com/cloudformation/home#/stacks/quickcreate?templateUrl=https://ws-assets-prod-iad-r-cmh-8d6e9c21a4dec77d.s3.us-east-2.amazonaws.com/d2b662ae-e9d7-4b31-b68b-64ade19d5dcc/eks-blueprints-workshop-team-stack-self.json&stackName=eks-blueprints-workshop&param_RepositoryRef=VAR::MANIFESTS_REF)            |
| `eu-west-1`      | [Launch](https://eu-west-1.console.aws.amazon.com/cloudformation/home#/stacks/quickcreate?templateUrl=https://ws-assets-prod-iad-r-dub-85e3be25bd827406.s3.eu-west-1.amazonaws.com/d2b662ae-e9d7-4b31-b68b-64ade19d5dcc/eks-blueprints-workshop-team-stack-self.json&stackName=eks-blueprints-workshop&param_RepositoryRef=VAR::MANIFESTS_REF)            |
| `eu-west-3`      | [Launch](https://eu-west-3.console.aws.amazon.com/cloudformation/home#/stacks/quickcreate?templateUrl=https://ws-assets-prod-iad-r-cdg-9e76383c31ad6229.s3.eu-west-3.amazonaws.com/d2b662ae-e9d7-4b31-b68b-64ade19d5dcc/eks-blueprints-workshop-team-stack-self.json&stackName=eks-blueprints-workshop&param_RepositoryRef=VAR::MANIFESTS_REF)            |
| `ap-southeast-1` | [Launch](https://ap-southeast-1.console.aws.amazon.com/cloudformation/home#/stacks/quickcreate?templateUrl=https://ws-assets-prod-iad-r-sin-694a125e41645312.s3.ap-southeast-1.amazonaws.com/d2b662ae-e9d7-4b31-b68b-64ade19d5dcc/eks-blueprints-workshop-team-stack-self.json&stackName=eks-blueprints-workshop&param_RepositoryRef=VAR::MANIFESTS_REF") |

We need to enter a valid IAM role ARN that will be used to access EKS clusters (this is typically the IAM role we assume to work in our account).

!["enter IAM role for EKS access"](/static/images/cfn_quickstart.jpg)

:::alert{header=Note type=success}
This process may take approximately 15 minutes to complete.
:::

If we want to deploy in another region, we can download the CloudFormation template and run it in our region of choice.

:button[CloudFormation Template]{variant="primary" href=":assetUrl{path="eks-blueprints-workshop-team-stack-self.json" source=s3}" download}

Create a stack for the workshop using CloudFormation.

Keep the default options while creating the stack, and wait for the CloudFormation stack status to show `CREATE_COMPLETE`.
