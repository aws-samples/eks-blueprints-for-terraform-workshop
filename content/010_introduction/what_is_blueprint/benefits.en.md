---
title: 'Benefits of EKS Blueprints'
weight: 11
---

## Why leverage the EKS Blueprints?

The ecosystem of tools that have developed around Kubernetes and the Cloud Native Computing Foundation (CNCF) provides cloud engineers with a wealth of choice when it comes to architecting their infrastructure. Determining the right mix of tools and services, however, in addition to how they integrate, can be a challenge. As your Kubernetes estate grows, managing configuration for your clusters can also become a challenge.

AWS customers are building internal platforms to tame this complexity, automate the management of their Kubernetes environments, and make it easy for developers to onboard their workloads. However, these platforms require an investment of time and engineering resources to build. The goal of this project is to provide customers with a tool chain that can help them deploy a platform on top of EKS with ease and best practices. EKS Blueprints provide logical abstractions and prescriptive guidance for building a platform. **Ultimately, we want to help EKS customers accelerate time to market for their own platform initiatives**.

### Separation of Concerns: Platform Teams vs Application Teams

Platform teams build the tools that provision, manage, and secure the underlying infrastructure, while application teams are free to focus on building the applications that deliver business value to customers. Application teams need to focus on writing code and quickly shipping products, but there must be certain standards that are uniform across all production applications to make them secure, compliant, and highly available.

EKS Blueprints provide a better workflow between platform and application teams and also provide a self-service interface for developers to use that is streamlined for developing code. The platform teams have full control to define standards on security, software delivery, monitoring, and networking that must be used across all applications deployed. This allows developers to be more productive because they don’t have to configure and manage the underlying cloud resources themselves. It also gives operators more control over making sure production applications are secure, compliant, and highly available.

### What does good look like?

EKS Blueprints will look slightly different between organizations depending on the requirements, but all of them look to solve the same set of problems listed below:
| Challenge | Solution provided by EKS Blueprints |
|:------------------------------------------------------------------:|:---------------------------------------------------------------------:|
| Developers wait days / weeks for infrastructure to be provisioned | Developers provision infrastructure on demand and deploy in minutes |
| Software is manually deployed on an ad-hoc basis | Software delivery is automated via continuous delivery pipelines |
| Security is configured ad-hoc for each application | Security best practices are baked in to every application and service |
| Developers lack visibility into applications running in production | Applications are fully instrumented for metric and log collection |
| Tooling is inconsistent across teams and business units | Organizations standardize on tools and best practices |

The reason why you would want to do this on top of AWS is because the breadth of services offered by AWS, paired with the vast open-source ecosystem backed by the Kubernetes community, provides a limitless number of different combinations of services and solutions to meet your specific requirements and needs. It is much easier to think about the benefits in the context of the core principles that EKS Blueprints was built upon, which include the following:

- Security and Compliance
- Cost Management
- Deployment Automation
- Provisioning of infrastructure
- Telemetry

In the next section, we will talk about the different personas that are involved in leveraging EKS Blueprints.
