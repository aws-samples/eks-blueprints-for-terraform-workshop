---
title: "Test Hub Spoke Connectivity"
weight: 30
---

This chapter validates hub-spoke connectivity by checking for the AWS Load Balancer Controller and other addons installed on the spoke-staging cluster. In this workshop, Argo CD was configured to install addon by setting a label to true. The label enable_aws_load_balancer_controller=true installs the load balancer addon. This label was set during creation of the spoke cluster. Once hub-spoke connectivity between hub and spoke was established, Argo CD installed the load balancer on the spoke by detecting this label had been set.

You can check on the spoke staging secret the labels showing the addons we wanted to enable:

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

The Terraform blueprint modules and gitops bridge set up an IAM role that gets assigned to the service account for the Karpenter addon. This configures the necessary permissions for Karpenter to operate.

You can check the IAM role on the spoke-stagging annotations:

```bash
kubectl --context hub-cluster get secrets -n argocd spoke-staging -o json | jq ".metadata.annotations.karpenter_node_iam_role_name"
```

Expected output:

```
"Karpenter-spoke-staging-20241009092211264300000028"
```

The Argo CD dashboard should have the stagging load balancer addon.

![Stagging LB](/static/images/spoke_applications.jpg)

As you demonstrated in this chapter Argo CD allows enabling/disabling addons on a Kubernetes cluster by setting a boolean variable. When the variable is true, Terraform adds a label to the cluster resource telling Argo CD to install that addon.

:::alert{header="Congratulation!" type="success"}
Argo CD streamlines the deployment of additional add-ons across multiple EKS clusters, ensuring a consistent and efficient process.
:::
