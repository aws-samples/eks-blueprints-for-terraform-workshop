---
title: "Summary"
weight: 300
---

### Mastering Cluster Deployment and Workload Management with EKS Blueprints and GitOps

Congratulations on completing this workshop! Throughout this hands-on experience, we have gained valuable insights into using EKS Blueprints and GitOps principles for streamlining cluster deployment and workload management.

We learned how EKS Blueprints simplifies the process of deploying Kubernetes clusters using Infrastructure as Code (IaC) with Terraform. This approach ensures consistent and repeatable cluster provisioning, enabling us to scale our infrastructure efficiently.

We explored the powerful features of Argo CD, a GitOps tool that enables seamless onboarding of teams onto a shared cluster and centralized management of deployment processes. By leveraging Argo CD, we can orchestrate workload deployments from a centralized configuration cluster (the Hub) to one or more spoke clusters, ensuring a consistent and controlled rollout across our entire infrastructure.

One of the key advantages of this setup is its scalability and flexibility. As our organization grows, we can easily onboard additional teams by following GitOps principles and submitting Git pull requests for review. Argo CD will automatically create the necessary namespaces, ArgoProjects, and ArgoApplications across one or more clusters, streamlining the onboarding process and ensuring proper segregation of resources.

With this robust and scalable solution in place, we can confidently manage and deploy workloads across multiple clusters, ensuring a reliable and efficient application lifecycle management process throughout our organization. The combination of EKS Blueprints and GitOps principles empowers us to maintain a consistent, repeatable, and scalable approach to cluster deployment and workload management, fostering collaboration and enabling seamless integration with our existing Git repository and development workflows.

<!--
We see how we can leverage Argo Rollout to do application blue/green deployment.

We make use of Karpenter to allow our application to define and use the resources it needs while having the right EC2 nodes at the right time, binpacking our nodes, and keeping the cost of the cluster low.

We see how we can rely on Spot instances to even reduce our cluster cost and use Kubecost to optimize our workloads.

Finally, we focused on Day2 Operations, and how we can automate Blue/Green EKS cluster migration for doing updates.
-->

We hope you enjoyed this workshop and know that the EKS Blueprint project is open-source. Learn more at: https://github.com/aws-ia/terraform-aws-eks-blueprints

The Workshop content is public. If you would like to see additional modules, submit an issue in our GitHub repository: https://github.com/aws-samples/eks-blueprints-for-terraform-workshop/issues
