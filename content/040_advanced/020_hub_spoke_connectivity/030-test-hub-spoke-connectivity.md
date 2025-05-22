---
title: "Test Hub Spoke Connectivity"
weight: 30
---

In this chapter, we will validate hub-spoke connectivity by examining the AWS Load Balancer Controller and other addons installed on the spoke-staging cluster. Throughout this workshop, we configured Argo CD to install addons by setting specific labels to true. For example, setting the label `enable_aws_load_balancer_controller=true` triggers the installation of the load balancer addon. This label was configured during the spoke cluster creation. Once we established hub-spoke connectivity, Argo CD detected this label and automatically installed the load balancer on the spoke cluster.

We can verify the addon configuration by checking the labels on the spoke staging secret:

```bash
kubectl --context hub-cluster get secrets -n argocd spoke-staging -o json | jq ".metadata.labels" | grep enable_ | grep true
```

Expected Output:

```
  "enable_aws_ebs_csi_resources": "true",
  "enable_aws_load_balancer_controller": "true",
  "enable_cni_metrics_helper": "true",
  "enable_cw_prometheus": "true",
  "enable_karpenter": "true",
  "enable_kyverno": "true",
  "enable_kyverno_policies": "true",
  "enable_kyverno_policy_reporter": "true",
  "enable_metrics_server": "true",
```

The Terraform blueprint modules and GitOps bridge establish an IAM role that gets assigned to the Karpenter addon's service account. This configuration provides Karpenter with the necessary permissions to operate.

We can verify the IAM role configuration in the spoke-staging annotations:

```bash
kubectl --context hub-cluster get secrets -n argocd spoke-staging -o json | jq ".metadata.annotations.karpenter_node_iam_role_name"
```

Expected output:

```
"Karpenter-spoke-staging-20241009092211264300000028"
```

The Argo CD dashboard should now display the staging load balancer addon.

![Staging LB](/static/images/spoke_applications.jpg)

As demonstrated in this chapter, Argo CD enables us to manage addons on a Kubernetes cluster through simple boolean variables. When we set a variable to true, Terraform adds a corresponding label to the cluster resource, instructing Argo CD to install that addon.

:::alert{header="Congratulations!" type="success"}
Argo CD streamlines the deployment of additional add-ons across multiple EKS clusters, ensuring a consistent and efficient process.
:::
