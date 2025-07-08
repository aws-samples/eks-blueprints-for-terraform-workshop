---
title: "Explore"
weight: 60
hidden: true
---

Now that we have completed the guided workshop, let's take some time to explore different aspects of what we've deployed and how we can monitor and observe our clusters.

Here are some suggested exploration activities:

1. Removing the webstore application from the Hub Cluster:
   - Investigate how we can configure the deployment to run the webstore application exclusively on the spoke cluster.
   - Consider the changes needed in the Argo CD configuration or Terraform files to achieve this.

2. CloudWatch Container Insights:
   - Explore the metrics and logs available in CloudWatch Container Insights for both the hub and spoke clusters.
   - Examine performance metrics, resource utilization, and any potential issues or bottlenecks.

3. Argo CD Project configuration:
   - Review the Argo CD Project settings and understand how they control deployment permissions and destinations.
   - Experiment with modifying project configurations to see how they affect deployment behavior.

4. Karpenter node provisioning:
   - Analyze how Karpenter is managing node provisioning for the webstore application.
   - Observe the scaling behavior as we interact with the webstore application.

5. Load balancer configuration:
   - Examine the AWS Load Balancer Controller configuration and how it's managing traffic to the webstore application.
   - Investigate options for customizing the load balancer settings.

We should take this opportunity to dig deeper into these areas and explore the capabilities of our deployed infrastructure. This hands-on exploration will help solidify our understanding of the Hub & Spoke architecture and its components.
