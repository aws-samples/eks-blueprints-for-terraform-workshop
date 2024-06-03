---
title : "Team Management"
weight : 33
---

In the next section, you will learn how to configure Application and Platform teams using EKS Blueprints. You'll learn the differences between the two, as well as the specific configuration of an Application Team object and how it can be used by the application team.

TODO: Change the diagramme
![Environment architecture diagram](/static/images/eks-blue.png)

## Terminology

In this part of the lab, we will cover how EKS Blueprints helps you manage cluster access for multiple teams in the organization. Before diving into the technical part, we want to introduce terminology from the [EKS Blueprints solution](https://aws-ia.github.io/terraform-aws-eks-blueprints/main/teams/), and also from the [AWS Well Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html) :

- **Component** (as defined in the [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/definitions.html)) - is the code, configuration, and AWS resources that together deliver against a requirement. A component is often the unit of technical ownership and is decoupled from other components.
- **Workload** - A set of components that together deliver business value. A workload is usually the level of detail that business and technology leaders communicate about.
- **Application Team** - A representation of a group of users/roles that are responsible for managing a specific workload in a namespace. Creating an Application Team creates a dedicated namespace for all of that team's components.
- **Platform Team** - This represents the cluster platform administrators who have admin access to the cluster. This construct doesn't create a dedicated namespace as the platform team has admin rights on the clusters. Note: A user or role that is configured in a Platform Team, can also be configured to act as one or more Application Teams in the cluster.

After setting up the based terminology, in this lab we will cover the following:

1. Add a Platform Team.
2. Add an Application Team that is responsible for the `core-services` workload.
3. Deploy a component into the application's team namespace.
